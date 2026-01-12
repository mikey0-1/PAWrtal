import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/web/admin_web/components/appbar/admin_change_pass_controller.dart';
import 'package:capstone_app/web/pages/web_admin_home/web_admin_home_controller.dart';
import 'package:capstone_app/web/responsive_layout.dart';
import 'package:capstone_app/web/admin_web/layouts/desktop/admin_desktop_home_page.dart';
import 'package:capstone_app/web/admin_web/layouts/tablet/admin_tablet_home_page.dart';
import 'package:capstone_app/web/admin_web/layouts/mobile/admin_mobile_home_page.dart';
import 'package:capstone_app/web/admin_web/components/staffs/data/permission_guard.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class WebAdminHomePage extends GetView<WebAdminHomeController> {
  const WebAdminHomePage({super.key});

  // Wrap a page with permission guard if needed
  Widget _wrapWithPermissionGuard(Widget page, int index) {
    // Home page (index 0) doesn't need permission check
    if (index == 0) return page;

    // Admin has full access to everything
    if (controller.isAdmin) return page;

    // Staff users - check if they have permission for this page
    final pageName = controller.navigationLabels[index];
    final hasPermission = controller.hasAuthority(pageName);

    return PermissionGuard(
      hasPermission: hasPermission,
      requiredPermission: pageName,
      child: page,
    );
  }

  void _checkPasswordChangeRequired() async {
    // Only check once per session
    if (Get.find<GetStorage>().read('passwordCheckDone') == true) {
      return;
    }

    final shouldPrompt = await controller.shouldPromptPasswordChange();

    if (shouldPrompt) {
      // Mark as checked for this session
      Get.find<GetStorage>().write('passwordCheckDone', true);

      // Show password change prompt dialog
      _showPasswordChangePrompt();
    }
  }

  void _showChangePasswordDialogFromPrompt() {
    final changePasswordController = Get.put(
      AdminChangePasswordController(Get.find<AuthRepository>()),
      tag: 'admin_change_password_prompt',
    );
    changePasswordController.clearFields();

    showDialog(
      context: Get.context!,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return _buildPasswordChangeDialog(
          dialogContext: dialogContext,
          controller: changePasswordController,
          isFromPrompt: true,
        );
      },
    );
  }

  Widget _buildPasswordChangeDialog({
    required BuildContext dialogContext,
    required AdminChangePasswordController controller,
    required bool isFromPrompt,
  }) {
    final isMobile = MediaQuery.of(dialogContext).size.width < 768;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: PopScope(
        canPop: !isFromPrompt, // If from prompt, prevent back button close
        onPopInvokedWithResult: (bool didPop, Object? result) async {
          if (!didPop && !isFromPrompt) {
            if (controller.hasUnsavedChanges()) {
              final shouldDiscard =
                  await _showDiscardChangesDialog(dialogContext);
              if (shouldDiscard == true) {
                controller.clearFields();
                Navigator.of(dialogContext).pop();
              }
            } else {
              controller.clearFields();
              Navigator.of(dialogContext).pop();
            }
          }
        },
        child: Container(
          width: isMobile ? double.infinity : 550,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(dialogContext).size.height * 0.9,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Form(
            key: controller.formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPasswordDialogHeader(
                      dialogContext, controller, isFromPrompt),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildErrorMessage(controller),
                        _buildCurrentPasswordField(controller),
                        const SizedBox(height: 24),
                        _buildNewPasswordField(controller),
                        const SizedBox(height: 24),
                        _buildConfirmPasswordField(controller),
                        const SizedBox(height: 32),
                        _buildDialogActions(
                            dialogContext, controller, isFromPrompt),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordDialogHeader(
    BuildContext dialogContext,
    AdminChangePasswordController controller,
    bool isFromPrompt,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.lock_reset, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Change Password',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  isFromPrompt
                      ? 'Set a secure password for your account'
                      : 'Create a strong, secure password',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          if (!isFromPrompt)
            IconButton(
              onPressed: () async {
                if (controller.hasUnsavedChanges()) {
                  final shouldDiscard =
                      await _showDiscardChangesDialog(dialogContext);
                  if (shouldDiscard == true) {
                    controller.clearFields();
                    Navigator.of(dialogContext).pop();
                  }
                } else {
                  controller.clearFields();
                  Navigator.of(dialogContext).pop();
                }
              },
              icon: const Icon(Icons.close, color: Colors.white),
            ),
        ],
      ),
    );
  }

  Widget _buildDialogActions(
    BuildContext dialogContext,
    AdminChangePasswordController controller,
    bool isFromPrompt,
  ) {
    return Row(
      children: [
        if (!isFromPrompt)
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                if (controller.hasUnsavedChanges()) {
                  final shouldDiscard =
                      await _showDiscardChangesDialog(dialogContext);
                  if (shouldDiscard == true) {
                    controller.clearFields();
                    Navigator.of(dialogContext).pop();
                  }
                } else {
                  controller.clearFields();
                  Navigator.of(dialogContext).pop();
                }
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey[400]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        if (!isFromPrompt) const SizedBox(width: 16),
        Expanded(
          child: Obx(() => ElevatedButton(
                onPressed: controller.isLoading.value
                    ? null
                    : () async {
                        final success = await controller.changePassword();
                        if (success) {
                          // Mark password as changed in database
                          final clinicId = Get.find<GetStorage>()
                              .read('clinicId') as String?;
                          if (clinicId != null) {
                            await controller.markPasswordAsChanged(clinicId);
                          }

                          Navigator.of(dialogContext).pop();
                          _showPasswordChangeSuccessDialog(isFromPrompt);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: controller.isLoading.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Change Password',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              )),
        ),
      ],
    );
  }

  void _showPasswordChangeSuccessDialog(bool wasFromPrompt) {
    Get.dialog(
      barrierDismissible: false,
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(Get.context!).size.width < 768
              ? double.infinity
              : 400,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[400]!, Colors.green[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: Colors.white,
                        size: 64,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Text(
                      'Password Changed!',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      wasFromPrompt
                          ? 'Your account is now secured with your new password. You can use it for future logins.'
                          : 'Your password has been successfully changed. You can now use your new password to sign in.',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Get.back(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Got it',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPasswordChangePrompt() {
    Get.dialog(
      barrierDismissible: false,
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(Get.context!).size.width < 768
              ? double.infinity
              : 500,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange[400]!, Colors.orange[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.security,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Security Notice',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Action required for account security',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange[700],
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'You are currently using an auto-generated password. For security reasons, please change your password now.',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'This is a one-time security setup. You will need to create a strong, unique password for your account.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Get.back(); // Close prompt
                          _showChangePasswordDialogFromPrompt();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[600],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_reset, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Change Password Now',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _showDiscardChangesDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        final isMobile = MediaQuery.of(context).size.width < 768;

        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: isMobile ? double.infinity : 400,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Warning Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange[400]!, Colors.orange[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.warning_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Discard Changes?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Your progress will be lost',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.orange[700],
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'You have unsaved changes. Are you sure you want to discard them?',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(false),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey[400]!),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text(
                                'Keep Editing',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange[600],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Discard',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorMessage(AdminChangePasswordController controller) {
    return Obx(() {
      if (controller.errorMessage.value.isEmpty) {
        return const SizedBox.shrink();
      }
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[700], size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                controller.errorMessage.value,
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, size: 18, color: Colors.red[700]),
              onPressed: () => controller.errorMessage.value = '',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildCurrentPasswordField(AdminChangePasswordController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Current Password',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() => TextFormField(
              controller: controller.currentPasswordController,
              obscureText: !controller.isCurrentPasswordVisible.value,
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'Enter your current password',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[600]),
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.isCurrentPasswordVisible.value
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.grey[600],
                  ),
                  onPressed: controller.toggleCurrentPasswordVisibility,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              validator: controller.validateCurrentPassword,
            )),
      ],
    );
  }

  Widget _buildNewPasswordField(AdminChangePasswordController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'New Password',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() => TextFormField(
              controller: controller.newPasswordController,
              obscureText: !controller.isNewPasswordVisible.value,
              style: const TextStyle(color: Colors.black87),
              onChanged: (value) => controller.checkPasswordRequirements(value),
              decoration: InputDecoration(
                hintText: 'Enter your new password',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[600]),
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.isNewPasswordVisible.value
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.grey[600],
                  ),
                  onPressed: controller.toggleNewPasswordVisibility,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              validator: controller.validateNewPassword,
            )),
        const SizedBox(height: 16),
        _buildPasswordStrengthIndicator(controller),
      ],
    );
  }

  Widget _buildConfirmPasswordField(AdminChangePasswordController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Confirm New Password',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() => TextFormField(
              controller: controller.confirmPasswordController,
              obscureText: !controller.isConfirmPasswordVisible.value,
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'Re-enter your new password',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[600]),
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.isConfirmPasswordVisible.value
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.grey[600],
                  ),
                  onPressed: controller.toggleConfirmPasswordVisibility,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              validator: controller.validateConfirmPassword,
            )),
      ],
    );
  }

  Widget _buildPasswordStrengthIndicator(
      AdminChangePasswordController controller) {
    return Obx(() {
      // Read observables first
      final hasMinLength = controller.hasMinLength.value;
      final hasUpperCase = controller.hasUpperCase.value;
      final hasNumber = controller.hasNumber.value;
      final hasSpecialChar = controller.hasSpecialChar.value;

      // Check if password is empty
      final passwordText = controller.newPasswordController.text;
      if (passwordText.isEmpty) {
        return const SizedBox.shrink();
      }

      // Get strength values
      final strength = controller.getPasswordStrength();
      final strengthColor = controller.getPasswordStrengthColor();
      final strengthLabel = controller.getPasswordStrengthLabel();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: strength / 4,
                    backgroundColor: Colors.grey[200],
                    color: strengthColor,
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                strengthLabel,
                style: TextStyle(
                  color: strengthColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Password Requirements:',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _buildPasswordRequirement(
                    'At least 8 characters', hasMinLength),
                const SizedBox(height: 8),
                _buildPasswordRequirement(
                    'One uppercase letter (A-Z)', hasUpperCase),
                const SizedBox(height: 8),
                _buildPasswordRequirement('One number (0-9)', hasNumber),
                const SizedBox(height: 8),
                _buildPasswordRequirement(
                    'One special character (!@#\$%^&*)', hasSpecialChar),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildPasswordRequirement(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.cancel,
          size: 16,
          color: isMet ? Colors.green : Colors.grey[400],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: isMet ? Colors.green[700] : Colors.grey[600],
              fontSize: 12,
              fontWeight: isMet ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Debug print to verify controller initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.debugPrintState();

      _checkPasswordChangeRequired();
    });

    return Scaffold(
      body: ResponsiveLayout(
        desktopBody: () => Obx(() {
          final selectedIndex = controller.selectedIndex.value;

          return AdminDesktopHomePage(
            selectedIndex: selectedIndex,
            onItemSelected: controller.setSelectedIndex,
            canAccessStaffs:
                true, // Always true now, handled by permission guard
          );
        }),
        tabletBody: () => Obx(() {
          final selectedIndex = controller.selectedIndex.value;

          return AdminTabletHomePage(
            selectedIndex: selectedIndex,
            onItemSelected: controller.setSelectedIndex,
            canAccessStaffs:
                true, // Always true now, handled by permission guard
          );
        }),
        mobileBody: () => Obx(() {
          final selectedIndex = controller.selectedIndex.value;

          return AdminMobileHomePage(
            selectedIndex: selectedIndex,
            onItemSelected: controller.setSelectedIndex,
            canAccessStaffs:
                true, // Always true now, handled by permission guard
          );
        }),
      ),
    );
  }
}
