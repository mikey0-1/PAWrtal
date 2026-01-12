import 'package:capstone_app/data/models/feedback_and_report_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class AdminFeedbackController extends GetxController {
  final AuthRepository authRepository;
  final UserSessionService session;
  final GetStorage storage = GetStorage();

  AdminFeedbackController({
    required this.authRepository,
    required this.session,
  });

  // Observable properties
  Rx<FeedbackType> selectedType = FeedbackType.bug.obs;
  Rx<FeedbackCategory> selectedCategory = FeedbackCategory.systemIssue.obs;
  RxString subject = ''.obs;
  RxString description = ''.obs;
  RxList<PlatformFile> selectedFiles = <PlatformFile>[].obs;
  RxBool isSubmitting = false.obs;

  // File helper methods
  String getFileSize(int? bytes) {
    if (bytes == null) return 'Unknown';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String getFileIcon(String? extension) {
  if (extension == null) return '🖼️';
  switch (extension.toLowerCase()) {
    case 'jpg':
    case 'jpeg':
    case 'png':
    case 'gif':
    case 'webp':
      return '🖼️';
    default:
      return '🖼️'; 
    }
  }

Future<void> pickFiles() async {
  try {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: [
        'jpg',
        'jpeg',
        'png',
        'gif',
        'webp',  // Added webp support
        // REMOVED: Video extensions (mp4, mov, avi, mkv)
        // REMOVED: Document extensions (pdf, doc, docx)
      ],
    );

    if (result != null) {
      for (var file in result.files) {
        // Validate that file is an image (double-check)
        final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp']
            .contains(file.extension?.toLowerCase());

        if (!isImage) {
          Get.snackbar(
            'Invalid File Type', 
            '${file.name} is not an image. Only JPG, PNG, GIF, and WEBP images are allowed.',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            icon: const Icon(Icons.error_outline, color: Colors.white),
          );
          continue;
        }

        // Validate file size (5MB limit for images)
        if (file.size > 5 * 1024 * 1024) {
          Get.snackbar(
            'File Too Large', 
            'Image ${file.name} exceeds 5MB limit',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            icon: const Icon(Icons.error_outline, color: Colors.white),
          );
          continue;
        }

        // Check if we haven't reached the limit
        if (selectedFiles.length < 5) {
          selectedFiles.add(file);
        } else {
          Get.snackbar(
            'Limit Reached', 
            'Maximum 5 images allowed',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            icon: const Icon(Icons.info_outline, color: Colors.white),
          );
          break;
        }
      }
    }
  } catch (e) {
    Get.snackbar(
      'Error', 
      'Error picking files: $e',
      backgroundColor: Colors.red,
      colorText: Colors.white,
      icon: const Icon(Icons.error_outline, color: Colors.white),
    );
  }
}

  void removeFile(PlatformFile file) {
    selectedFiles.remove(file);
  }

  Future<bool> submitFeedback() async {
    try {
      // Validation
      if (subject.value.isEmpty) {
        Get.snackbar('Validation', 'Please enter a subject',
            backgroundColor: Colors.orange);
        return false;
      }

      if (description.value.length < 20) {
        Get.snackbar('Validation', 'Description must be at least 20 characters',
            backgroundColor: Colors.orange);
        return false;
      }

      isSubmitting.value = true;

      // Get current user info from storage
      final userId = storage.read('userId') as String?;
      final userEmail = storage.read('email') as String? ?? 'unknown@email.com';
      final userName = storage.read('name') as String? ?? 'Unknown User';
      final userRole = storage.read('role') as String? ?? 'user';
      var clinicId = storage.read('clinicId') as String?;

      if (userId == null) {
        Get.snackbar('Error', 'User session not found',
            backgroundColor: Colors.red);
        isSubmitting.value = false;
        return false;
      }

      // Debug: Print stored values

      // For admin/staff, clinicId must be present
      if ((userRole.toLowerCase() == 'admin' ||
          userRole.toLowerCase() == 'staff')) {
        if (clinicId == null || clinicId.isEmpty) {
          Get.snackbar(
              'Error', 'Clinic information not found. Please login again.',
              backgroundColor: Colors.red);
          isSubmitting.value = false;
          return false;
        }
      } else {
        // For regular users, clinicId can be empty string instead of null
        clinicId = clinicId ?? '';
      }

      // Upload attachments if any
      List<String> attachmentIds = [];
      if (selectedFiles.isNotEmpty) {
        final uploadedFiles = await authRepository
            .uploadFeedbackAttachments(selectedFiles.toList());
        attachmentIds = uploadedFiles.map((f) => f.$id).toList();
      }

      // Determine the reporting role
      String? reportedBy;
      String? adminId;
      String? staffId;

      if (userRole.toLowerCase() == 'admin') {
        reportedBy = 'admin';
        adminId = userId;
      } else if (userRole.toLowerCase() == 'staff') {
        reportedBy = 'staff';
        staffId = userId;
      } else {
        reportedBy = 'user';
      }

      // Create feedback model
      final feedback = FeedbackAndReport(
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        feedbackType: selectedType.value,
        category: selectedCategory.value,
        subject: subject.value,
        description: description.value,
        attachments: attachmentIds,
        priority: Priority.medium,
        status: FeedbackStatus.pending,
        appVersion: '1.0.0',
        deviceInfo: 'Web Browser',
        platform: 'web',
        submittedAt: DateTime.now(),
        reportedBy: reportedBy,
        adminId: adminId,
        staffId: staffId,
        clinicId: clinicId,
      );

      // Submit feedback through repository
      await authRepository.createFeedbackAndReport(feedback);

      // Reset form
      selectedType.value = FeedbackType.bug;
      selectedCategory.value = FeedbackCategory.systemIssue;
      subject.value = '';
      description.value = '';
      selectedFiles.clear();

      Get.snackbar(
        'Success',
        'Feedback submitted successfully. Thank you for helping us improve!',
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      );

      isSubmitting.value = false;
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to submit feedback: $e',
          backgroundColor: Colors.red);
      isSubmitting.value = false;
      return false;
    }
  }

  @override
  void onClose() {
    selectedFiles.clear();
    super.onClose();
  }
}
