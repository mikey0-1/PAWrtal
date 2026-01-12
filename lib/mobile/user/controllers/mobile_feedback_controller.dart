import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:capstone_app/data/models/feedback_and_report_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:appwrite/models.dart' as models;
import 'package:capstone_app/data/models/daily_report_tracker_model.dart';

class MobileFeedbackController extends GetxController {
  final AuthRepository authRepository;
  final UserSessionService session;

  MobileFeedbackController({
    required this.authRepository,
    required this.session,
  });

  // User-side properties
  RxList<PlatformFile> selectedFiles = <PlatformFile>[].obs;
  RxBool isSubmitting = false.obs;
  Rx<FeedbackType> selectedType = FeedbackType.bug.obs;
  Rx<FeedbackCategory> selectedCategory = FeedbackCategory.other.obs;
  RxString subject = ''.obs;
  RxString description = ''.obs;
  final Rx<UserDailyReportTracker?> dailyTracker = Rx<UserDailyReportTracker?>(null);
  final RxBool isCheckingLimit = false.obs;

  // ============= NOTIFICATION HELPER =============

@override
  void onInit() {
    super.onInit();
    _loadDailyReportTracker();
  }

    Future<void> _loadDailyReportTracker() async {
    try {
      isCheckingLimit.value = true;
      
      final userId = session.userId;
      if (userId.isEmpty) {
        return;
      }
      
      
      // Get user's feedback submissions from last 24 hours
      final allFeedback = await authRepository.getUserFeedback(userId);
      
      final now = DateTime.now();
      final last24Hours = now.subtract(const Duration(hours: 24));
      
      // Count reports in last 24 hours
      final recentReports = allFeedback.where((feedback) {
        return feedback.submittedAt.isAfter(last24Hours);
      }).toList();
      
      
      // Find the oldest report timestamp to use as reset time
      DateTime lastResetAt = now.subtract(const Duration(hours: 24));
      DateTime? lastReportAt;
      
      if (recentReports.isNotEmpty) {
        // Sort by submission time
        recentReports.sort((a, b) => a.submittedAt.compareTo(b.submittedAt));
        lastResetAt = recentReports.first.submittedAt;
        lastReportAt = recentReports.last.submittedAt;
      }
      
      // Create tracker
      final tracker = UserDailyReportTracker(
        userId: userId,
        reportCount: recentReports.length,
        lastResetAt: lastResetAt,
        lastReportAt: lastReportAt ?? now,
      );
      
      // Check if needs reset
      if (tracker.needsReset) {
        dailyTracker.value = tracker.reset();
      } else {
        dailyTracker.value = tracker;
      }
      
      
    } catch (e) {
    } finally {
      isCheckingLimit.value = false;
    }
  }

  bool canSubmitFeedback() {
    if (dailyTracker.value == null) {
      return true;
    }
    
    // Check if needs reset first
    if (dailyTracker.value!.needsReset) {
      dailyTracker.value = dailyTracker.value!.reset();
      return true;
    }
    
    final canSubmit = !dailyTracker.value!.hasExceededLimit;
    
    if (!canSubmit) {
    }
    
    return canSubmit;
  }

  int getRemainingReports() {
    if (dailyTracker.value == null) return 3;
    
    if (dailyTracker.value!.needsReset) {
      return 3;
    }
    
    return dailyTracker.value!.remainingReports;
  }
  
  String getTimeUntilReset() {
    if (dailyTracker.value == null) return 'N/A';
    
    if (dailyTracker.value!.needsReset) {
      return 'Ready to reset';
    }
    
    return _formatDuration(dailyTracker.value!.timeUntilReset);
  }
  
  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      return '${hours}h ${minutes}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return 'Less than 1 minute';
    }
  }
  /// Show compact toast notification
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

  void _showSuccess(String message) {
    _showCompactNotification(message,
        bgColor: Colors.green[600]!,
        icon: Icons.check_circle_outline,
        iconColor: Colors.white);
  }

  void _showError(String message) {
    _showCompactNotification(message,
        bgColor: Colors.red[600]!,
        icon: Icons.error_outline,
        iconColor: Colors.white);
  }

  void _showInfo(String message) {
    _showCompactNotification(message,
        bgColor: Colors.blue[600]!,
        icon: Icons.info_outline,
        iconColor: Colors.white);
  }

  void _showWarning(String message) {
    _showCompactNotification(message,
        bgColor: Colors.amber[700]!,
        icon: Icons.warning_amber,
        iconColor: Colors.white);
  }

  // ============= USER-SIDE METHODS =============

 /// Validate file before adding (IMAGES ONLY)
bool _validateFile(PlatformFile file) {
  final extension = file.extension?.toLowerCase() ?? '';

  // Check if it's an image (NO VIDEOS ALLOWED)
  final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(extension);

  if (!isImage) {
    _showError("Only image files are allowed (JPG, PNG, GIF, WEBP, BMP)");
    return false;
  }

  // Check image file size limit (5MB)
  if (file.size > 5 * 1024 * 1024) {
    _showError("Image files must be under 5MB (${(file.size / (1024 * 1024)).toStringAsFixed(2)}MB)");
    return false;
  }

  return true;
}

    /// Pick files (IMAGES ONLY - No videos allowed)
    Future<void> pickFiles() async {
      if (selectedFiles.length >= 5) {
        _showError("You can only attach up to 5 files");
        return;
      }

      try {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: [
            // IMAGES ONLY
            'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp',
          ],
          allowMultiple: true,
        );

        if (result != null) {
          for (var file in result.files) {
            if (selectedFiles.length >= 5) {
              _showWarning("Maximum 5 files allowed. Remaining files not added.");
              break;
            }

            if (_validateFile(file)) {
              selectedFiles.add(file);
            }
          }
        }
      } catch (e) {
        _showError("Failed to pick files: $e");
      }
    }

  /// Remove a file from selection
  void removeFile(PlatformFile file) {
    selectedFiles.remove(file);
    selectedFiles.refresh();
  }

  /// Clear all selected files
  void clearFiles() {
    selectedFiles.clear();
  }

    /// Get file icon based on extension (IMAGES ONLY)
    String getFileIcon(String? extension) {
      final ext = extension?.toLowerCase() ?? '';
      
      // All allowed files are images
      if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext)) {
        return '🖼️';
      }
      
      // Fallback (should never happen with our validation)
      return '📄';
    }

  /// Get file size in readable format
  String getFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Validate feedback form
  bool validateForm() {
    if (subject.value.trim().isEmpty) {
      _showError("Please enter a subject");
      return false;
    }

    if (subject.value.trim().length < 5) {
      _showError("Subject must be at least 5 characters long");
      return false;
    }

    if (description.value.trim().isEmpty) {
      _showError("Please provide details about your feedback");
      return false;
    }

    if (description.value.trim().length < 20) {
      _showError("Please provide at least 20 characters of description");
      return false;
    }

    // Attachments are now OPTIONAL

    return true;
  }

  /// Submit feedback
  Future<bool> submitFeedback() async {
      if (!canSubmitFeedback()) {
      _showError(
        'Daily limit reached (3/3). You can submit again in ${getTimeUntilReset()}.'
      );
      return false;
    }
    if (!validateForm()) return false;

    isSubmitting.value = true;

    try {
      // Get user information
      final userId = session.userId;
      final userName = session.userName;
      final userEmail = session.userEmail;


      if (userId.isEmpty) {
        _showError("User session data is missing. Please log in again.");
        isSubmitting.value = false;
        return false;
      }

      List<String> attachmentIds = [];

      // Upload attachments ONLY if files are selected (optional)
      if (selectedFiles.isNotEmpty) {
        _showInfo("Uploading ${selectedFiles.length} file(s)...");

        final uploadedFiles = await authRepository.uploadFeedbackAttachments(selectedFiles);
        attachmentIds = uploadedFiles.map((f) => f.$id).toList();

      } else {
      }

      // Get device/platform info
      final platform = 'mobile';
      final appVersion = '1.0.0';
      final deviceInfo = 'Mobile Device';
      final now = DateTime.now(); 

      // Create feedback object
      final feedback = FeedbackAndReport(
        userId: userId,
        userName: userName.isNotEmpty ? userName : 'Unknown User',
        userEmail: userEmail.isNotEmpty ? userEmail : 'unknown@email.com',
        feedbackType: selectedType.value,
        category: selectedCategory.value,
        subject: subject.value.trim(),
        description: description.value.trim(),
        attachments: attachmentIds,
        priority: Priority.medium,
        status: FeedbackStatus.pending,
        appVersion: appVersion,
        deviceInfo: deviceInfo,
        platform: platform,
        submittedAt: now,
      );


      // Submit to database
      await authRepository.createFeedbackAndReport(feedback);


 if (dailyTracker.value != null) {
        dailyTracker.value = dailyTracker.value!.incrementCount();
      } else {
        // Create new tracker if doesn't exist
        dailyTracker.value = UserDailyReportTracker(
          userId: userId,
          reportCount: 1,
          lastResetAt: now,
          lastReportAt: now,
        );
      }
      // Clear form
      clearForm();

        final remaining = getRemainingReports();
      _showSuccess(
        "Feedback submitted! ($remaining reports remaining today)"
      );

      return true;
    } catch (e, stackTrace) {

      _showError("Failed to submit feedback. Please try again.");
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Clear the feedback form completely
  void clearForm() {
    
    // Clear text values
    subject.value = '';
    description.value = '';
    
    // Clear file selections
    selectedFiles.clear();
    
    // Reset to DEFAULT selections
    selectedType.value = FeedbackType.bug;
    selectedCategory.value = FeedbackCategory.other;
    
    // Force refresh
    subject.refresh();
    description.refresh();
    selectedFiles.refresh();
    selectedType.refresh();
    selectedCategory.refresh();
    
  }
}