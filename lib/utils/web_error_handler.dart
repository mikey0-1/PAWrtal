import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WebErrorHandler {
  static void handleError(dynamic error, {String? context}) {
    String message = 'An unexpected error occurred';
    
    if (error is AppwriteException) {
      message = _handleAppwriteError(error);
    } else if (error is Exception) {
      message = error.toString().replaceAll('Exception: ', '');
    } else {
      message = error.toString();
    }

    // Log error for debugging

    // Show user-friendly error message
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
    );
  }

  static String _handleAppwriteError(AppwriteException error) {
    switch (error.code) {
      case 401:
        return 'Invalid credentials. Please check your email and password.';
      case 409:
        return 'This email is already registered. Please use a different email.';
      case 429:
        return 'Too many requests. Please wait a moment and try again.';
      case 500:
        return 'Server error. Please try again later.';
      case 503:
        return 'Service unavailable. Please try again later.';
      default:
        return error.message ?? 'An error occurred. Please try again.';
    }
  }

  static void handleSuccess(String message) {
    Get.snackbar(
      'Success',
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
    );
  }

  static void handleInfo(String message) {
    Get.snackbar(
      'Info',
      message,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
    );
  }

  static void handleWarning(String message) {
    Get.snackbar(
      'Warning',
      message,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
    );
  }
}