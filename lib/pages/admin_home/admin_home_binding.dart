import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:get/get.dart';
import 'admin_home_controller.dart';

class AdminHomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<AdminHomeController>(AdminHomeController(Get.find<AuthRepository>()));
    Get.lazyPut<AuthRepository>(() => AuthRepository(AppWriteProvider()));  
  }
}