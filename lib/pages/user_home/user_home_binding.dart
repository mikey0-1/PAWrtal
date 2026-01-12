import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/web/pages/web_user_home/web_user_home_controller.dart';
import 'package:get/get.dart';
import 'user_home_controller.dart';

class UserHomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<UserHomeController>(UserHomeController(Get.find<AuthRepository>()));
    Get.lazyPut<AuthRepository>(() => AuthRepository(AppWriteProvider()));
    Get.lazyPut<WebUserHomeController>(
      () => WebUserHomeController(),
    );  
  }
}