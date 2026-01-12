import 'package:capstone_app/data/models/appointment_model.dart';
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/conversation_model.dart';
import 'package:capstone_app/data/models/message_model.dart';
import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/data/models/user_model.dart';
import 'package:capstone_app/data/models/user_status_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:capstone_app/web/admin_web/components/appointments/admin_web_appointment_controller.dart';
import 'package:capstone_app/web/pages/web_admin_home/web_admin_home_controller.dart';
import 'package:appwrite/appwrite.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get_storage/get_storage.dart';

class AdminDashboardController extends GetxController {
  final AuthRepository authRepository;
  final UserSessionService session;

  AdminDashboardController({
    required this.authRepository,
    required this.session,
  });

  RealtimeSubscription? _conversationSubscription;
  RealtimeSubscription? _messageSubscription;

  var isLoading = false.obs;
  var clinicData = Rxn<Clinic>();
  var appointments = <Appointment>[].obs;
  var appointmentStats = <String, int>{}.obs;
  var todayAppointments = <Appointment>[].obs;
  var upcomingAppointments = <Appointment>[].obs;
  var recentMessages = <Map<String, dynamic>>[].obs;
  var monthlyStats = <String, int>{}.obs;
  var petsCache = <String, Pet>{}.obs;
  var ownersCache = <String, Map<String, dynamic>>{}.obs;

  var selectedDate = DateTime.now().obs;
  var calendarAppointments = <DateTime, List<Appointment>>{}.obs;

  RealtimeSubscription? _appointmentSubscription;
  Timer? _fallbackTimer;
  var lastUpdateTime = DateTime.now().obs;
  var isRealTimeConnected = false.obs;

  var currentMessages = <Message>[].obs;
  var isLoadingConversation = false.obs;
  var isSendingMessage = false.obs;
  final messageController = TextEditingController();
  final scrollController = ScrollController();
  final appointmentController = Get.find<WebAppointmentController>();

  var petProfilePictures = <String, String?>{}.obs;
  var petImageLoadingStates = <String, bool>{}.obs;

  var isDashboardCached = false.obs;
  var lastCacheTime = Rxn<DateTime>();
  final int cacheValidityMinutes = 30;

  // ============================================
// CRITICAL FIX: Dashboard should NOT reload when cached
// Replace these methods in admin_dashboard_controller.dart
// ============================================

// ============================================
// 1. FIXED onInit() - Instant display with cache
// ============================================
  @override
  void onInit() {
    super.onInit();

    // CRITICAL: Check cache FIRST
    if (_isCacheValid()) {
      // CRITICAL: Don't set loading - data is already there!
      isLoading.value = false;

      // Reconnect real-time in background (non-blocking)
      Future.microtask(() {
        _initializeRealTimeUpdates().then((_) {}).catchError((e) {});
      });
    } else {
      isLoading.value = true;
      initializeDashboard();
    }

    // Setup date change listener
    ever(selectedDate, (_) => fetchAppointmentsForDate(selectedDate.value));
  }

  @override
  void onClose() {
    // CRITICAL: Only close real-time connections, DON'T clear data
    try {
      _appointmentSubscription?.close();
    } catch (e) {}

    try {
      _conversationSubscription?.close();
    } catch (e) {}

    try {
      _messageSubscription?.close();
    } catch (e) {}

    try {
      _fallbackTimer?.cancel();
    } catch (e) {}

    // CRITICAL: DON'T clear cached data - it will be reused on next init
    // DON'T call cleanupOnLogout() here - only call it from LogoutHelper

    super.onClose();
  }

  bool _isCacheValid() {
    // Check if cache flag is set
    if (!isDashboardCached.value) {
      return false;
    }

    // Check if cache timestamp exists
    if (lastCacheTime.value == null) {
      return false;
    }

    // Check cache age
    final cacheAge = DateTime.now().difference(lastCacheTime.value!);
    final isValid = cacheAge.inMinutes < cacheValidityMinutes;

    // If valid by time, check if we have essential data
    if (isValid) {
      final hasClinic = clinicData.value != null;
      final hasStats = appointmentStats.isNotEmpty;

      // Must have clinic data at minimum
      if (!hasClinic) {
        return false;
      }

      return true;
    }

    return false;
  }

  void invalidateCache() {
    isDashboardCached.value = false;
    lastCacheTime.value = null;
  }

  @override
  Future<void> initializeDashboard() async {
    try {

      // CRITICAL: Ensure WebAppointmentController is available
      if (!Get.isRegistered<WebAppointmentController>()) {

        // Register the controller if it doesn't exist
        Get.put(
          WebAppointmentController(
            authRepository: authRepository,
            session: session,
          ),
          permanent: true,
        );
      }

      // Step 1: Fetch clinic data FIRST
      await fetchClinicData();

      if (clinicData.value == null || clinicData.value?.documentId == null) {
        isLoading.value = false;
        Get.snackbar(
          "Error",
          "Unable to load clinic data. Please check your permissions and try again.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
        return;
      }


      // Step 2: Fetch MINIMAL data in parallel
      try {
        await Future.wait([
          fetchPendingAppointments(force: true), // For the pending section
          fetchUpcomingAppointments(force: true),
          fetchRecentMessages(),
          // Don't fetch stats here - we'll get them from appointment controller
        ]);

        // CRITICAL: Mark cache as valid AFTER data is loaded
        isDashboardCached.value = true;
        lastCacheTime.value = DateTime.now();
      } catch (e) {
      }

      // Step 3: Generate calendar data
      try {
        await generateCalendarData();
      } catch (e) {
      }

      // Step 4: Initialize real-time updates LAST
      try {
        await _initializeRealTimeUpdates();
      } catch (e) {
      }

      // Step 5: Trigger appointment controller to ensure it has data
      try {
        final appointmentController = Get.find<WebAppointmentController>();
        if (appointmentController.appointments.isEmpty) {
          await appointmentController.fetchClinicData();
        }
      } catch (e) {
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to load dashboard: ${e.toString()}",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading.value = false;
    }
  }

// Add this method to refresh messages separately if needed
  Future<void> refreshMessages() async {
    try {
      await fetchRecentMessages();
    } catch (e) {}
  }

  Future<void> _subscribeToAppointmentUpdates() async {
    try {
      // Ensure old subscription is closed
      await _appointmentSubscription?.close();
      _appointmentSubscription = null;

      if (clinicData.value?.documentId == null) {
        return;
      }

      final realtime = Realtime(authRepository.client);


      _appointmentSubscription = realtime.subscribe([
        'databases.${AppwriteConstants.dbID}.collections.${AppwriteConstants.appointmentCollectionID}.documents'
      ]);

      _appointmentSubscription!.stream.listen(
        (response) {
          try {

            // CRITICAL: Verify this update is for OUR clinic
            final updateClinicId = response.payload['clinicId'];
            final ourClinicId = clinicData.value?.documentId;

            if (updateClinicId != ourClinicId) {
              return;
            }

            _handleAppointmentRealTimeUpdate(response);

            // Update connection status
            isRealTimeConnected.value = true;
            lastUpdateTime.value = DateTime.now();
          } catch (e) {
          }
        },
        onError: (error) {
          isRealTimeConnected.value = false;

          // Try to reconnect after delay
          Future.delayed(const Duration(seconds: 5), () {
            if (clinicData.value?.documentId != null) {
              _subscribeToAppointmentUpdates().catchError((e) {
              });
            }
          });

          // Increase fallback polling frequency
          _setupFallbackPolling(interval: 10);
        },
        onDone: () {
          isRealTimeConnected.value = false;

          // Try to reconnect
          Future.delayed(const Duration(seconds: 3), () {
            if (clinicData.value?.documentId != null) {
              _subscribeToAppointmentUpdates().catchError((e) {
              });
            }
          });
        },
      );

      isRealTimeConnected.value = true;
      lastUpdateTime.value = DateTime.now();
    } catch (e, stackTrace) {
      isRealTimeConnected.value = false;

      // Setup fallback polling
      _setupFallbackPolling(interval: 15);
      rethrow;
    }
  }

  void _handleAppointmentRealTimeUpdate(RealtimeMessage response) {
    try {
      final payload = response.payload;
      final appointmentId = payload['\$id'];

      final appointment = Appointment.fromMap(payload);

      // Determine event type
      bool isCreate = false;
      bool isUpdate = false;
      bool isDelete = false;

      for (String event in response.events) {
        if (event.contains('.create')) {
          isCreate = true;
        } else if (event.contains('.update')) {
          isUpdate = true;
        } else if (event.contains('.delete')) {
          isDelete = true;
        }
      }

      // Handle the update
      if (isDelete) {
        _handleDeletedAppointment(appointment);
      } else if (isCreate) {
        _handleNewAppointment(appointment);
      } else if (isUpdate) {
        _handleUpdatedAppointment(appointment);
      }

      // Update timestamp
      lastUpdateTime.value = DateTime.now();

      // Show notification for new appointments
      if (isCreate && appointment.status == 'pending') {
        _showNewAppointmentNotification(appointment);
      }
    } catch (e, stackTrace) {}
  }

  void _handleNewAppointment(Appointment appointment) {
    try {

      // Check if appointment already exists in main list
      final existingIndex = appointments.indexWhere(
        (a) => a.documentId == appointment.documentId,
      );

      if (existingIndex == -1) {
        appointments.add(appointment);
      } else {
        appointments[existingIndex] = appointment;
        appointments.refresh();
      }

      // CRITICAL: Only show in pending section if status is PENDING
      if (appointment.status == 'pending') {

        // FIXED: Work with current list, don't rebuild from scratch
        final currentList = List<Appointment>.from(todayAppointments);

        // Check if appointment already exists in pending list
        final existingPendingIndex = currentList.indexWhere(
          (a) => a.documentId == appointment.documentId,
        );

        if (existingPendingIndex != -1) {
          // Remove old version
          currentList.removeAt(existingPendingIndex);
        }

        // Insert at the correct position based on date/time (soonest first)
        int insertIndex = 0;
        for (int i = 0; i < currentList.length; i++) {
          final current = currentList[i];
          if (appointment.dateTime.isBefore(current.dateTime)) {
            insertIndex = i;
            break;
          }
          insertIndex = i + 1;
        }

        // Insert at calculated position
        currentList.insert(insertIndex, appointment);

        // Keep only top 5
        final top5 = currentList.take(5).toList();

        for (var i = 0; i < top5.length; i++) {
        }

        // Update with smooth transition
        todayAppointments.value = List.from(top5);
      } else {
      }

      // Update other lists
      _processUpcomingAppointments();
      _updateAppointmentStats();
      _updateCalendarData(appointment, isNew: true);

      // Fetch related data if not cached
      if (!petsCache.containsKey(appointment.petId)) {
        _fetchOwnerData(appointment.userId);
        preloadPetImagesForAppointments([appointment]);
      }

      // Update cache timestamp
      lastCacheTime.value = DateTime.now();
    } catch (e) {
    }
  }

  void _handleUpdatedAppointment(Appointment appointment) {
    try {

      // Update in main list
      final index = appointments.indexWhere(
        (a) => a.documentId == appointment.documentId,
      );

      if (index != -1) {
        final oldStatus = appointments[index].status;
        appointments[index] = appointment;
      } else {
        appointments.add(appointment);
      }

      // CRITICAL: Check if this appointment is in pending list
      final isInPendingList = todayAppointments.any(
        (a) => a.documentId == appointment.documentId,
      );

      if (isInPendingList) {

        // CRITICAL: If status changed from pending, REMOVE it from pending list
        if (appointment.status != 'pending') {

          final currentList = List<Appointment>.from(todayAppointments);
          currentList
              .removeWhere((a) => a.documentId == appointment.documentId);

          // Try to fill the gap with another pending appointment
          if (currentList.length < 5) {

            final allPendingAppts = appointments.where((appt) {
              return appt.status == 'pending' &&
                  !currentList.any(
                      (existing) => existing.documentId == appt.documentId);
            }).toList();

            // Sort by date/time (soonest first)
            allPendingAppts.sort((a, b) => a.dateTime.compareTo(b.dateTime));

            // Add to fill up to 5
            final needed = 5 - currentList.length;
            final toAdd = allPendingAppts.take(needed).toList();
            currentList.addAll(toAdd);

          }

          // Update with new list
          todayAppointments.value = List.from(currentList);
        } else {
          // Status is still pending - just update in place

          final currentList = List<Appointment>.from(todayAppointments);
          final existingIndex = currentList.indexWhere(
            (a) => a.documentId == appointment.documentId,
          );

          if (existingIndex != -1) {
            // Remove from current position
            currentList.removeAt(existingIndex);

            // Find new correct position based on date/time
            int insertIndex = 0;
            for (int i = 0; i < currentList.length; i++) {
              if (appointment.dateTime.isBefore(currentList[i].dateTime)) {
                insertIndex = i;
                break;
              }
              insertIndex = i + 1;
            }

            // Reinsert at new position
            currentList.insert(insertIndex, appointment);
            todayAppointments.value = List.from(currentList.take(5));
          }
        }
      } else if (appointment.status == 'pending') {
        // Not in list but is now pending - check if it should be in top 5

        final allPendingAppts = appointments.where((appt) {
          return appt.status == 'pending';
        }).toList();

        // Sort by date/time
        allPendingAppts.sort((a, b) => a.dateTime.compareTo(b.dateTime));

        // Take top 5
        final top5 = allPendingAppts.take(5).toList();

        // Check if updated appointment is in top 5
        final isInTop5 =
            top5.any((a) => a.documentId == appointment.documentId);

        if (isInTop5) {
          todayAppointments.value = List.from(top5);
        } else {
        }
      }

      // Update other lists
      _processUpcomingAppointments();
      _updateAppointmentStats();
      _updateCalendarData(appointment, isUpdate: true);

      // Update cache timestamp
      lastCacheTime.value = DateTime.now();
    } catch (e) {
    }
  }

  void _handleDeletedAppointment(Appointment appointment) {
    try {

      // Remove from main list
      final removedCount = appointments.length;
      appointments.removeWhere((a) => a.documentId == appointment.documentId);
      final actuallyRemoved = removedCount - appointments.length;

      if (actuallyRemoved > 0) {

        // Check if it was in pending list
        final wasInPending = todayAppointments.any(
          (a) => a.documentId == appointment.documentId,
        );

        if (wasInPending) {

          // Remove from pending list
          final currentList = List<Appointment>.from(todayAppointments);
          currentList
              .removeWhere((a) => a.documentId == appointment.documentId);

          // Try to fill the gap with another pending appointment
          if (currentList.length < 5) {

            final allPendingAppts = appointments.where((appt) {
              return appt.status == 'pending' &&
                  !currentList.any(
                      (existing) => existing.documentId == appt.documentId);
            }).toList();

            // Sort by date/time (soonest first)
            allPendingAppts.sort((a, b) => a.dateTime.compareTo(b.dateTime));

            // Add to fill up to 5
            final needed = 5 - currentList.length;
            final toAdd = allPendingAppts.take(needed).toList();
            currentList.addAll(toAdd);

          }

          // Create new list
          final newList = <Appointment>[];
          for (var appt in currentList) {
            newList.add(appt);
          }

          todayAppointments.value = newList;
        }
      }

      // Update other lists
      _processUpcomingAppointments();
      _updateAppointmentStats();
      _removeFromCalendarData(appointment);

      // Update cache timestamp
      lastCacheTime.value = DateTime.now();
    } catch (e) {
    }
  }

  void _updateCalendarData(Appointment appointment,
      {bool isNew = false, bool isUpdate = false}) {
    final date = DateTime(
      appointment.dateTime.year,
      appointment.dateTime.month,
      appointment.dateTime.day,
    );

    if (isNew || isUpdate) {
      if (calendarAppointments[date] == null) {
        calendarAppointments[date] = [];
      }

      if (isUpdate) {
        calendarAppointments[date]!
            .removeWhere((a) => a.documentId == appointment.documentId);
      }

      calendarAppointments[date]!.add(appointment);
    }

    calendarAppointments.refresh();
  }

  void _removeFromCalendarData(Appointment appointment) {
    final date = DateTime(
      appointment.dateTime.year,
      appointment.dateTime.month,
      appointment.dateTime.day,
    );

    calendarAppointments[date]
        ?.removeWhere((a) => a.documentId == appointment.documentId);
    if (calendarAppointments[date]?.isEmpty ?? false) {
      calendarAppointments.remove(date);
    }
    calendarAppointments.refresh();
  }

  void _updateAppointmentStats() {
    try {

      final stats = <String, int>{
        'total': appointments.length,
        'pending': appointments.where((a) => a.status == 'pending').length,
        'accepted': appointments.where((a) => a.status == 'accepted').length,
        'completed': appointments.where((a) => a.status == 'completed').length,
        'cancelled': appointments.where((a) => a.status == 'cancelled').length,
        'declined': appointments.where((a) => a.status == 'declined').length,
        'today': todayAppointments.length, // This is now pending count
      };

      appointmentStats.assignAll(stats);
      appointmentStats.refresh();

      // Changed label
    } catch (e) {
    }
  }

  void _showNewAppointmentNotification(Appointment appointment) {
    // Get.snackbar(
    //   "New Appointment",
    //   "New appointment from ${getOwnerName(appointment.userId)} for ${getPetName(appointment.petId)}",
    //   backgroundColor: Colors.green,
    //   colorText: Colors.white,
    //   duration: const Duration(seconds: 5),
    //   snackPosition: SnackPosition.TOP,
    //   mainButton: TextButton(
    //     onPressed: () {
    //       navigateToAppointments('pending');
    //     },
    //     child: const Text("View", style: TextStyle(color: Colors.white)),
    //   ),
    // );
  }

  /// Setup more aggressive fallback polling for messages
  void _setupFallbackPolling({int interval = 30}) {
    _fallbackTimer?.cancel();

    _fallbackTimer = Timer.periodic(Duration(seconds: interval), (timer) {
      if (!isRealTimeConnected.value) {
        // Refresh both appointments and messages
        Future.wait([
          fetchAllAppointments(),
          fetchRecentMessages(),
        ]);
      }
    });
  }

  @override
  Future<void> refreshDashboard() async {
    try {
      // Check if cache is still valid and real-time is connected
      if (_isCacheValid() && isRealTimeConnected.value) {
        lastUpdateTime.value = DateTime.now();

        Get.snackbar(
          "Already Up-to-Date",
          "Dashboard is showing live data",
          backgroundColor: Colors.blue,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(8),
        );

        return;
      }

      // Silently refresh in background (no loading spinner)
      await Future.wait([
        fetchPendingAppointments(force: true),
        fetchUpcomingAppointments(force: true),
        fetchRecentMessages(),
        fetchAppointmentStats(),
      ]);

      // Update cache timestamp
      lastCacheTime.value = DateTime.now();
      lastUpdateTime.value = DateTime.now();
      isDashboardCached.value = true;

      Get.snackbar(
        "Refreshed",
        "Dashboard data updated",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(8),
      );
    } catch (e) {
      Get.snackbar(
        "Refresh Failed",
        "Could not update dashboard data",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }

    // Try to reconnect real-time if disconnected
    if (!isRealTimeConnected.value) {
      try {
        await _initializeRealTimeUpdates();
      } catch (e) {}
    }
  }

  /// Send a message in the current conversation
  Future<void> sendMessageInConversation({
    required String conversationId,
    required String messageText,
    bool isStarterMessage = false,
  }) async {
    try {
      if (messageText.trim().isEmpty) {
        return;
      }

      isSendingMessage.value = true;

      // Send the message using the updated repository method
      final message = await authRepository.sendMessage(
        conversationId: conversationId,
        senderId: session.userId,
        messageText: messageText,
      );

      // Add to current messages list
      currentMessages.add(message);
      currentMessages.refresh();

      // Clear input
      messageController.clear();

      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to send message: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isSendingMessage.value = false;
    }
  }

  /// Mark all messages in a conversation as read
  Future<void> markConversationAsRead(String conversationId) async {
    try {
      await authRepository.markMessagesAsRead(conversationId, session.userId);
    } catch (e) {}
  }

  /// Open a specific conversation and load its messages
  Future<void> openConversation(
    Conversation conversation,
    String userId,
    String userType,
  ) async {
    try {
      isLoadingConversation.value = true;

      // Load messages for this conversation
      final messages = await authRepository.getConversationMessages(
        conversation.documentId!,
        limit: 50,
      );

      currentMessages.assignAll(messages);
      currentMessages.refresh();

      // Mark as read
      await markConversationAsRead(conversation.documentId!);

      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          scrollController.jumpTo(scrollController.position.maxScrollExtent);
        }
      });
    } catch (e) {
      Get.snackbar('Error', 'Failed to open conversation');
    } finally {
      isLoadingConversation.value = false;
    }
  }

  /// Check if a user ID belongs to current admin
  bool isCurrentUser(String userId) {
    return userId == session.userId;
  }

  /// Get user status by user ID
  UserStatus? getUserStatus(String userId) {
    try {
      // This would typically fetch from a cache or provider
      // For now, return offline status
      return UserStatus.offline(userId);
    } catch (e) {
      return null;
    }
  }

  /// Handle incoming real-time message
  void _handleIncomingMessage(Message message) {
    try {
      // Check if message already exists
      final exists =
          currentMessages.any((m) => m.documentId == message.documentId);

      if (!exists) {
        currentMessages.add(message);
        currentMessages.refresh();

        // Auto-scroll to bottom
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scrollController.hasClients) {
            scrollController.animateTo(
              scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });

        // Mark as read
        markConversationAsRead(message.conversationId);
      }

      // Refresh recent messages if needed
      Future.delayed(const Duration(milliseconds: 500), () {
        refreshMessages();
      });
    } catch (e) {}
  }

  /// Subscribe to conversation updates for real-time message refreshes
  Future<void> _subscribeToConversationUpdates() async {
    try {
      await _conversationSubscription?.close();

      if (clinicData.value?.documentId == null) {
        return;
      }

      final realtime = Realtime(authRepository.client);

      _conversationSubscription = realtime.subscribe([
        'databases.${AppwriteConstants.dbID}.collections.${AppwriteConstants.conversationsCollectionID}.documents'
      ]);

      _conversationSubscription!.stream.listen(
        (response) {
          _handleConversationRealTimeUpdate(response);
        },
        onError: (error) {
          Future.delayed(const Duration(seconds: 3), () {
            if (clinicData.value?.documentId != null) {
              _subscribeToConversationUpdates();
            }
          });
        },
        onDone: () {},
      );
    } catch (e) {}
  }

  Future<void> _initializeRealTimeUpdates() async {
    if (clinicData.value == null || clinicData.value?.documentId == null) {
      return;
    }

    try {

      // Close old subscriptions first
      await _appointmentSubscription?.close();
      _appointmentSubscription = null;

      await _conversationSubscription?.close();
      _conversationSubscription = null;

      await _messageSubscription?.close();
      _messageSubscription = null;

      _fallbackTimer?.cancel();
      _fallbackTimer = null;

      // Subscribe to appointments
      await _subscribeToAppointmentUpdates();

      // Subscribe to conversations (for message updates)
      await _subscribeToConversationUpdates();

      // Setup fallback polling (safety net)
      _setupFallbackPolling(interval: 30); // 30 seconds as backup

      isRealTimeConnected.value = true;
      lastUpdateTime.value = DateTime.now();

    } catch (e, stackTrace) {
      isRealTimeConnected.value = false;

      // Setup more frequent fallback polling on error
      _setupFallbackPolling(interval: 15);
    }
  }

  void _handleConversationRealTimeUpdate(RealtimeMessage response) {
    try {
      final payload = response.payload;

      // Only process if this is for our clinic
      final conversationClinicId = payload['clinicId'];
      if (conversationClinicId != clinicData.value?.documentId) {
        return;
      }

      // Check if this is a create or update event (new or updated message)
      final isCreateEvent = response.events.any(
        (event) =>
            event.contains('databases.*.collections.*.documents.*.create'),
      );

      final isUpdateEvent = response.events.any(
        (event) =>
            event.contains('databases.*.collections.*.documents.*.update'),
      );

      if (isCreateEvent || isUpdateEvent) {
        // Update immediately with the new conversation data
        _updateRecentMessagesFromPayload(payload);

        // Also refresh from database after a delay for consistency
        Future.delayed(const Duration(milliseconds: 500), () {
          fetchRecentMessages();
        });
      }
    } catch (e) {}
  }

  /// Helper method to fetch user profile picture
  Future<Map<String, dynamic>> _fetchUserProfilePicture(String userId) async {
    try {
      if (userId.isEmpty) {
        return {
          'url': '',
          'hasProfilePicture': false,
        };
      }

      final userDoc = await authRepository.getUserById(userId);
      if (userDoc != null) {
        final user = User.fromMap(userDoc.data);
        if (user.hasProfilePicture && user.profilePictureId != null) {
          try {
            final profilePictureUrl =
                authRepository.getUserProfilePictureUrl(user.profilePictureId!);
            return {
              'url': profilePictureUrl,
              'hasProfilePicture': true,
            };
          } catch (e) {
            return {
              'url': '',
              'hasProfilePicture': false,
            };
          }
        }
      }
      return {
        'url': '',
        'hasProfilePicture': false,
      };
    } catch (e) {
      return {
        'url': '',
        'hasProfilePicture': false,
      };
    }
  }

  /// Update recent messages immediately from payload without waiting for database
  void _updateRecentMessagesFromPayload(Map<String, dynamic> payload) {
    try {
      // Validate payload has required fields
      if (payload['lastMessageText'] == null ||
          payload['lastMessageTime'] == null ||
          payload['\$id'] == null ||
          payload['userId'] == null) {
        return;
      }

      final conversationId = payload['\$id'] as String;
      final userId = payload['userId'] as String;
      final lastMessageText = payload['lastMessageText'] as String;
      final lastMessageTime =
          DateTime.parse(payload['lastMessageTime'] as String);
      final clinicUnreadCount = payload['clinicUnreadCount'] as int? ?? 0;

      // Fetch user data for name and profile picture
      String senderName = 'Unknown User';
      String profilePictureUrl = '';
      bool hasProfilePicture = false;

      if (_userNamesCache.containsKey(userId)) {
        senderName = _userNamesCache[userId]!;
      } else {
        // Fetch user name asynchronously
        _getUserName(userId).then((name) {
          // Update the message with fetched name
          final index = recentMessages.indexWhere(
            (m) => m['senderId'] == userId,
          );
          if (index != -1) {
            recentMessages[index]['senderName'] = name;
            recentMessages.refresh();
          }
        }).catchError((e) {});
        senderName = userId.length > 6
            ? 'User #${userId.substring(0, 6)}'
            : 'Unknown User';
      }

      // Fetch profile picture asynchronously
      _fetchUserProfilePicture(userId).then((profileData) {
        final index = recentMessages.indexWhere(
          (m) => m['senderId'] == userId,
        );
        if (index != -1) {
          recentMessages[index]['profilePictureUrl'] = profileData['url'] ?? '';
          recentMessages[index]['hasProfilePicture'] =
              profileData['hasProfilePicture'] ?? false;
          recentMessages.refresh();
        }
      }).catchError((e) {});

      final newMessage = {
        'id': conversationId,
        'senderName': senderName,
        'senderId': userId,
        'message': lastMessageText,
        'time': lastMessageTime,
        'isRead': clinicUnreadCount == 0,
        'unreadCount': clinicUnreadCount,
        'conversationId': conversationId,
        'profilePictureUrl': profilePictureUrl,
        'hasProfilePicture': hasProfilePicture,
      };

      // Find if this conversation already exists in recent messages
      final existingIndex = recentMessages.indexWhere(
        (m) => m['conversationId'] == conversationId,
      );

      if (existingIndex != -1) {
        recentMessages[existingIndex] = newMessage;
      } else {
        recentMessages.insert(0, newMessage);
      }

      // Keep only the 3 most recent
      if (recentMessages.length > 3) {
        recentMessages.value = recentMessages.take(3).toList();
      }

      // Sort by time to ensure most recent is first
      recentMessages.sort((a, b) {
        final timeA = a['time'] as DateTime;
        final timeB = b['time'] as DateTime;
        return timeB.compareTo(timeA);
      });

      recentMessages.refresh();
    } catch (e, stackTrace) {}
  }

  void _removeDuplicateAppointments() {
    final uniqueAppointments = <Appointment>[];
    final seenIds = <String>{};

    for (var appointment in appointments) {
      if (appointment.documentId != null &&
          !seenIds.contains(appointment.documentId)) {
        seenIds.add(appointment.documentId!);
        uniqueAppointments.add(appointment);
      }
    }

    if (uniqueAppointments.length != appointments.length) {
      appointments.assignAll(uniqueAppointments);
    }
  }

  Future<void> fetchClinicData() async {
    try {
      final user = await authRepository.getUser();
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get user role from storage
      final storage = GetStorage();
      final userRole = storage.read('role') as String?;

      String? clinicId;

      if (userRole == 'staff') {
        // Staff: Get clinicId from storage
        clinicId = storage.read('clinicId') as String?;

        if (clinicId == null || clinicId.isEmpty) {
          throw Exception('No clinic assigned to staff account');
        }
      } else {
        // Admin: Get clinic by admin ID
        final clinicDoc = await authRepository.getClinicByAdminId(user.$id);
        if (clinicDoc != null) {
          clinicId = clinicDoc.$id;
        } else {
          throw Exception('No clinic found for this admin account');
        }
      }

      if (clinicId != null && clinicId.isNotEmpty) {
        final clinicDoc = await authRepository.getClinicById(clinicId);

        if (clinicDoc != null) {
          clinicData.value = Clinic.fromMap(clinicDoc.data);
          clinicData.value!.documentId = clinicDoc.$id;
        } else {
          throw Exception('Clinic document not found');
        }
      } else {
        throw Exception('No clinic ID available');
      }
    } catch (e) {
      clinicData.value = null; // Ensure it's null on error
      rethrow; // Re-throw to be caught by initializeDashboard
    }
  }

  Future<void> fetchAllAppointments() async {
    if (clinicData.value == null || clinicData.value?.documentId == null) {
      return; // DON'T clear appointments
    }

    try {
      final result = await authRepository.getClinicAppointments(
        clinicData.value!.documentId!,
      );

      appointments.assignAll(result);

      // DON'T call _fetchRelatedData() here - it's expensive
      // Only fetch when needed

      _processPendingAppointments();
      _processUpcomingAppointments();

      // Update cache timestamp
      lastCacheTime.value = DateTime.now();
    } catch (e) {
      // DON'T clear on error
    }
  }

  Future<void> fetchAppointmentStats() async {
    if (clinicData.value == null || clinicData.value?.documentId == null) {
      appointmentStats.clear();
      return;
    }

    try {
      // OPTIMIZATION: Use Appwrite's count functionality instead of fetching all documents
      // Fetch counts for each status in parallel
      final futures = await Future.wait([
        // Pending count
        authRepository.appWriteProvider.databases!.listDocuments(
          databaseId: AppwriteConstants.dbID,
          collectionId: AppwriteConstants.appointmentCollectionID,
          queries: [
            Query.equal('clinicId', clinicData.value!.documentId!),
            Query.equal('status', 'pending'),
            Query.limit(1), // We only need the total count
          ],
        ),
        // Accepted count
        authRepository.appWriteProvider.databases!.listDocuments(
          databaseId: AppwriteConstants.dbID,
          collectionId: AppwriteConstants.appointmentCollectionID,
          queries: [
            Query.equal('clinicId', clinicData.value!.documentId!),
            Query.equal('status', 'accepted'),
            Query.limit(1),
          ],
        ),
        // Completed count
        authRepository.appWriteProvider.databases!.listDocuments(
          databaseId: AppwriteConstants.dbID,
          collectionId: AppwriteConstants.appointmentCollectionID,
          queries: [
            Query.equal('clinicId', clinicData.value!.documentId!),
            Query.equal('status', 'completed'),
            Query.limit(1),
          ],
        ),
        // Cancelled count
        authRepository.appWriteProvider.databases!.listDocuments(
          databaseId: AppwriteConstants.dbID,
          collectionId: AppwriteConstants.appointmentCollectionID,
          queries: [
            Query.equal('clinicId', clinicData.value!.documentId!),
            Query.equal('status', 'cancelled'),
            Query.limit(1),
          ],
        ),
        // Declined count
        authRepository.appWriteProvider.databases!.listDocuments(
          databaseId: AppwriteConstants.dbID,
          collectionId: AppwriteConstants.appointmentCollectionID,
          queries: [
            Query.equal('clinicId', clinicData.value!.documentId!),
            Query.equal('status', 'declined'),
            Query.limit(1),
          ],
        ),
      ]);

      final pendingCount = futures[0].total;
      final acceptedCount = futures[1].total;
      final completedCount = futures[2].total;
      final cancelledCount = futures[3].total;
      final declinedCount = futures[4].total;

      final totalCount = pendingCount +
          acceptedCount +
          completedCount +
          cancelledCount +
          declinedCount;

      final stats = <String, int>{
        'total': totalCount,
        'pending': pendingCount,
        'accepted': acceptedCount,
        'completed': completedCount,
        'cancelled': cancelledCount,
        'declined': declinedCount,
        'today': todayAppointments.length, // Use already fetched today's count
      };

      appointmentStats.assignAll(stats);
    } catch (e) {
      appointmentStats.clear();
    }
  }

  Future<void> _fetchOwnerData(String userId) async {
    if (!ownersCache.containsKey(userId)) {
      try {
        final ownerDoc = await authRepository.getUserById(userId);
        if (ownerDoc != null) {
          // Create a proper User object
          final user = User.fromMap(ownerDoc.data);
          ownersCache[userId] = {
            'name': user.name,
            'email': user.email,
            'phone': user.phone,
          };
        } else {
          // Add fallback data to prevent repeated fetching
          ownersCache[userId] = {
            'name': 'User #${userId.substring(0, 6)}',
            'email': 'N/A',
            'phone': 'N/A',
          };
        }
      } catch (e) {
        // Add fallback data
        ownersCache[userId] = {
          'name': 'User #${userId.substring(0, 6)}',
          'email': 'N/A',
          'phone': 'N/A',
        };
      }
    }
  }

  Future<void> _fetchRelatedData() async {
    for (var appointment in appointments) {
      // Skip if pet is already cached
      if (petsCache.containsKey(appointment.petId)) {
        continue;
      }

      // Skip empty petId
      if (appointment.petId.isEmpty) {
        continue;
      }

      try {
        // Try to get pet by ID if it looks like a valid document ID
        Pet? pet;

        if (_isValidDocumentId(appointment.petId)) {
          try {
            final petDoc = await authRepository.getPetById(appointment.petId);
            if (petDoc != null) {
              pet = Pet.fromMap(petDoc.data);
              pet.documentId = petDoc.$id;
            }
          } catch (e) {}
        }

        // If not found by ID, try by name
        if (pet == null) {
          try {
            final petByName =
                await authRepository.getPetByName(appointment.petId);
            if (petByName != null) {
              pet = Pet.fromMap(petByName.data);
              pet.documentId = petByName.$id;
            }
          } catch (e) {}
        }

        // If still not found, create fallback
        if (pet == null) {
          pet = Pet(
            petId: appointment.petId,
            userId: appointment.userId,
            name: _formatPetName(appointment.petId),
            type: 'Unknown',
            breed: 'Unknown',
          );
        }

        // Cache the pet
        petsCache[appointment.petId] = pet;
      } catch (e) {
        // Create fallback pet
        petsCache[appointment.petId] = Pet(
          petId: appointment.petId,
          userId: appointment.userId,
          name: _formatPetName(appointment.petId),
          type: 'Unknown',
          breed: 'Unknown',
        );
      }

      // Fetch owner data
      if (!ownersCache.containsKey(appointment.userId)) {
        await _fetchOwnerData(appointment.userId);
      }
    }
  }

  String _formatPetName(String rawName) {
    if (rawName.isEmpty) return 'Unknown Pet';

    // If it looks like a document ID, create a generic name
    if (_isValidDocumentId(rawName) && !rawName.contains(' ')) {
      return 'Pet #${rawName.substring(0, 6)}';
    }

    // Remove any special characters except spaces
    final cleaned = rawName.replaceAll(RegExp(r'[^\w\s]'), ' ');

    // Split by camelCase, underscores, dashes, or multiple spaces
    final words = cleaned.split(RegExp(r'(?=[A-Z])|[_\-\s]+'));

    // Capitalize each word and join with spaces
    final formatted = words
        .where((word) => word.isNotEmpty)
        .map((word) {
          if (word.length == 1) return word.toUpperCase();
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ')
        .trim();

    return formatted.isEmpty ? 'Unknown Pet' : formatted;
  }

  bool _isValidDocumentId(String id) {
    // Basic checks
    if (id.isEmpty) return false;

    // Appwrite document IDs are typically 20-36 characters
    if (id.length < 20 || id.length > 36) return false;

    // Check if it contains only valid characters
    // Appwrite IDs use alphanumeric characters and may include underscore, dot, dash
    final validIdRegex = RegExp(r'^[a-zA-Z0-9_.-]+$');
    if (!validIdRegex.hasMatch(id)) return false;

    // Check if it doesn't look like a pet name (no spaces, not too many special chars)
    if (id.contains(' ')) return false;

    // If it has more than 2 consecutive special characters, it's likely not a valid ID
    if (RegExp(r'[_.-]{3,}').hasMatch(id)) return false;

    return true;
  }

  void _processPendingAppointments() {
    try {

      // Get ONLY pending appointments (not all time, only pending status)
      final allPendingAppts = appointments.where((appointment) {
        return appointment.status == 'pending'; // CRITICAL: Only pending
      }).toList();


      // Sort by date/time (upcoming first - soonest at top)
      allPendingAppts.sort((a, b) => a.dateTime.compareTo(b.dateTime));

      // Take top 5 (or 3 if you prefer)
      final top5 = allPendingAppts.take(5).toList();

      for (var appt in top5) {
      }

      // Update the observable list
      todayAppointments.value = List.from(top5);

      // Pre-load images if needed
      if (top5.isNotEmpty) {
        preloadPetImagesForAppointments(top5);
      }
    } catch (e) {
    }
  }

  void _processUpcomingAppointments() {
    try {
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1);

      final upcomingAppts = appointments.where((appointment) {
        // Only accepted appointments
        if (appointment.status != 'accepted') return false;

        // Only future dates (not today)
        final appointmentDate = DateTime(
          appointment.dateTime.year,
          appointment.dateTime.month,
          appointment.dateTime.day,
        );

        return appointmentDate.isAfter(DateTime(now.year, now.month, now.day));
      }).toList();

      // Sort by date/time (nearest first)
      upcomingAppts.sort((a, b) => a.dateTime.compareTo(b.dateTime));

      // Take only first 5
      final limitedUpcoming = upcomingAppts.take(3).toList();

      upcomingAppointments.assignAll(limitedUpcoming);
      upcomingAppointments.refresh();
    } catch (e) {}
  }

  Future<void> generateCalendarData() async {
    Map<DateTime, List<Appointment>> calendarData = {};

    for (var appointment in appointments) {
      final date = DateTime(
        appointment.dateTime.year,
        appointment.dateTime.month,
        appointment.dateTime.day,
      );

      if (calendarData[date] == null) {
        calendarData[date] = [];
      }
      calendarData[date]!.add(appointment);
    }

    calendarAppointments.assignAll(calendarData);
  }

  Future<void> fetchAppointmentsForDate(DateTime date) async {
    // Placeholder for future implementation
  }

  Future<void> fetchRecentMessages() async {
    if (clinicData.value == null || clinicData.value?.documentId == null) {
      recentMessages.clear();
      return;
    }

    try {
      // OPTIMIZATION: Fetch ONLY 3 most recent conversations with messages
      final conversations =
          await authRepository.appWriteProvider.databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.conversationsCollectionID,
        queries: [
          Query.equal('clinicId', clinicData.value!.documentId!),
          Query.equal('isActive', true),
          Query.notEqual('lastMessageText',
              ''), // CRITICAL: Only conversations with messages
          Query.isNotNull(
              'lastMessageTime'), // CRITICAL: Must have lastMessageTime
          Query.orderDesc('lastMessageTime'),
          Query.limit(3), // OPTIMIZATION: Fetch ONLY 3 conversations
        ],
      );

      if (conversations.documents.isEmpty) {
        recentMessages.clear();
        recentMessages.refresh();
        return;
      }

      final List<Map<String, dynamic>> messages = [];

      // Process each conversation
      for (var doc in conversations.documents) {
        final userId = doc.data['userId'] as String;
        final lastMessageText = doc.data['lastMessageText'] as String?;
        final lastMessageTime = doc.data['lastMessageTime'] as String?;
        final clinicUnreadCount = doc.data['clinicUnreadCount'] as int? ?? 0;

        // Skip if no message data
        if (lastMessageText == null ||
            lastMessageText.isEmpty ||
            lastMessageTime == null) {
          continue;
        }

        // Fetch user data
        String senderName = 'Unknown User';
        String profilePictureUrl = '';
        bool hasProfilePicture = false;

        try {
          final userDoc = await authRepository.getUserById(userId);

          if (userDoc != null) {
            final user = User.fromMap(userDoc.data);
            senderName = user.name.isNotEmpty ? user.name : 'Unknown User';

            if (user.hasProfilePicture && user.profilePictureId != null) {
              try {
                profilePictureUrl = authRepository
                    .getUserProfilePictureUrl(user.profilePictureId!);
                hasProfilePicture = true;
              } catch (e) {}
            }
          }
        } catch (e) {
          senderName = userId.length > 6
              ? 'User #${userId.substring(0, 6)}'
              : 'Unknown User';
        }

        final messageData = {
          'id': doc.$id,
          'senderName': senderName,
          'senderId': userId,
          'message': lastMessageText,
          'time': DateTime.parse(lastMessageTime),
          'isRead': clinicUnreadCount == 0,
          'unreadCount': clinicUnreadCount,
          'conversationId': doc.$id,
          'profilePictureUrl': profilePictureUrl,
          'hasProfilePicture': hasProfilePicture,
        };

        messages.add(messageData);
      }

      // Update observable (should be exactly 3 or less)
      recentMessages.assignAll(messages);
      recentMessages.refresh();
    } catch (e, stackTrace) {
      recentMessages.clear();
      recentMessages.refresh();
    }
  }

// Add this helper method to cache user data
  final Map<String, String> _userNamesCache = {};

  Future<String> _getUserName(String userId) async {
    if (userId.isEmpty) {
      return 'Unknown User';
    }

    if (_userNamesCache.containsKey(userId)) {
      return _userNamesCache[userId]!;
    }

    try {
      final userDoc = await authRepository.getUserById(userId);
      if (userDoc != null) {
        final user = User.fromMap(userDoc.data);
        final name = user.name.isNotEmpty ? user.name : 'Unknown User';
        _userNamesCache[userId] = name;
        return name;
      }
    } catch (e) {}

    final fallback =
        userId.length > 6 ? 'User #${userId.substring(0, 6)}' : 'Unknown User';
    _userNamesCache[userId] = fallback;
    return fallback;
  }

  String getOwnerName(String userId) {
    if (!ownersCache.containsKey(userId)) {
      // Trigger a fetch if we don't have the data
      _fetchOwnerData(userId);
      return 'Loading...';
    }
    return ownersCache[userId]?['name'] ?? 'User #${userId.substring(0, 6)}';
  }

  String getPetName(String petId) {
    if (petId.isEmpty) return 'Unknown Pet';

    final pet = petsCache[petId];
    if (pet != null) {
      if (pet.name.isNotEmpty && pet.name != 'Unknown') {
        return pet.name;
      }
    }

    // If pet not in cache or has no name, format the ID
    return _formatPetName(petId);
  }

  String getPetType(String petId) {
    if (petId.isEmpty) return 'Unknown';

    final pet = petsCache[petId];
    if (pet != null && pet.type.isNotEmpty && pet.type != 'Unknown') {
      return pet.type;
    }

    return 'Not Available';
  }

  Pet? getPetForAppointment(String petId) {
    if (petId.isEmpty) return null;
    return petsCache[petId];
  }

  /// Force refresh pet data for a specific appointment
  Future<void> refreshPetData(String petId) async {
    if (petId.isEmpty) return;

    try {
      Pet? pet;

      // Try by ID first
      if (_isValidDocumentId(petId)) {
        try {
          final petDoc = await authRepository.getPetById(petId);
          if (petDoc != null) {
            pet = Pet.fromMap(petDoc.data);
            pet.documentId = petDoc.$id;
          }
        } catch (e) {}
      }

      // Try by name if not found
      if (pet == null) {
        try {
          final petByName = await authRepository.getPetByName(petId);
          if (petByName != null) {
            pet = Pet.fromMap(petByName.data);
            pet.documentId = petByName.$id;
          }
        } catch (e) {}
      }

      // Update cache
      if (pet != null) {
        petsCache[petId] = pet;
        petsCache.refresh();
      } else {
        petsCache[petId] = Pet(
          petId: petId,
          userId: '',
          name: _formatPetName(petId),
          type: 'Unknown',
          breed: 'Unknown',
        );
      }
    } catch (e) {}
  }

  int get pendingCount => appointmentStats['pending'] ?? 0;
  int get acceptedCount => appointmentStats['accepted'] ?? 0;
  int get completedCount => appointmentStats['completed'] ?? 0;
  int get cancelledCount => appointmentStats['cancelled'] ?? 0;
  int get declinedCount => appointmentStats['declined'] ?? 0;
  int get totalAppointments => appointmentStats['total'] ?? 0;

  Future<void> quickAcceptAppointment(Appointment appointment) async {
    try {
      await appointmentController.acceptAppointment(appointment);
      // Get.snackbar("Success", "Appointment accepted!");
    } catch (e) {
      Get.snackbar("Error", "Failed to accept appointment: $e");
    }
  }

  // ✅ FIXED: Dynamic index lookup for Appointments
  void navigateToAppointments([String? filter]) {
    try {
      final homeController = Get.find<WebAdminHomeController>();

      // Find the correct index dynamically
      final appointmentsIndex =
          homeController.navigationLabels.indexOf('Appointments');

      if (appointmentsIndex != -1) {
        homeController.setSelectedIndex(appointmentsIndex);

        if (filter != null) {
          Future.delayed(const Duration(milliseconds: 100), () {
            try {
              appointmentController.setSelectedTab(filter);
            } catch (e) {}
          });
        }
      } else {}
    } catch (e) {}
  }

  // ✅ FIXED: Dynamic index lookup for Messages
  void navigateToMessages() {
    try {
      final homeController = Get.find<WebAdminHomeController>();

      // Find the correct index dynamically
      final messagesIndex = homeController.navigationLabels.indexOf('Messages');

      if (messagesIndex != -1) {
        homeController.setSelectedIndex(messagesIndex);
      } else {}
    } catch (e) {}
  }

  // ✅ FIXED: Dynamic index lookup for Clinic
  void navigateToClinic() {
    try {
      final homeController = Get.find<WebAdminHomeController>();

      // Find the correct index dynamically
      final clinicIndex = homeController.navigationLabels.indexOf('Clinic');

      if (clinicIndex != -1) {
        homeController.setSelectedIndex(clinicIndex);
      } else {}
    } catch (e) {}
  }

  void setSelectedDate(DateTime date) {
    selectedDate.value = date;
  }

  String get connectionStatus =>
      isRealTimeConnected.value ? "Connected" : "Polling";
  String get lastUpdateDisplay =>
      "Last update: ${DateFormat('hh:mm:ss a').format(lastUpdateTime.value)}";

  /// Check if user can view appointments widget
  bool canViewAppointmentsWidget() {
    try {
      final homeController = Get.find<WebAdminHomeController>();
      return homeController.canAccessFeature('appointments');
    } catch (e) {
      return false;
    }
  }

  /// Check if user can view messages widget
  bool canViewMessagesWidget() {
    try {
      final homeController = Get.find<WebAdminHomeController>();
      return homeController.canAccessFeature('messages');
    } catch (e) {
      return false;
    }
  }

  /// Check if user can view clinic widget
  bool canViewClinicWidget() {
    try {
      final homeController = Get.find<WebAdminHomeController>();
      return homeController.canAccessFeature('clinic_info');
    } catch (e) {
      return false;
    }
  }

  /// NEW: Get only visible stats based on permissions
  List<Map<String, dynamic>> getVisibleStats() {
    final allStats = [
      {
        'title': 'Today\'s Appointments',
        'value': todayAppointments.length.toString(),
        'subtitle': 'Scheduled today',
        'icon': Icons.event_available,
        'color': Colors.blue,
        'permission': 'appointments',
      },
      {
        'title': 'Pending Appointments',
        'value': pendingCount.toString(),
        'subtitle': 'Need approval',
        'icon': Icons.pending_actions,
        'color': Colors.orange,
        'permission': 'appointments',
      },
      {
        'title': 'Today\'s In Progress',
        'value': todayAppointments
            .where((a) => a.status == 'in_progress')
            .length
            .toString(),
        'subtitle': 'Currently being treated',
        'icon': Icons.medical_services,
        'color': Colors.purple,
        'permission': 'appointments',
      },
      {
        'title': 'Today\'s Completed',
        'value': todayAppointments
            .where((a) => a.status == 'completed')
            .length
            .toString(),
        'subtitle': 'Finished appointments today',
        'icon': Icons.check_circle,
        'color': Colors.green,
        'permission': 'appointments',
      },
    ];

    try {
      final homeController = Get.find<WebAdminHomeController>();
      return allStats
          .where((stat) =>
              homeController.canAccessFeature(stat['permission'] as String))
          .toList();
    } catch (e) {
      return allStats;
    }
  }

  /// NEW: Get count of visible widgets for layout purposes
  Map<String, bool> getVisibleWidgets() {
    try {
      final homeController = Get.find<WebAdminHomeController>();
      return {
        'appointments': homeController.canAccessFeature('appointments'),
        'messages': homeController.canAccessFeature('messages'),
        'clinic': homeController.canAccessFeature('clinic_info'),
      };
    } catch (e) {
      return {
        'appointments': true,
        'messages': true,
        'clinic': true,
      };
    }
  }
  // Add these methods to AdminDashboardController class

  /// Confirm before accepting appointment from dashboard
  Future<void> confirmQuickAcceptAppointment(Appointment appointment) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Accept Appointment?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are about to accept this appointment.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${getPetName(appointment.petId)} • ${appointment.service}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Owner: ${getOwnerName(appointment.userId)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM dd, yyyy • hh:mm a')
                        .format(appointment.dateTime),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'The time slot will be reserved and the client will be notified.',
              style: TextStyle(fontSize: 12, color: Colors.orange[700]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Accept', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      await quickAcceptAppointment(appointment);
    }
  }

  /// Confirm before declining appointment from dashboard
  Future<void> confirmQuickDeclineAppointment(Appointment appointment) async {
    String selectedReason = '';
    final customReasonController = TextEditingController();
    bool hasChanges = false;

    final predefinedReasons = [
      'Time slot already booked',
      'Clinic at full capacity',
      'Service not available',
      'Emergency override needed',
      'Insufficient information provided',
      'Other (specify below)',
    ];

    final result = await Get.dialog<Map<String, String>?>(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: StatefulBuilder(
            builder: (context, setState) {
              return WillPopScope(
                onWillPop: () async {
                  customReasonController.dispose();
                  return true;
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.cancel,
                              color: Colors.red, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Decline Appointment',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Please select or provide a reason for declining:',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 16),
                    ...predefinedReasons.map((reason) {
                      return RadioListTile<String>(
                        title:
                            Text(reason, style: const TextStyle(fontSize: 14)),
                        value: reason,
                        groupValue: selectedReason,
                        onChanged: (value) {
                          setState(() {
                            selectedReason = value!;
                            hasChanges = true;
                          });
                        },
                        activeColor: const Color.fromARGB(255, 81, 115, 153),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      );
                    }),
                    const SizedBox(height: 16),
                    TextField(
                      controller: customReasonController,
                      decoration: InputDecoration(
                        labelText: 'Custom reason (optional)',
                        hintText: 'Enter additional details...',
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      maxLength: 200,
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          hasChanges = true;
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            customReasonController.dispose();
                            Get.back();
                          },
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: selectedReason.isEmpty
                              ? null
                              : () {
                                  String finalReason = selectedReason;
                                  if (customReasonController.text.isNotEmpty) {
                                    finalReason = selectedReason ==
                                            'Other (specify below)'
                                        ? customReasonController.text
                                        : '$selectedReason - ${customReasonController.text}';
                                  }

                                  Get.back(result: {
                                    'reason': finalReason,
                                  });
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Decline Appointment',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    if (result != null && result['reason'] != null) {
      await quickDeclineAppointment(appointment, result['reason']!);
      customReasonController.dispose();
    } else {
      customReasonController.dispose();
    }
  }

  /// Quick decline appointment
  Future<void> quickDeclineAppointment(
      Appointment appointment, String reason) async {
    try {
      await appointmentController.declineAppointment(appointment, reason);

      // Update the appointment in the local list if needed
      final index = appointments
          .indexWhere((a) => a.documentId == appointment.documentId);
      if (index != -1) {
        appointments[index] = appointment.copyWith(
          status: 'declined',
          updatedAt: DateTime.now(),
        );
        appointments.refresh();
      }

      // Get.snackbar(
      //   "Success",
      //   "Appointment declined. Patient will be notified.",
      //   backgroundColor: Colors.red,
      //   colorText: Colors.white,
      // );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to decline appointment: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Add this method to fetch pet profile picture
  Future<String?> getPetProfilePictureUrl(String petId) async {
    // Check cache first
    if (petProfilePictures.containsKey(petId)) {
      return petProfilePictures[petId];
    }

    try {
      // Fetch pet document
      final petDoc = await authRepository.getPetById(petId);

      if (petDoc != null) {
        final imageUrl = petDoc.data['image'] as String?;

        if (imageUrl != null && imageUrl.isNotEmpty) {
          // Cache the URL
          petProfilePictures[petId] = imageUrl;
          return imageUrl;
        }
      }

      // No image found, cache null
      petProfilePictures[petId] = null;
      return null;
    } catch (e) {
      petProfilePictures[petId] = null;
      return null;
    }
  }

// Add this method to fetch pet image by userId (same as in WebAppointmentController)
  Future<String?> getPetImageByUserId(String petId, String userId) async {
    try {
      // Return immediately if already cached
      if (petProfilePictures.containsKey(petId)) {
        return petProfilePictures[petId];
      }

      // Prevent duplicate fetches
      if (petImageLoadingStates[petId] == true) {
        return null;
      }

      petImageLoadingStates[petId] = true;

      // Fetch all pets for this user
      final userPets = await authRepository.getUserPets(userId);

      if (userPets.isEmpty) {
        petProfilePictures[petId] = null;
        petImageLoadingStates[petId] = false;
        return null;
      }

      // Find the specific pet by petId
      Pet? targetPet;

      for (var petDoc in userPets) {
        final pet = Pet.fromMap(petDoc.data);
        pet.documentId = petDoc.$id;

        // Match by petId (document ID or petId field)
        if (petDoc.$id == petId || pet.petId == petId || pet.name == petId) {
          targetPet = pet;
          break;
        }
      }

      if (targetPet == null) {
        petProfilePictures[petId] = null;
        petImageLoadingStates[petId] = false;
        return null;
      }

      // Cache the pet
      petsCache[petId] = targetPet;

      // Cache the image
      if (targetPet.image != null && targetPet.image!.isNotEmpty) {
        petProfilePictures[petId] = targetPet.image;
        petImageLoadingStates[petId] = false;
        return targetPet.image;
      }

      petProfilePictures[petId] = null;
      petImageLoadingStates[petId] = false;
      return null;
    } catch (e) {
      petProfilePictures[petId] = null;
      petImageLoadingStates[petId] = false;
      return null;
    }
  }

  Future<void> preloadPetImagesForAppointments(
      List<Appointment> appointments) async {
    final futures = <Future>[];

    for (var appointment in appointments) {
      // Skip if already cached
      if (petProfilePictures.containsKey(appointment.petId)) {
        continue;
      }

      // Add to batch
      futures.add(getPetImageByUserId(appointment.petId, appointment.userId)
          .catchError((e) {}));
    }

    // Wait for all images to load
    await Future.wait(futures);
  }

  void clearPetProfilePicturesCache() {
    petProfilePictures.clear();
    petImageLoadingStates.clear();
  }

// Add this method to refresh pet images
  Future<void> refreshPetImages() async {
    petProfilePictures.clear();
    petImageLoadingStates.clear();
    await _fetchRelatedData();
  }

  // new shits

  Future<void> fetchPendingAppointments({bool force = false}) async {
    if (clinicData.value == null || clinicData.value?.documentId == null) {
      return; // DON'T clear - keep existing data
    }

    // CRITICAL: Skip fetch if cache is valid and not forced
    if (!force && _isCacheValid() && todayAppointments.isNotEmpty) {
      return;
    }

    try {

      // Fetch ONLY pending appointments
      final result =
          await authRepository.appWriteProvider.databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.appointmentCollectionID,
        queries: [
          Query.equal('clinicId', clinicData.value!.documentId!),
          Query.equal('status', 'pending'), // CRITICAL: Only pending
          Query.orderAsc('dateTime'), // Soonest first
          Query.limit(100), // Get all pending (up to 100)
        ],
      );


      // Parse all pending appointments
      final List<Appointment> allPendingAppts = [];
      for (var doc in result.documents) {
        try {
          final appointment = Appointment.fromMap(doc.data);
          allPendingAppts.add(appointment);
        } catch (e) {
        }
      }

      // Take exactly 5 (or less if not enough)
      final top5 = allPendingAppts.take(5).toList();

      for (var appt in top5) {
      }

      // Update with new list instance
      todayAppointments.value = List.from(top5);

      // Pre-load images
      if (top5.isNotEmpty) {
        preloadPetImagesForAppointments(top5);
      }

      // Update cache timestamp
      lastCacheTime.value = DateTime.now();
      isDashboardCached.value = true;
    } catch (e) {
      // DON'T clear on error - keep existing data
    }
  }

  Future<void> fetchUpcomingAppointments({bool force = false}) async {
    if (clinicData.value == null || clinicData.value?.documentId == null) {
      return; // DON'T clear
    }

    // CRITICAL: Skip fetch if cache is valid and not forced
    if (!force && _isCacheValid() && upcomingAppointments.isNotEmpty) {
      return;
    }

    try {
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1, 0, 0, 0);

      // Fetch ONLY 5 upcoming accepted appointments
      final result =
          await authRepository.appWriteProvider.databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.appointmentCollectionID,
        queries: [
          Query.equal('clinicId', clinicData.value!.documentId!),
          Query.equal('status', 'accepted'),
          Query.greaterThanEqual('dateTime', tomorrow.toIso8601String()),
          Query.orderAsc('dateTime'),
          Query.limit(5),
        ],
      );

      final List<Appointment> upcomingAppts = [];
      for (var doc in result.documents) {
        try {
          final appointment = Appointment.fromMap(doc.data);
          upcomingAppts.add(appointment);
        } catch (e) {}
      }

      upcomingAppointments.assignAll(upcomingAppts);
      upcomingAppointments.refresh();

      // Pre-load images
      if (upcomingAppts.isNotEmpty) {
        preloadPetImagesForAppointments(upcomingAppts);
      }

      // Update cache timestamp
      lastCacheTime.value = DateTime.now();
      isDashboardCached.value = true;
    } catch (e) {
      // DON'T clear on error
    }
  }

  Future<void> forceRefreshAppointments() async {
    if (clinicData.value?.documentId == null) {
      return;
    }

    // Check if we really need a force refresh
    if (_isCacheValid() && isRealTimeConnected.value) {
      return;
    }

    try {
      // Fetch fresh from database
      final freshAppointments = await authRepository.getClinicAppointments(
        clinicData.value!.documentId!,
      );

      // Replace all data
      appointments.assignAll(freshAppointments);

      // Update all filtered views
      _processPendingAppointments();
      _processUpcomingAppointments();
      _updateAppointmentStats();
      await generateCalendarData();

      // Update cache
      lastCacheTime.value = DateTime.now();
      isDashboardCached.value = true;
    } catch (e) {}
  }

  void cleanupOnLogout() {
    // Cancel all subscriptions
    try {
      _appointmentSubscription?.close();
      _conversationSubscription?.close();
      _messageSubscription?.close();
      _fallbackTimer?.cancel();
    } catch (e) {}

    // Clear ALL cached data
    clinicData.value = null;
    appointments.clear();
    appointmentStats.clear();
    todayAppointments.clear();
    upcomingAppointments.clear();
    recentMessages.clear();
    monthlyStats.clear();
    petsCache.clear();
    ownersCache.clear();
    calendarAppointments.clear();
    _userNamesCache.clear();
    petProfilePictures.clear();
    petImageLoadingStates.clear();

    // Invalidate cache
    isDashboardCached.value = false;
    lastCacheTime.value = null;
    isRealTimeConnected.value = false;
  }

  String get cacheStatus {
    if (!isDashboardCached.value) {
      return 'No cache';
    }

    if (lastCacheTime.value == null) {
      return 'Invalid cache';
    }

    final age = DateTime.now().difference(lastCacheTime.value!);
    final remainingMinutes = cacheValidityMinutes - age.inMinutes;

    if (remainingMinutes <= 0) {
      return 'Cache expired';
    }

    return 'Cache valid (${remainingMinutes}m left)';
  }

  /// Check if cache needs refresh soon
  bool get shouldRefreshSoon {
    if (!isDashboardCached.value || lastCacheTime.value == null) {
      return true;
    }

    final age = DateTime.now().difference(lastCacheTime.value!);
    final remainingMinutes = cacheValidityMinutes - age.inMinutes;

    return remainingMinutes <= 1; // Refresh if less than 1 minute left
  }

  List<Appointment> get pendingAppointments {
    final pendingAppts =
        appointments.where((a) => a.status == 'pending').toList();

    // Sort by date/time (upcoming first)
    pendingAppts.sort((a, b) => a.dateTime.compareTo(b.dateTime));


    return pendingAppts;
  }
}
