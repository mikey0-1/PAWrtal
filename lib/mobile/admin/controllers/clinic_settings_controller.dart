import 'package:capstone_app/data/models/clinic_settings_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/pages/admin_home/admin_home_controller.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class ClinicSettingsController extends GetxController {
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final AdminHomeController _adminController = Get.find<AdminHomeController>();

  // Loading states
  final isLoading = false.obs;
  final isSaving = false.obs;
  final hasUnsavedChanges = false.obs;

  // Clinic settings data
  ClinicSettings? _originalSettings;
  String? _settingsDocumentId;

  // Observable properties
  final isOpen = true.obs;
  final appointmentDuration = 30.obs;
  final maxAdvanceBooking = 30.obs;
  final autoAccept = false.obs;
  final gallery = <String>[].obs;
  final operatingHours = <String, dynamic>{}.obs;

  // Text controllers
  final servicesController = TextEditingController();
  final emergencyContactController = TextEditingController();
  final specialInstructionsController = TextEditingController();
  final latController = TextEditingController();
  final lngController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _initializeOperatingHours();
    loadSettings();
    _setupChangeListeners();
  }

  @override
  void onClose() {
    servicesController.dispose();
    emergencyContactController.dispose();
    specialInstructionsController.dispose();
    latController.dispose();
    lngController.dispose();
    super.onClose();
  }

  void _initializeOperatingHours() {
    operatingHours.value = {
      'monday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '17:00'},
      'tuesday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '17:00'},
      'wednesday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '17:00'},
      'thursday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '17:00'},
      'friday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '17:00'},
      'saturday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '15:00'},
      'sunday': {'isOpen': false, 'openTime': '09:00', 'closeTime': '17:00'},
    };
  }

  void _setupChangeListeners() {
    // Listen to changes in reactive variables
    ever(isOpen, (_) => _markAsChanged());
    ever(appointmentDuration, (_) => _markAsChanged());
    ever(maxAdvanceBooking, (_) => _markAsChanged());
    ever(autoAccept, (_) => _markAsChanged());
    ever(gallery, (_) => _markAsChanged());
    ever(operatingHours, (_) => _markAsChanged());

    // Listen to text controller changes
    servicesController.addListener(_markAsChanged);
    emergencyContactController.addListener(_markAsChanged);
    specialInstructionsController.addListener(_markAsChanged);
    latController.addListener(_markAsChanged);
    lngController.addListener(_markAsChanged);
  }

  void _markAsChanged() {
    if (_originalSettings != null && !hasUnsavedChanges.value) {
      hasUnsavedChanges.value = true;
    }
  }

  Future<void> loadSettings() async {
    try {
      isLoading.value = true;
      
      final clinic = _adminController.clinic.value;
      if (clinic?.documentId == null) {
        throw Exception('No clinic found');
      }

      // Try to get existing settings
      final settings = await _authRepository.getClinicSettingsByClinicId(clinic!.documentId!);
      
      if (settings != null) {
        _originalSettings = settings;
        _settingsDocumentId = settings.documentId;
        _populateFields(settings);
      } else {
        // Create default settings if none exist
        await _createDefaultSettings(clinic.documentId!);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load clinic settings: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _createDefaultSettings(String clinicId) async {
    try {
      final defaultSettings = ClinicSettings(clinicId: clinicId);
      final doc = await _authRepository.createClinicSettings(defaultSettings);
      
      _originalSettings = defaultSettings;
      _settingsDocumentId = doc.$id;
      _originalSettings!.documentId = doc.$id;
      
      _populateFields(_originalSettings!);
    } catch (e) {
      throw Exception('Failed to create default settings: $e');
    }
  }

  void _populateFields(ClinicSettings settings) {
    isOpen.value = settings.isOpen;
    appointmentDuration.value = settings.appointmentDuration;
    maxAdvanceBooking.value = settings.maxAdvanceBooking;
    autoAccept.value = settings.autoAcceptAppointments;
    gallery.value = List<String>.from(settings.gallery);
    operatingHours.value = Map<String, dynamic>.from(settings.operatingHours);
    
    servicesController.text = settings.services.join('\n');
    emergencyContactController.text = settings.emergencyContact;
    specialInstructionsController.text = settings.specialInstructions;
    
    if (settings.location != null) {
      latController.text = settings.location!['lat']?.toString() ?? '';
      lngController.text = settings.location!['lng']?.toString() ?? '';
    }

    // Reset change flag after loading
    hasUnsavedChanges.value = false;
  }

  Future<void> saveSettings() async {
    try {
      isSaving.value = true;

      if (_settingsDocumentId == null) {
        throw Exception('No settings document ID found');
      }

      final updatedSettings = _buildSettingsFromForm();
      updatedSettings.documentId = _settingsDocumentId;

      await _authRepository.updateClinicSettings(updatedSettings);
      
      _originalSettings = updatedSettings;
      hasUnsavedChanges.value = false;

      Get.snackbar(
        'Success',
        'Clinic settings saved successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save settings: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isSaving.value = false;
    }
  }

  ClinicSettings _buildSettingsFromForm() {
    final clinic = _adminController.clinic.value!;
    
    // Parse location
    Map<String, double>? location;
    if (latController.text.isNotEmpty && lngController.text.isNotEmpty) {
      try {
        location = {
          'lat': double.parse(latController.text),
          'lng': double.parse(lngController.text),
        };
      } catch (e) {
        // Invalid location format, keep as null
      }
    }

    // Parse services
    final servicesList = servicesController.text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return ClinicSettings(
      documentId: _settingsDocumentId,
      clinicId: clinic.documentId!,
      isOpen: isOpen.value,
      operatingHours: Map<String, Map<String, dynamic>>.from(operatingHours),
      gallery: List<String>.from(gallery),
      location: location,
      services: servicesList,
      appointmentDuration: appointmentDuration.value,
      maxAdvanceBooking: maxAdvanceBooking.value,
      emergencyContact: emergencyContactController.text.trim(),
      specialInstructions: specialInstructionsController.text.trim(),
      autoAcceptAppointments: autoAccept.value,
      createdAt: _originalSettings?.createdAt ?? DateTime.now().toIso8601String(),
    );
  }

  // Operating hours methods
  void toggleDayStatus(String day, bool isOpen) {
    final currentHours = Map<String, dynamic>.from(operatingHours);
    currentHours[day] = {
      ...currentHours[day],
      'isOpen': isOpen,
    };
    operatingHours.value = currentHours;
  }

  void updateDayTime(String day, String timeType, String time) {
    final currentHours = Map<String, dynamic>.from(operatingHours);
    currentHours[day] = {
      ...currentHours[day],
      timeType: time,
    };
    operatingHours.value = currentHours;
  }

  // Gallery methods
  Future<void> pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      
      // Pick multiple images
      final List<XFile> images = await picker.pickMultiImage();
      
      if (images.isNotEmpty) {
        // Show loading
        Get.dialog(
          const Center(
            child: CircularProgressIndicator(color: Color(0xFF608BC1)),
          ),
          barrierDismissible: false,
        );

        try {
          final newGallery = List<String>.from(gallery);
          
          for (final image in images) {
            // Upload each image
            final imageResponse = await _authRepository.uploadImage(image.path);
            newGallery.add(imageResponse.$id);
          }
          
          gallery.value = newGallery;

          // Auto-save the settings after successful upload
          await _saveSettingsAfterImageUpload();

          Get.back(); // Close loading dialog
          
          Get.snackbar(
            'Success',
            '${images.length} image(s) uploaded and saved successfully!',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } catch (e) {
          Get.back(); // Close loading dialog
          Get.snackbar(
            'Error',
            'Failed to upload images: $e',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick images: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Private method to save settings after image upload without showing success message
  Future<void> _saveSettingsAfterImageUpload() async {
    try {
      if (_settingsDocumentId == null) {
        throw Exception('No settings document ID found');
      }

      final updatedSettings = _buildSettingsFromForm();
      updatedSettings.documentId = _settingsDocumentId;

      await _authRepository.updateClinicSettings(updatedSettings);
      
      _originalSettings = updatedSettings;
      hasUnsavedChanges.value = false;
    } catch (e) {
      // Don't throw error here, just log it
    }
  }

  void removeImage(int index) {
    Get.dialog(
      AlertDialog(
        title: const Text('Remove Image'),
        content: const Text('Are you sure you want to remove this image?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              
              // Show loading while removing and saving
              Get.dialog(
                const Center(
                  child: CircularProgressIndicator(color: Color(0xFF608BC1)),
                ),
                barrierDismissible: false,
              );

              try {
                final imageId = gallery[index];
                final newGallery = List<String>.from(gallery);
                newGallery.removeAt(index);
                gallery.value = newGallery;

                // Auto-save the settings after removing image
                await _saveSettingsAfterImageUpload();

                // Delete from storage
                try {
                  // Extract file ID if it's a full URL
                  String fileIdToDelete = imageId;
                  if (imageId.startsWith('http')) {
                    // Extract file ID from URL: .../files/{fileId}/view...
                    final uri = Uri.parse(imageId);
                    final segments = uri.pathSegments;
                    final filesIndex = segments.indexOf('files');
                    if (filesIndex != -1 && filesIndex + 1 < segments.length) {
                      fileIdToDelete = segments[filesIndex + 1];
                    }
                  }
                  await _authRepository.deleteImage(fileIdToDelete);
                } catch (e) {
                  // Don't fail the whole operation if storage deletion fails
                }

                Get.back(); // Close loading dialog

                Get.snackbar(
                  'Success',
                  'Image removed and saved successfully!',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              } catch (e) {
                Get.back(); // Close loading dialog
                Get.snackbar(
                  'Error',
                  'Failed to remove image: $e',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  String getImageUrl(String imageId) {
    // Check if imageId is already a full URL (from web upload)
    if (imageId.startsWith('http://') || imageId.startsWith('https://')) {
      return imageId;
    }
    
    // If it's just a file ID, construct the URL (from mobile upload)
    final url = '${AppwriteConstants.endPoint}/storage/buckets/${AppwriteConstants.imageBucketID}/files/$imageId/view?project=${AppwriteConstants.projectID}';
    
    return url;
  }

  // Status methods
  void toggleClinicStatus(bool status) {
    isOpen.value = status;
  }

  // Validation methods
  bool validateSettings() {
    if (emergencyContactController.text.trim().isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Emergency contact is required',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }

    if (servicesController.text.trim().isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please list your clinic services',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }

    // Validate at least one day is open
    bool hasOpenDay = false;
    for (final day in operatingHours.keys) {
      if (operatingHours[day]['isOpen'] == true) {
        hasOpenDay = true;
        break;
      }
    }

    if (!hasOpenDay) {
      Get.snackbar(
        'Validation Error',
        'At least one day must be open',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }

    return true;
  }

  Future<bool> onWillPop() async {
    if (!hasUnsavedChanges.value) return true;

    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Do you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}