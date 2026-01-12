import 'dart:convert';
import 'dart:typed_data';
import 'package:appwrite/appwrite.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UserPfpController extends GetxController {
  final AuthRepository authRepository;

  UserPfpController({required this.authRepository});

  // Observable properties
  Rx<PlatformFile?> selectedFile = Rx<PlatformFile?>(null);
  RxString currentProfilePictureId = ''.obs;
  RxBool isUploading = false.obs;
  RxString previewUrl = ''.obs;

  /// Pick image file from device/web
  Future<void> pickProfilePicture() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true, // Important for web support
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Validate file size (max 5MB)
        if (file.size > 5 * 1024 * 1024) {
          _showWarning('File size exceeds 5MB. Please select a smaller image.');
          return;
        }

        // Validate file type
        final validExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
        if (!validExtensions.contains(file.extension?.toLowerCase())) {
          _showWarning( 'Invalid file type. Please select an image file. (JPG, PNG, GIF, or WebP)');
          return;
        }

        selectedFile.value = file;

        // Create temporary preview URL for web (using bytes)
        if (file.bytes != null) {
          // For web, we can create a data URL from bytes
          previewUrl.value = 'data:image/${file.extension};base64,${_bytesToBase64(file.bytes!)}';
        }
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
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

  void _showError (String message) {
    _showCompactNotification(
      message,
      bgColor: Colors.red[600]!,
      icon: Icons.error_outline,
      iconColor: Colors.white,
    );
  }

  void _showSuccess (String message) {
    _showCompactNotification(
      message,
      bgColor: Colors.green[600]!,
      icon: Icons.check_circle_outline,
      iconColor: Colors.white,
    );
  }

  void _showWarning (String message) {
    _showCompactNotification(
      message,
      bgColor: Colors.orange[600]!,
      icon: Icons.warning_amber_outlined,
      iconColor: Colors.white,
    );
  }

  /// Convert bytes to base64 string for preview
  String _bytesToBase64(Uint8List bytes) {
    return base64Encode(bytes);
  }

  /// Get preview image widget based on current state
  Widget getPreviewImage({
    double size = 96,
    Color placeholderColor = const Color.fromARGB(255, 81, 115, 153),
    String userName = 'User',
  }) {
    // If a new file is selected, show it
    if (selectedFile.value != null && selectedFile.value!.bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.memory(
          selectedFile.value!.bytes!,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }

    // If there's a current profile picture from database
        if (currentProfilePictureId.isNotEmpty) {
          final imageUrl = authRepository.getUserProfilePictureUrl(currentProfilePictureId.value);
          return ClipRRect(
            borderRadius: BorderRadius.circular(size / 2),
            child: Image.network(
              imageUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder(size, placeholderColor, userName);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[200],
              ),
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                ),
              ),
            );
          },
        ),
      );
    }

    // Show placeholder
    return _buildPlaceholder(size, placeholderColor, userName);
  }

  /// Build placeholder avatar with user's initial
  Widget _buildPlaceholder(double size, Color color, String userName) {
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  /// Check if there are unsaved changes
  bool hasChanges() {
    return selectedFile.value != null;
  }

  /// Save profile picture to database
  /// Returns the new file ID if successful, null otherwise
Future<String?> saveProfilePicture(String userDocumentId) async {
  if (selectedFile.value == null) {
    _showError('No image selected');
    return null;
  }

  try {
    isUploading.value = true;

    // Delete old profile picture if it exists
    if (currentProfilePictureId.isNotEmpty) {
      try {
        await authRepository.deleteUserProfilePicture(currentProfilePictureId.value);
      } catch (e) {
      }
    }

    // Convert PlatformFile to InputFile for upload
    final file = selectedFile.value!;
    final fileName = 'user_profile_${DateTime.now().millisecondsSinceEpoch}.${file.extension}';
    
    InputFile inputFile;
    if (file.bytes != null) {
      inputFile = InputFile.fromBytes(
        bytes: file.bytes!,
        filename: fileName,
      );
    } else if (file.path != null) {
      inputFile = InputFile.fromPath(
        path: file.path!,
        filename: fileName,
      );
    } else {
      throw Exception('File has neither bytes nor path');
    }

    // Upload new profile picture
    final uploadedFile = await authRepository.uploadUserProfilePicture(inputFile);

    // Update user record with new profile picture ID
    await authRepository.updateUserProfilePicture(
      userDocumentId,
      currentProfilePictureId.isEmpty ? null : currentProfilePictureId.value,
      inputFile,
    );

    // Update local state
    currentProfilePictureId.value = uploadedFile.$id;
    selectedFile.value = null;
    previewUrl.value = '';

    _showSuccess('Profile picture updated successfully');

    isUploading.value = false;
    return uploadedFile.$id;
  } catch (e) {
    isUploading.value = false;
    _showError('Failed to upload profile picture: $e');
    return null;
  }
}

  /// Cancel changes and revert to previous state
  void cancelChanges() {
    selectedFile.value = null;
    previewUrl.value = '';
  }

  /// Initialize with existing profile picture ID
  void setCurrentProfilePicture(String? profilePictureId) {
    if (profilePictureId != null && profilePictureId.isNotEmpty) {
      currentProfilePictureId.value = profilePictureId;
    }
  }

  @override
  void onClose() {
    selectedFile.value = null;
    previewUrl.value = '';
    super.onClose();
  }
}