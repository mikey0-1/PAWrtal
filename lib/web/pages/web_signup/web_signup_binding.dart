import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/session_redirect_helper.dart';
import 'package:capstone_app/web/pages/web_signup/web_signup_controller.dart';
import 'package:get/get.dart';

class WebSignUpBinding extends Bindings {
  @override
  void dependencies() {
    SessionRedirectHelper.checkAndRedirect(pageName: 'SIGNUP');

    if (!Get.isRegistered<AuthRepository>()) {
      Get.lazyPut<AuthRepository>(() => AuthRepository(AppWriteProvider()));
    }

    Get.lazyPut<WebSignUpController>(
      () => WebSignUpController(Get.find<AuthRepository>()),
    );
  }
}