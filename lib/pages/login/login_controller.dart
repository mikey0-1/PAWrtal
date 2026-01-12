import 'package:appwrite/appwrite.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/notification/services/in_app_notification_service.dart';
import 'package:capstone_app/notification/services/notification_preferences_service.dart';
import 'package:capstone_app/pages/routes/app_pages.dart';
import 'package:capstone_app/utils/custom_snack_bar.dart';
import 'package:capstone_app/utils/full_screen_dialog_loader.dart';
import 'package:capstone_app/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:capstone_app/data/models/staff_model.dart';
import 'package:capstone_app/utils/mobile_oauth_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:capstone_app/notification/services/notification_service.dart';
import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/notification/services/appointment_reminder_service.dart';
import 'package:capstone_app/utils/session_manager.dart';
import 'package:capstone_app/utils/security_monitor.dart';

class LoginController extends GetxController {
  AuthRepository authRepository;
  LoginController(this.authRepository);

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  TextEditingController emailEditingController = TextEditingController();
  TextEditingController passwordEditingController = TextEditingController();
  TextEditingController emailForPasswordResetController =
      TextEditingController();

  bool isFormValid = false;

  final GetStorage _getStorage = GetStorage();

  // Observable for password visibility
  final isPasswordVisible = false.obs;

  // Observable for error message
  final errorMessage = ''.obs;

  // NEW: Observable for Google Sign-In loading
  final isGoogleLoading = false.obs;

  @override
  void onClose() {
    super.onClose();
    emailEditingController.dispose();
    passwordEditingController.dispose();
    emailForPasswordResetController.dispose();
  }

  void clearTextEditingControllers() {
    emailEditingController.clear();
    passwordEditingController.clear();
    errorMessage.value = '';
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  // REMOVED: Old validateEmail method - no longer needed

  /// Validator for username or email - accepts both formats
  /// Just checks: not empty and max 50 characters
  String? validateEmailOrUsername(String value) {
    // Check length limit (50 characters)
    if (value.length > 50) {
      return "Maximum 50 characters allowed";
    }

    // That's it! No format validation - let the database check handle it
    return null;
  }

  /// Password validator with 50 character limit
  String? validatePassword(String value) {
    if (value.isEmpty) {
      return "Please enter your password";
    }

    return null;
  }

  /// Login method - accepts username or email
  /// Shows "Invalid username/email or password" for any login failure
  void validateAndLogin({
    required String emailOrUsername,
    required String password,
  }) async {
    // Clear any previous error
    errorMessage.value = '';

    // Trim inputs
    emailOrUsername = emailOrUsername.trim();
    password = password.trim();

    isFormValid = formKey.currentState!.validate();
    if (!isFormValid) return;

    String? sessionId;

    try {
      formKey.currentState!.save();
      FullScreenDialogLoader.showDialog();

      _clearExistingControllers();

      // Check if input is username or email
      final isEmail = emailOrUsername.contains('@');

      if (!isEmail) {
        // It's a username - check if staff account exists first in database
        final staffDoc =
            await authRepository.getStaffByUsername(emailOrUsername);

        if (staffDoc == null) {
          FullScreenDialogLoader.cancelDialog();
          errorMessage.value =
              'Invalid username/email or password. Please check your credentials.';
          return;
        }

        if (!staffDoc.isActive) {
          FullScreenDialogLoader.cancelDialog();
          errorMessage.value =
              'Your account has been deactivated. Please contact your administrator.';
          return;
        }
      } else {}

      // Attempt authentication
      final value = await authRepository.login({
        "email": emailOrUsername,
        "password": password,
      });

      final session = value["session"];
      if (session == null) {
        throw Exception("Login failed: Session data is missing");
      }

      sessionId = session.$id;
      final userId = session.userId;

      final user = value["user"];
      if (user == null) {
        throw Exception("Login failed: User data is missing");
      }
      final userEmail = user.email;

      _getStorage.write("userId", userId);
      _getStorage.write("sessionId", session.$id);

      String role = "";
      bool matched = false;

      // Step 1: Check if account is ADMIN
      final clinicDoc = await authRepository.getClinicByAdminId(userId);
      if (clinicDoc != null) {
        role = clinicDoc.data["role"];
        _getStorage.write("clinicId", clinicDoc.$id);
        _getStorage.write("userName", clinicDoc.data["createdBy"] ?? user.name);
        matched = true;
      } else {}

      // Step 2: Check if account is STAFF
      if (!matched) {
        // Try by userId first
        var staff = await authRepository.getStaffByUserId(userId);

        // If not found, try by username (catches userId mismatches)
        if (staff == null && !isEmail) {
          staff = await authRepository.getStaffByUsername(emailOrUsername);

          // Auto-fix userId if found by username
          if (staff != null) {
            await _autoFixStaffUserId(staff, userId);
          }
        } else if (staff != null) {}

        if (staff != null) {
          role = staff.role;
          _getStorage.write("staffId", staff.documentId);
          _getStorage.write("clinicId", staff.clinicId);
          _getStorage.write("authorities", staff.authorities);
          _getStorage.write("userName", staff.name);
          _getStorage.write("username", staff.username);
          matched = true;
        } else {}
      }

      // Step 3: Check if CUSTOMER
      if (!matched) {
        final userDoc = await authRepository.getUserById(userId);
        if (userDoc != null) {
          role = userDoc.data["role"];
          _getStorage.write("customerId", userDoc.$id);
          _getStorage.write(
              "userDocumentId", userDoc.$id); // ✅ Store document ID
          _getStorage.write("userName", user.name);

          // ✅✅ ADD THESE TWO LINES ✅✅
          final phone = userDoc.data["phone"] as String?;
          _getStorage.write("phone", phone ?? "");

          // ✅✅ ALSO STORE PROFILE PICTURE ID ✅✅
          final profilePictureId = userDoc.data["profilePictureId"] as String?;
          _getStorage.write("userProfilePictureId", profilePictureId ?? "");

          matched = true;
          // ✅ Log it
          // ✅ Log it
        } else {}
      }

      // Step 4: Check if DEVELOPER
      if (!matched &&
          (userEmail == "test.developer@gmail.com" ||
              userEmail == "super.developer@gmail.com")) {
        role = "developer";
        _getStorage.write("userName", user.name);
        matched = true;
      }

      // If no role matched, deny access
      if (!matched) {
        if (sessionId != null) {
          await authRepository.logout(sessionId);
        }

        FullScreenDialogLoader.cancelDialog();
        errorMessage.value =
            'Invalid username/email or password. Please try again.';
        return;
      }

      _getStorage.write("role", role);
      _getStorage.write("email", userEmail);

      _initializeSecureSession(userId, role);

      // Initialize appointment reminder service (ONLY for regular users)
      if (role == "user") {
        await authRepository.syncAuthNameOnLogin(user.$id);
        try {

          // Create user-specific reminder service instance
          final reminderService = AppointmentReminderService(
            authRepository: authRepository,
            notificationPrefsService:
                Get.find<NotificationPreferencesService>(),
            appWriteProvider: Get.find<AppWriteProvider>(),
            userId: userId, // ✅ Pass the logged-in user's ID
          );

          // Register it in GetX with user-specific tag
          Get.put(
            reminderService,
            tag: 'reminder_$userId', // ✅ User-specific tag
          );

          // Start the service
          reminderService.startReminderService();

        } catch (e) {
          // Don't fail login if reminder service fails
        }
      }

      // Register FCM token for push notifications (Mobile only)

      try {
        // Only register FCM on mobile platforms
        if (!kIsWeb) {
          final notificationService = Get.find<NotificationService>();

          // Request permissions
          final hasPermission = await notificationService.requestPermissions();

          if (hasPermission) {
            // Get FCM token
            final fcmToken = await notificationService.getFreshToken();

            if (fcmToken != null && fcmToken.isNotEmpty) {
              // Get AppwriteProvider instance
              final appwriteProvider = Get.find<AppWriteProvider>();

              // Register with Appwrite
              final target = await appwriteProvider.registerUserPushTarget(
                userId: userId,
                fcmToken: fcmToken,
              );

              if (target != null) {
                _getStorage.write('push_target_id', target.$id);
              } else {}
            } else {}
          } else {}
        } else {}
      } catch (e) {
        // Don't fail login if FCM registration fails
      }

      // Initialize in-app notification service
      try {
        final notificationService = Get.find<InAppNotificationService>();
        await notificationService.initialize();
      } catch (e) {}

      FullScreenDialogLoader.cancelDialog();
      SnackbarHelper.showSuccess(
          context: Get.overlayContext,
          title: "Success",
          message: "Login Successful");

      clearTextEditingControllers();

      // Route by role
      if (role == "admin") {
        Get.offAllNamed(Routes.adminHome);
      } else if (role == "developer") {
        Get.offAllNamed(Routes.superAdminHome);
      } else if (role == "staff") {
        Get.offAllNamed(Routes.adminHome);
      } else {
        Get.offAllNamed(Routes.userHome);
      }
    } catch (e) {
      if (sessionId != null) {
        try {
          await authRepository.logout(sessionId);
        } catch (logoutError) {}
      }

      FullScreenDialogLoader.cancelDialog();

      // UNIFIED ERROR MESSAGE: Always show this for any login error
      errorMessage.value =
          'Invalid username/email or password. Please check your credentials.';

    }
  }

  Future<void> _autoFixStaffUserId(Staff staff, String correctUserId) async {
    if (staff.userId != correctUserId) {
      try {
        await authRepository.fixStaffUserId(staff.documentId!, correctUserId);
        staff.userId = correctUserId;
      } catch (e) {}
    }
  }

  Future<void> signInWithGoogle() async {
    if (isGoogleLoading.value) return;

    try {
      isGoogleLoading.value = true;
      errorMessage.value = '';

      if (kIsWeb) {
        final appWriteProvider = Get.find<AppWriteProvider>();
        await appWriteProvider.signInWithGoogle();
      } else {
        // Use the mobile OAuth handler which uses Appwrite SDK's createOAuth2Session
        final success = await MobileOAuthHandler.initiateGoogleOAuth();

        if (!success) {
          isGoogleLoading.value = false;
          errorMessage.value =
              'Google Sign-In failed. Please try again or use email/password.';
        }
      }
      // If success, the handler will navigate to userHome automatically
    } catch (e) {
      isGoogleLoading.value = false;
      errorMessage.value =
          'Google Sign-In failed. Please try again or use email/password.';
    }
  }

  void moveToSignUp() {
    clearTextEditingControllers();
    Get.toNamed(Routes.signup);
  }

  void _initializeSecureSession(String userId, String role) {
    // Store session timestamp
    _getStorage.write('sessionTimestamp', DateTime.now().toIso8601String());

    // Start session monitoring
    // SessionManager.startSessionMonitoring();

    // Log successful login event
    SecurityMonitor.logSecurityEvent(
      eventType: 'LOGIN_SUCCESS',
      userId: userId,
      details: 'Role: $role',
    );

    // Clean up old security data periodically
    // SessionManager.cleanupOldData();
  }

  Future<void> sendPasswordResetEmail() async {
    try {
      final email = emailForPasswordResetController.text.trim();

      if (email.isEmpty) {
        Get.snackbar(
          'Error',
          'Please enter your email address',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
        );
        return;
      }

      // Validate email format
      if (!GetUtils.isEmail(email)) {
        Get.snackbar(
          'Error',
          'Please enter a valid email address',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
        );
        return;
      }

      // Show loading
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // Call repository method
      final result = await authRepository.sendPasswordResetEmail(email);

      // Hide loading
      Get.back();

      if (result['success'] == true) {
        // Clear the email field
        emailForPasswordResetController.clear();

        Get.snackbar(
          'Success',
          result['message'] ?? 'Password reset link sent to your email',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade900,
          duration: const Duration(seconds: 5),
        );
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? 'Failed to send password reset email',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
        );
      }
    } catch (e) {
      // Hide loading if still showing
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      Get.snackbar(
        'Error',
        'An error occurred. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
    }
  }

  void _clearExistingControllers() {
    try {
      // Delete AdminDashboardController if it exists
      if (Get.isRegistered<dynamic>(tag: 'AdminDashboardController')) {
        Get.delete<dynamic>(tag: 'AdminDashboardController', force: true);
      }

      // Try to delete by finding it
      try {
        Get.delete(force: true);
      } catch (e) {
        // Ignore if not found
      }
    } catch (e) {
      // Continue anyway - not critical
    }
  }
}
