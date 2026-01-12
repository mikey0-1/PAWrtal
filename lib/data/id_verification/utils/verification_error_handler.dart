import 'package:capstone_app/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:capstone_app/utils/custom_snack_bar.dart';
import 'package:get/get.dart';

/// Centralized error handling for ID verification
class VerificationErrorHandler {
  /// Handle errors during verification process
  static void handleVerificationError({
    required BuildContext context,
    required dynamic error,
    String? customMessage,
  }) {

    String title = 'Verification Error';
    String message = customMessage ?? _getErrorMessage(error);

    SnackbarHelper.showError(
      context: Get.overlayContext ?? context,
      title: title,
      message: message,
    );
  }

  /// Handle network errors specifically
  static void handleNetworkError(BuildContext context) {
    SnackbarHelper.showError(
      context: Get.overlayContext ?? context,
      title: 'Connection Error',
      message: 'Please check your internet connection and try again.',
    );
  }

  /// Handle timeout errors
  static void handleTimeoutError(BuildContext context) {
    SnackbarHelper.showError(
      context: Get.overlayContext ?? context,
      title: 'Request Timeout',
      message: 'The verification process took too long. Please try again.',
    );
  }

  /// Handle ARGOS API errors
  static void handleArgosApiError({
    required BuildContext context,
    required int statusCode,
    String? errorMessage,
  }) {
    String title = 'Verification Service Error';
    String message;

    switch (statusCode) {
      case 400:
        message =
            'Invalid request. Please check your information and try again.';
        break;
      case 401:
        message = 'Authentication failed. Please contact support.';
        break;
      case 403:
        message =
            'Access denied. This feature may not be available for your account.';
        break;
      case 404:
        message = 'Verification service not found. Please contact support.';
        break;
      case 429:
        message =
            'Too many verification attempts. Please wait a moment and try again.';
        break;
      case 500:
      case 502:
      case 503:
        message =
            'Verification service is temporarily unavailable. Please try again later.';
        break;
      default:
        message =
            errorMessage ?? 'An unexpected error occurred. Please try again.';
    }

    SnackbarHelper.showError(
      context: Get.overlayContext ?? context,
      title: title,
      message: message,
    );
  }

  /// Handle Appwrite errors
  static void handleAppwriteError({
    required BuildContext context,
    required dynamic error,
  }) {

    String message = 'Failed to save verification data. Please try again.';

    if (error.toString().contains('permission')) {
      message = 'Permission denied. Please contact support.';
    } else if (error.toString().contains('network')) {
      message = 'Network error. Please check your connection.';
    } else if (error.toString().contains('document not found')) {
      message =
          'Verification record not found. Please start a new verification.';
    }

    SnackbarHelper.showError(
      context: Get.overlayContext ?? context,
      title: 'Database Error',
      message: message,
    );
  }

  /// Show verification rejected dialog
  static void showRejectedDialog({
    required BuildContext context,
    String? reason,
    required VoidCallback onRetry,
    required VoidCallback onCancel,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.cancel_outlined,
                color: Color(0xFFF44336),
                size: 32,
              ),
              SizedBox(width: 12),
              Text('Verification Rejected'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your ID verification was not successful.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (reason != null && reason.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reason:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reason,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                'Common reasons for rejection:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildRejectionTip('ID document is blurry or unclear'),
              _buildRejectionTip('ID document is expired'),
              _buildRejectionTip('Photo doesn\'t match the ID'),
              _buildRejectionTip('Document is damaged or tampered'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onCancel();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onRetry();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        );
      },
    );
  }

  /// Show pending verification dialog
  static void showPendingDialog({
    required BuildContext context,
    required VoidCallback onClose,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.hourglass_empty,
                color: Color(0xFFFF9800),
                size: 32,
              ),
              SizedBox(width: 12),
              Text('Verification Pending'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your ID verification is being reviewed.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                'This usually takes a few minutes. You will receive a notification once the verification is complete.',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onClose();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
              ),
              child: const Text('Got It'),
            ),
          ],
        );
      },
    );
  }

  static Widget _buildRejectionTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('â€¢ ', style: TextStyle(fontSize: 14)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  /// Get user-friendly error message from error object
  static String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('socket')) {
      return 'Network connection error. Please check your internet and try again.';
    } else if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    } else if (errorString.contains('permission')) {
      return 'Permission denied. Please check your app permissions.';
    } else if (errorString.contains('camera')) {
      return 'Camera access is required for verification. Please grant camera permission.';
    } else if (errorString.contains('not found')) {
      return 'Resource not found. Please try again.';
    } else {
      return 'An unexpected error occurred. Please try again or contact support.';
    }
  }

  /// Show generic error dialog
  static void showErrorDialog({
    required BuildContext context,
    required String title,
    required String message,
    VoidCallback? onRetry,
    VoidCallback? onCancel,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: Color(0xFFF44336),
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title)),
            ],
          ),
          content: Text(message),
          actions: [
            if (onCancel != null)
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  onCancel();
                },
                child: const Text('Cancel'),
              ),
            if (onRetry != null)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  onRetry();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              )
            else
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                ),
                child: const Text('OK'),
              ),
          ],
        );
      },
    );
  }
}