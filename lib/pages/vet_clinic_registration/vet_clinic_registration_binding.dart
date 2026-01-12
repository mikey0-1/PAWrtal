import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:get/get.dart';
import 'vet_clinic_registration_controller.dart';

class VetClinicRegistrationBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(VetClinicRegistrationController());
    Get.lazyPut<AuthRepository>(() => AuthRepository(AppWriteProvider()));  
  }
}