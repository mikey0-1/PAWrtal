import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';

class ResetPasswordController extends GetxController {
  final AuthRepository _authRepository;
  ResetPasswordController(this._authRepository);

  // Form
  final formKey = GlobalKey<FormState>();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Observables
  final isNewPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;
  final isLoading = false.obs;
  final isValidating = true.obs;
  final resetSuccess = false.obs;
  final validationError = ''.obs;

  // URL parameters
  String? userId;
  String? secret;

  @override
  void onInit() {
    super.onInit();
    _validateResetLink();
  }

  @override
  void onClose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  void toggleNewPasswordVisibility() {
    isNewPasswordVisible.value = !isNewPasswordVisible.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  /// Validate the reset link from URL parameters
  Future<void> _validateResetLink() async {
    try {

      // CRITICAL: Get URL parameters with multiple strategies
      final parameters = Get.parameters;

      // Strategy 1: Direct parameters
      userId = parameters['userId'];
      secret = parameters['secret'];


      // Strategy 2: Try alternative parameter names
      if (userId == null || secret == null) {
        userId = parameters['userId'] ?? parameters['user'] ?? parameters['id'];
        secret = parameters['secret'] ?? parameters['token'];
      }

      // Strategy 3: Parse from current route
      if (userId == null || secret == null) {
        final currentRoute = Get.currentRoute;

        final uri = Uri.parse(currentRoute);
        userId = uri.queryParameters['userId'];
        secret = uri.queryParameters['secret'];
      }

      // Strategy 4: Parse from browser URL (Web only)
      if (userId == null || secret == null) {
        try {
          // Import dart:html at the top of your file
          // import 'dart:html' as html;

          // Get the full URL from browser
          final url = Uri.base.toString();

          // Parse query parameters from the full URL
          final uri = Uri.parse(url);

          // Check both hash and query parameters
          if (uri.fragment.isNotEmpty && uri.fragment.contains('?')) {
            // Parameters are in the hash fragment
            final fragmentParams = uri.fragment.split('?');
            if (fragmentParams.length > 1) {
              final queryString = fragmentParams[1];
              final params = Uri.splitQueryString(queryString);
              userId = params['userId'];
              secret = params['secret'];
            }
          } else {
            // Try regular query parameters
            userId = uri.queryParameters['userId'];
            secret = uri.queryParameters['secret'];
          }
        } catch (e) {
        }
      }

      // Validate we have the required parameters
      if (userId == null ||
          secret == null ||
          userId!.isEmpty ||
          secret!.isEmpty) {
        validationError.value =
            'Invalid reset link. Please request a new password reset.';
        isValidating.value = false;
        return;
      }


      // Validate secret with backend
      final isValid =
          await _authRepository.validatePasswordResetSecret(userId!, secret!);

      if (isValid) {
        isValidating.value = false;
      } else {
        validationError.value =
            'This reset link has expired or is invalid. Please request a new one.';
        isValidating.value = false;
      }

    } catch (e) {
      validationError.value = 'An error occurred. Please try again.';
      isValidating.value = false;
    }
  }

  /// Password validator
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Password is required";
    }

    if (value.length < 8) {
      return "Password must be at least 8 characters";
    }

    // Check for at least one uppercase letter
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return "Password must contain at least one uppercase letter";
    }

    // Check for at least one number
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return "Password must contain at least one number";
    }

    // Check for at least one special character
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return "Password must contain at least one special character";
    }

    return null;
  }

  /// Confirm password validator
  String? validateConfirmPassword(String? value, String newPassword) {
    if (value == null || value.isEmpty) {
      return "Please confirm your password";
    }

    if (value != newPassword) {
      return "Passwords do not match";
    }

    return null;
  }

  /// Reset password
  Future<void> resetPassword() async {
    if (!formKey.currentState!.validate()) return;

    try {
      isLoading.value = true;


      final success = await _authRepository.resetPassword(
        userId: userId!,
        secret: secret!,
        newPassword: newPasswordController.text,
      );

      if (success) {
        resetSuccess.value = true;

        // Clear form
        newPasswordController.clear();
        confirmPasswordController.clear();
      } else {
        Get.snackbar(
          'Error',
          'Failed to reset password. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
        );
      }

    } catch (e) {
      Get.snackbar(
        'Error',
        'An error occurred. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
