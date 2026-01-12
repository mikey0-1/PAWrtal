import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/session_redirect_helper.dart';
import 'package:get/get.dart';
import 'login_controller.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    SessionRedirectHelper.checkAndRedirect(pageName: 'LOGIN');
    Get.lazyPut<AuthRepository>(() => AuthRepository(AppWriteProvider()));
    Get.lazyPut(() => LoginController(Get.find<AuthRepository>()));
  }
}
