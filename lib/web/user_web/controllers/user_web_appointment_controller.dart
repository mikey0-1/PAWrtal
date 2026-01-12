import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:capstone_app/data/models/appointment_model.dart';
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/clinic_settings_model.dart';
import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/data/models/notification_model.dart';
import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WebAppointmentController extends GetxController {
  final AuthRepository authRepository;
  final UserSessionService session;
  final Clinic clinic;

  WebAppointmentController({
    required this.authRepository,
    required this.session,
    required this.clinic,
  });

  var isLoading = false.obs;
  var isBooking = false.obs;
  var selectedDateTime = Rx<DateTime?>(null);
  var selectedTime = Rx<String?>(null);
  var selectedService = Rx<String?>(null);
  var selectedPet = Rx<Pet?>(null);
  var clinicSettings = Rx<ClinicSettings?>(null);
  var pets = <Pet>[].obs;
  var availableTimes = <String>[].obs;
  var occupiedTimeSlots = <String>[].obs;
  StreamSubscription<RealtimeMessage>? _appointmentSubscription;

  var closedDates = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadClinicSettings();
    _loadUserPets();
    _setupRealtimeSubscription();
  }

  @override
  void onClose() {
    _appointmentSubscription?.cancel();
    super.onClose();
  }

  void _setupRealtimeSubscription() {
    try {
      final clinicId = clinic.documentId ?? '';
      if (clinicId.isEmpty) return;

      _appointmentSubscription = authRepository
          .subscribeToClinicAppointments(clinicId)
          .listen((message) {
        // When an appointment is created, updated, or deleted, refresh time slots
        if (selectedDateTime.value != null) {
          _fetchOccupiedSlots();
        }
      });
    } catch (e) {}
  }

  Future<void> _fetchOccupiedSlots() async {
    if (selectedDateTime.value == null) return;

    try {
      final clinicId = clinic.documentId ?? '';
      if (clinicId.isEmpty) return;

      final slots = await authRepository.getOccupiedTimeSlots(
          clinicId, selectedDateTime.value!);

      occupiedTimeSlots.value = slots;
      _updateAvailableTimeSlots();
    } catch (e) {}
  }

  Future<void> _loadClinicSettings() async {
    try {
      final settings = await authRepository
          .getClinicSettingsByClinicId(clinic.documentId ?? '');
      clinicSettings.value = settings;

      // Load closed dates
      if (settings != null) {
        closedDates.value = settings.closedDates;
      }
    } catch (e) {}
  }

  Future<void> _loadUserPets() async {
    try {
      isLoading.value = true;
      final userId = session.userId;

      if (userId.isNotEmpty) {
        final petDocs = await authRepository.getUserPets(userId);
        pets.assignAll(petDocs.map((doc) => Pet.fromMap(doc.data)).toList());
      }
    } catch (e) {
    } finally {
      isLoading.value = false;
    }
  }

  List<String> get services {
    if (clinicSettings.value != null &&
        clinicSettings.value!.services.isNotEmpty) {
      return clinicSettings.value!.services;
    }

    if (clinic.services.isEmpty) {
      return ['General Consultation', 'Vaccination', 'Check-up', 'Grooming'];
    }
    return clinic.services.split(',').map((s) => s.trim()).toList();
  }

  bool isDateSelectable(DateTime day) {
    // Check if date is in the past
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final checkDate = DateTime(day.year, day.month, day.day);

    if (checkDate.isBefore(startOfToday)) {
      return false;
    }

    // Check if clinic settings allow this date
    if (clinicSettings.value != null) {
      // Check if clinic is open
      if (!clinicSettings.value!.isOpen) {
        return false;
      }

      // CRITICAL: Check if date is in closed dates
      final dateStr = _formatDateToString(day);
      if (closedDates.contains(dateStr)) {
        return false;
      }

      // Check max advance booking
      final maxAdvanceDate = DateTime.now()
          .add(Duration(days: clinicSettings.value!.maxAdvanceBooking));
      if (day.isAfter(maxAdvanceDate)) {
        return false;
      }

      // Check if clinic is open on this day of week
      final dayName = _getDayName(day.weekday);
      final daySchedule = clinicSettings.value!.operatingHours[dayName];
      if (daySchedule?['isOpen'] != true) {
        return false;
      }
    }

    return true;
  }

  String _formatDateToString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'monday';
      case 2:
        return 'tuesday';
      case 3:
        return 'wednesday';
      case 4:
        return 'thursday';
      case 5:
        return 'friday';
      case 6:
        return 'saturday';
      case 7:
        return 'sunday';
      default:
        return 'monday';
    }
  }

  void onDateSelected(DateTime date) {
    selectedDateTime.value = date;
    selectedTime.value = null;
    _fetchOccupiedSlots();
  }

  void _updateAvailableTimeSlots() {
    if (selectedDateTime.value == null) {
      availableTimes.clear();
      return;
    }

    List<String> slots = [];

    if (clinicSettings.value != null) {
      slots = clinicSettings.value!
          .getAvailableTimeSlotsFiltered(selectedDateTime.value!);
    } else {
      slots = [
        '09:00',
        '10:00',
        '11:00',
        '13:00',
        '14:00',
        '15:00',
        '16:00',
      ];

      if (_isToday(selectedDateTime.value!)) {
        slots = _filterPastTimeSlots(slots);
      }
    }

    // Filter out occupied time slots
    slots = slots.where((slot) => !occupiedTimeSlots.contains(slot)).toList();

    availableTimes.assignAll(slots);

    if (selectedTime.value != null && !slots.contains(selectedTime.value)) {
      selectedTime.value = null;
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  List<String> _filterPastTimeSlots(List<String> timeSlots) {
    final now = DateTime.now();

    return timeSlots.where((timeSlot) {
      try {
        // Handle both 24-hour and 12-hour format
        DateTime slotDateTime;

        if (timeSlot.contains('AM') || timeSlot.contains('PM')) {
          // 12-hour format (e.g., "02:00 PM")
          final parts = timeSlot.trim().split(' ');
          final timeParts = parts[0].split(':');
          int hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          final period = parts.length > 1 ? parts[1].toUpperCase() : 'AM';

          // Convert to 24-hour
          if (period == 'PM' && hour != 12) {
            hour += 12;
          } else if (period == 'AM' && hour == 12) {
            hour = 0;
          }

          slotDateTime = DateTime(
            selectedDateTime.value!.year,
            selectedDateTime.value!.month,
            selectedDateTime.value!.day,
            hour,
            minute,
          );
        } else {
          // 24-hour format (e.g., "14:00")
          final timeParts = timeSlot.split(':');
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);

          slotDateTime = DateTime(
            selectedDateTime.value!.year,
            selectedDateTime.value!.month,
            selectedDateTime.value!.day,
            hour,
            minute,
          );
        }

        // Add a 30-minute buffer
        return slotDateTime.isAfter(now.add(const Duration(minutes: 30)));
      } catch (e) {
        return true; // Include if parsing fails
      }
    }).toList();
  }

  void onTimeSelected(String? time) {
    selectedTime.value = time;
  }

  void onServiceSelected(String? service) {
    selectedService.value = service;
  }

  void onPetSelected(Pet? pet) {
    selectedPet.value = pet;
  }

  bool get canBookAppointment {
    return selectedDateTime.value != null &&
        selectedTime.value != null &&
        selectedService.value != null &&
        selectedPet.value != null &&
        !isBooking.value &&
        (clinicSettings.value?.isOpen ?? true);
  }

  String? get bookingValidationMessage {
    if (clinicSettings.value != null && !clinicSettings.value!.isOpen) {
      return 'This clinic is currently not accepting appointments';
    }

    if (selectedDateTime.value == null) {
      return 'Please select a date';
    }

    if (availableTimes.isEmpty) {
      return 'No available times for this date';
    }

    if (selectedTime.value == null) {
      return 'Please select a time';
    }

    // Check if selected time is now occupied (race condition protection)
    if (occupiedTimeSlots.contains(selectedTime.value)) {
      return 'This time slot was just booked. Please select another time.';
    }

    if (selectedService.value == null) {
      return 'Please select a service';
    }

    if (selectedPet.value == null) {
      return 'Please select a pet';
    }

    return null;
  }

  Future<void> bookAppointment() async {
    if (!canBookAppointment) return;

    final userId = session.userId;
    if (userId.isEmpty) {
      _showCompactNotification(
        "User not logged in",
        bgColor: Colors.red[600]!,
        icon: Icons.error_outline,
        iconColor: Colors.white,
      );
      return;
    }

    try {
      isBooking.value = true;

      // ✅ FIXED: Parse time correctly handling both 12-hour and 24-hour formats
      final timeString = selectedTime.value!;
      int hour;
      int minute;

      try {
        if (timeString.contains('AM') || timeString.contains('PM')) {
          // 12-hour format (e.g., "02:30 PM")
          final parts = timeString.trim().split(' ');
          final timeParts = parts[0].split(':');
          hour = int.parse(timeParts[0]);
          minute = int.parse(timeParts[1]);
          final period = parts.length > 1 ? parts[1].toUpperCase() : 'AM';

          // Convert to 24-hour format
          if (period == 'PM' && hour != 12) {
            hour += 12;
          } else if (period == 'AM' && hour == 12) {
            hour = 0;
          }
        } else {
          // 24-hour format (e.g., "14:30")
          final timeParts = timeString.split(':');
          hour = int.parse(timeParts[0]);
          minute = int.parse(timeParts[1]);
        }
      } catch (e) {
        _showCompactNotification(
          "Invalid time format. Please try again.",
          bgColor: Colors.red[600]!,
          icon: Icons.error_outline,
          iconColor: Colors.white,
        );
        isBooking.value = false;
        return;
      }

      final appointmentDateTime = DateTime(
        selectedDateTime.value!.year,
        selectedDateTime.value!.month,
        selectedDateTime.value!.day,
        hour,
        minute,
      );

      // CRITICAL: Check if service is medical from clinic settings
      bool isMedicalService = false;
      if (clinicSettings.value != null && selectedService.value != null) {
        isMedicalService =
            clinicSettings.value!.isServiceMedical(selectedService.value!);
      } else {}

      final appointment = Appointment(
        userId: userId,
        clinicId: clinic.documentId ?? '',
        petId: selectedPet.value!.name, // Use name instead of petId
        service: selectedService.value!,
        dateTime: appointmentDateTime,
        status: clinicSettings.value?.autoAcceptAppointments == true
            ? 'accepted'
            : 'pending',
        isMedicalService: isMedicalService,
      );

      await authRepository.createAppointment(appointment);

      // Create notification for admin
      try {
        final clinicDoc =
            await authRepository.getClinicById(clinic.documentId ?? '');
        if (clinicDoc != null) {
          final adminId = clinicDoc.data['adminId'] as String?;

          if (adminId != null && adminId.isNotEmpty) {
            final notification = AppNotification.appointmentBooked(
              adminId: adminId,
              appointmentId: '', // Will be filled by backend
              clinicId: clinic.documentId ?? '',
              petName: selectedPet.value?.name ?? 'Unknown Pet',
              ownerName: session.userName.isEmpty ? 'A user' : session.userName,
              service: selectedService.value!,
              appointmentDateTime: appointmentDateTime,
            );

            await authRepository.createNotification(notification);
          }
        }
      } catch (e) {}

      await _notifyAdminOfNewAppointment(appointment);

      // Show success message
      _showCompactNotification(
        clinicSettings.value?.autoAcceptAppointments == true
            ? "Appointment automatically confirmed!"
            : "Appointment booked! Awaiting clinic confirmation.",
        bgColor: Colors.green[600]!,
        icon: Icons.check_circle_outline,
        iconColor: Colors.white,
      );

      // Reset form
      selectedDateTime.value = null;
      selectedTime.value = null;
      selectedService.value = null;
      selectedPet.value = null;
      availableTimes.clear();
    } catch (e) {
      _showCompactNotification(
        "Failed to book appointment: $e",
        bgColor: Colors.red[600]!,
        icon: Icons.error_outline,
        iconColor: Colors.white,
      );
    } finally {
      isBooking.value = false;
    }
  }

  Future<void> _notifyAdminOfNewAppointment(Appointment appointment) async {
    try {
      // Get clinic admin ID
      final clinicDoc =
          await authRepository.getClinicById(clinic.documentId ?? '');
      if (clinicDoc == null) {
        return;
      }

      final adminId = clinicDoc.data['adminId'] as String?;
      if (adminId == null || adminId.isEmpty) {
        return;
      }

      // Get user details
      final userName = session.userName.isEmpty ? 'A user' : session.userName;
      final petName = selectedPet.value?.name ?? appointment.petId;

      // Use AppwriteProvider to send notification
      final appwriteProvider = Get.find<AppWriteProvider>();

      await appwriteProvider.notifyAdminNewAppointment(
        adminId: adminId,
        petName: petName,
        ownerName: userName,
        service: appointment.service,
        appointmentDateTime: appointment.dateTime,
        appointmentId: appointment.documentId ?? '',
      );
    } catch (e) {
      // Don't fail booking if notification fails
    }
  }

  void _showCompactNotification(String message,
      {required Color bgColor,
      required IconData icon,
      required Color iconColor}) {
    Get.rawSnackbar(
      messageText: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      backgroundColor: bgColor,
      snackPosition: SnackPosition.TOP,
      borderRadius: 4,
      margin: const EdgeInsets.only(top: 16, right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      duration: const Duration(seconds: 2),
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      maxWidth: 300,
    );
  }

  Future<String?> fetchClinicImage(String clinicId) async {
    if (clinicId.isEmpty) {
      return null;
    }

    try {
      final clinicDoc = await authRepository.getClinicById(clinicId);

      if (clinicDoc == null) {
        return null;
      }

      final clinicData = clinicDoc.data;

      // Priority 1: dashboardPic
      if (clinicData['dashboardPic'] != null &&
          clinicData['dashboardPic'].toString().trim().isNotEmpty) {
        final imageUrl = clinicData['dashboardPic'].toString();
        return imageUrl;
      }

      // Priority 2: image
      if (clinicData['image'] != null &&
          clinicData['image'].toString().trim().isNotEmpty) {
        final imageUrl = clinicData['image'].toString();
        return imageUrl;
      }

      return null;
    } catch (e, stackTrace) {
      return null;
    }
  }
}
