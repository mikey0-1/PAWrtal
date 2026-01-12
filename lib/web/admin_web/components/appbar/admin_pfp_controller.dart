import 'dart:convert';
import 'dart:typed_data';
import 'package:appwrite/appwrite.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminPfpController extends GetxController {
  final AuthRepository authRepository;

  AdminPfpController({required this.authRepository});

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
          Get.snackbar(
            'File Too Large',
            'Profile picture must be smaller than 5MB',
            backgroundColor: Colors.red,
          );
          return;
        }

        // Validate file type
        final validExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
        if (!validExtensions.contains(file.extension?.toLowerCase())) {
          Get.snackbar(
            'Invalid Format',
            'Please use JPG, PNG, GIF, or WebP format',
            backgroundColor: Colors.red,
          );
          return;
        }

        selectedFile.value = file;

        // Create temporary preview URL for web (using bytes)
        if (file.bytes != null) {
          // For web, we can create a data URL from bytes
          previewUrl.value =
              'data:image/${file.extension};base64,${_bytesToBase64(file.bytes!)}';
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick image: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  /// Convert bytes to base64 string for preview
  String _bytesToBase64(Uint8List bytes) {
    return base64Encode(bytes);
  }

  /// Get preview image widget based on current state
  Widget getPreviewImage({
    double size = 96,
    Color placeholderColor = Colors.purple,
  }) {
    // If a new file is selected, show it
    if (selectedFile.value != null && selectedFile.value!.bytes != null) {
      return Image.memory(
        selectedFile.value!.bytes!,
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    }

    // If there's a current profile picture from database
    if (currentProfilePictureId.isNotEmpty) {
      final imageUrl =
          authRepository.getImageUrl(currentProfilePictureId.value);
      return Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder(size, placeholderColor);
        },
      );
    }

    // Show placeholder
    return _buildPlaceholder(size, placeholderColor);
  }

  /// Build placeholder avatar
  Widget _buildPlaceholder(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [color.withOpacity(0.7), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(
        Icons.local_hospital,
        color: Colors.white,
        size: 32,
      ),
    );
  }

  /// Check if there are unsaved changes
  bool hasChanges() {
    return selectedFile.value != null;
  }

  /// Save profile picture to database
  /// Returns the new file ID if successful, null otherwise
  Future<String?> saveProfilePicture(String clinicId) async {
    if (selectedFile.value == null) {
      Get.snackbar(
        'Error',
        'No image selected',
        backgroundColor: Colors.red,
      );
      return null;
    }

    try {
      isUploading.value = true;

      // Delete old profile picture if it exists
      if (currentProfilePictureId.isNotEmpty) {
        try {
          await authRepository.deleteImage(currentProfilePictureId.value);
        } catch (e) {
        }
      }

      // Convert PlatformFile to InputFile for upload
      final file = selectedFile.value!;
      final fileName = file.name;

      InputFile inputFile;
      if (file.bytes != null) {
        // Web upload
        inputFile = InputFile.fromBytes(
          bytes: file.bytes!,
          filename: fileName,
        );
      } else if (file.path != null) {
        // Mobile upload
        inputFile = InputFile.fromPath(
          path: file.path!,
          filename: fileName,
        );
      } else {
        throw Exception('File has neither bytes nor path');
      }

      // Upload new profile picture
      final uploadedFile =
          await authRepository.uploadClinicProfilePicture(inputFile);

      // Update clinic record with new profile picture ID
      await authRepository.updateClinic(clinicId, {
        'profilePictureId': uploadedFile.$id,
      });

      // Update local state
      currentProfilePictureId.value = uploadedFile.$id;
      selectedFile.value = null;
      previewUrl.value = '';

      Get.snackbar(
        'Success',
        'Profile picture updated successfully',
        backgroundColor: Colors.green,
      );

      isUploading.value = false;
      return uploadedFile.$id;
    } catch (e) {
      isUploading.value = false;
      Get.snackbar(
        'Error',
        'Failed to save profile picture: $e',
        backgroundColor: Colors.red,
      );
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

  Future<String?> saveStaffProfilePicture(String staffDocumentId) async {
    if (selectedFile.value == null) {
      Get.snackbar(
        'Error',
        'No image selected',
        backgroundColor: Colors.red,
      );
      return null;
    }

    try {
      isUploading.value = true;


      // Delete old profile picture if it exists
      if (currentProfilePictureId.isNotEmpty) {
        try {
          await authRepository.deleteImage(currentProfilePictureId.value);
        } catch (e) {
        }
      }

      // Convert PlatformFile to InputFile for upload
      final file = selectedFile.value!;
      final fileName = file.name;

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
      final uploadedFile = await authRepository.uploadImage(inputFile);


      // âœ… CRITICAL FIX: Save ONLY the file ID, NOT a URL
      await authRepository.updateStaffInfo(
        staffDocumentId: staffDocumentId,
        image: uploadedFile.$id, // âœ… SAVE FILE ID ONLY
      );


      // Update local state with FILE ID
      currentProfilePictureId.value = uploadedFile.$id;
      selectedFile.value = null;
      previewUrl.value = '';

      Get.snackbar(
        'Success',
        'Profile picture updated successfully',
        backgroundColor: Colors.green,
      );


      isUploading.value = false;
      return uploadedFile.$id; // âœ… RETURN FILE ID ONLY
    } catch (e) {

      isUploading.value = false;
      Get.snackbar(
        'Error',
        'Failed to save profile picture: $e',
        backgroundColor: Colors.red,
      );
      return null;
    }
  }
}
