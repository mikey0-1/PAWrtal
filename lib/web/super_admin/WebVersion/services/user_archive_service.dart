import 'dart:async';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:get/get.dart';

class ArchiveService extends GetxService {
  final AuthRepository _authRepository;
  Timer? _deletionTimer;
  
  final RxBool isRunning = false.obs;
  final RxInt lastProcessedCount = 0.obs;
  final RxString lastRunTime = ''.obs;
  final RxList<String> processingErrors = <String>[].obs;

  ArchiveService(this._authRepository);

  static ArchiveService get instance => Get.find<ArchiveService>();

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
  /// Runs every hour to check for users due for deletion
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


      final result = await _authRepository.processScheduledDeletions();

      lastProcessedCount.value = result['totalProcessed'] ?? 0;

      if (result['errors'] != null && (result['errors'] as List).isNotEmpty) {
        processingErrors.value = List<String>.from(result['errors']);
        for (var error in processingErrors) {
        }
      }


      // Log to system
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

  /// Get users that will be deleted soon (within 7 days)
  Future<List<Map<String, dynamic>>> getUsersDueSoon() async {
    try {
      final allArchived = await _authRepository.getAllArchivedUsers(
        includePermanentlyDeleted: false,
        limit: 1000,
      );

      final now = DateTime.now();
      final sevenDaysFromNow = now.add(const Duration(days: 7));

      final dueSoon = allArchived.where((user) {
        return user.scheduledDeletionAt.isBefore(sevenDaysFromNow) &&
               user.scheduledDeletionAt.isAfter(now) &&
               !user.isPermanentlyDeleted &&
               !user.isRecovered;
      }).map((user) {
        return {
          'userId': user.userId,
          'name': user.name,
          'email': user.email,
          'scheduledDeletionAt': user.scheduledDeletionAt.toIso8601String(),
          'daysLeft': user.daysUntilDeletion,
          'archivedBy': user.archivedBy,
          'archiveReason': user.archiveReason,
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
      return await _authRepository.getArchiveStatistics();
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

  /// Log deletion activity (can be expanded to save to database)
  void _logDeletionActivity(Map<String, dynamic> result) {
    // You can implement logging to a separate collection here
    // For now, just console logging
  }

  /// Check if a specific user is due for deletion
  Future<bool> isUserDueForDeletion(String userId) async {
    try {
      final archivedUser = await _authRepository.getArchivedUserByUserId(userId);
      if (archivedUser == null) return false;
      
      return archivedUser.isDeletionDue && 
             !archivedUser.isPermanentlyDeleted &&
             !archivedUser.isRecovered;
    } catch (e) {
      return false;
    }
  }

  /// Get time remaining until deletion for a user
  Future<String?> getTimeUntilDeletion(String userId) async {
    try {
      final archivedUser = await _authRepository.getArchivedUserByUserId(userId);
      if (archivedUser == null) return null;

      if (archivedUser.isPermanentlyDeleted) {
        return 'Already deleted';
      }

      if (archivedUser.isRecovered) {
        return 'Recovered';
      }

      final daysLeft = archivedUser.daysUntilDeletion;

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

  /// Send warning notifications for users due for deletion soon
  Future<void> sendDeletionWarnings() async {
    try {
      final usersDueSoon = await getUsersDueSoon();


      for (var user in usersDueSoon) {
        final daysLeft = user['daysLeft'] as int;

        // Send warning at 7 days, 3 days, and 1 day
        if (daysLeft == 7 || daysLeft == 3 || daysLeft == 1) {
          
          // Here you can implement email/notification sending
          // await _sendDeletionWarningEmail(user);
          // await _sendDeletionWarningNotification(user);
        }
      }
    } catch (e) {
    }
  }
}