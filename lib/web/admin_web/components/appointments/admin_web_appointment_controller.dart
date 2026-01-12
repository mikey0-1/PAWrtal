import 'package:capstone_app/data/models/appointment_model.dart';
import 'package:capstone_app/data/models/medical_record_model.dart';
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/data/models/conversation_model.dart';
import 'package:capstone_app/data/models/message_model.dart';
import 'package:capstone_app/data/models/vaccination_model.dart';
import 'package:capstone_app/data/models/notification_model.dart';
import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/notification/services/notification_preferences_service.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:capstone_app/utils/snackbar_helper.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:appwrite/appwrite.dart';
import 'package:capstone_app/web/admin_web/components/dashboard/admin_dashboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';

import 'appointment_view_mode.dart';

class WebAppointmentController extends GetxController {
  final AuthRepository authRepository;
  final UserSessionService session;

  WebAppointmentController({
    required this.authRepository,
    required this.session,
  });

  // Observable variables
  var isLoading = false.obs;
  var appointments = <Appointment>[].obs;
  var filteredAppointments = <Appointment>[].obs;
  var clinicData = Rxn<Clinic>();
  var petsCache = <String, Pet>{}.obs;
  var ownersCache = <String, Map<String, dynamic>>{}.obs;

  // Filter and search
  var selectedTab = 'today'.obs;
  var searchQuery = ''.obs;
  var selectedDateFilter = DateTime.now().obs;

  // Real-time related
  RealtimeSubscription? _appointmentSubscription;
  Timer? _fallbackTimer;
  var lastUpdateTime = DateTime.now().obs;
  var isRealTimeConnected = false.obs;

  var viewMode = AppointmentViewMode.today.obs;
  var selectedCalendarDate = Rxn<DateTime>();

  // CRITICAL: Store pending vitals locally (in memory, not in appointment)
  var pendingVitals = <String, Map<String, dynamic>>{}.obs;

  var petProfilePictures = <String, String?>{}.obs;

  final RxMap<String, String> petImagesCache = <String, String>{}.obs;

  Timer? _autoDeclineTimer;
  static const int _autoDeclineCheckInterval = 60;
  var isAutoDeclineActive = false.obs;

  @override
  void onInit() {
    super.onInit();

    // Initialize fresh
    fetchClinicData();

    // Listen to changes
    ever(selectedTab, (_) => updateFilteredAppointments());
    ever(searchQuery, (_) => updateFilteredAppointments());
    ever(selectedDateFilter, (_) => updateFilteredAppointments());

    // Start auto-decline timer AFTER a small delay to ensure initialization
    Future.delayed(const Duration(seconds: 2), () {
      _startAutoDeclineTimer();
    });

    // Set default tab to pending
    selectedTab.value = 'pending';
  }

  @override
  void onClose() {
    _autoDeclineTimer?.cancel();
    _autoDeclineTimer = null;
    isAutoDeclineActive.value = false;

    super.onClose();
    cleanupOnLogout();
  }

  Future<void> fetchClinicData() async {
    try {
      isLoading.value = true;

      // CRITICAL: Clear ALL old data first
      appointments.clear();
      filteredAppointments.clear();
      petsCache.clear();
      ownersCache.clear();
      petProfilePictures.clear();
      petImagesCache.clear();
      pendingVitals.clear();

      final user = await authRepository.getUser();
      if (user == null) {
        if (Get.context != null) {
          SnackbarHelper.showError(
            context: Get.context!,
            title: "Authentication Error",
            message: "User session expired. Please log in again.",
          );
        }
        return;
      }

      final storage = GetStorage();
      final userRole = storage.read('role') as String?;
      final storedClinicId = storage.read('clinicId') as String?;

      String? clinicId;

      if (userRole == 'staff') {
        clinicId = storedClinicId;
      } else if (userRole == 'admin') {
        final clinicDoc = await authRepository.getClinicByAdminId(user.$id);
        if (clinicDoc != null) {
          clinicId = clinicDoc.$id;
        }
      }

      if (clinicId != null && clinicId.isNotEmpty) {
        final clinicDoc = await authRepository.getClinicById(clinicId);
        if (clinicDoc != null) {
          clinicData.value = Clinic.fromMap(clinicDoc.data);
          clinicData.value!.documentId = clinicDoc.$id;

          // Close old subscriptions before creating new ones
          await _appointmentSubscription?.close();
          _fallbackTimer?.cancel();

          // Fetch fresh appointments
          await fetchClinicAppointments();

          // Initialize new real-time updates
          await _initializeRealTimeUpdates();
        } else {
          if (Get.context != null) {
            SnackbarHelper.showError(
              context: Get.context!,
              title: "Clinic Not Found",
              message: "Could not load clinic data. Please contact support.",
            );
          }
        }
      } else {
        if (Get.context != null) {
          SnackbarHelper.showWarning(
            context: Get.context!,
            title: "No Clinic Associated",
            message: "Your account is not associated with a clinic.",
          );
        }
      }
    } catch (e) {
      if (Get.context != null) {
        SnackbarHelper.showError(
          context: Get.context!,
          title: "Error",
          message: "Failed to load clinic data. Please try again.",
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _initializeRealTimeUpdates() async {
    try {
      if (clinicData.value?.documentId == null) {
        return;
      }

      // CRITICAL: Close old subscription first
      await _appointmentSubscription?.close();
      _appointmentSubscription = null;

      _fallbackTimer?.cancel();
      _fallbackTimer = null;

      // Create new subscription
      await _subscribeToAppointmentUpdates();

      // Setup fallback polling - but mark as connected immediately
      isRealTimeConnected.value = true; // Set BEFORE setup
      _setupFallbackPolling();
    } catch (e) {
      isRealTimeConnected.value = false;
      _setupFallbackPolling(interval: 15);
    }
  }

  Future<void> _subscribeToAppointmentUpdates() async {
    try {
      // Close old subscription
      await _appointmentSubscription?.close();
      _appointmentSubscription = null;

      final realtime = Realtime(authRepository.client);

      _appointmentSubscription = realtime.subscribe([
        'databases.${AppwriteConstants.dbID}.collections.${AppwriteConstants.appointmentCollectionID}.documents'
      ]);

      _appointmentSubscription!.stream.listen(
        (response) {
          // Mark as connected when we receive messages
          if (!isRealTimeConnected.value) {
            isRealTimeConnected.value = true;
          }

          // CRITICAL: Verify this update is for OUR clinic
          final updateClinicId = response.payload['clinicId'];
          final ourClinicId = clinicData.value?.documentId;

          if (updateClinicId != ourClinicId) {
            return;
          }

          _handleAppointmentRealTimeUpdate(response);
        },
        onError: (error) {
          isRealTimeConnected.value = false;
          _setupFallbackPolling(interval: 10);
        },
        onDone: () {
          isRealTimeConnected.value = false;
          _setupFallbackPolling(interval: 10);
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  void _handleAppointmentRealTimeUpdate(RealtimeMessage response) {
    try {
      final payload = response.payload;
      final appointmentClinicId = payload['clinicId'];

      if (appointmentClinicId != clinicData.value?.documentId) {
        return;
      }

      final appointment = Appointment.fromMap(payload);

      for (String event in response.events) {
        if (event.contains('.create')) {
          _handleNewAppointment(appointment);
        } else if (event.contains('.update')) {
          _handleUpdatedAppointment(appointment);
        } else if (event.contains('.delete')) {
          _handleDeletedAppointment(appointment);
        }
      }

      lastUpdateTime.value = DateTime.now();

      // Refresh stats after any update
      appointments.refresh();
      updateFilteredAppointments();

      // Only show notification for new appointments
      if (response.events.any((event) => event.contains('.create'))) {
        _showNewAppointmentNotification(appointment);
      }
    } catch (e) {}
  }

  void _handleNewAppointment(Appointment appointment) {
    final existingIndex =
        appointments.indexWhere((a) => a.documentId == appointment.documentId);

    if (existingIndex == -1) {
      appointments.add(appointment);
    } else {
      appointments[existingIndex] = appointment;
      appointments.refresh();
    }

    updateFilteredAppointments();
  }

  void _handleUpdatedAppointment(Appointment appointment) {
    final index = appointments.indexWhere(
      (a) => a.documentId == appointment.documentId,
    );

    if (index != -1) {
      appointments[index] = appointment;
      appointments.refresh();
      updateFilteredAppointments();
    } else {
      appointments.add(appointment);
      updateFilteredAppointments();
    }
  }

  void _handleDeletedAppointment(Appointment appointment) {
    appointments.removeWhere((a) => a.documentId == appointment.documentId);
    updateFilteredAppointments();
  }

  void _showNewAppointmentNotification(Appointment appointment) {
    // Get.snackbar(
    //   "New Appointment",
    //   "New appointment from ${getOwnerName(appointment.userId)} for ${getPetName(appointment.petId)}",
    //   backgroundColor: const Color.fromARGB(255, 81, 115, 153),
    //   colorText: Colors.white,
    //   duration: const Duration(seconds: 5),
    //   snackPosition: SnackPosition.TOP,
    // );
  }

  void _setupFallbackPolling({int interval = 30}) {
    _fallbackTimer?.cancel();
    _fallbackTimer = Timer.periodic(Duration(seconds: interval), (timer) {
      // CRITICAL FIX: Only poll if realtime is NOT connected
      // Don't refetch if we're already connected
      if (!isRealTimeConnected.value) {
        fetchClinicAppointments();
      } else {}
    });
  }

  Future<void> fetchClinicAppointments() async {
    if (clinicData.value?.documentId == null) {
      return;
    }

    try {
      // CRITICAL: Don't clear caches if we're just refreshing
      // Only clear on initial load or forced refresh
      final isInitialLoad = appointments.isEmpty;

      if (isInitialLoad) {
        appointments.clear();
        filteredAppointments.clear();
        petsCache.clear();
        ownersCache.clear();
        petProfilePictures.clear();
        petImagesCache.clear();
      } else {}

      // Fetch fresh appointments
      final result = await authRepository
          .getClinicAppointments(clinicData.value!.documentId!);

      // Log status breakdown
      final statusCounts = <String, int>{};
      for (var apt in result) {
        statusCounts[apt.status] = (statusCounts[apt.status] ?? 0) + 1;
      }

      appointments.assignAll(result);

      // Fetch related data only for new pets/owners
      await _fetchRelatedData();

      // Update filtered view
      updateFilteredAppointments();
    } catch (e) {
      if (Get.context != null) {
        SnackbarHelper.showError(
          context: Get.context!,
          title: "Error",
          message: "Failed to load appointments",
        );
      }
    }
  }

  void debugRefetchTriggers() {}

  Future<void> _fetchOwnerData(String userId) async {
    if (!ownersCache.containsKey(userId)) {
      try {
        final ownerDoc = await authRepository.getUserById(userId);
        if (ownerDoc != null) {
          ownersCache[userId] = {
            'name': ownerDoc.data['name'] ?? 'User #${userId.substring(0, 6)}',
            'email': ownerDoc.data['email'] ?? 'N/A',
            'phone': ownerDoc.data['phone'] ?? 'N/A',
          };
        } else {
          ownersCache[userId] = {
            'name': 'User #${userId.substring(0, 6)}',
            'email': 'N/A',
            'phone': 'N/A',
          };
        }
      } catch (e) {
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
      final petIdentifier = appointment.petId;
      final userId = appointment.userId;

      // CRITICAL: Use composite key to avoid conflicts between different users with same pet names
      final petCacheKey = '${userId}_$petIdentifier';
      final imageCacheKey = '${userId}_$petIdentifier';

      // Only fetch if not already cached
      if (!petsCache.containsKey(petCacheKey) && petIdentifier.isNotEmpty) {
        try {
          // Fetch pet using the new method that includes userId
          final fetchedPet = await _fetchPetByUserAndId(userId, petIdentifier);

          if (fetchedPet != null) {
            // Cache the pet with composite key
            petsCache[petCacheKey] = fetchedPet;

            // Cache profile picture with composite key
            if (fetchedPet.image != null && fetchedPet.image!.isNotEmpty) {
              petProfilePictures[imageCacheKey] = fetchedPet.image;
            } else {
              petProfilePictures[imageCacheKey] = null;
            }
          } else {
            // Create fallback pet if not found
            petsCache[petCacheKey] = Pet(
              petId: petIdentifier,
              userId: userId,
              name: petIdentifier,
              type: 'Unknown',
              breed: 'Unknown',
            );
            petProfilePictures[imageCacheKey] = null;
          }
        } catch (e) {
          // Create fallback pet on error
          petsCache[petCacheKey] = Pet(
            petId: petIdentifier,
            userId: userId,
            name: petIdentifier,
            type: 'Unknown',
            breed: 'Unknown',
          );
          petProfilePictures[imageCacheKey] = null;
        }
      }

      // Fetch owner data if not cached
      if (!ownersCache.containsKey(userId)) {
        await _fetchOwnerData(userId);
      }
    }

    for (var entry in petsCache.entries) {}
  }

  /// NEW HELPER METHOD: Fetch pet by both userId and petId
  Future<Pet?> _fetchPetByUserAndId(String userId, String petIdentifier) async {
    try {
      // Get all pets for this specific user
      final userPets = await authRepository.getUserPets(userId);

      if (userPets.isEmpty) {
        return null;
      }

      // Find the specific pet by petId (document ID, petId field, or name)
      for (var petDoc in userPets) {
        final pet = Pet.fromMap(petDoc.data);
        pet.documentId = petDoc.$id;

        // Match by document ID, petId field, or name (in that order of priority)
        if (petDoc.$id == petIdentifier ||
            pet.petId == petIdentifier ||
            pet.name == petIdentifier) {
          return pet;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  void updateFilteredAppointments() {
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);

    List<Appointment> filtered;

    // ✅ CRITICAL FIX: Pending tab shows ALL pending appointments regardless of date
    if (selectedTab.value == 'pending') {
      // For pending tab, start with ALL appointments (no date filtering)
      filtered = appointments.where((a) => a.status == 'pending').toList();
    } else {
      // For all other tabs, apply date filtering first
      filtered = _getBaseFilteredAppointments();

      // Then apply status filtering
      switch (selectedTab.value) {
        case 'scheduled':
          filtered = filtered.where((a) => a.status == 'accepted').toList();
          break;

        case 'in_progress':
          filtered = filtered.where((a) => a.status == 'in_progress').toList();
          break;

        case 'completed':
          filtered = filtered.where((a) => a.status == 'completed').toList();
          break;

        case 'cancelled':
          filtered = filtered.where((a) => a.status == 'cancelled').toList();
          break;

        case 'declined':
          filtered = filtered.where((a) => a.status == 'declined').toList();
          break;
      }
    }

    // Apply search filtering (common to all tabs)
    if (searchQuery.value.isNotEmpty) {
      filtered = filtered.where((appointment) {
        final petName = getPetName(appointment.petId).toLowerCase();
        final ownerName = getOwnerName(appointment.userId).toLowerCase();
        final service = appointment.service.toLowerCase();
        final query = searchQuery.value.toLowerCase();

        return petName.contains(query) ||
            ownerName.contains(query) ||
            service.contains(query);
      }).toList();
    }

    // Sort by nearest date/time from current moment
    filtered.sort((a, b) {
      final nowMoment = DateTime.now();
      final aDiff = a.dateTime.difference(nowMoment).abs();
      final bDiff = b.dateTime.difference(nowMoment).abs();
      final comparison = aDiff.compareTo(bDiff);
      if (comparison == 0) {
        return a.dateTime.compareTo(b.dateTime);
      }
      return comparison;
    });

    filteredAppointments.assignAll(filtered);
  }

  String getOwnerName(String userId) {
    if (!ownersCache.containsKey(userId)) {
      _fetchOwnerData(userId);
      return 'Loading...';
    }
    return ownersCache[userId]?['name'] ?? 'User #${userId.substring(0, 6)}';
  }

  /// Get pet name using composite key (userId + petId)
  String getPetName(String petId) {
    // Find the appointment to get userId
    final appointment = appointments.firstWhereOrNull(
      (a) => a.petId == petId,
    );

    if (appointment != null) {
      final cacheKey = '${appointment.userId}_$petId';
      final pet = petsCache[cacheKey];

      if (pet != null && pet.name.isNotEmpty) {
        return pet.name;
      }
    }

    // Fallback: trigger fetch if not cached
    if (appointment != null) {
      _fetchRelatedData();
    }

    return petId.isEmpty ? 'Unknown Pet' : petId;
  }

  /// Get pet breed using composite key
  String getPetBreed(String petId) {
    final appointment = appointments.firstWhereOrNull(
      (a) => a.petId == petId,
    );

    if (appointment != null) {
      final cacheKey = '${appointment.userId}_$petId';
      final pet = petsCache[cacheKey];

      if (pet != null) {
        return pet.breed.isNotEmpty ? pet.breed : 'Not Available';
      }
    }

    if (appointment != null) {
      _fetchRelatedData();
    }

    return 'Loading...';
  }

  /// Get pet type using composite key
  String getPetType(String petId) {
    final appointment = appointments.firstWhereOrNull(
      (a) => a.petId == petId,
    );

    if (appointment != null) {
      final cacheKey = '${appointment.userId}_$petId';
      final pet = petsCache[cacheKey];

      if (pet != null) {
        return pet.type.isNotEmpty ? pet.type : 'Not Available';
      }
    }

    if (appointment != null) {
      _fetchRelatedData();
    }

    return 'Loading...';
  }

  Pet? getPetForAppointment(String petId) => petsCache[petId];

  List<Appointment> get todayAppointments {
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);

    final todayAppts = appointments.where((appointment) {
      // The stored dateTime is ALREADY in local time (not UTC)
      // Just compare the DATE part
      final appointmentDate = DateTime(
        appointment.dateTime.year,
        appointment.dateTime.month,
        appointment.dateTime.day,
      );

      return appointmentDate.isAtSameMomentAs(todayDate);
    }).toList();

    return todayAppts;
  }

  List<Appointment> get pending {
    // ✅ Return ALL pending appointments regardless of date
    return appointments.where((a) => a.status == 'pending').toList();
  }

  List<Appointment> get scheduled {
    // Show ALL accepted appointments (including today)
    return appointments.where((a) => a.status == 'accepted').toList();
  }

  List<Appointment> get inProgress =>
      appointments.where((a) => a.status == 'in_progress').toList();

  List<Appointment> get completed =>
      appointments.where((a) => a.status == 'completed').toList();

  List<Appointment> get cancelled =>
      appointments.where((a) => a.status == 'cancelled').toList();

  List<Appointment> get declined {
    final filtered = _getFilteredAppointmentsForStats();
    final declinedList = filtered.where((a) => a.status == 'declined').toList();

    return declinedList;
  }

  Map<String, int> get appointmentStats {
    // Use the new filteredAppointmentStats which respects calendar date and view mode
    return filteredAppointmentStats;
  }

  List<Appointment> _getFilteredAppointmentsForStats() {
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);

    List<Appointment> timeFilteredAppointments;

    switch (viewMode.value) {
      case AppointmentViewMode.today:
        // CRITICAL: Stored dateTime is already local, just compare dates
        timeFilteredAppointments = appointments.where((appointment) {
          final appointmentDate = DateTime(
            appointment.dateTime.year,
            appointment.dateTime.month,
            appointment.dateTime.day,
          );

          return appointmentDate.isAtSameMomentAs(todayDate);
        }).toList();

        final statusBreakdown = <String, int>{};
        for (var apt in timeFilteredAppointments) {
          statusBreakdown[apt.status] = (statusBreakdown[apt.status] ?? 0) + 1;

          // Debug each appointment
          final aptDate =
              DateTime(apt.dateTime.year, apt.dateTime.month, apt.dateTime.day);
        }
        break;

      case AppointmentViewMode.thisWeek:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final weekStartDate =
            DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        final weekEndDate = weekStartDate.add(const Duration(days: 6));

        timeFilteredAppointments = appointments.where((a) {
          final appointmentDate = DateTime(
            a.dateTime.year,
            a.dateTime.month,
            a.dateTime.day,
          );

          return !appointmentDate.isBefore(weekStartDate) &&
              !appointmentDate.isAfter(weekEndDate);
        }).toList();

        break;

      case AppointmentViewMode.thisMonth:
        timeFilteredAppointments = appointments.where((a) {
          return a.dateTime.year == now.year && a.dateTime.month == now.month;
        }).toList();

        break;

      case AppointmentViewMode.allTime:
        timeFilteredAppointments = appointments.toList();

        break;
    }

    return timeFilteredAppointments;
  }

  Future<void> debugDeclinedCounts() async {
    final now = _nowInPhilippineTime;

    // Count declined for each view mode

    // Today
    final todayDeclined = appointments.where((a) {
      if (a.status != 'declined') return false;
      final utc = a.dateTime.toUtc();
      final appointmentPH = utc.add(const Duration(hours: 8));
      return appointmentPH.year == now.year &&
          appointmentPH.month == now.month &&
          appointmentPH.day == now.day;
    }).length;

    // This Week
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final thisWeekDeclined = appointments.where((a) {
      if (a.status != 'declined') return false;
      final utc = a.dateTime.toUtc();
      final appointmentPH = utc.add(const Duration(hours: 8));
      final appointmentDate =
          DateTime(appointmentPH.year, appointmentPH.month, appointmentPH.day);
      final weekStartDate =
          DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      final weekEndDate = weekStartDate.add(const Duration(days: 6));
      return !appointmentDate.isBefore(weekStartDate) &&
          !appointmentDate.isAfter(weekEndDate);
    }).length;

    // This Month
    final thisMonthDeclined = appointments.where((a) {
      if (a.status != 'declined') return false;
      final utc = a.dateTime.toUtc();
      final appointmentPH = utc.add(const Duration(hours: 8));
      return appointmentPH.year == now.year && appointmentPH.month == now.month;
    }).length;

    // All Time
    final allTimeDeclined =
        appointments.where((a) => a.status == 'declined').length;
  }

  void setViewMode(AppointmentViewMode mode) {
    viewMode.value = mode;
    selectedCalendarDate.value =
        null; // Clear calendar date when changing view mode

    // Refresh filtered appointments and stats
    updateFilteredAppointments();

    // Force refresh of stats
    appointmentStats; // Trigger the getter
  }

  void setCalendarDate(DateTime? date) {
    selectedCalendarDate.value = date;
    if (date != null) {
      // When calendar date is selected, keep current view mode
      // Don't force to 'today' view mode
    } else {}

    // Refresh filtered appointments and stats
    updateFilteredAppointments();

    // Force refresh of stats (this will update stat cards and tab counts)
    appointmentStats; // Trigger the getter
  }

  Future<void> acceptAppointment(Appointment appointment) async {
    final isAvailable = await checkTimeSlotAvailability(
      appointment.clinicId,
      appointment.dateTime,
      excludeAppointmentId: appointment.documentId,
    );

    if (!isAvailable) {
      if (Get.context != null) {
        SnackbarHelper.showWarning(
          context: Get.context!,
          title: "Time Slot Unavailable",
          message:
              "This time slot is already booked. Please ask the client to choose a different time.",
        );
      }
      return;
    }

    try {
      await _updateAppointmentStatus(appointment, 'accepted');

      try {
        final notification = AppNotification.appointmentAccepted(
          userId: appointment.userId,
          appointmentId: appointment.documentId!,
          clinicId: appointment.clinicId,
          clinicName: clinicData.value?.clinicName ?? 'Clinic',
          petName: getPetName(appointment.petId),
          service: appointment.service,
          appointmentDateTime: appointment.dateTime,
        );

        await authRepository.createNotification(notification);
      } catch (e) {
        // Notification creation failed, but appointment was accepted
      }

      await _sendAppointmentStatusNotification(appointment, 'accepted');

      await _sendAutomatedAppointmentMessage(
        appointment: appointment,
        messageType: 'accepted',
      );

      if (Get.context != null) {
        SnackbarHelper.showSuccess(
          context: Get.context!,
          title: "Appointment Accepted",
          message:
              "Appointment for ${getPetName(appointment.petId)} has been accepted successfully!",
        );
      }
    } catch (e) {
      if (Get.context != null) {
        SnackbarHelper.showError(
          context: Get.context!,
          title: "Error",
          message: "Failed to accept appointment. Please try again.",
        );
      }
    }
  }

  Future<void> declineAppointment(
    Appointment appointment,
    String notes, {
    bool showSnackbar = true, // NEW: Control snackbar display
  }) async {
    if (appointment.documentId == null) {
      if (showSnackbar && Get.context != null) {
        SnackbarHelper.showError(
          context: Get.context!,
          title: "Error",
          message: "Cannot decline appointment: Missing document ID",
        );
      }
      return;
    }

    try {
      // STEP 1: Update appointment status (CRITICAL - This must succeed)
      final updatedAppointment = appointment.copyWith(
        status: 'declined',
        notes: notes,
        updatedAt: DateTime.now(),
        // IMPORTANT: Set cancellation tracking fields
        cancelledBy: 'clinic',
        cancelledAt: DateTime.now(),
        cancellationReason: notes,
      );

      await updateFullAppointment(updatedAppointment);

      // STEP 2: Create in-app notification (non-critical - wrapped in try-catch)
      try {
        final notification = AppNotification.appointmentDeclined(
          userId: appointment.userId,
          appointmentId: appointment.documentId!,
          clinicId: appointment.clinicId,
          clinicName: clinicData.value?.clinicName ?? 'Clinic',
          petName: getPetName(appointment.petId),
          declineReason: notes,
        );

        await authRepository.createNotification(notification);
      } catch (e) {
        // Continue - notification failure shouldn't fail the decline
      }

      // STEP 3: Send push notification (non-critical - wrapped in try-catch)
      try {
        await _sendAppointmentStatusNotification(
          updatedAppointment,
          'declined',
          declineReason: notes,
        );
      } catch (e) {
        // Continue - notification failure shouldn't fail the decline
      }

      // STEP 4: Send automated message (non-critical - wrapped in try-catch)
      try {
        await _sendAutomatedAppointmentMessage(
          appointment: updatedAppointment,
          messageType: 'declined',
          declineReason: notes,
        );
      } catch (e) {
        // Continue - message failure shouldn't fail the decline
      }

      // Show success snackbar only if requested
      if (showSnackbar && Get.context != null) {
        SnackbarHelper.showSuccess(
          context: Get.context!,
          title: "Appointment Declined",
          message:
              "Appointment declined successfully. Patient will be notified.",
        );
      }
    } catch (e, stackTrace) {
      // Show error snackbar only if requested
      if (showSnackbar && Get.context != null) {
        SnackbarHelper.showError(
          context: Get.context!,
          title: "Error",
          message: "Failed to decline appointment. Please try again.",
        );
      }

      // Rethrow so caller knows it failed
      rethrow;
    }
  }

  Future<void> checkInPatient(Appointment appointment) async {
    if (!appointment.isToday) {
      if (Get.context != null) {
        SnackbarHelper.showWarning(
          context: Get.context!,
          title: "Cannot Check In",
          message: "Cannot check in patient for future appointments.",
        );
      }
      return;
    }

    try {
      final updatedAppointment = appointment.copyWith(
        status: 'in_progress',
        checkedInAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await updateFullAppointment(updatedAppointment);

      await _sendAppointmentStatusNotification(
          updatedAppointment, 'in_progress');

      if (Get.context != null) {
        SnackbarHelper.showSuccess(
          context: Get.context!,
          title: "Patient Checked In",
          message:
              "${getPetName(appointment.petId)} has been checked in successfully!",
        );
      }
    } catch (e) {
      if (Get.context != null) {
        SnackbarHelper.showError(
          context: Get.context!,
          title: "Error",
          message: "Failed to check in patient. Please try again.",
        );
      }
    }
  }

  Future<void> startService(Appointment appointment) async {
    try {
      final updatedAppointment = appointment.copyWith(
        serviceStartedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await updateFullAppointment(updatedAppointment);

      if (Get.context != null) {
        SnackbarHelper.showSuccess(
          context: Get.context!,
          title: "Service Started",
          message: "Service for ${getPetName(appointment.petId)} has begun.",
        );
      }
    } catch (e) {
      if (Get.context != null) {
        SnackbarHelper.showError(
          context: Get.context!,
          title: "Error",
          message: "Failed to start service. Please try again.",
        );
      }
    }
  }

  Future<void> completeServiceWithRecord({
    required Appointment appointment,
    required String diagnosis,
    required String treatment,
    String? prescription,
    String? vetNotes,
    Map<String, dynamic>? vitals,
    String? followUpInstructions,
    DateTime? nextAppointmentDate,
  }) async {
    try {
      // Check if we have pending vitals stored locally
      Map<String, dynamic>? finalVitals = vitals;
      if (pendingVitals.containsKey(appointment.documentId)) {
        finalVitals = pendingVitals[appointment.documentId];
      }

      // Step 1: Update appointment status
      final updatedAppointment = appointment.copyWith(
        status: 'completed',
        serviceCompletedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        followUpInstructions: followUpInstructions,
        nextAppointmentDate: nextAppointmentDate,
      );

      await updateFullAppointment(updatedAppointment);

      // Step 2: Create medical record with vitals
      final user = await authRepository.getUser();
      if (user != null) {
        // Parse vitals into individual fields
        double? temperature;
        double? weight;
        String? bloodPressure;
        int? heartRate;

        if (finalVitals != null && finalVitals.isNotEmpty) {
          if (finalVitals.containsKey('temperature') &&
              finalVitals['temperature'] != null) {
            try {
              final tempValue = finalVitals['temperature'];
              temperature = tempValue is double
                  ? tempValue
                  : double.parse(tempValue.toString());
            } catch (e) {}
          }

          if (finalVitals.containsKey('weight') &&
              finalVitals['weight'] != null) {
            try {
              final weightValue = finalVitals['weight'];
              weight = weightValue is double
                  ? weightValue
                  : double.parse(weightValue.toString());
            } catch (e) {}
          }

          if (finalVitals.containsKey('bloodPressure') &&
              finalVitals['bloodPressure'] != null) {
            bloodPressure = finalVitals['bloodPressure'].toString();
          }

          if (finalVitals.containsKey('heartRate') &&
              finalVitals['heartRate'] != null) {
            try {
              final hrValue = finalVitals['heartRate'];
              heartRate =
                  hrValue is int ? hrValue : int.parse(hrValue.toString());
            } catch (e) {}
          }
        }

        final medicalRecord = MedicalRecord(
          petId: appointment.petId,
          clinicId: appointment.clinicId,
          vetId: user.$id,
          appointmentId: appointment.documentId!,
          visitDate: appointment.serviceCompletedAt ?? DateTime.now(),
          service: appointment.service,
          diagnosis: diagnosis,
          treatment: treatment,
          prescription: prescription,
          notes: vetNotes,
          temperature: temperature,
          weight: weight,
          bloodPressure: bloodPressure,
          heartRate: heartRate,
          attachments: appointment.attachments,
        );

        await authRepository.createMedicalRecord(medicalRecord);

        // Clear pending vitals after successful save
        if (pendingVitals.containsKey(appointment.documentId)) {
          pendingVitals.remove(appointment.documentId);
        }
      }

      // Step 3: Create notification
      try {
        final notification = AppNotification.appointmentCompleted(
          userId: appointment.userId,
          appointmentId: appointment.documentId!,
          clinicId: appointment.clinicId,
          clinicName: clinicData.value?.clinicName ?? 'Clinic',
          petName: getPetName(appointment.petId),
        );

        await authRepository.createNotification(notification);
      } catch (e) {
        // Notification creation failed
      }

      // Step 4: Send status notification
      await _sendAppointmentStatusNotification(updatedAppointment, 'completed');

      // Step 5: Send automated message
      await _sendAutomatedAppointmentMessage(
        appointment: updatedAppointment,
        messageType: 'completed',
      );

      // Show success snackbar
      if (Get.context != null) {
        SnackbarHelper.showSuccess(
          context: Get.context!,
          title: "Service Completed",
          message: finalVitals != null
              ? "Medical record created with vitals for ${getPetName(appointment.petId)}!"
              : "Medical record created for ${getPetName(appointment.petId)}!",
        );
      }
    } catch (e) {
      if (Get.context != null) {
        SnackbarHelper.showError(
          context: Get.context!,
          title: "Error",
          message: "Failed to complete service. Please try again.",
        );
      }
      rethrow;
    }
  }

  // NEW: Check if appointment has pending vitals
  bool hasPendingVitals(String appointmentId) {
    return pendingVitals.containsKey(appointmentId);
  }

  // NEW: Get pending vitals for display
  Map<String, dynamic>? getPendingVitals(String appointmentId) {
    return pendingVitals[appointmentId];
  }

  // NEW: Clear pending vitals (if user cancels)
  void clearPendingVitals(String appointmentId) {
    pendingVitals.remove(appointmentId);
  }

  Future<void> recordVitalsLocally(
    Appointment appointment,
    Map<String, dynamic> vitals,
  ) async {
    try {
      if (!Get.isRegistered<WebAppointmentController>()) {
        if (Get.context != null) {
          SnackbarHelper.showError(
            context: Get.context!,
            title: "Error",
            message: "Controller not available. Please refresh the page.",
          );
        }
        return;
      }

      // Store vitals in memory with appointment ID as key
      pendingVitals[appointment.documentId!] =
          Map<String, dynamic>.from(vitals);

      // Use postFrameCallback to avoid showing snackbar during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.context != null) {
          SnackbarHelper.showSuccess(
            context: Get.context!,
            title: "Vitals Recorded",
            message:
                "Vital signs saved. They will be included when you complete the service.",
          );
        }
      });
    } catch (e) {
      if (Get.context != null) {
        SnackbarHelper.showError(
          context: Get.context!,
          title: "Error",
          message: "Failed to record vitals. Please try again.",
        );
      }
    }
  }

  Future<void> markNoShow(Appointment appointment) async {
    // Check if appointment is in the future
    if (appointment.dateTime.isAfter(DateTime.now())) {
      if (Get.context != null) {
        SnackbarHelper.showWarning(
          context: Get.context!,
          title: "Cannot Mark No-Show",
          message: "Cannot mark as no-show for future appointments.",
        );
      }
      return;
    }

    try {
      await _updateAppointmentStatus(appointment, 'no_show');

      if (Get.context != null) {
        SnackbarHelper.showSuccess(
          context: Get.context!,
          title: "No Show Recorded",
          message:
              "Appointment for ${getPetName(appointment.petId)} marked as No Show.",
        );
      }
    } catch (e) {
      if (Get.context != null) {
        SnackbarHelper.showError(
          context: Get.context!,
          title: "Error",
          message: "Failed to mark as no-show. Please try again.",
        );
      }
    }
  }

  // Check if a time slot is available
  Future<bool> checkTimeSlotAvailability(
    String clinicId,
    DateTime dateTime, {
    String? excludeAppointmentId,
  }) async {
    try {
      final allAppointments =
          await authRepository.getClinicAppointments(clinicId);

      // Check for accepted appointments at the same date/time
      final conflictingAppointments = allAppointments.where((apt) {
        // Exclude the current appointment if checking for update
        if (excludeAppointmentId != null &&
            apt.documentId == excludeAppointmentId) {
          return false;
        }

        // Only check accepted appointments
        if (apt.status != 'accepted') return false;

        //   // Check if same date and time (within 30-minute window)
        //   final timeDifference =
        //       apt.dateTime.difference(dateTime).inMinutes.abs();
        //   return timeDifference != 0;
        // }).toList();

        // Check if appointment time is exactly the same
        return apt.dateTime.isAtSameMomentAs(dateTime);
      }).toList();

      return conflictingAppointments.isEmpty;
    } catch (e) {
      return true; // Default to available if error
    }
  }

  Future<void> updateFullAppointment(Appointment appointment) async {
    if (appointment.documentId == null) {
      if (Get.context != null) {
        SnackbarHelper.showError(
          context: Get.context!,
          title: "Error",
          message: "Cannot update appointment: Missing document ID",
        );
      }
      return;
    }

    try {
      await authRepository.updateFullAppointment(
          appointment.documentId!, appointment.toMap());

      final index = appointments
          .indexWhere((a) => a.documentId == appointment.documentId);
      if (index != -1) {
        appointments[index] = appointment;
        appointments.refresh();
        updateFilteredAppointments();
      }
    } catch (e) {
      if (Get.context != null) {
        SnackbarHelper.showError(
          context: Get.context!,
          title: "Error",
          message: "Failed to update appointment. Please try again.",
        );
      }
      rethrow;
    }
  }

  Future<void> _updateAppointmentStatus(
      Appointment appointment, String status) async {
    if (appointment.documentId == null) {
      SnackbarHelper.showError(
        context: Get.context!,
        title: "Error",
        message: "Cannot update appointment: Missing document ID",
      );
      return;
    }

    try {
      await authRepository.updateAppointmentStatus(
          appointment.documentId!, status);

      final index = appointments
          .indexWhere((a) => a.documentId == appointment.documentId);
      if (index != -1) {
        appointments[index] = appointment.copyWith(
          status: status,
          updatedAt: DateTime.now(),
        );
        appointments.refresh();
        updateFilteredAppointments();
      }
    } catch (e) {
      SnackbarHelper.showError(
        context: Get.context!,
        title: "Error",
        message: "Failed to update appointment",
      );
    }
  }

  Future<void> refreshAppointments() async {
    try {
      await fetchClinicAppointments();

      if (Get.context != null) {
        SnackbarHelper.showSuccess(
          context: Get.context!,
          title: "Refreshed",
          message: "Appointments refreshed successfully!",
        );
      }
    } catch (e) {
      if (Get.context != null) {
        SnackbarHelper.showError(
          context: Get.context!,
          title: "Error",
          message: "Failed to refresh appointments. Please try again.",
        );
      }
    }
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
  }

  void setSelectedTab(String tab) {
    // Validate tab value (no 'today' allowed)
    final validTabs = [
      'pending',
      'scheduled',
      'in_progress',
      'completed',
      'cancelled',
      'declined'
    ];

    if (validTabs.contains(tab)) {
      selectedTab.value = tab;
    } else {
      // Default to pending if invalid tab
      selectedTab.value = 'pending';
    }
  }

  void setDateFilter(DateTime date) {
    selectedDateFilter.value = date;
  }

  String get connectionStatus => isRealTimeConnected.value ? "Live" : "Polling";

  // ============= VACCINATION-SPECIFIC METHODS =============

  /// Check if a service is a vaccination service
  bool isVaccinationService(String serviceName) {
    final vaccinationKeywords = [
      'vaccination',
      'vaccine',
      'immunization',
      'rabies',
      'dhpp',
      'bordetella',
      'lepto',
      'lyme',
      'influenza',
      'shot',
    ];

    final lowerService = serviceName.toLowerCase();
    return vaccinationKeywords.any((keyword) => lowerService.contains(keyword));
  }

  /// Get veterinarian name from current user
  String getVeterinarianName() {
    try {
      final storage = GetStorage();
      final userName = storage.read('userName') as String?;
      return userName ?? 'Dr. Veterinarian';
    } catch (e) {
      return 'Dr. Veterinarian';
    }
  }

  /// Complete a vaccination service with both vaccination and medical records
  Future<void> completeVaccinationService({
    required Appointment appointment,
    required Map<String, dynamic> vaccinationData,
    String? vetNotes,
  }) async {
    try {
      // Step 1: Update appointment status - ONLY workflow fields
      final updatedAppointment = appointment.copyWith(
        status: 'completed',
        serviceCompletedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await updateFullAppointment(updatedAppointment);

      // Step 2: Create medical record with vaccination details
      final user = await authRepository.getUser();
      if (user != null) {
        final medicalRecord = MedicalRecord(
          petId: appointment.petId,
          clinicId: appointment.clinicId,
          vetId: user.$id,
          appointmentId: appointment.documentId!,
          visitDate: appointment.serviceCompletedAt ?? DateTime.now(),
          service: appointment.service,
          diagnosis: 'Vaccination: ${vaccinationData['vaccineType']}',
          treatment: 'Administered ${vaccinationData['vaccineName']}',
          prescription: vaccinationData['batchNumber'] != null
              ? 'Batch: ${vaccinationData['batchNumber']}'
              : null,
          notes: vetNotes ?? 'Vaccination completed successfully',
          temperature: null,
          weight: null,
          bloodPressure: null,
          heartRate: null,
          attachments: appointment.attachments,
        );

        await authRepository.createMedicalRecord(medicalRecord);
      }

      // Step 3: Create vaccination record
      final vaccination = Vaccination(
        petId: appointment.petId,
        clinicId: appointment.clinicId,
        vaccineType: vaccinationData['vaccineType'],
        vaccineName: vaccinationData['vaccineName'],
        dateGiven: appointment.serviceCompletedAt ?? DateTime.now(),
        nextDueDate: vaccinationData['nextDueDate'],
        veterinarianName: vaccinationData['veterinarianName'],
        veterinarianId: user?.$id,
        batchNumber: vaccinationData['batchNumber'],
        manufacturer: vaccinationData['manufacturer'],
        notes: vaccinationData['notes'],
        isBooster: vaccinationData['isBooster'] ?? false,
      );

      await authRepository.createVaccination(vaccination);

      if (Get.context != null) {
        SnackbarHelper.showSuccess(
          context: Get.context!,
          title: "Success",
          message: "Vaccination completed! Records created",
        );
      }
    } catch (e) {
      if (Get.context != null) {
        SnackbarHelper.showError(
          context: Get.context!,
          title: "Error",
          message: "Failed to complete vaccination",
        );
      }
      rethrow;
    }
  }

  // ============= CONFIRMATION METHODS =============

  /// Confirm before accepting appointment (pending -> accepted)
  Future<void> confirmAcceptAppointment(Appointment appointment) async {
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
      await acceptAppointment(appointment);
    }
  }

  /// Confirm before checking in patient (accepted/today -> in_progress)
  Future<void> confirmCheckInPatient(Appointment appointment) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Check In Patient?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are checking in ${getPetName(appointment.petId)}.',
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
                    '${getPetName(appointment.petId)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Service: ${appointment.service}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Owner: ${getOwnerName(appointment.userId)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'The appointment status will change to "In Progress".',
              style: TextStyle(fontSize: 12, color: Colors.blue[700]),
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
              backgroundColor: Colors.blue,
            ),
            child:
                const Text('Check In', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      await checkInPatient(appointment);
    }
  }

  /// Confirm before starting service (in_progress -> service started)
  Future<void> confirmStartService(Appointment appointment) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Start Service?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.purple,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are about to begin the service.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple[200]!),
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
                    'Time: ${DateFormat('hh:mm a').format(appointment.dateTime)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Service start time will be recorded.',
              style: TextStyle(fontSize: 12, color: Colors.purple[700]),
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
              backgroundColor: Colors.purple,
            ),
            child: const Text('Start Service',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      await startService(appointment);
    }
  }

  /// Confirm before marking as no-show (accepted/today -> no_show)
  Future<void> confirmMarkNoShow(Appointment appointment) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Mark as No Show?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are marking this appointment as No Show.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
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
            Row(
              children: [
                Icon(Icons.warning_outlined, size: 16, color: Colors.red[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This marks the appointment as uncompleted.',
                    style: TextStyle(fontSize: 12, color: Colors.red[700]),
                  ),
                ),
              ],
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
              backgroundColor: Colors.red,
            ),
            child: const Text('Mark No Show',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      await markNoShow(appointment);
    }
  }

  Future<void> _sendAppointmentStatusNotification(
    Appointment appointment,
    String status, {
    String? declineReason,
  }) async {
    try {
      // Get user details
      final userDoc = await authRepository.getUserById(appointment.userId);
      if (userDoc == null) {
        return;
      }

      final userName = userDoc.data['name'] ?? 'User';
      final userEmail = userDoc.data['email'] ?? '';

      // CRITICAL FIX: Read preferences DIRECTLY from the user document
      // Don't call getPreferencesForUser() - just read from the document we already have!
      final pushEnabled =
          userDoc.data['pushNotificationsEnabled'] as bool? ?? true;
      final emailEnabled =
          userDoc.data['emailNotificationsEnabled'] as bool? ?? true;

      // Get pet and clinic info
      final petName = getPetName(appointment.petId);
      final clinicName = clinicData.value?.clinicName ?? 'Unknown Clinic';

      // Check if AppwriteProvider is registered
      if (!Get.isRegistered<AppWriteProvider>()) {
        return;
      }

      // NEW: Get user's notification preferences
      final notificationPrefsService =
          Get.find<NotificationPreferencesService>();
      final userDocId = userDoc.data['\$id'] ?? appointment.userId;
      final userPreferences =
          await notificationPrefsService.getPreferencesForUser(userDocId);

      // Use AppwriteProvider to send notifications
      final appwriteProvider = Get.find<AppWriteProvider>();

      // Prepare notification content
      String pushTitle;
      String pushBody;

      switch (status) {
        case 'accepted':
          pushTitle = 'Appointment Confirmed! 🎉';
          pushBody =
              'Your appointment for $petName at $clinicName has been accepted.';
          break;
        case 'declined':
          pushTitle = 'Appointment Update';
          pushBody = 'Your appointment for $petName was declined.';
          break;
        case 'in_progress':
          pushTitle = 'Appointment Started';
          pushBody = '$petName is now being attended to.';
          break;
        case 'completed':
          pushTitle = 'Appointment Completed ✓';
          pushBody = '$petName\'s appointment is complete.';
          break;
        default:
          pushTitle = 'Appointment Update';
          pushBody = 'Your appointment for $petName has been updated.';
      }

      // 1. Send push notification ONLY if user has it enabled
      if (userPreferences.pushNotificationsEnabled) {
        await appwriteProvider.sendPushNotification(
          title: pushTitle,
          body: pushBody,
          userIds: [appointment.userId],
          data: {
            'type': 'appointment',
            'status': status,
            'appointmentId': appointment.documentId!,
            'petName': petName,
            'clinicName': clinicName,
          },
        );
      } else {}

      // STEP 3: Send email (only if enabled and status is accepted/declined)
      if (status == 'accepted' || status == 'declined') {
        if (userPreferences.emailNotificationsEnabled) {
          await appwriteProvider.sendEmail(
            to: userEmail,
            subject: status == 'accepted'
                ? 'Appointment Confirmed - PAWrtal'
                : 'Appointment Update - PAWrtal',
            htmlContent: appwriteProvider.buildEmailTemplate(
              userName: userName,
              petName: petName,
              clinicName: clinicName,
              service: appointment.service,
              appointmentDateTime: appointment.dateTime,
              status: status,
              declineReason: declineReason,
            ),
            userId: appointment.userId,
          );
        } else {}
      }
    } catch (e) {
      // Don't fail the appointment operation if notification fails
    }
  }

  /// Complete a vaccination service with both vaccination and medical records INCLUDING VITALS
  Future<void> completeVaccinationServiceWithVitals({
    required Appointment appointment,
    required Map<String, dynamic> vaccinationData,
    String? vetNotes,
    Map<String, dynamic>? vitals,
  }) async {
    try {
      // Extract individual vital values
      double? temperature;
      double? weight;
      String? bloodPressure;
      int? heartRate;

      if (vitals != null && vitals.isNotEmpty) {
        if (vitals.containsKey('temperature') &&
            vitals['temperature'] != null) {
          try {
            final tempValue = vitals['temperature'];
            temperature = tempValue is double
                ? tempValue
                : double.parse(tempValue.toString());
          } catch (e) {}
        }

        if (vitals.containsKey('weight') && vitals['weight'] != null) {
          try {
            final weightValue = vitals['weight'];
            weight = weightValue is double
                ? weightValue
                : double.parse(weightValue.toString());
          } catch (e) {}
        }

        if (vitals.containsKey('bloodPressure') &&
            vitals['bloodPressure'] != null) {
          bloodPressure = vitals['bloodPressure'].toString();
        }

        if (vitals.containsKey('heartRate') && vitals['heartRate'] != null) {
          try {
            final hrValue = vitals['heartRate'];
            heartRate =
                hrValue is int ? hrValue : int.parse(hrValue.toString());
          } catch (e) {}
        }
      }

      // Step 1: Update appointment status
      final updatedAppointment = appointment.copyWith(
        status: 'completed',
        serviceCompletedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await updateFullAppointment(updatedAppointment);

      // Step 2: Create medical record with vaccination details AND vitals
      final user = await authRepository.getUser();
      if (user != null) {
        final medicalRecord = MedicalRecord(
          petId: appointment.petId,
          clinicId: appointment.clinicId,
          vetId: user.$id,
          appointmentId: appointment.documentId!,
          visitDate: appointment.serviceCompletedAt ?? DateTime.now(),
          service: appointment.service,
          diagnosis: 'Vaccination: ${vaccinationData['vaccineType']}',
          treatment: 'Administered ${vaccinationData['vaccineName']}',
          prescription: vaccinationData['batchNumber'] != null
              ? 'Batch: ${vaccinationData['batchNumber']}'
              : null,
          notes: vetNotes ?? 'Vaccination completed successfully',
          temperature: temperature,
          weight: weight,
          bloodPressure: bloodPressure,
          heartRate: heartRate,
          attachments: appointment.attachments,
        );

        await authRepository.createMedicalRecord(medicalRecord);

        // Clear pending vitals after successful save
        if (pendingVitals.containsKey(appointment.documentId)) {
          pendingVitals.remove(appointment.documentId);
        }
      }

      // Step 3: Create vaccination record
      final vaccination = Vaccination(
        petId: appointment.petId,
        clinicId: appointment.clinicId,
        vaccineType: vaccinationData['vaccineType'],
        vaccineName: vaccinationData['vaccineName'],
        dateGiven: appointment.serviceCompletedAt ?? DateTime.now(),
        nextDueDate: vaccinationData['nextDueDate'],
        veterinarianName: vaccinationData['veterinarianName'],
        veterinarianId: user?.$id,
        batchNumber: vaccinationData['batchNumber'],
        manufacturer: vaccinationData['manufacturer'],
        notes: vaccinationData['notes'],
        isBooster: vaccinationData['isBooster'] ?? false,
      );

      await authRepository.createVaccination(vaccination);

      // Step 4: Create notification
      try {
        final notification = AppNotification.appointmentCompleted(
          userId: appointment.userId,
          appointmentId: appointment.documentId!,
          clinicId: appointment.clinicId,
          clinicName: clinicData.value?.clinicName ?? 'Clinic',
          petName: getPetName(appointment.petId),
        );

        await authRepository.createNotification(notification);
      } catch (e) {}

      await _sendAppointmentStatusNotification(updatedAppointment, 'completed');

      await _sendAutomatedAppointmentMessage(
        appointment: updatedAppointment,
        messageType: 'completed',
      );

      if (Get.context != null) {
        SnackbarHelper.showSuccess(
          context: Get.context!,
          title: "Vaccination Completed",
          message: vitals != null
              ? "Vaccination and medical records created with vitals for ${getPetName(appointment.petId)}!"
              : "Vaccination and medical records created for ${getPetName(appointment.petId)}!",
        );
      }
    } catch (e) {
      if (Get.context != null) {
        SnackbarHelper.showError(
          context: Get.context!,
          title: "Error",
          message: "Failed to complete vaccination. Please try again.",
        );
      }
      rethrow;
    }
  }

  /// Check if a service is a medical service (requires vitals)
  bool isMedicalService(String serviceName) {
    final medicalKeywords = [
      'checkup',
      'check-up',
      'examination',
      'exam',
      'consultation',
      'diagnosis',
      'treatment',
      'surgery',
      'vaccination',
      'vaccine',
      'immunization',
      'dental',
      'xray',
      'x-ray',
      'ultrasound',
      'blood test',
      'lab test',
      'emergency',
      'medical',
      'health check',
      'wellness',
      'sick visit',
      'follow-up',
      'follow up',
    ];

    final lowerService = serviceName.toLowerCase();
    return medicalKeywords.any((keyword) => lowerService.contains(keyword));
  }

  /// Check if a service is a basic service (grooming, etc.)
  bool isBasicService(String serviceName) {
    final basicKeywords = [
      'grooming',
      'bath',
      'nail trim',
      'nail clipping',
      'haircut',
      'shampoo',
      'brush',
      'ear cleaning',
      'teeth cleaning',
      'boarding',
      'daycare',
    ];

    final lowerService = serviceName.toLowerCase();
    return basicKeywords.any((keyword) => lowerService.contains(keyword));
  }

  /// Get service type for display
  String getServiceType(String serviceName) {
    if (isMedicalService(serviceName)) {
      return 'Medical Service';
    } else if (isBasicService(serviceName)) {
      return 'Basic Service';
    } else {
      return 'General Service';
    }
  }

  /// Get service type icon
  IconData getServiceTypeIcon(String serviceName) {
    if (isMedicalService(serviceName)) {
      return Icons.medical_services;
    } else if (isBasicService(serviceName)) {
      return Icons.content_cut;
    } else {
      return Icons.pets;
    }
  }

  /// Get service type color
  Color getServiceTypeColor(String serviceName) {
    if (isMedicalService(serviceName)) {
      return Colors.red; // Medical = Red
    } else if (isBasicService(serviceName)) {
      return Colors.blue; // Basic = Blue
    } else {
      return Colors.grey; // General = Grey
    }
  }

  /// Check if service should show vitals button
  bool shouldShowVitalsButton(String serviceName) {
    // Only medical services need vitals
    return isMedicalService(serviceName);
  }

  /// Debug method to verify pet fetching
  Future<void> debugPetFetching() async {
    for (var appointment in appointments.take(5)) {
      // Try to fetch directly
      try {
        final petDoc = await authRepository.getPetById(appointment.petId);
        if (petDoc != null) {
        } else {}
      } catch (e) {}
    }
  }

  /// Get pet profile picture URL using composite key (userId + petId)
  Future<String?> getPetProfilePictureUrl(String petId,
      {String? userId}) async {
    // If userId is provided, use it directly
    if (userId != null) {
      final cacheKey = '${userId}_$petId';

      // Check cache first
      if (petProfilePictures.containsKey(cacheKey)) {
        return petProfilePictures[cacheKey];
      }

      // Fetch and cache
      return await _fetchAndCachePetImage(userId, petId);
    }

    // If userId not provided, find it from appointments
    final appointment = appointments.firstWhereOrNull(
      (a) => a.petId == petId,
    );

    if (appointment != null) {
      final cacheKey = '${appointment.userId}_$petId';

      // Check cache first
      if (petProfilePictures.containsKey(cacheKey)) {
        return petProfilePictures[cacheKey];
      }

      // Fetch and cache
      return await _fetchAndCachePetImage(appointment.userId, petId);
    }

    return null;
  }

  /// HELPER: Fetch and cache pet image
  Future<String?> _fetchAndCachePetImage(String userId, String petId) async {
    try {
      final cacheKey = '${userId}_$petId';

      // Fetch pet using the user-specific method
      final pet = await _fetchPetByUserAndId(userId, petId);

      if (pet != null && pet.image != null && pet.image!.isNotEmpty) {
        // Cache the image URL
        petProfilePictures[cacheKey] = pet.image;
        return pet.image;
      }

      // Cache null result
      petProfilePictures[cacheKey] = null;
      return null;
    } catch (e) {
      final cacheKey = '${userId}_$petId';
      petProfilePictures[cacheKey] = null;
      return null;
    }
  }

  /// Get pet image by userId (already implemented correctly)
  Future<String?> getPetImageByUserId(String petId, String userId) async {
    try {
      // CRITICAL: Use composite key (userId + petId)
      final cacheKey = '${userId}_$petId';

      // Check cache FIRST - return immediately if already cached
      if (petProfilePictures.containsKey(cacheKey)) {
        return petProfilePictures[cacheKey];
      }

      // Use the new helper method
      final pet = await _fetchPetByUserAndId(userId, petId);

      if (pet == null) {
        petProfilePictures[cacheKey] = null;
        return null;
      }

      // Cache the pet with composite key
      final petCacheKey = '${userId}_${pet.petId}';
      petsCache[petCacheKey] = pet;

      // Return and cache the image URL
      if (pet.image != null && pet.image!.isNotEmpty) {
        petProfilePictures[cacheKey] = pet.image;
        return pet.image;
      }

      petProfilePictures[cacheKey] = null;
      return null;
    } catch (e) {
      final cacheKey = '${userId}_$petId';
      petProfilePictures[cacheKey] = null;
      return null;
    }
  }

  /// Preload pet images for visible appointments
  Future<void> preloadPetImages() async {
    final visibleAppointments = filteredAppointments.take(20).toList();

    for (var appointment in visibleAppointments) {
      final cacheKey = '${appointment.userId}_${appointment.petId}';

      // Skip if already cached
      if (petProfilePictures.containsKey(cacheKey)) {
        continue;
      }

      // Fetch in background (don't await)
      getPetImageByUserId(appointment.petId, appointment.userId)
          .catchError((e) {});
    }
  }

  Future<void> _sendAutomatedAppointmentMessage({
    required Appointment appointment,
    required String
        messageType, // 'accepted', 'declined', 'completed', 'auto_declined'
    String? declineReason,
  }) async {
    try {
      // Step 1: Get or create conversation
      final conversation = await authRepository.getOrCreateConversation(
        appointment.userId,
        appointment.clinicId,
      );

      if (conversation == null) {
        return;
      }

      // Step 2: Build the automated message based on type
      String messageText;
      final petName = getPetName(appointment.petId);
      final clinicName = clinicData.value?.clinicName ?? 'Our clinic';
      final formattedDate =
          DateFormat('MMMM dd, yyyy').format(appointment.dateTime);
      final formattedTime = DateFormat('hh:mm a').format(appointment.dateTime);

      switch (messageType) {
        case 'accepted':
          messageText = '''
Hello! 🎉

Your appointment for $petName has been ACCEPTED!

📅 Date: $formattedDate
🕐 Time: $formattedTime
🏥 Service: ${appointment.service}

Please arrive 10 minutes early. We look forward to seeing you and $petName!

If you need to make any changes, please let us know as soon as possible.

- $clinicName Team
''';
          break;

        case 'declined':
          messageText = '''
Hello,

We regret to inform you that your appointment for $petName on $formattedDate at $formattedTime could not be confirmed.

${declineReason != null && declineReason.isNotEmpty ? '📝 Reason: $declineReason\n\n' : ''}Please contact us to reschedule or discuss alternative time slots.

We apologize for any inconvenience.

- $clinicName Team
''';
          break;

        case 'auto_declined':
          messageText = '''
Hello,

Your appointment for $petName on $formattedDate at $formattedTime has been automatically declined.

⏰ Reason: The appointment time has passed without confirmation.

We noticed that this appointment was not confirmed before the scheduled time. This might have been overlooked.

To ensure you receive the care your pet needs, please book a new appointment at a time that works for you.

If you have any questions or concerns, please don't hesitate to contact us.

We apologize for any inconvenience and look forward to serving you and $petName soon!

- $clinicName Team
''';
          break;

        case 'completed':
          messageText = '''
Hello! ✅

$petName's appointment has been completed.

📋 Service: ${appointment.service}
📅 Date: $formattedDate

${appointment.followUpInstructions != null && appointment.followUpInstructions!.isNotEmpty ? '💡 Follow-up instructions: ${appointment.followUpInstructions}\n\n' : ''}Thank you for choosing $clinicName. If you have any questions about the visit, please don't hesitate to reach out!

- $clinicName Team
''';
          break;

        default:
          messageText = '''
Hello,

Your appointment for $petName has been updated.

📅 Date: $formattedDate
🕐 Time: $formattedTime
🏥 Service: ${appointment.service}

For more details, please check your appointments.

- $clinicName Team
''';
      }

      // Step 3: Send the automated message
      final messageData = {
        'conversationId': conversation.documentId!,
        'senderId': appointment.clinicId,
        'senderType': 'clinic',
        'receiverId': appointment.userId,
        'messageText': messageText,
        'messageType': 'text',
        'timestamp': DateTime.now().toIso8601String(),
        'isRead': false,
        'isDeleted': false,
        'sentAt': DateTime.now().toIso8601String(),
      };

      await authRepository.appWriteProvider.createMessage(messageData);
    } catch (e) {
      // Don't rethrow - the appointment action already succeeded
    }
  }

  /// Clear pet profile pictures cache
  void clearPetProfilePicturesCache() {
    petProfilePictures.clear();
  }

  Future<void> refreshPetImages() async {
    petProfilePictures.clear();
    await _fetchRelatedData();
  }

  Future<void> debugPetData(String appointmentId) async {
    try {
      final appointment = appointments.firstWhere(
        (a) => a.documentId == appointmentId,
        orElse: () => throw Exception('Appointment not found'),
      );

      // Fetch user's pets
      final userPets = await authRepository.getUserPets(appointment.userId);

      for (var petDoc in userPets) {
        final pet = Pet.fromMap(petDoc.data);
      }

      // Check cache
      if (petProfilePictures.containsKey(appointment.petId)) {}
    } catch (e) {}
  }

  /// Get medical record by appointment ID
  Future<MedicalRecord?> getMedicalRecordByAppointmentId(
      String appointmentId) async {
    try {
      // Get all medical records for the clinic
      final allRecords = await authRepository
          .getClinicMedicalRecords(clinicData.value!.documentId!);

      // Find the record that matches this appointment ID
      final matchingRecord = allRecords.firstWhereOrNull(
        (record) => record.appointmentId == appointmentId,
      );

      if (matchingRecord != null) {
      } else {}

      return matchingRecord;
    } catch (e) {
      return null;
    }
  }

  Future<void> completeNonMedicalService({
    required Appointment appointment,
    String? notes,
  }) async {
    try {
      // Update appointment to completed
      final updatedAppointment = appointment.copyWith(
        status: 'completed',
        serviceCompletedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        notes: notes,
      );

      await updateFullAppointment(updatedAppointment);

      // Create notification
      try {
        final notification = AppNotification.appointmentCompleted(
          userId: appointment.userId,
          appointmentId: appointment.documentId!,
          clinicId: appointment.clinicId,
          clinicName: clinicData.value?.clinicName ?? 'Clinic',
          petName: getPetName(appointment.petId),
        );

        await authRepository.createNotification(notification);
      } catch (e) {}

      // Send status notification
      await _sendAppointmentStatusNotification(updatedAppointment, 'completed');

      // Send automated message
      await _sendAutomatedAppointmentMessage(
        appointment: updatedAppointment,
        messageType: 'completed',
      );

      if (Get.context != null) {
        SnackbarHelper.showSuccess(
          context: Get.context!,
          title: "Service Completed",
          message:
              "Service completed successfully for ${getPetName(appointment.petId)}!",
        );
      }
    } catch (e) {
      if (Get.context != null) {
        SnackbarHelper.showError(
          context: Get.context!,
          title: "Error",
          message: "Failed to complete service. Please try again.",
        );
      }
      rethrow;
    }
  }

  Future<bool> isCurrentStaffDoctor() async {
    try {
      final storage = GetStorage();
      final userRole = storage.read('role') as String?;

      if (userRole != 'staff') {
        // Admins can complete all appointments
        return true;
      }

      final staffId = storage.read('staffId') as String?;
      if (staffId == null) return false;

      final staffDoc = await authRepository.getStaffByDocumentId(staffId);
      return staffDoc?.isDoctor ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<String?> getPetImageUrl(String petId) async {
    try {
      // Check cache first
      if (petImagesCache.containsKey(petId)) {
        return petImagesCache[petId];
      }

      final petData = await authRepository.getPetWithImage(petId);

      if (petData != null) {
        final imageUrl = petData['imageUrl'] as String?;

        if (imageUrl != null && imageUrl.isNotEmpty) {
          // Cache the URL
          petImagesCache[petId] = imageUrl;
          return imageUrl;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Clear pet images cache
  void clearPetImagesCache() {
    petImagesCache.clear();
  }

  void cleanupOnLogout() {
    // Cancel all subscriptions
    _appointmentSubscription?.close();
    _appointmentSubscription = null;

    _fallbackTimer?.cancel();
    _fallbackTimer = null;

    _autoDeclineTimer?.cancel();
    _autoDeclineTimer = null;

    // Clear all cached data
    appointments.clear();
    filteredAppointments.clear();
    petsCache.clear();
    ownersCache.clear();
    petProfilePictures.clear();
    petImagesCache.clear();
    pendingVitals.clear();

    // Reset clinic data
    clinicData.value = null;

    // Reset filters
    searchQuery.value = '';

    // ✅ IMPORTANT: Reset to pending on logout ONLY
    selectedTab.value = 'pending';

    selectedDateFilter.value = DateTime.now();
    selectedCalendarDate.value = null;
    viewMode.value = AppointmentViewMode.today;

    // Reset connection status
    isRealTimeConnected.value = false;
  }

  void _startAutoDeclineTimer() {
    try {
      _autoDeclineTimer?.cancel();

      _autoDeclineTimer = Timer.periodic(
        const Duration(seconds: _autoDeclineCheckInterval),
        (timer) {
          if (clinicData.value?.documentId != null) {
            _checkAndDeclineOverlookedAppointments();
          }
        },
      );

      isAutoDeclineActive.value = true;

      // Initial check after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (clinicData.value?.documentId != null) {
          _checkAndDeclineOverlookedAppointments();
        }
      });
    } catch (e) {}
  }

  Future<void> _checkAndDeclineOverlookedAppointments() async {
    try {
      final now = DateTime.now();

      if (clinicData.value?.documentId == null) {
        return;
      }

      // Get only PENDING appointments
      final pendingAppointments =
          appointments.where((a) => a.status == 'pending').toList();

      if (pendingAppointments.isEmpty) {
        return;
      }

      int declinedCount = 0;
      int errorCount = 0;
      List<String> declinedIds = []; // Track declined appointment IDs

      for (var appointment in pendingAppointments) {
        try {
          // Parse the appointment time correctly (it's stored in UTC)
          final storedDateTime = appointment.dateTime;

          // Convert to local time for comparison
          final actualLocalTime = DateTime(
            storedDateTime.year,
            storedDateTime.month,
            storedDateTime.day,
            storedDateTime.hour,
            storedDateTime.minute,
            storedDateTime.second,
          );

          // Check if appointment time has passed
          final isPast = actualLocalTime.isBefore(now);

          if (isPast) {
            final minutesOverdue = now.difference(actualLocalTime).inMinutes;

            try {
              // Use the EXISTING declineAppointment method
              await _autoDeclineUsingExistingMethod(
                  appointment, actualLocalTime);

              declinedCount++;
              declinedIds.add(appointment.documentId!);
            } catch (e) {
              errorCount++;
              // Continue with other appointments
            }
          }
        } catch (e) {
          errorCount++;
          // Continue with other appointments
        }
      }

      // CRITICAL FIX: Don't call fetchClinicAppointments() here!
      // The realtime subscription will handle updating the UI automatically
      // Only log the results
      if (declinedCount > 0) {
        // Optional: Manually update the local state without refetching
        for (var appointmentId in declinedIds) {
          final index =
              appointments.indexWhere((a) => a.documentId == appointmentId);
          if (index != -1) {
            final updated = appointments[index].copyWith(
              status: 'declined',
              cancelledBy: 'clinic',
              cancelledAt: DateTime.now(),
            );
            appointments[index] = updated;
          }
        }

        // Refresh the filtered view
        appointments.refresh();
        updateFilteredAppointments();
      }
    } catch (e, stackTrace) {
      // Silent fail - don't crash the app
    }
  }

  Future<void> _autoDeclineUsingExistingMethod(
    Appointment appointment,
    DateTime actualLocalTime,
  ) async {
    try {
      // Create a detailed auto-decline reason
      final formattedTime =
          DateFormat('MMM dd, yyyy • hh:mm a').format(actualLocalTime);
      final minutesOverdue =
          DateTime.now().difference(actualLocalTime).inMinutes;

      final autoDeclineReason = 'Appointment was overlooked.';

      // ✅ CRITICAL: Call declineAppointment WITHOUT snackbars (background operation)
      await declineAppointment(
        appointment,
        autoDeclineReason,
        showSnackbar: false, // Don't show snackbars for auto-decline
      );
    } catch (e, stackTrace) {
      // Don't rethrow - we want to continue processing other appointments
    }
  }

  Future<bool> verifyAppointmentDeclined(String appointmentId) async {
    try {
      // Check local state first (much faster)
      final localAppointment = appointments.firstWhereOrNull(
        (a) => a.documentId == appointmentId,
      );

      if (localAppointment != null) {
        final isDeclined = localAppointment.status == 'declined';
        return isDeclined;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  bool _isAppointmentOverlooked(Appointment appointment) {
    try {
      final now = DateTime.now();

      final storedDateTime = appointment.dateTime;
      final actualLocalTime = DateTime(
        storedDateTime.year,
        storedDateTime.month,
        storedDateTime.day,
        storedDateTime.hour,
        storedDateTime.minute,
        storedDateTime.second,
      );

      return actualLocalTime.isBefore(now);
    } catch (e) {
      return false;
    }
  }

  int getOverlookedAppointmentCount() {
    try {
      return appointments.where((apt) {
        return apt.status == 'pending' && _isAppointmentOverlooked(apt);
      }).length;
    } catch (e) {
      return 0;
    }
  }

  List<Appointment> getOverlookedAppointments() {
    try {
      return appointments.where((apt) {
        return apt.status == 'pending' && _isAppointmentOverlooked(apt);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  String getTimeUntilOverlooked(Appointment appointment) {
    try {
      final now = DateTime.now();

      final storedDateTime = appointment.dateTime;
      final actualLocalTime = DateTime(
        storedDateTime.year,
        storedDateTime.month,
        storedDateTime.day,
        storedDateTime.hour,
        storedDateTime.minute,
        storedDateTime.second,
      );

      if (actualLocalTime.isBefore(now)) {
        final minutesPassed = now.difference(actualLocalTime).inMinutes;
        return 'Overlooked ($minutesPassed minutes overdue)';
      }

      final difference = actualLocalTime.difference(now);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ${difference.inHours % 24}h until start';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ${difference.inMinutes % 60}m until start';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m until start';
      } else {
        return 'Starting now';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<void> manualCheckOverlookedAppointments() async {
    await _checkAndDeclineOverlookedAppointments();
  }

  Future<void> triggerManualDeclineCheck() async {
    await manualCheckOverlookedAppointments();
  }

  Future<void> fetchTodayAppointmentsFromDatabase() async {
    if (clinicData.value?.documentId == null) {
      return;
    }

    try {
      // Use local time to define "today" (same as dashboard)
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day, 0, 0, 0);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      // Fetch ALL today's appointments (same query as dashboard)
      final result =
          await authRepository.appWriteProvider.databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.appointmentCollectionID,
        queries: [
          Query.equal('clinicId', clinicData.value!.documentId!),
          Query.greaterThanEqual('dateTime', startOfDay.toIso8601String()),
          Query.lessThanEqual('dateTime', endOfDay.toIso8601String()),
          Query.limit(100), // Get all today's appointments
        ],
      );

      // Parse appointments
      final List<Appointment> todayAppts = [];
      for (var doc in result.documents) {
        try {
          final appointment = Appointment.fromMap(doc.data);
          todayAppts.add(appointment);
        } catch (e) {}
      }

      // Log status breakdown
      final statusBreakdown = <String, int>{};
      for (var apt in todayAppts) {
        statusBreakdown[apt.status] = (statusBreakdown[apt.status] ?? 0) + 1;
      }

      // Update main appointments list by merging with existing
      // Remove old today appointments and add new ones
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);

      appointments.removeWhere((a) {
        final aptDate = DateTime(
          a.dateTime.toLocal().year,
          a.dateTime.toLocal().month,
          a.dateTime.toLocal().day,
        );
        return aptDate.isAtSameMomentAs(todayDate);
      });

      appointments.addAll(todayAppts);
      appointments.refresh();

      // Update filtered view
      updateFilteredAppointments();
    } catch (e) {}
  }

  /// Get current time in Philippine timezone (UTC+8)
  DateTime get _nowInPhilippineTime {
    final utcNow = DateTime.now().toUtc();
    return utcNow.add(const Duration(hours: 8));
  }

  void resetToPendingTab() {
    // Reset tab selection to "pending"
    selectedTab.value = 'pending';

    // Clear calendar date filter
    selectedCalendarDate.value = null;

    // Keep the current view mode (don't force to 'today')
    // Users can still use the view mode filter

    // Clear search query
    searchQuery.value = '';

    // Trigger filter update to show pending appointments
    updateFilteredAppointments();
  }

  void syncTabControllerWithState(
      TabController desktopController, TabController mobileController) {
    // Define tab values list (WITHOUT 'today')
    final tabValues = [
      'pending',
      'scheduled',
      'in_progress',
      'completed',
      'cancelled',
      'declined',
    ];

    // Find the index of the currently selected tab (from the persistent state)
    final currentTabIndex = tabValues.indexOf(selectedTab.value);

    if (currentTabIndex != -1) {
      // Set both controllers to the saved tab
      desktopController.index = currentTabIndex;
      mobileController.index = currentTabIndex;
    } else {
      // Fallback to pending if something went wrong
      // BUT DON'T change selectedTab.value - keep the controller state
      desktopController.index = 0;
      mobileController.index = 0;
    }

    // Ensure filtered appointments match the selected tab
    updateFilteredAppointments();
  }

  void initializeWithPendingTab() {
    // Set to pending tab
    selectedTab.value = 'pending';

    // Clear any calendar date filter
    selectedCalendarDate.value = null;

    // Clear search
    searchQuery.value = '';

    // Trigger filter update
    updateFilteredAppointments();
  }

  Map<String, int> get filteredAppointmentStats {
    // For stat cards, always show correct counts based on date filters
    List<Appointment> baseFiltered = _getBaseFilteredAppointments();

    // ✅ EXCEPTION: Pending count should ALWAYS show ALL pending (no date filter)
    final allPendingCount =
        appointments.where((a) => a.status == 'pending').length;

    final stats = {
      'total': baseFiltered.length,
      'today': todayAppointments.length,
      'pending': allPendingCount, // ✅ Show ALL pending appointments
      'scheduled': baseFiltered.where((a) => a.status == 'accepted').length,
      'in_progress':
          baseFiltered.where((a) => a.status == 'in_progress').length,
      'completed': baseFiltered.where((a) => a.status == 'completed').length,
      'cancelled': baseFiltered.where((a) => a.status == 'cancelled').length,
      'declined': baseFiltered.where((a) => a.status == 'declined').length,
    };

    return stats;
  }

  List<Appointment> _getBaseFilteredAppointments() {
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);

    List<Appointment> filtered;

    // Priority 1: Calendar date selection (if set)
    if (selectedCalendarDate.value != null) {
      final selectedDate = selectedCalendarDate.value!;

      filtered = appointments.where((appointment) {
        final appointmentDate = DateTime(
          appointment.dateTime.year,
          appointment.dateTime.month,
          appointment.dateTime.day,
        );

        return appointmentDate.year == selectedDate.year &&
            appointmentDate.month == selectedDate.month &&
            appointmentDate.day == selectedDate.day;
      }).toList();

      return filtered;
    }

    // Priority 2: View mode filtering
    switch (viewMode.value) {
      case AppointmentViewMode.today:
        filtered = appointments.where((appointment) {
          final appointmentDate = DateTime(
            appointment.dateTime.year,
            appointment.dateTime.month,
            appointment.dateTime.day,
          );
          return appointmentDate.isAtSameMomentAs(todayDate);
        }).toList();
        break;

      case AppointmentViewMode.thisWeek:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final weekStartDate =
            DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        final weekEndDate = weekStartDate.add(const Duration(days: 6));

        filtered = appointments.where((a) {
          final appointmentDate = DateTime(
            a.dateTime.year,
            a.dateTime.month,
            a.dateTime.day,
          );
          return !appointmentDate.isBefore(weekStartDate) &&
              !appointmentDate.isAfter(weekEndDate);
        }).toList();
        break;

      case AppointmentViewMode.thisMonth:
        filtered = appointments.where((a) {
          return a.dateTime.year == now.year && a.dateTime.month == now.month;
        }).toList();
        break;

      case AppointmentViewMode.allTime:
        filtered = appointments.toList();
        break;
    }

    return filtered;
  }
}
