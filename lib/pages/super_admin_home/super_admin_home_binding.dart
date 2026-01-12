import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:get/get.dart';
import 'super_admin_home_controller.dart';

class SuperAdminHomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<SuperAdminHomeController>(SuperAdminHomeController(Get.find<AuthRepository>()));
    Get.lazyPut<AuthRepository>(() => AuthRepository(AppWriteProvider()));  
  }
}