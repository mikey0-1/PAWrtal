import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/mobile/user/controllers/user_messaging_controller.dart';
import 'package:capstone_app/notification/services/appointment_reminder_service.dart';
import 'package:capstone_app/notification/services/notification_service.dart';
import 'package:capstone_app/pages/routes/app_pages.dart';
import 'package:capstone_app/utils/snackbar_helper.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:capstone_app/web/admin_web/components/appointments/admin_web_appointment_controller.dart';
import 'package:capstone_app/web/admin_web/components/dashboard/admin_dashboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class LogoutHelper {
  static final GetStorage _getStorage = GetStorage();

  // Global logout flag
  static final RxBool isLoggingOut = false.obs;

  static Future<void> logout() async {
    try {
      // CRITICAL: Set global logout flag FIRST
      isLoggingOut.value = true;


      // ========================================
      // STEP 1: Get ALL data IMMEDIATELY and store in local variables
      // ========================================
      final sessionId = _getStorage.read('sessionId');
      final userId = _getStorage.read('userId');
      final pushTargetId = _getStorage.read('push_target_id');
      final fcmToken = _getStorage.read('fcm_token');


      // ========================================
      // STEP 2: AGGRESSIVELY delete FCM target FIRST
      // Don't even check if session is valid - just try to delete it
      // ========================================
      bool fcmTargetDeleted = false;

      if (!kIsWeb && pushTargetId != null && pushTargetId.isNotEmpty) {
        try {
          final appWriteProvider = Get.find<AppWriteProvider>();

          // Try to delete without checking session validity first
          final deleted = await appWriteProvider.deletePushTarget(pushTargetId);

          if (deleted) {
            fcmTargetDeleted = true;
          } else {
          }
        } catch (fcmError) {

          // If it failed due to auth error, the session is already dead
          // Log this for debugging
          if (fcmError.toString().contains('401') ||
              fcmError.toString().contains('unauthorized')) {
          }
        }
      }

      // Try to clear FCM token from Firebase (this doesn't require Appwrite session)
      if (!kIsWeb && fcmToken != null) {
        try {
          final notificationService = Get.find<NotificationService>();
          await notificationService.clearToken();
        } catch (e) {
        }
      }

      // ========================================
      // STEP 3: Show loading indicator
      // ========================================
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(),
        ),
        barrierDismissible: false,
      );

      // ========================================
      // STEP 4: Do other cleanup
      // ========================================

      // Set user offline and clear messaging
      if (Get.isRegistered<MessagingController>()) {
        final messagingController = Get.find<MessagingController>();
        try {
          // Only try to set offline if we think session might be valid
          if (sessionId != null && sessionId.isNotEmpty) {
            await messagingController.setUserOffline();
          }
        } catch (e) {
        }
        messagingController.clearAllData();
        Get.delete<MessagingController>();
      }

      // Stop user-specific appointment reminder service
      if (userId != null && userId.isNotEmpty) {
        final serviceTag = 'reminder_$userId'; // ✅ User-specific tag

        if (Get.isRegistered<AppointmentReminderService>(tag: serviceTag)) {
          try {
            final reminderService =
                Get.find<AppointmentReminderService>(tag: serviceTag);
            reminderService.stopReminderService();
            Get.delete<AppointmentReminderService>(
                tag: serviceTag, force: true);
          } catch (e) {
          }
        }
      }

      // Clear WebAppointmentController
      if (Get.isRegistered<WebAppointmentController>()) {
        try {
          final appointmentController = Get.find<WebAppointmentController>();
          appointmentController.cleanupOnLogout();
          Get.delete<WebAppointmentController>(force: true);
        } catch (e) {
        }
      }

      // Clear AdminDashboardController
      if (Get.isRegistered<AdminDashboardController>()) {
        try {
          final dashboardController = Get.find<AdminDashboardController>();
          dashboardController.cleanupOnLogout();
          Get.delete<AdminDashboardController>(force: true);
        } catch (e) {
        }
      }

      // Clear UserSessionService
      if (Get.isRegistered<UserSessionService>()) {
        final userSession = Get.find<UserSessionService>();
        await userSession.clearSession();
      }

      // ========================================
      // STEP 5: Try to delete Appwrite session (may already be invalid)
      // ========================================
      if (sessionId != null && sessionId.isNotEmpty) {
        bool serverLogoutSuccess = false;
        try {
          final appWriteProvider = Get.find<AppWriteProvider>();

          // STRATEGY 1: Try deleting specific session
          try {
            await appWriteProvider.account!.deleteSession(sessionId: sessionId);
            serverLogoutSuccess = true;
          } catch (e) {
          }

          // STRATEGY 2: Try deleting current session
          if (!serverLogoutSuccess) {
            try {
              await appWriteProvider.account!
                  .deleteSession(sessionId: 'current');
              serverLogoutSuccess = true;
            } catch (e) {
            }
          }

          // STRATEGY 3: Try deleting ALL sessions (mobile only)
          if (!serverLogoutSuccess && !kIsWeb) {
            try {
              await appWriteProvider.account!.deleteSessions();
              serverLogoutSuccess = true;
            } catch (e) {
            }
          }

          if (!serverLogoutSuccess) {
          }
        } catch (e) {
        }
      } else {
      }

      // ========================================
      // STEP 6: Clear local storage
      // ========================================
      await _clearAllUserData();

      // ========================================
      // STEP 7: Reinitialize AppwriteProvider (web only)
      // ========================================
      if (kIsWeb) {
        try {
          final appWriteProvider = Get.find<AppWriteProvider>();
          appWriteProvider.client = appWriteProvider.client
              .setEndpoint(appWriteProvider.client.endPoint)
              .setProject(appWriteProvider.client.config['project']);
          appWriteProvider.account = appWriteProvider.account;
          appWriteProvider.storage = appWriteProvider.storage;
          appWriteProvider.databases = appWriteProvider.databases;
        } catch (e) {
        }
      }

      // ========================================
      // STEP 8: Close dialog and navigate
      // ========================================
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      Get.offAllNamed(Routes.login);

      // Show appropriate message
      // String message;
      // if (fcmTargetDeleted) {
      //   message = "You have been successfully logged out";
      // } else if (pushTargetId != null && pushTargetId.isNotEmpty) {
      //   message = "Logged out (Note: Your session was already invalid. You may need to clear app data if you experience issues.)";
      // } else {
      //   message = "You have been successfully logged out";
      // }

      SnackbarHelper.showSuccess(
          context: Get.overlayContext,
          title: "Logged Out",
          message: "You have been successfully logged out");

      if (fcmTargetDeleted) {
      } else if (pushTargetId != null && pushTargetId.isNotEmpty) {
      }
    } catch (e) {

      // Close loading dialog if open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      // CRITICAL: Always clear local data and navigate, even on error
      try {
        await _clearAllUserData();
        Get.offAllNamed(Routes.login);
      } catch (navError) {
      }

      Get.snackbar(
        'Logged Out',
        'You have been signed out locally',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      // CRITICAL: Reset global logout flag
      isLoggingOut.value = false;
    }
  }

  /// Alternative logout with custom navigation
  static Future<void> logoutWithNavigation(
      BuildContext context, String route) async {
    try {

      // Get session data FIRST
      final sessionId = _getStorage.read('sessionId');
      final userId = _getStorage.read('userId');
      final pushTargetId = _getStorage.read('push_target_id');
      final fcmToken = _getStorage.read('fcm_token');

      // AGGRESSIVELY delete FCM target
      if (!kIsWeb && pushTargetId != null && pushTargetId.isNotEmpty) {
        try {
          final appWriteProvider = Get.find<AppWriteProvider>();
          final deleted = await appWriteProvider.deletePushTarget(pushTargetId);
          if (deleted) {
          }
        } catch (e) {
        }
      }

      // Clear FCM token
      if (!kIsWeb && fcmToken != null) {
        try {
          final notificationService = Get.find<NotificationService>();
          await notificationService.clearToken();
        } catch (e) {
        }
      }

      // Do other cleanup
      if (Get.isRegistered<MessagingController>()) {
        final messagingController = Get.find<MessagingController>();
        try {
          if (sessionId != null && sessionId.isNotEmpty) {
            await messagingController.setUserOffline();
          }
        } catch (e) {
        }
        messagingController.clearAllData();
        Get.delete<MessagingController>();
      }

      if (userId != null && userId.isNotEmpty) {
        final serviceTag = 'reminder_$userId';

        if (Get.isRegistered<AppointmentReminderService>(tag: serviceTag)) {
          try {
            final reminderService =
                Get.find<AppointmentReminderService>(tag: serviceTag);
            reminderService.stopReminderService();
            Get.delete<AppointmentReminderService>(
                tag: serviceTag, force: true);
          } catch (e) {
          }
        }
      }

      if (Get.isRegistered<WebAppointmentController>()) {
        try {
          final appointmentController = Get.find<WebAppointmentController>();
          appointmentController.cleanupOnLogout();
          Get.delete<WebAppointmentController>(force: true);
        } catch (e) {
        }
      }

      if (Get.isRegistered<AdminDashboardController>()) {
        try {
          final dashboardController = Get.find<AdminDashboardController>();
          dashboardController.cleanupOnLogout();
          Get.delete<AdminDashboardController>(force: true);
        } catch (e) {
        }
      }

      // Logout from Appwrite
      if (sessionId != null && sessionId.isNotEmpty) {
        try {
          final appWriteProvider = Get.find<AppWriteProvider>();

          try {
            await appWriteProvider.account!.deleteSession(sessionId: sessionId);
          } catch (e) {
            try {
              await appWriteProvider.account!
                  .deleteSession(sessionId: 'current');
            } catch (e2) {
              if (!kIsWeb) {
                try {
                  await appWriteProvider.account!.deleteSessions();
                } catch (e3) {
                }
              }
            }
          }
        } catch (e) {
        }
      }

      // Clear session and storage
      if (Get.isRegistered<UserSessionService>()) {
        await Get.find<UserSessionService>().clearSession();
      }
      await _clearAllUserData();

      // Custom navigation
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
      }

    } catch (e) {
      await _clearAllUserData();
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
      }
    }
  }

  static Future<void> _clearAllUserData() async {
    final keys = [
      "userId",
      "sessionId",
      "role",
      "email",
      "userName",
      "clinicId",
      "staffId",
      "customerId",
      "userProfile",
      "lastLogin",
      "preferences",
      "userDocumentId",
      "userProfilePictureId",
      "push_target_id", // CRITICAL: Clear FCM target ID
      "fcm_token", // CRITICAL: Also clear FCM token
      "phone",
      "username",
      "authorities",
    ];

    for (String key in keys) {
      _getStorage.remove(key);
    }

  }

  // Utility getters
  static bool get isLoggedIn {
    final userId = _getStorage.read("userId");
    final role = _getStorage.read("role");
    return userId != null && role != null;
  }

  static String? get currentUserRole {
    return _getStorage.read("role");
  }

  static String? get currentUserId {
    return _getStorage.read("userId");
  }

  static String? get currentUserEmail {
    return _getStorage.read("email");
  }

  static String? get currentUserName {
    return _getStorage.read("userName");
  }
}
