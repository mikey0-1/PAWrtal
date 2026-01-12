import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:capstone_app/pages/routes/app_pages.dart';
import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/notification/services/notification_service.dart';
import 'package:capstone_app/notification/services/in_app_notification_service.dart';
import 'package:appwrite/enums.dart';
import 'package:appwrite/appwrite.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'dart:math' as Math;

/// Handles OAuth for mobile using Appwrite SDK's built-in OAuth
/// Includes FCM push notifications, in-app notifications, and all login features
class MobileOAuthHandler {
  static final _storage = GetStorage();
  static bool _isProcessing = false;
  static Timer? _sessionCheckTimer;

  /// Initialize and handle Google OAuth flow
  static Future<bool> initiateGoogleOAuth() async {
    if (_isProcessing) {
      return false;
    }

    try {
      _isProcessing = true;


      final appwriteProvider = Get.find<AppWriteProvider>();


      // CRITICAL FIX: createOAuth2Session returns void on mobile, not bool
      // It opens the browser and returns immediately
      await appwriteProvider.account!.createOAuth2Session(
        provider: OAuthProvider.google,
      );


      // Start polling for session establishment
      return await _pollForSession();
    } catch (e, stackTrace) {

      _handleOAuthFailure();
      return false;
    } finally {
      _isProcessing = false;
    }
  }

  /// Poll for OAuth session establishment
  static Future<bool> _pollForSession() async {

    _showLoadingDialog();

    const maxAttempts = 60; // 60 seconds total
    const checkInterval = Duration(seconds: 1);

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        await Future.delayed(checkInterval);

        if (attempt % 5 == 0 || attempt <= 3) {
        }

        // CRITICAL: Create a FRESH Appwrite client to check for session
        // The old client instance doesn't have the OAuth session cookies
        final testClient = Client()
            .setEndpoint(AppwriteConstants.endPoint)
            .setProject(AppwriteConstants.projectID);

        final testAccount = Account(testClient);

        // Try to get the user - this will succeed if session exists
        final user = await testAccount.get();

        if (user != null && user.$id.isNotEmpty) {

          // CRITICAL: Replace the global AppWriteProvider's client with fresh one
          final appwriteProvider = Get.find<AppWriteProvider>();
          appwriteProvider.client = testClient;
          appwriteProvider.account = testAccount;
          appwriteProvider.storage = Storage(testClient);
          appwriteProvider.databases = Databases(testClient);

          // Get AuthRepository and update it too
          final authRepository = Get.find<AuthRepository>();
          // authRepository.appWriteProvider = appwriteProvider;

          // Process the OAuth success
          await _handleOAuthSuccess(appwriteProvider, authRepository, user);
          return true;
        }
      } catch (e) {
        // Session not ready yet - this is expected
        if (attempt % 10 == 0) {
        }
      }
    }

    // Timeout - no session found

    _closeLoadingDialog();
    _handleOAuthFailure();
    return false;
  }

  /// Handle successful OAuth after session is detected
  static Future<void> _handleOAuthSuccess(
    AppWriteProvider appwriteProvider,
    AuthRepository authRepository,
    dynamic user,
  ) async {
    try {

      // Get current session using the NEW client
      final session = await appwriteProvider.account!.getSession(
        sessionId: 'current',
      );

      // Check if user exists in database
      final existingUserDoc = await authRepository.getUserById(user.$id);

      if (existingUserDoc == null) {

        final newUserDoc = await authRepository.createUser({
          "userId": user.$id,
          "name": user.name,
          "email": user.email,
          "role": "user",
          "phone": "",
          "profilePictureId": "",
          "idVerified": false,
          "idVerifiedAt": null,
          "verificationDocumentId": null,
          "isArchived": false,
          "archivedAt": null,
          "archivedBy": null,
          "archiveReason": null,
          "archivedDocumentId": null,
        });

        await _storage.write('userDocumentId', newUserDoc.$id);
      } else {
        await _storage.write('userDocumentId', existingUserDoc.$id);

        // Get profile picture if exists
        final profilePictureId =
            existingUserDoc.data['profilePictureId'] as String?;
        if (profilePictureId != null && profilePictureId.isNotEmpty) {
          await _storage.write('userProfilePictureId', profilePictureId);
        } else {
          await _storage.write('userProfilePictureId', '');
        }
      }

      // Store session data
      await _storage.write('userId', user.$id);
      await _storage.write('sessionId', session.$id);
      await _storage.write('email', user.email);
      await _storage.write('userName', user.name);
      await _storage.write('role', 'user');


      // FEATURE: Register FCM token for push notifications (Mobile only)
      // NOTE: We're in a mobile app, so kIsWeb will be false

      try {
        // Only register FCM on mobile platforms
        if (!kIsWeb) {

          if (Get.isRegistered<NotificationService>()) {
            final notificationService = Get.find<NotificationService>();

            // Request permissions
            final hasPermission =
                await notificationService.requestPermissions();

            if (hasPermission) {
              // Get FCM token
              final fcmToken = await notificationService.getFreshToken();

              if (fcmToken != null && fcmToken.isNotEmpty) {

                // Register with Appwrite
                final target = await appwriteProvider.registerUserPushTarget(
                  userId: user.$id,
                  fcmToken: fcmToken,
                );

                if (target != null) {
                  await _storage.write('push_target_id', target.$id);
                } else {
                }
              } else {
              }
            } else {
            }
          } else {
          }
        } else {
        }
      } catch (e, stack) {
        // Don't fail login if FCM registration fails
      }

      // FEATURE: Initialize in-app notification service

      try {
        if (Get.isRegistered<InAppNotificationService>()) {
          final notificationService = Get.find<InAppNotificationService>();
          await notificationService.initialize();
        } else {
        }
      } catch (e) {
      }


      _closeLoadingDialog();

      // Navigate to user home
      Get.offAllNamed(Routes.userHome);

      // Show success message
      Get.snackbar(
        'Welcome!',
        'Successfully signed in with Google',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade900,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
      );

    } catch (e, stackTrace) {

      _closeLoadingDialog();
      _handleOAuthFailure();
    }
  }

  static void _showLoadingDialog() {
    if (!(Get.isDialogOpen ?? false)) {
      Get.dialog(
        WillPopScope(
          onWillPop: () async => false,
          child: const Center(
            child: Card(
              margin: EdgeInsets.all(32),
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color.fromARGB(255, 81, 115, 153),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Completing Google Sign-In...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Please wait while we verify your account...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'This may take up to 60 seconds',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );
    }
  }

  static void _closeLoadingDialog() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }

  static void _handleOAuthFailure() {

    _closeLoadingDialog();

    Get.snackbar(
      'Sign In Cancelled',
      'Google Sign-In was cancelled or failed. Please try again.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange.shade100,
      colorText: Colors.orange.shade900,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(16),
    );
  }

  /// Cleanup method
  static void dispose() {
    _sessionCheckTimer?.cancel();
    _sessionCheckTimer = null;
    _isProcessing = false;
  }
}
