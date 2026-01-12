import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:capstone_app/data/models/staff_model.dart';
import 'package:get_storage/get_storage.dart';

class StaffAuthController extends GetxController {
  final AuthRepository authRepository;
  final UserSessionService userSession;
  final GetStorage _getStorage = GetStorage();

  StaffAuthController({
    required this.authRepository,
    required this.userSession,
  });

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool obscurePassword = true.obs;
  final RxString errorMessage = ''.obs;

  Rx<Staff?> currentStaff = Rx<Staff?>(null);
  RxList<String> staffAuthorities = <String>[].obs;

  // Store session data in the controller
  final RxString sessionId = ''.obs;
  final RxString clinicId = ''.obs;
  final RxString staffDocId = ''.obs;

  final RxBool isDoctor = false.obs;

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  Future<void> login() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      errorMessage.value = 'Please enter email and password';
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {

      final result = await authRepository.staffLogin(
        emailController.text.trim(),
        passwordController.text,
      );


      if (result['success'] != true) {
        errorMessage.value = result['message'] ?? 'Login failed';
        throw Exception(errorMessage.value);
      }

      // Store session data
      sessionId.value = result['session'].$id;
      clinicId.value = result['clinicId'] ?? '';

      // Store staff data
      final staffDoc = result['staffDoc'];
      final staff = Staff.fromMap(staffDoc.data);
      staff.documentId = staffDoc.$id;

      currentStaff.value = staff;
      staffAuthorities.value = List<String>.from(result['authorities'] ?? []);
      staffDocId.value = staff.documentId!;

      isDoctor.value = staff.isDoctor;
      _getStorage.write('isDoctor', staff.isDoctor);


      // CRITICAL: Store data in GetStorage for persistence
      _getStorage.write('role', 'staff');
      _getStorage.write('sessionId', sessionId.value);
      _getStorage.write('userId', staff.userId);
      _getStorage.write('userName', staff.name);
      _getStorage.write('email', staff.email);
      _getStorage.write('clinicId', clinicId.value);
      _getStorage.write('staffDocId', staffDocId.value);
      _getStorage.write('authorities', staffAuthorities);


      Get.snackbar(
        'Success',
        'Welcome back, ${staff.name}!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
        duration: const Duration(seconds: 2),
      );

      // Navigate to staff dashboard
      await Future.delayed(const Duration(milliseconds: 500));
      Get.offAllNamed('/adminHome'); // Staff and admin share the same home
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');

      Get.snackbar(
        'Login Failed',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadStaffData() async {
    try {
      // Try to load from GetStorage first
      final storedRole = _getStorage.read('role');
      final storedUserId = _getStorage.read('userId');


      if (storedRole == 'staff' && storedUserId != null) {
        final staff = await authRepository.getStaffByUserId(storedUserId);

        if (staff != null) {
          currentStaff.value = staff;
          staffAuthorities.value = staff.authorities;
          clinicId.value = staff.clinicId;
          staffDocId.value = staff.documentId ?? '';
          isDoctor.value = staff.isDoctor;

        }
      }
    } catch (e) {
    }
  }

  bool isDoctorStaff() {
    return isDoctor.value;
  }

  bool canCompleteMedicalAppointments() {
    return isDoctor.value;
  }

  bool canViewMedicalServices() {
    // All staff can view, but only doctors can complete
    return true;
  }

  bool hasAuthority(String authority) {
    final result = staffAuthorities.contains(authority);
    return result;
  }

  bool hasAnyAuthority(List<String> authorities) {
    return authorities.any((auth) => staffAuthorities.contains(auth));
  }

  bool hasAllAuthorities(List<String> authorities) {
    return authorities.every((auth) => staffAuthorities.contains(auth));
  }

  Future<void> logout() async {
    try {
      final logoutSessionId =
          sessionId.value.isNotEmpty ? sessionId.value : 'current';

      await authRepository.logout(logoutSessionId);

      // Clear controller state
      currentStaff.value = null;
      staffAuthorities.clear();
      sessionId.value = '';
      clinicId.value = '';
      staffDocId.value = '';
      isDoctor.value = false;

      // Clear GetStorage
      _getStorage.erase();

      Get.offAllNamed('/login');

      Get.snackbar(
        'Logged Out',
        'You have been logged out successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
    } catch (e) {
    }
  }
}
