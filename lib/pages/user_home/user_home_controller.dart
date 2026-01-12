import 'package:appwrite/appwrite.dart';
import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/pages/routes/app_pages.dart';
import 'package:capstone_app/utils/custom_snack_bar.dart';
import 'package:capstone_app/utils/full_screen_dialog_loader.dart';
import 'package:capstone_app/utils/logout_helper.dart';
import 'package:capstone_app/utils/snackbar_helper.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class UserHomeController extends GetxController {
  AuthRepository authRepository;
  UserHomeController(this.authRepository);

  final GetStorage _getStorage = GetStorage();

  /// IMPROVED: Use LogoutHelper for consistent logout across the app
  logout() async {
    try {
      
      // CRITICAL DEBUG: Check session BEFORE calling LogoutHelper
      try {
        final appWriteProvider = Get.find<AppWriteProvider>();
        final user = await appWriteProvider.account!.get();
      } catch (e) {
      }
      
      // Use the centralized logout helper
      await LogoutHelper.logout();
    } catch (e) {

      // Fallback: Force local logout
      try {
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }

        await _getStorage.erase();
        Get.offAllNamed(Routes.login);

        SnackbarHelper.showError(
            context: Get.overlayContext,
            title: "Logged Out",
            message: "You have been signed out locally");
      } catch (fallbackError) {
      }
    }
  }

  /// DEPRECATED: Old logout method (kept for backward compatibility)
  /// This is no longer used - logout() now calls LogoutHelper.logout()
  _legacyLogout() async {
    try {
      FullScreenDialogLoader.showDialog();
      await authRepository.logout(_getStorage.read("sessionId")).then((value) {
        FullScreenDialogLoader.cancelDialog();
        _getStorage.erase();
        Get.offAllNamed(Routes.login);
      }).catchError((error) {
        FullScreenDialogLoader.cancelDialog();
        if (error is AppwriteException) {
          final message = error.response ?? "An error occurred";
          SnackbarHelper.showError(
              context: Get.overlayContext, title: "Error", message: message);
        } else {
          SnackbarHelper.showError(
              context: Get.overlayContext,
              title: "Error",
              message: "Something went wrong");
        }
      });
    } catch (e) {
      FullScreenDialogLoader.cancelDialog();
      SnackbarHelper.showError(
          context: Get.overlayContext,
          title: "Error",
          message: "Something went wrong");
    }
  }
}