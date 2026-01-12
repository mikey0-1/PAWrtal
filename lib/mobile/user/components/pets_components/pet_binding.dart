import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:get/get.dart';

import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'pet_creation_controller.dart';

class PetBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PetCreationController>(
      () => PetCreationController(AuthRepository(AppWriteProvider())),
    );
  }
}