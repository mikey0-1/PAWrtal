import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../routes/app_pages.dart';

class SplashController extends GetxController {
  SplashController(AuthRepository authRepository);

  final GetStorage _getStorage = GetStorage();

  @override
  void onReady() async {
    super.onReady();
    await Future.delayed(const Duration(seconds: 2));

    final userId = _getStorage.read("userId");
    final sessionId = _getStorage.read("sessionId");
    final role = _getStorage.read("role");


    // Check if user has a valid session
    if (userId != null && sessionId != null && role != null) {
      
      // Route based on role
      switch (role) {
        case "admin":
          Get.offAllNamed(Routes.adminHome);
          break;
        case "staff":
          Get.offAllNamed(Routes.adminHome);
          break;
        case "developer":
          Get.offAllNamed(Routes.superAdminHome);
          break;
        case "user":
          Get.offAllNamed(Routes.userHome);
          break;
        default:
          Get.offAllNamed(Routes.landing);
          break;
      }
    } else {
      Get.offAllNamed(Routes.landing);
    }

  }
}