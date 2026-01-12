import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:get/get.dart';

import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'staff_account_controller.dart';

class CreateStaffBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CreateStaffController>(
      () => CreateStaffController(AuthRepository(AppWriteProvider())),
    );
  }
}