import 'package:appwrite/appwrite.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class StaffChangePasswordController extends GetxController {
  final AuthRepository authRepository;
  final GetStorage _storage = GetStorage();

  StaffChangePasswordController(this.authRepository);

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

  // Error message
  final errorMessage = ''.obs;

  @override
  void onClose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

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
    return null;
  }

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

    if (value == currentPasswordController.text) {
      return 'New password must be different from current password';
    }

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

  /// Change password for staff
  Future<bool> changePassword() async {
    try {
      // Validate form
      if (!formKey.currentState!.validate()) {
        return false;
      }

      // Additional check: Ensure passwords match
      if (newPasswordController.text.trim() !=
          confirmPasswordController.text.trim()) {
        errorMessage.value = 'New password and confirm password do not match.';
        return false;
      }

      isLoading.value = true;
      errorMessage.value = '';


      final currentPassword = currentPasswordController.text.trim();
      final newPassword = newPasswordController.text.trim();

      // Get staff username from storage
      final userEmail = _storage.read('email');
      if (userEmail == null) {
        throw Exception('User email not found');
      }


      final account = Account(authRepository.appWriteProvider.appwriteClient);

      // Appwrite's updatePassword for staff (same as admin)
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

      // Handle specific Appwrite errors
      if (e.code == 401 || e.type == 'user_invalid_credentials') {
        errorMessage.value = 'Current password is incorrect. Please try again.';
      } else if (e.code == 400 || e.type == 'general_argument_invalid') {
        errorMessage.value =
            'Invalid password format. Please check the requirements.';
      } else if (e.message?.toLowerCase().contains('password') == true &&
          e.message?.toLowerCase().contains('invalid') == true) {
        errorMessage.value = 'Current password is incorrect. Please try again.';
      } else {
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
}
