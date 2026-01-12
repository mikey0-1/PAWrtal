import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/data/models/medical_record_model.dart';
import 'package:capstone_app/data/models/vaccination_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:get/get.dart';

class AdminPetCardViewController extends GetxController {
  final AuthRepository authRepository;

  AdminPetCardViewController({required this.authRepository});

  // Observable data
  final Rx<Pet?> currentPet = Rx<Pet?>(null);
  final RxList<MedicalRecord> medicalRecords = <MedicalRecord>[].obs;
  final RxList<Vaccination> vaccinations = <Vaccination>[].obs;
  final RxList<Map<String, dynamic>> medicalAppointments =
      <Map<String, dynamic>>[].obs;

  // Loading states
  final RxBool isLoadingMedicalRecords = false.obs;
  final RxBool isLoadingVaccinations = false.obs;
  final RxBool isLoadingMedicalAppointments = false.obs;

  final RxString currentClinicId = ''.obs;

  // Cache for vet/staff names
  final RxMap<String, String> vetNamesCache = <String, String>{}.obs;

  Future<void> loadPetData(Pet pet, String clinicId) async {
    currentPet.value = pet;
    currentClinicId.value = clinicId;


    // Fetch ALL data immediately in parallel
    await Future.wait([
      fetchPetMedicalRecords(pet.petId),
      fetchPetVaccinations(pet.petId),
      fetchPetMedicalAppointmentsByClinic(pet.petId, clinicId),
    ]);

  }

  Future<void> fetchPetMedicalAppointmentsByClinic(
    String petId,
    String clinicId,
  ) async {
    isLoadingMedicalAppointments.value = true;
    try {

      final appointments = await authRepository
          .getPetMedicalAppointmentsByClinic(petId, clinicId);

      medicalAppointments.value = appointments;


      if (appointments.isNotEmpty) {
      }
    } catch (e) {
      medicalAppointments.clear();
    } finally {
      isLoadingMedicalAppointments.value = false;
    }
  }

  Future<void> fetchPetMedicalRecords(String petId) async {
    isLoadingMedicalRecords.value = true;
    try {

      final records = await authRepository.getPetMedicalRecords(petId);
      medicalRecords.value = records;


      if (records.isNotEmpty) {
        for (var record in records) {
        }
      }
    } catch (e, stackTrace) {
      medicalRecords.clear();
    } finally {
      isLoadingMedicalRecords.value = false;
    }
  }

  Future<void> fetchPetVaccinations(String petId) async {
    isLoadingVaccinations.value = true;
    try {

      final vaccins = await authRepository.getPetVaccinations(petId);
      vaccinations.value = vaccins;


      if (vaccins.isNotEmpty) {
      }
    } catch (e) {
      vaccinations.clear();
    } finally {
      isLoadingVaccinations.value = false;
    }
  }

  /// MODIFIED: Get veterinarian/staff name with doctor/admin distinction
  Future<String> getVeterinarianName(String vetId) async {
    // Check cache first
    if (vetNamesCache.containsKey(vetId)) {
      return vetNamesCache[vetId]!;
    }

    try {

      // STEP 1: Check if this is a clinic admin (by user ID)
      final clinicDoc = await authRepository.getClinicByAdminId(vetId);

      if (clinicDoc != null) {
        vetNamesCache[vetId] = 'Admin';
        return 'Admin';
      }

      // STEP 2: Try to get staff by USER ID (most common case after admin)
      try {
        final staffDoc = await authRepository.getStaffByUserId(vetId);
        if (staffDoc != null) {
          final staffName = staffDoc.name;
          final isDoctor = staffDoc.isDoctor;


          // CRITICAL: Return "Dr. [Name]" if doctor, otherwise just name
          final displayName = isDoctor ? 'Dr. $staffName' : staffName;
          vetNamesCache[vetId] = displayName;
          return displayName;
        }
      } catch (e) {
      }

      // STEP 3: Try to get staff by DOCUMENT ID (fallback)
      try {
        final staffDoc = await authRepository.getStaffByDocumentId(vetId);
        if (staffDoc != null) {
          final staffName = staffDoc.name;
          final isDoctor = staffDoc.isDoctor;


          // CRITICAL: Return "Dr. [Name]" if doctor, otherwise just name
          final displayName = isDoctor ? 'Dr. $staffName' : staffName;
          vetNamesCache[vetId] = displayName;
          return displayName;
        }
      } catch (e) {
      }

      // STEP 4: Get the user document as last resort
      final userDoc = await authRepository.getUserById(vetId);

      if (userDoc == null) {
        vetNamesCache[vetId] = 'Unknown';
        return 'Unknown';
      }

      final userName = userDoc.data['name'] ?? 'Unknown';
      final userRole = userDoc.data['role'] ?? '';


      // Return the user's name
      vetNamesCache[vetId] = userName;
      return userName;
    } catch (e, stackTrace) {
      vetNamesCache[vetId] = 'Unknown';
      return 'Unknown';
    }
  }

  /// Get veterinarian role (for display)
  Future<String> getVeterinarianRole(String vetId) async {
    try {
      // Check if admin
      final clinicDoc = await authRepository.getClinicByAdminId(vetId);
      if (clinicDoc != null) {
        return 'Admin';
      }

      // Check if staff
      final userDoc = await authRepository.getUserById(vetId);
      if (userDoc != null && userDoc.data['role'] == 'staff') {
        final staffDoc = await authRepository.getStaffByUserId(vetId);
        if (staffDoc != null && staffDoc.isDoctor) {
          return 'Doctor';
        }
        return 'Staff';
      }

      return 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  void clearData() {
    currentPet.value = null;
    medicalRecords.clear();
    vaccinations.clear();
    medicalAppointments.clear();
    vetNamesCache.clear();
  }

  int get vaccinationCount => vaccinations.length;
  int get medicalAppointmentsCount => medicalAppointments.length;

  @override
  void onClose() {
    clearData();
    super.onClose();
  }

  Future<void> debugVetIdIssue(String vetId, String appointmentId) async {
    try {

      // Step 1: Find the medical record
      final medicalRecord = medicalRecords.firstWhere(
        (record) => record.appointmentId == appointmentId,
        orElse: () => throw Exception('Medical record not found'),
      );


      // Step 2: Get all staff in the clinic
      final allStaff =
          await authRepository.getClinicStaff(currentClinicId.value);

      for (var staff in allStaff) {
      }

      // Step 3: Check if it's the admin
      final clinicDoc = await authRepository.getClinicByAdminId(vetId);
      if (clinicDoc != null) {
      } else {
      }

      // Step 4: Try direct user lookup
      final userDoc = await authRepository.getUserById(vetId);
      if (userDoc != null) {
      } else {
      }

    } catch (e, stackTrace) {
    }
  }
}
