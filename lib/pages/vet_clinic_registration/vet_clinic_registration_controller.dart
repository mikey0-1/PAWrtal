import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';

class VetClinicRegistrationController extends GetxController {
  final AuthRepository authRepository = Get.find<AuthRepository>();

  final formKey = GlobalKey<FormState>();

  // Text Controllers
  final clinicNameController = TextEditingController();
  final contactController = TextEditingController();
  final emailController = TextEditingController();

  // NEW: Address detail controllers
  final streetController = TextEditingController();
  final blockController = TextEditingController();
  final buildingController = TextEditingController();
  final barangaySearchController =
      TextEditingController(); // NEW: For searchable dropdown

  // Observable Variables
  final selectedBarangay = ''.obs;
  final uploadedFiles = <PlatformFile>[].obs;
  final isUploading = false.obs;
  final isSubmitting = false.obs;

  // NEW: For searchable dropdown
  final filteredBarangays = <String>[].obs;
  final showBarangayDropdown = false.obs;

  // Barangay List from San Jose Del Monte, Bulacan
  final List<String> barangays = [
    'Assumption',
    'Bagong Buhay I',
    'Bagong Buhay II',
    'Bagong Buhay III',
    'Citrus',
    'Ciudad Real',
    'Dulong Bayan',
    'Fatima',
    'Fatima II',
    'Fatima III',
    'Fatima IV',
    'Fatima V',
    'Francisco Homes - Guijo',
    'Francisco Homes - Mulawin',
    'Francisco Homes - Narra',
    'Francisco Homes - Yakal',
    'Gaya-Gaya',
    'Graceville',
    'Gumaoc Central',
    'Gumaoc East',
    'Gumaoc West',
    'Kaybanban',
    'Kaypian',
    'Lawang Pari',
    'Maharlika',
    'Minuyan',
    'Minuyan II',
    'Minuyan III',
    'Minuyan IV',
    'Minuyan V',
    'Minuyan Proper',
    'Muzon East',
    'Muzon Proper',
    'Muzon South',
    'Muzon West',
    'Paradise III',
    'Poblacion',
    'Poblacion I',
    'Saint Martin de Porres',
    'San Isidro',
    'San Manuel',
    'San Martin I',
    'San Martin II',
    'San Martin III',
    'San Martin IV',
    'San Pedro',
    'San Rafael I',
    'San Rafael II',
    'San Rafael III',
    'San Rafael IV',
    'San Rafael V',
    'San Roque',
    'Santa Cruz I',
    'Santa Cruz II',
    'Santa Cruz III',
    'Santa Cruz IV',
    'Santa Cruz V',
    'Santo Cristo',
    'Santo Niño I',
    'Santo Niño II',
    'Sapang Palay',
    'Tungkong Mangga',
  ];

  @override
  void onInit() {
    super.onInit();
    // Pre-fill contact with "09"
    contactController.text = '09';
    contactController.selection = TextSelection.fromPosition(
      TextPosition(offset: contactController.text.length),
    );

    // Initialize filtered barangays
    filteredBarangays.value = List.from(barangays);

    // Listen to barangay search changes
    barangaySearchController.addListener(_filterBarangays);
  }

  @override
  void onClose() {
    clinicNameController.dispose();
    contactController.dispose();
    emailController.dispose();
    streetController.dispose();
    blockController.dispose();
    buildingController.dispose();
    barangaySearchController.dispose();
    super.onClose();
  }

  // NEW: Filter barangays based on search input
  void _filterBarangays() {
    final query = barangaySearchController.text.toLowerCase().trim();

    if (query.isEmpty) {
      filteredBarangays.value = List.from(barangays);
      showBarangayDropdown.value = false;
    } else {
      filteredBarangays.value = barangays
          .where((barangay) => barangay.toLowerCase().contains(query))
          .toList();
      showBarangayDropdown.value = filteredBarangays.isNotEmpty;
    }
  }

  // NEW: Select barangay from dropdown
  void selectBarangay(String barangay) {
    selectedBarangay.value = barangay;
    barangaySearchController.text = barangay;
    showBarangayDropdown.value = false;
  }

  // NEW: Clear barangay selection
  void clearBarangaySearch() {
    barangaySearchController.clear();
    selectedBarangay.value = '';
    filteredBarangays.value = List.from(barangays);
    showBarangayDropdown.value = false;
  }

  // NEW: Build complete address string
  String getCompleteAddress() {
    List<String> addressParts = [];

    // Add building/unit if provided
    if (buildingController.text.trim().isNotEmpty) {
      addressParts.add(buildingController.text.trim());
    }

    // Add block/lot if provided
    if (blockController.text.trim().isNotEmpty) {
      addressParts.add(blockController.text.trim());
    }

    // Add street if provided
    if (streetController.text.trim().isNotEmpty) {
      addressParts.add(streetController.text.trim());
    }

    // Add barangay if selected
    if (selectedBarangay.value.isNotEmpty) {
      addressParts.add('Brgy. ${selectedBarangay.value}');
    }

    // Always add city and province
    addressParts.add('San Jose del Monte');
    addressParts.add('Bulacan');

    return addressParts.join(', ');
  }

  Future<void> pickFiles() async {
    try {
      isUploading.value = true;

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: true,
      );

      if (result != null) {
        // Validate file sizes (max 5MB each)
        for (var file in result.files) {
          if (file.size > 5 * 1024 * 1024) {
            Get.snackbar(
              'File Too Large',
              '${file.name} exceeds 5MB limit',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red.shade100,
              colorText: Colors.red.shade900,
            );
            continue;
          }

          // Check if file already exists
          final exists = uploadedFiles.any((f) => f.name == file.name);
          if (!exists) {
            uploadedFiles.add(file);
          }
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick files: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
    } finally {
      isUploading.value = false;
    }
  }

  void removeFile(int index) {
    uploadedFiles.removeAt(index);
  }

  Future<void> submitRegistration() async {
    // Validate form
    if (!formKey.currentState!.validate()) {
      return;
    }

    // Validate barangay selection
    if (selectedBarangay.value.isEmpty) {
      Get.snackbar(
        'Missing Information',
        'Please select a barangay',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade900,
      );
      return;
    }

    // Validate file upload
    if (uploadedFiles.isEmpty) {
      Get.snackbar(
        'Missing Documents',
        'Please upload at least one document',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade900,
      );
      return;
    }

    try {
      isSubmitting.value = true;

      // Upload files to Appwrite Storage
      final fileIds = <String>[];
      for (var file in uploadedFiles) {
        try {
          final uploadedFile =
              await authRepository.uploadVetRegistrationDocument(file);
          fileIds.add(uploadedFile.$id);
        } catch (e) {
          Get.snackbar(
            'Upload Error',
            'Failed to upload ${file.name}: ${e.toString()}',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade900,
          );
          // Clean up already uploaded files
          for (var uploadedFileId in fileIds) {
            try {
              await authRepository
                  .deleteVetRegistrationDocument(uploadedFileId);
            } catch (_) {}
          }
          return;
        }
      }

      // Create registration request with complete address
      final requestData = {
        'clinicName': clinicNameController.text.trim(),
        'barangay': selectedBarangay.value,
        'contactNumber': contactController.text.trim(),
        'email': emailController.text.trim().toLowerCase(),
        'documentFileIds': fileIds,
        'status': 'pending',
        'reviewedBy': '',
        'reviewNotes': '',
        'submittedAt': DateTime.now().toIso8601String(),
        'reviewedAt': '',
        // NEW: Store individual address components
        'street': streetController.text.trim(),
        'blockLot': blockController.text.trim(),
        'buildingUnit': buildingController.text.trim(),
      };

      await authRepository.createVetRegistrationRequest(requestData);

      // Show success dialog
      Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green.shade700,
                  size: 56,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Registration Submitted!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF517399),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Your clinic registration has been submitted successfully. Our team will review your application within 1-2 business days.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Get.back(); // Close dialog
                    Get.back(); // Go back to previous page
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF517399),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        barrierDismissible: false,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to submit registration: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isSubmitting.value = false;
    }
  }
}
