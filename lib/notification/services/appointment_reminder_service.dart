import 'dart:async';
import 'package:appwrite/appwrite.dart';
import 'package:capstone_app/data/models/appointment_model.dart';
import 'package:capstone_app/data/models/notification_model.dart';
import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/notification/services/notification_preferences_service.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// USER-SPECIFIC Appointment Reminder Service
/// Each logged-in user gets their own instance of this service
class AppointmentReminderService extends GetxService {
  final AuthRepository authRepository;
  final NotificationPreferencesService notificationPrefsService;
  final AppWriteProvider appWriteProvider;
  final String userId; // ✅ NEW: User-specific service

  AppointmentReminderService({
    required this.authRepository,
    required this.notificationPrefsService,
    required this.appWriteProvider,
    required this.userId, // ✅ NEW: Required userId
  });

  Timer? _reminderTimer;
  final Set<String> _remindedAppointments = {};
  final GetStorage _storage = GetStorage();

  // Configuration
  static const Duration checkInterval = Duration(minutes: 10);
  static const Duration reminderWindow = Duration(hours: 1);

  // ✅ REMOVED: onInit() - no automatic initialization
  // Service will be started manually after login

  @override
  void onClose() {
    stopReminderService();
    super.onClose();
  }

  /// Start the reminder service (called manually after user login)
  void startReminderService() {
    if (_reminderTimer != null && _reminderTimer!.isActive) {
      return;
    }


    // Load previously reminded appointments for this user
    _loadRemindedAppointments();

    // Run initial check
    _checkAndSendReminders();

    // Schedule periodic checks
    _reminderTimer = Timer.periodic(checkInterval, (timer) {
      _checkAndSendReminders();
    });

  }

  /// Stop the reminder service
  void stopReminderService() {
    _reminderTimer?.cancel();
    _reminderTimer = null;
  }

  /// Main method to check and send reminders (USER-SPECIFIC)
  Future<void> _checkAndSendReminders() async {
    try {
      final now = DateTime.now();

      // ✅ OPTIMIZATION: Only get THIS user's accepted appointments
      final userAppointments = await _getUserAcceptedAppointments();

      if (userAppointments.isEmpty) {
        return;
      }


      int remindersCount = 0;

      for (var appointment in userAppointments) {
        // ✅ OPTIMIZATION 1: Skip if already reminded
        if (_remindedAppointments.contains(appointment.documentId)) {
          continue;
        }

        // ✅ OPTIMIZATION 2: Skip if reminderSent flag is true
        if (appointment.reminderSent) {
          _remindedAppointments.add(appointment.documentId!);
          _saveRemindedAppointments();
          continue;
        }

        // Get the stored datetime and treat as local time
        final storedDateTime = appointment.dateTime;
        final actualLocalTime = DateTime(
          storedDateTime.year,
          storedDateTime.month,
          storedDateTime.day,
          storedDateTime.hour,
          storedDateTime.minute,
          storedDateTime.second,
        );

        final nowLocal = now;


        // Calculate time until appointment
        final timeUntilAppointment = actualLocalTime.difference(nowLocal);

        // Check if appointment is within reminder window (1 hour) and hasn't passed
        if (timeUntilAppointment > Duration.zero &&
            timeUntilAppointment <= reminderWindow) {

          await _sendAppointmentReminder(
            appointment,
            timeUntilAppointment.inMinutes,
          );
          remindersCount++;

          // ✅ Mark as reminded locally
          _remindedAppointments.add(appointment.documentId!);
          _saveRemindedAppointments();

          // ✅ CRITICAL: Update reminderSent flag in database
          await _markReminderSent(appointment.documentId!);
        }
      }

      if (remindersCount > 0) {
      } else {
      }

      // Cleanup old reminded appointments
      _cleanupRemindedAppointments(userAppointments);
    } catch (e) {
    }
  }

  /// ✅ NEW: Get only THIS user's accepted appointments
  Future<List<Appointment>> _getUserAcceptedAppointments() async {
    try {
      final result = await appWriteProvider.databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.appointmentCollectionID,
        queries: [
          Query.equal("userId", userId), // ✅ Filter by THIS user
          Query.equal("status", "accepted"),
          Query.limit(100), // Reasonable limit per user
        ],
      );


      return result.documents
          .map((doc) => Appointment.fromMap(doc.data))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// ✅ NEW: Mark reminder as sent in database
  Future<void> _markReminderSent(String appointmentId) async {
    try {
      await authRepository.updateFullAppointment(appointmentId, {
        'reminderSent': true,
        'reminderSentAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Don't throw - notification was still sent
    }
  }

  /// Send appointment reminder (both in-app and push)
  Future<void> _sendAppointmentReminder(
    Appointment appointment,
    int minutesUntil,
  ) async {
    try {

      // Get user details
      final userDoc = await authRepository.getUserById(appointment.userId);
      if (userDoc == null) {
        return;
      }

      final userDocId = userDoc.data['\$id'] ?? appointment.userId;

      // Get user's notification preferences
      final userPreferences =
          await notificationPrefsService.getPreferencesForUser(userDocId);


      // Get clinic and pet details
      final clinicDoc = await authRepository.getClinicById(appointment.clinicId);
      final clinicName = clinicDoc?.data['clinicName'] ?? 'Clinic';

      // Try to get pet name
      String petName = appointment.petId;
      try {
        final petDoc = await authRepository.getPetById(appointment.petId);
        if (petDoc != null) {
          petName = petDoc.data['name'] ?? appointment.petId;
        }
      } catch (e) {
      }

      // 1. Create in-app notification (ALWAYS create)
      final notification = AppNotification.appointmentReminder(
        userId: appointment.userId,
        appointmentId: appointment.documentId!,
        clinicId: appointment.clinicId,
        clinicName: clinicName,
        petName: petName,
        service: appointment.service,
        appointmentDateTime: appointment.dateTime,
        minutesUntil: minutesUntil,
      );

      await authRepository.createNotification(notification);

      // 2. Send push notification (only if user has it enabled)
      if (userPreferences.pushNotificationsEnabled) {

        String timeMessage;
        if (minutesUntil < 60) {
          timeMessage = 'in $minutesUntil minutes';
        } else {
          final hours = (minutesUntil / 60).floor();
          timeMessage = 'in $hours hour${hours > 1 ? 's' : ''}';
        }

        await authRepository.appWriteProvider.sendPushNotification(
          title: '⏰ Appointment Reminder',
          body: '$petName\'s appointment at $clinicName is coming up $timeMessage!',
          userIds: [appointment.userId],
          data: {
            'type': 'appointment_reminder',
            'appointmentId': appointment.documentId!,
            'petName': petName,
            'clinicName': clinicName,
            'minutesUntil': minutesUntil.toString(),
          },
        );
      } else {
      }

    } catch (e) {
    }
  }

  /// Load reminded appointments from storage (USER-SPECIFIC)
  void _loadRemindedAppointments() {
    try {
      final key = 'reminded_appointments_$userId'; // ✅ User-specific key
      final reminded = _storage.read<List>(key);
      if (reminded != null) {
        _remindedAppointments.addAll(reminded.cast<String>());
      }
    } catch (e) {
    }
  }

  /// Save reminded appointments to storage (USER-SPECIFIC)
  void _saveRemindedAppointments() {
    try {
      final key = 'reminded_appointments_$userId'; // ✅ User-specific key
      _storage.write(key, _remindedAppointments.toList());
    } catch (e) {
    }
  }

  /// Cleanup old reminded appointments
  void _cleanupRemindedAppointments(List<Appointment> currentAppointments) {
    final appointmentIds = currentAppointments
        .map((a) => a.documentId)
        .where((id) => id != null)
        .toSet();

    _remindedAppointments.removeWhere((id) => !appointmentIds.contains(id));

    final cutoffTime = DateTime.now().subtract(const Duration(hours: 24));
    final toRemove = <String>[];

    for (var id in _remindedAppointments) {
      final appointment = currentAppointments.firstWhereOrNull(
        (a) => a.documentId == id,
      );
      if (appointment != null && appointment.dateTime.isBefore(cutoffTime)) {
        toRemove.add(id);
      }
    }

    if (toRemove.isNotEmpty) {
      _remindedAppointments.removeAll(toRemove);
      _saveRemindedAppointments();
    }
  }

  /// Manually trigger reminder check (for testing)
  Future<void> manualCheckReminders() async {
    await _checkAndSendReminders();
  }

  /// Clear reminded appointments (for testing)
  void clearRemindedAppointments() {
    _remindedAppointments.clear();
    _saveRemindedAppointments();
  }

  /// Get reminder statistics
  Map<String, dynamic> getReminderStats() {
    return {
      'userId': userId,
      'isRunning': _reminderTimer != null && _reminderTimer!.isActive,
      'checkIntervalMinutes': checkInterval.inMinutes,
      'reminderWindowMinutes': reminderWindow.inMinutes,
      'remindedCount': _remindedAppointments.length,
    };
  }
}