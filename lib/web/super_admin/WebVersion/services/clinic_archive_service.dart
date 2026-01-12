import 'dart:async';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:get/get.dart';

/// Service for managing clinic archive and scheduled deletions
class ClinicArchiveService extends GetxService {
  final AuthRepository _authRepository;
  Timer? _deletionTimer;

  final RxBool isRunning = false.obs;
  final RxInt lastProcessedCount = 0.obs;
  final RxString lastRunTime = ''.obs;
  final RxList<String> processingErrors = <String>[].obs;

  ClinicArchiveService(this._authRepository);

  static ClinicArchiveService get instance => Get.find<ClinicArchiveService>();

  @override
  void onInit() {
    super.onInit();
    startScheduledDeletionService();
  }

  @override
  void onClose() {
    stopScheduledDeletionService();
    super.onClose();
  }

  /// Start the background service
  /// Runs every hour to check for clinics due for deletion
  void startScheduledDeletionService() {

    // Run immediately on start
    _processScheduledDeletions();

    // Then run every hour
    _deletionTimer = Timer.periodic(
      const Duration(hours: 1),
      (timer) => _processScheduledDeletions(),
    );

  }

  /// Stop the background service
  void stopScheduledDeletionService() {
    _deletionTimer?.cancel();
    _deletionTimer = null;
    isRunning.value = false;
  }

  /// Process scheduled deletions
  Future<void> _processScheduledDeletions() async {
    if (isRunning.value) {
      return;
    }

    try {
      isRunning.value = true;
      processingErrors.clear();
      lastRunTime.value = DateTime.now().toIso8601String();


      final result = await _authRepository.processScheduledClinicDeletions();

      lastProcessedCount.value = result['totalProcessed'] ?? 0;

      if (result['errors'] != null && (result['errors'] as List).isNotEmpty) {
        processingErrors.value = List<String>.from(result['errors']);
        for (var error in processingErrors) {
        }
      }


      _logDeletionActivity(result);
    } catch (e) {
      processingErrors.add('Service error: ${e.toString()}');
    } finally {
      isRunning.value = false;
    }
  }

  /// Manual trigger for processing deletions (for admin dashboard)
  Future<Map<String, dynamic>> processNow() async {
    await _processScheduledDeletions();

    return {
      'processed': lastProcessedCount.value,
      'errors': processingErrors.toList(),
      'lastRun': lastRunTime.value,
    };
  }

  /// Get service status
  Map<String, dynamic> getServiceStatus() {
    return {
      'isRunning': isRunning.value,
      'lastProcessedCount': lastProcessedCount.value,
      'lastRunTime': lastRunTime.value,
      'hasErrors': processingErrors.isNotEmpty,
      'errorCount': processingErrors.length,
      'errors': processingErrors.toList(),
      'timerActive': _deletionTimer?.isActive ?? false,
    };
  }

  /// Get clinics that will be deleted soon (within 7 days)
  Future<List<Map<String, dynamic>>> getClinicsDueSoon() async {
    try {
      final allArchived = await _authRepository.getAllArchivedClinics(
        includePermanentlyDeleted: false,
        limit: 1000,
      );

      final now = DateTime.now();
      final sevenDaysFromNow = now.add(const Duration(days: 7));

      final dueSoon = allArchived.where((clinic) {
        return clinic.scheduledDeletionAt.isBefore(sevenDaysFromNow) &&
            clinic.scheduledDeletionAt.isAfter(now) &&
            !clinic.isPermanentlyDeleted &&
            !clinic.isRecovered;
      }).map((clinic) {
        return {
          'clinicId': clinic.adminId,
          'clinicName': clinic.clinicName,
          'email': clinic.email,
          'scheduledDeletionAt': clinic.scheduledDeletionAt.toIso8601String(),
          'daysLeft': clinic.daysUntilDeletion,
          'archivedBy': clinic.archivedBy,
          'archiveReason': clinic.archiveReason,
        };
      }).toList();

      return dueSoon;
    } catch (e) {
      return [];
    }
  }

  /// Get archive statistics
  Future<Map<String, int>> getArchiveStats() async {
    try {
      return await _authRepository.getClinicArchiveStatistics();
    } catch (e) {
      return {
        'total': 0,
        'activeArchives': 0,
        'recovered': 0,
        'permanentlyDeleted': 0,
        'dueSoon': 0,
      };
    }
  }

  /// Log deletion activity
  void _logDeletionActivity(Map<String, dynamic> result) {
  }

  /// Check if a specific clinic is due for deletion
  Future<bool> isClinicDueForDeletion(String clinicId) async {
    try {
      final archivedClinic =
          await _authRepository.getArchivedClinicByAdminId(clinicId);
      if (archivedClinic == null) return false;

      return archivedClinic.isDeletionDue &&
          !archivedClinic.isPermanentlyDeleted &&
          !archivedClinic.isRecovered;
    } catch (e) {
      return false;
    }
  }

  /// Get time remaining until deletion for a clinic
  Future<String?> getTimeUntilDeletion(String clinicId) async {
    try {
      final archivedClinic =
          await _authRepository.getArchivedClinicByAdminId(clinicId);
      if (archivedClinic == null) return null;

      if (archivedClinic.isPermanentlyDeleted) {
        return 'Already deleted';
      }

      if (archivedClinic.isRecovered) {
        return 'Recovered';
      }

      final daysLeft = archivedClinic.daysUntilDeletion;

      if (daysLeft <= 0) {
        return 'Due for deletion now';
      } else if (daysLeft == 1) {
        return '1 day remaining';
      } else {
        return '$daysLeft days remaining';
      }
    } catch (e) {
      return null;
    }
  }
}
