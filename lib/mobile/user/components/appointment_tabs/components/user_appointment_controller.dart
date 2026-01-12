import 'dart:async';
import 'package:appwrite/appwrite.dart';
import 'package:capstone_app/data/models/appointment_model.dart';
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/data/models/notification_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EnhancedUserAppointmentController extends GetxController {
  final AuthRepository authRepository;
  final UserSessionService session;

  EnhancedUserAppointmentController({
    required this.authRepository,
    required this.session,
  });

  var isLoading = false.obs;
  var appointments = <Appointment>[].obs;
  var clinics = <String, Clinic>{}.obs;
  var pets = <String, Pet>{}.obs;

  var appointmentReviews = <String, bool>{}.obs;

  DateTime? _lastFetchTime;
  final Duration _cacheDuration = const Duration(minutes: 30);

  StreamSubscription<RealtimeMessage>? _appointmentSubscription;
  StreamSubscription<RealtimeMessage>? _reviewSubscription;

  bool get isCacheValid {
    if (_lastFetchTime == null) return false;
    final now = DateTime.now();
    return now.difference(_lastFetchTime!) < _cacheDuration;
  }

  bool get hasData => appointments.isNotEmpty || _lastFetchTime != null;

  @override
  void onInit() {
    super.onInit();
    // Only fetch if cache is invalid or no data exists
    if (!isCacheValid) {
      fetchAppointments();
    } else {
      // Data is cached, just set up real-time
      _setupRealtimeSubscription();
      _setupReviewSubscription();
    }
  }

  @override
  void onClose() {
    _appointmentSubscription?.cancel();
    _reviewSubscription?.cancel();
    super.onClose();
  }

  void _setupRealtimeSubscription() {
    try {
      final userId = session.userId;
      if (userId.isEmpty) return;

      // Cancel existing subscription if any
      _appointmentSubscription?.cancel();

      _appointmentSubscription =
          authRepository.subscribeToUserAppointments(userId).listen((message) {
        _handleRealtimeUpdate(message);
      });
    } catch (e) {
      // Silent fail for real-time setup
    }
  }

  void _setupReviewSubscription() {
    try {
      final userId = session.userId;
      if (userId.isEmpty) return;

      // Cancel existing subscription if any
      _reviewSubscription?.cancel();

      _reviewSubscription =
          authRepository.subscribeToClinicReviews('').listen((message) {
        _handleReviewUpdate(message);
      });
    } catch (e) {
      // Silent fail for real-time setup
    }
  }

  void _handleReviewUpdate(RealtimeMessage message) {
    final payload = message.payload;
    final eventType = message.events.first;
    final appointmentId = payload['appointmentId'] as String?;

    if (appointmentId == null) return;

    if (eventType.contains('create')) {
      appointmentReviews[appointmentId] = true;
    } else if (eventType.contains('delete')) {
      appointmentReviews[appointmentId] = false;
    }

    appointments.refresh();
  }

  void _handleRealtimeUpdate(RealtimeMessage message) {
    final payload = message.payload;
    final eventType = message.events.first;

    if (eventType.contains('create')) {
      _addOrUpdateAppointment(payload);
    } else if (eventType.contains('update')) {
      _addOrUpdateAppointment(payload);
    } else if (eventType.contains('delete')) {
      appointments.removeWhere((a) => a.documentId == payload['\$id']);
    }

    appointments.refresh();
  }

  void _addOrUpdateAppointment(Map<String, dynamic> payload) {
    final appointment = Appointment.fromMap(payload);
    final index =
        appointments.indexWhere((a) => a.documentId == appointment.documentId);

    if (index != -1) {
      appointments[index] = appointment;
    } else {
      appointments.add(appointment);
    }

    _fetchRelatedDataForAppointment(appointment);
    _checkAppointmentReview(appointment.documentId!);
  }

  Map<String, dynamic> getCacheStatus() {
    return {
      'isCacheValid': isCacheValid,
      'lastFetchTime': _lastFetchTime?.toString() ?? 'Never',
      'minutesRemaining': _lastFetchTime != null
          ? _cacheDuration.inMinutes -
              DateTime.now().difference(_lastFetchTime!).inMinutes
          : 0,
      'appointmentCount': appointments.length,
    };
  }

  Future<void> _checkAppointmentReview(String appointmentId) async {
    try {
      final hasReview =
          await authRepository.hasUserReviewedAppointment(appointmentId);
      appointmentReviews[appointmentId] = hasReview;
    } catch (e) {}
  }

  Future<void> fetchAppointments({bool forceRefresh = false}) async {
    // Check cache validity unless force refresh is requested
    if (!forceRefresh && isCacheValid && appointments.isNotEmpty) {
      // Cache is still valid, no need to fetch
      return;
    }

    try {
      isLoading.value = true;
      final userId = session.userId;

      if (userId.isEmpty) {
        Get.snackbar("Error", "User not logged in.");
        return;
      }

      final result = await authRepository.getUserAppointments(userId);
      appointments.assignAll(result);

      // Update cache timestamp
      _lastFetchTime = DateTime.now();

      await _fetchRelatedData();
      await _checkAllAppointmentReviews();

      // Setup real-time subscriptions after first fetch
      if (_appointmentSubscription == null) {
        _setupRealtimeSubscription();
      }
      if (_reviewSubscription == null) {
        _setupReviewSubscription();
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to load appointments: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshAppointments() async {
    await fetchAppointments(forceRefresh: true);
  }

  void clearCache() {
    _lastFetchTime = null;
  }

  Future<void> _checkAllAppointmentReviews() async {
    for (var appointment in appointments) {
      if (appointment.documentId != null && appointment.isCompleted) {
        await _checkAppointmentReview(appointment.documentId!);
      }
    }
  }

  Future<void> _fetchRelatedData() async {
    final clinicIds = appointments.map((a) => a.clinicId).toSet();
    final petNames = appointments.map((a) => a.petId).toSet();

    for (final clinicId in clinicIds) {
      if (!clinics.containsKey(clinicId) && clinicId.isNotEmpty) {
        try {
          final clinicDoc = await authRepository.getClinicById(clinicId);
          if (clinicDoc != null) {
            final clinic = Clinic.fromMap(clinicDoc.data);
            clinic.documentId = clinicDoc.$id;
            clinics[clinicId] = clinic;
          }
        } catch (e) {}
      }
    }

    for (final petName in petNames) {
      if (!pets.containsKey(petName) && petName.isNotEmpty) {
        try {
          final petDoc = await authRepository.getPetByName(petName);
          if (petDoc != null) {
            final pet = Pet.fromMap(petDoc.data);
            pet.documentId = petDoc.$id;
            pets[petName] = pet;
          }
        } catch (e) {}
      }
    }
  }

  Future<void> _fetchRelatedDataForAppointment(Appointment appointment) async {
    if (!clinics.containsKey(appointment.clinicId) &&
        appointment.clinicId.isNotEmpty) {
      try {
        final clinicDoc =
            await authRepository.getClinicById(appointment.clinicId);
        if (clinicDoc != null) {
          final clinic = Clinic.fromMap(clinicDoc.data);
          clinic.documentId = clinicDoc.$id;
          clinics[appointment.clinicId] = clinic;
        }
      } catch (e) {}
    }

    if (!pets.containsKey(appointment.petId) && appointment.petId.isNotEmpty) {
      try {
        final petDoc = await authRepository.getPetByName(appointment.petId);
        if (petDoc != null) {
          final pet = Pet.fromMap(petDoc.data);
          pet.documentId = petDoc.$id;
          pets[appointment.petId] = pet;
        }
      } catch (e) {}
    }
  }

  List<Appointment> get upcoming {
    final now = DateTime.now();
    return appointments
        .where((a) => a.status == 'accepted' && a.dateTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  List<Appointment> get pending {
    return appointments.where((a) => a.status == 'pending').toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<Appointment> get completed {
    return appointments.where((a) {
      if (a.status != 'completed') return false;

      final hasReview = appointmentReviews[a.documentId] ?? false;
      return !hasReview;
    }).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  List<Appointment> get history {
    return appointments.where((a) {
      if (a.status == 'cancelled' ||
          a.status == 'declined' ||
          a.status == 'no_show') {
        return true;
      }

      if (a.status == 'completed') {
        final hasReview = appointmentReviews[a.documentId] ?? false;
        return hasReview;
      }

      return false;
    }).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  List<Appointment> get inProgress {
    return appointments.where((a) => a.status == 'in_progress').toList();
  }

  List<Appointment> get todayAppointments {
    final today = DateTime.now();
    return appointments.where((appointment) {
      final appointmentDate = appointment.dateTime;
      return appointmentDate.year == today.year &&
          appointmentDate.month == today.month &&
          appointmentDate.day == today.day;
    }).toList();
  }

  Future<void> cancelPendingAppointment(String appointmentId) async {
    try {
      isLoading.value = true;

      await authRepository.updateFullAppointment(appointmentId, {
        'status': 'cancelled',
        'cancelledBy': 'user',
        'cancelledAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      appointments.removeWhere((a) => a.documentId == appointmentId);

      Get.snackbar(
        "Cancelled",
        "Appointment request cancelled successfully",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade50,
        colorText: Colors.orange.shade700,
        icon: const Icon(Icons.cancel_outlined, color: Colors.orange),
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to cancel appointment: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> cancelAcceptedAppointment(
    String appointmentId,
    String cancellationReason,
  ) async {
    try {
      isLoading.value = true;

      final appointment = appointments.firstWhere(
        (a) => a.documentId == appointmentId,
      );

      // ✅ ADD THIS CHECK - Verify cancellation is still allowed
      if (!canCancelAppointment(appointment)) {
        Get.snackbar(
          "Cannot Cancel",
          "This appointment is less than 1 hour away and cannot be cancelled.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade50,
          colorText: Colors.red.shade700,
          icon: const Icon(Icons.block, color: Colors.red),
          duration: const Duration(seconds: 3),
        );
        return;
      }

      await authRepository.updateFullAppointment(appointmentId, {
        'status': 'cancelled',
        'cancellationReason': cancellationReason,
        'cancelledBy': 'user',
        'cancelledAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      try {
        final clinicDoc =
            await authRepository.getClinicById(appointment.clinicId);
        if (clinicDoc != null) {
          final adminId = clinicDoc.data['adminId'] as String?;

          if (adminId != null && adminId.isNotEmpty) {
            final notification = AppNotification.appointmentCancelled(
              adminId: adminId,
              appointmentId: appointmentId,
              clinicId: appointment.clinicId,
              petName: getPetNameForAppointment(appointment),
              ownerName: session.userName,
              cancellationReason: cancellationReason,
            );

            await authRepository.createNotification(notification);
          }
        }
      } catch (e) {}

      Get.snackbar(
        "Appointment Cancelled",
        "Your appointment has been cancelled. The clinic has been notified.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade50,
        colorText: Colors.orange.shade700,
        icon: const Icon(Icons.info_outline, color: Colors.orange),
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to cancel appointment: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Helper methods
  Clinic? getClinicForAppointment(Appointment appointment) {
    return clinics[appointment.clinicId];
  }

  Pet? getPetForAppointment(Appointment appointment) {
    return pets[appointment.petId];
  }

  String getPetNameForAppointment(Appointment appointment) {
    final pet = pets[appointment.petId];
    return pet?.name ?? appointment.petId;
  }

  String getClinicNameForAppointment(Appointment appointment) {
    final clinic = clinics[appointment.clinicId];
    return clinic?.clinicName ?? 'Unknown Clinic';
  }

  String getAppointmentStage(Appointment appointment) {
    switch (appointment.status) {
      case 'pending':
        return 'Waiting for clinic approval';
      case 'accepted':
        return 'Confirmed - Please arrive on time';
      case 'in_progress':
        if (appointment.checkedInAt != null &&
            appointment.serviceStartedAt == null) {
          return 'Checked in - Waiting for treatment';
        } else if (appointment.serviceStartedAt != null) {
          return 'Currently receiving treatment';
        }
        return 'Treatment in progress';
      case 'completed':
        final hasReview = appointmentReviews[appointment.documentId] ?? false;
        return hasReview ? 'Reviewed' : 'Treatment completed';
      case 'no_show':
        return 'Missed appointment';
      case 'declined':
        return 'Not approved by clinic';
      case 'cancelled':
        return appointment.cancelledBy == 'user'
            ? 'Cancelled by you'
            : 'Cancelled by clinic';
      default:
        return appointment.status;
    }
  }

  String getUserFriendlyStatus(Appointment appointment) {
    switch (appointment.status) {
      case 'pending':
        return 'Pending Approval';
      case 'accepted':
        return 'Confirmed';
      case 'in_progress':
        return 'In Treatment';
      case 'completed':
        final hasReview = appointmentReviews[appointment.documentId] ?? false;
        return hasReview ? 'Reviewed' : 'Completed';
      case 'no_show':
        return 'Missed';
      case 'declined':
        return 'Declined';
      case 'cancelled':
        return 'Cancelled';
      default:
        return appointment.status.toUpperCase();
    }
  }

  bool canCancelAppointment(Appointment appointment) {
    if (appointment.status == 'pending') {
      return true;
    }

    if (appointment.status == 'accepted') {
      // Convert both times to local timezone for comparison
      final now = DateTime.now();

      // Convert the appointment time to local time (if it's in UTC)
      final appointmentLocal = appointment.dateTime.toLocal();

      // Calculate one hour before the appointment in local time
      final oneHourBeforeAppointment =
          appointment.dateTime.subtract(const Duration(hours: 1));

      // Can cancel if current time is before the time 1 hour before the appointment
      return now.toLocal().isBefore(oneHourBeforeAppointment);
    }

    return false;
  }

  bool needsCancellationReason(Appointment appointment) {
    return appointment.status == 'accepted';
  }

  double getAppointmentProgress(Appointment appointment) {
    switch (appointment.status) {
      case 'pending':
        return 0.25;
      case 'accepted':
        return 0.5;
      case 'in_progress':
        if (appointment.serviceStartedAt != null) return 0.85;
        return 0.7;
      case 'completed':
        return 1.0;
      default:
        return 0.0;
    }
  }

  Map<String, int> get userStats {
    return {
      'total': appointments.length,
      'pending': pending.length,
      'upcoming': upcoming.length,
      'completed': completed.length,
      'today': todayAppointments.length,
      'history': history.length,
    };
  }

  bool hasReview(String appointmentId) {
    return appointmentReviews[appointmentId] ?? false;
  }

  Future<void> refreshAfterReview(String appointmentId) async {
    await _checkAppointmentReview(appointmentId);
    appointments.refresh();
  }

  // ✅ FIXED: Use the Appointment model's helper methods consistently
  String getFormattedAppointmentTime(Appointment appointment) {
    return appointment.formattedTime;
  }

  String getFormattedAppointmentDateTime(Appointment appointment) {
    return appointment.formattedDateTime;
  }

  // ✅ NEW: Additional helper for date only
  String getFormattedAppointmentDate(Appointment appointment) {
    return appointment.formattedDate;
  }

  // ✅ NEW: Debug method to compare times
  void debugAppointmentTime(String appointmentId) {
    final appointment = appointments.firstWhere(
      (a) => a.documentId == appointmentId,
      orElse: () => throw Exception('Appointment not found'),
    );
  }
}
