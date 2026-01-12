import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/logout_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class WebSuperAdminHomeController extends GetxController {
  final AuthRepository _authRepository;
  WebSuperAdminHomeController(this._authRepository);

  final GetStorage _getStorage = GetStorage();
  final isLoggingOut = false.obs;
  final selectedMenuIndex = 0.obs;

  String get userName {
    return _getStorage.read("userName") ?? "Developer";
  }

  String get userEmail {
    return _getStorage.read("email") ?? "";
  }

  Future<void> logout() async {
    try {
      isLoggingOut.value = true;
      await LogoutHelper.logout();
    } catch (e) {
      Get.snackbar(
        'Error',
        'An error occurred during logout: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoggingOut.value = false;
    }
  }

  // Navigation methods for super admin features
  void navigateToVetClinics() {
    selectedMenuIndex.value = 0;
    Get.snackbar(
      'Info',
      'Vet Clinics Management',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }

  void navigateToPetOwners() {
    selectedMenuIndex.value = 1;
    Get.snackbar(
      'Info',
      'Pet Owners Management',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }

  void navigateToReports() {
    selectedMenuIndex.value = 2;
    Get.snackbar(
      'Info',
      'Reports and Analytics',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }

  void navigateToSettings() {
    Get.snackbar(
      'Info',
      'System Settings',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }
}
