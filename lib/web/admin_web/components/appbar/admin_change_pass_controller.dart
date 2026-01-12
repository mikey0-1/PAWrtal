import 'package:appwrite/appwrite.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:capstone_app/utils/custom_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class AdminChangePasswordController extends GetxController {
  final AuthRepository authRepository;
  final GetStorage _storage = GetStorage();

  AdminChangePasswordController(this.authRepository);

  // Text Controllers
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Form Key
  final formKey = GlobalKey<FormState>();

  // Observable states
  final isCurrentPasswordVisible = false.obs;
  final isNewPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;
  final isLoading = false.obs;

  // Password strength indicators
  final hasMinLength = false.obs;
  final hasUpperCase = false.obs;
  final hasNumber = false.obs;
  final hasSpecialChar = false.obs;

  // Add this new observable for error messages
  final errorMessage = ''.obs;

  @override
  void onClose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  /// Toggle password visibility
  void toggleCurrentPasswordVisibility() {
    isCurrentPasswordVisible.value = !isCurrentPasswordVisible.value;
  }

  void toggleNewPasswordVisibility() {
    isNewPasswordVisible.value = !isNewPasswordVisible.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  /// Validate current password
  String? validateCurrentPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your current password';
    }
    // No format validation - just check it's not empty
    // The actual password matching will be verified by Appwrite server
    return null;
  }

  /// Check password requirements and update indicators
  void checkPasswordRequirements(String password) {
    hasMinLength.value = password.length >= 8;
    hasUpperCase.value = password.contains(RegExp(r'[A-Z]'));
    hasNumber.value = password.contains(RegExp(r'[0-9]'));
    hasSpecialChar.value = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  }

  /// Validate new password
  String? validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a new password';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }

    // Don't compare with current password here
    return null;
  }

  /// Validate confirm password
  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your new password';
    }

    if (value != newPasswordController.text) {
      return 'Passwords do not match';
    }

    return null;
  }

  /// Calculate password strength (0-4)
  int getPasswordStrength() {
    int strength = 0;
    if (hasMinLength.value) strength++;
    if (hasUpperCase.value) strength++;
    if (hasNumber.value) strength++;
    if (hasSpecialChar.value) strength++;
    return strength;
  }

  /// Get password strength label
  String getPasswordStrengthLabel() {
    final strength = getPasswordStrength();
    switch (strength) {
      case 0:
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      default:
        return '';
    }
  }

  /// Get password strength color
  Color getPasswordStrengthColor() {
    final strength = getPasswordStrength();
    switch (strength) {
      case 0:
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.blue;
      case 4:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// Clear all fields
  void clearFields() {
    currentPasswordController.clear();
    newPasswordController.clear();
    confirmPasswordController.clear();
    hasMinLength.value = false;
    hasUpperCase.value = false;
    hasNumber.value = false;
    hasSpecialChar.value = false;
    errorMessage.value = '';
  }

  Future<bool> changePassword() async {
    try {
      // Validate form (only checks empty fields and new password format)
      if (!formKey.currentState!.validate()) {
        return false;
      }

      isLoading.value = true;
      errorMessage.value = '';

      final currentPassword = currentPasswordController.text.trim();
      final newPassword = newPasswordController.text.trim();

      final account = Account(authRepository.appWriteProvider.appwriteClient);

      // This is where the REAL current password verification happens
      // Appwrite will check if currentPassword matches the user's actual password
      await account.updatePassword(
        password: newPassword,
        oldPassword: currentPassword,
      );

      isLoading.value = false;
      errorMessage.value = '';

      // Clear fields after successful change
      clearFields();

      return true;
    } on AppwriteException catch (e) {
      isLoading.value = false;

      // Handle specific Appwrite errors - focus on wrong password detection
      if (e.code == 401) {
        // 401 Unauthorized = Wrong current password
        errorMessage.value = 'Current password is incorrect. Please try again.';
      } else if (e.type == 'user_invalid_credentials') {
        // Invalid credentials = Wrong current password
        errorMessage.value = 'Current password is incorrect. Please try again.';
      } else if (e.message?.toLowerCase().contains('password') == true &&
          (e.message?.toLowerCase().contains('wrong') == true ||
              e.message?.toLowerCase().contains('incorrect') == true ||
              e.message?.toLowerCase().contains('invalid') == true)) {
        // Error message explicitly mentions wrong password
        errorMessage.value = 'Current password is incorrect. Please try again.';
      } else if (e.type == 'user_invalid_token' ||
          e.type == 'user_session_not_found') {
        // Session errors
        errorMessage.value = 'Session expired. Please log in again.';
      } else {
        // Any other error
        errorMessage.value =
            e.message ?? 'Failed to change password. Please try again.';
      }

      return false;
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'An unexpected error occurred. Please try again.';
      return false;
    }
  }

  // Check if form has unsaved changes
  bool hasUnsavedChanges() {
    return currentPasswordController.text.isNotEmpty ||
        newPasswordController.text.isNotEmpty ||
        confirmPasswordController.text.isNotEmpty;
  }

  Future<void> markPasswordAsChanged(String clinicId) async {
    try {
      final databases =
          Databases(authRepository.appWriteProvider.appwriteClient);

      await databases.updateDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.clinicsCollectionID,
        documentId: clinicId,
        data: {
          'hasChangedPassword': true,
        },
      );

      // Update local storage
      _storage.write('hasChangedPassword', true);
    } catch (e) {
    }
  }
}
