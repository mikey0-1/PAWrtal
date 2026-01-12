import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/pages/landing/landing_controller.dart';
import 'package:capstone_app/utils/session_redirect_helper.dart';
import 'package:get/get.dart';

class LandingBinding extends Bindings {
  @override
  void dependencies() {
    // CHECK SESSION FIRST - Redirect if user is already logged in
    SessionRedirectHelper.checkAndRedirect(pageName: 'LANDING');

    // Register dependencies if not already registered
    if (!Get.isRegistered<AppWriteProvider>()) {
      Get.lazyPut<AppWriteProvider>(() => AppWriteProvider());
    }
    
    if (!Get.isRegistered<AuthRepository>()) {
      Get.lazyPut<AuthRepository>(() => AuthRepository(Get.find<AppWriteProvider>()));
    }

    // Register landing controller
    Get.lazyPut<LandingController>(() => LandingController(Get.find<AuthRepository>()));
  }
}