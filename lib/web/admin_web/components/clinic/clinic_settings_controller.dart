import 'package:appwrite/models.dart' as models;
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/clinic_settings_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:capstone_app/utils/snackbar_helper.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ClinicSettingsController extends GetxController {
  final AuthRepository authRepository;
  final UserSessionService session;

  ClinicSettingsController({
    required this.authRepository,
    required this.session,
  });

  // Observable variables
  var isLoading = false.obs;
  var isSaving = false.obs;
  var clinic = Rxn<Clinic>();
  var clinicSettings = Rxn<ClinicSettings>();

  // NEW: Dashboard picture observable
  var tempDashboardPic = ''.obs;
  var dashboardPicChanged = false.obs;

  // Flag to track if controllers are initialized
  var _controllersInitialized = false;

  // NEW: Observable for closed dates
  var closedDates = <String>[].obs;
  var selectedClosedDates = <DateTime>[].obs;

  var clinicProfilePictureUrl = ''.obs;

  // Form controllers - Make them nullable initially
  TextEditingController? _clinicNameController;
  TextEditingController? _addressController;
  TextEditingController? _contactController;
  TextEditingController? _emailController;
  TextEditingController? _descriptionController;
  TextEditingController? _emergencyContactController;
  TextEditingController? _specialInstructionsController;

  // Getters with lazy initialization
  TextEditingController get clinicNameController {
    _ensureControllersInitialized();
    return _clinicNameController!;
  }

  TextEditingController get addressController {
    _ensureControllersInitialized();
    return _addressController!;
  }

  TextEditingController get contactController {
    _ensureControllersInitialized();
    return _contactController!;
  }

  TextEditingController get emailController {
    _ensureControllersInitialized();
    return _emailController!;
  }

  TextEditingController get descriptionController {
    _ensureControllersInitialized();
    return _descriptionController!;
  }

  TextEditingController get emergencyContactController {
    _ensureControllersInitialized();
    return _emergencyContactController!;
  }

  TextEditingController get specialInstructionsController {
    _ensureControllersInitialized();
    return _specialInstructionsController!;
  }

  // Settings observables
  var isClinicOpen = true.obs;
  var autoAcceptAppointments = false.obs;
  var appointmentDuration = 30.obs;
  var maxAdvanceBooking = 30.obs;
  var selectedServices = <String>[].obs;
  var galleryImages = <String>[].obs;
  var operatingHours = <String, Map<String, dynamic>>{}.obs;
  var selectedLocation = Rxn<Map<String, double>>();

  // Available services list
  final List<String> availableServices = [
    'General Checkup',
    'Vaccination',
    'Surgery',
    'Dental Care',
    'Emergency Care',
    'Laboratory Tests',
    'Pet Grooming',
    'Microchipping',
    'Spay/Neuter',
    'X-Ray Imaging',
    'Ultrasound',
    'Blood Work',
    'Behavioral Consultation',
    'Nutritional Counseling',
    'Pet Boarding',
    'Parasite Treatment',
    'Wound Care',
    'Prescription Medications',
    'Health Certificates',
    'Euthanasia Services',
  ];

  // Character limits
  static const int emailMaxLength = 40;
  static const int contactMaxLength = 20;
  static const int addressMaxLength = 200;
  static const int descriptionMaxLength = 1000;
  static const int serviceNameMaxLength = 50;

  var medicalServices = <String, bool>{}.obs;

  @override
  void onInit() {
    super.onInit();

    _ensureControllersInitialized();

    // CRITICAL: Clear any cached data before initializing
    clinic.value = null;
    clinicSettings.value = null;

    initializeData();
  }

  // Ensure controllers are initialized only once
  void _ensureControllersInitialized() {
    if (!_controllersInitialized) {
      _initializeControllers();
      _controllersInitialized = true;
    }
  }

  void _initializeControllers() {
    _clinicNameController = TextEditingController();
    _addressController = TextEditingController();
    _contactController = TextEditingController();
    _emailController = TextEditingController();
    _descriptionController = TextEditingController();
    _emergencyContactController = TextEditingController();
    _specialInstructionsController = TextEditingController();
  }

  Future<void> initializeData() async {
    try {
      isLoading.value = true;

      // CRITICAL: Clear all cached data first
      clinic.value = null;
      clinicSettings.value = null;
      galleryImages.clear();
      selectedServices.clear();
      medicalServices.clear();
      closedDates.clear();
      selectedClosedDates.clear();

      // Fetch fresh data
      await fetchClinicData();
      await fetchClinicSettings();
    } catch (e) {
      _showSnackBar("Failed to load clinic data: $e", isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchClinicData() async {
    try {
      final user = await authRepository.getUser();
      if (user == null) {
        return;
      }

      final storage = GetStorage();

      // CRITICAL FIX: Always get fresh role from storage
      final userRole = storage.read('role') as String?;

      String? clinicId;

      if (userRole == 'staff') {
        // CRITICAL FIX: Get fresh clinicId from storage
        clinicId = storage.read('clinicId') as String?;
      } else if (userRole == 'admin') {
        // CRITICAL FIX: Always lookup fresh clinic data for admin
        final clinicDoc = await authRepository.getClinicByAdminId(user.$id);
        if (clinicDoc != null) {
          clinicId = clinicDoc.$id;
        } else {}
      } else {}

      if (clinicId != null && clinicId.isNotEmpty) {
        // CRITICAL FIX: Clear old data before fetching new
        clinic.value = null;

        final clinicDoc = await authRepository.getClinicById(clinicId);
        if (clinicDoc != null) {
          clinic.value = Clinic.fromMap(clinicDoc.data);
          clinic.value!.documentId = clinicDoc.$id;

          _populateClinicFields();
        } else {}
      } else {}
    } catch (e) {
      rethrow;
    }
  }

  Future<void> fetchClinicSettings() async {
    try {
      if (clinic.value?.documentId == null) {
        clinicSettings.value = null;
        return;
      }

      final currentClinicId = clinic.value!.documentId!;

      final settings =
          await authRepository.getClinicSettingsByClinicId(currentClinicId);

      if (settings != null) {
        // CRITICAL: Create fresh settings object
        clinicSettings.value = settings;

        // Populate form fields
        _populateSettingsFields();
      } else {
        await createDefaultSettings();
      }
    } catch (e) {
      clinicSettings.value = null;
      _showSnackBar("Failed to load clinic settings: $e", isError: true);
    }
  }

  Future<void> createDefaultSettings() async {
    try {
      if (clinic.value?.documentId == null) {
        return;
      }

      final createdSettings = await authRepository
          .initializeClinicSettings(clinic.value!.documentId!);
      clinicSettings.value = createdSettings;
      _populateSettingsFields();
    } catch (e) {
      _showSnackBar("Failed to create default settings: $e", isError: true);
    }
  }

  Future<void> _loadClinicProfilePictureUrl() async {
    try {
      if (clinic.value?.profilePictureId != null &&
          clinic.value!.profilePictureId!.isNotEmpty) {
        final profilePicUrl = authRepository
            .getClinicProfilePictureUrl(clinic.value!.profilePictureId!);

        clinicProfilePictureUrl.value = profilePicUrl;
      } else {
        // Fallback to clinic.image if no profile picture
        clinicProfilePictureUrl.value = clinic.value?.image ?? '';
      }
    } catch (e) {
      clinicProfilePictureUrl.value = clinic.value?.image ?? '';
    }
  }

  void _populateClinicFields() {
    if (clinic.value == null) {
      return;
    }

    try {
      _ensureControllersInitialized();

      clinicNameController.text = clinic.value!.clinicName;
      addressController.text = clinic.value!.address;
      contactController.text = clinic.value!.contact;
      emailController.text = clinic.value!.email;
      descriptionController.text = clinic.value!.description;

      // NEW: Load clinic profile picture URL
      _loadClinicProfilePictureUrl();
    } catch (e) {}
  }

  void _populateSettingsFields() {
    if (clinicSettings.value == null) {
      return;
    }

    try {
      _ensureControllersInitialized();

      final settings = clinicSettings.value!;

      // CRITICAL: Clear existing data before populating
      galleryImages.clear();
      selectedServices.clear();
      medicalServices.clear();
      operatingHours.clear();
      closedDates.clear();
      selectedClosedDates.clear();

      // Populate observables
      isClinicOpen.value = settings.isOpen;
      autoAcceptAppointments.value = settings.autoAcceptAppointments;
      appointmentDuration.value = settings.appointmentDuration;
      maxAdvanceBooking.value = settings.maxAdvanceBooking;

      // CRITICAL: Use assignAll to replace entire lists
      selectedServices.assignAll(settings.services);
      galleryImages.assignAll(settings.gallery);
      operatingHours.assignAll(settings.operatingHours);
      medicalServices.assignAll(settings.medicalServices);
      closedDates.assignAll(settings.closedDates);

      // Parse closed dates
      selectedClosedDates.assignAll(settings.closedDates
          .map((dateStr) => DateTime.parse(dateStr))
          .toList());

      selectedLocation.value = settings.location;
      emergencyContactController.text = settings.emergencyContact;
      specialInstructionsController.text = settings.specialInstructions;
      tempDashboardPic.value = settings.dashboardPic;
      dashboardPicChanged.value = false;
    } catch (e) {}
  }

  // NEW: Add a closed date
  void addClosedDate(DateTime date) {
    final dateStr = _formatDateToString(date);

    if (!closedDates.contains(dateStr)) {
      closedDates.add(dateStr);
      selectedClosedDates.add(date);

      // Sort dates in ascending order
      selectedClosedDates.sort((a, b) => a.compareTo(b));
      closedDates.sort();

      // _showSnackBar("Closed date added: ${_formatDateForDisplay(date)}");
    } else {
      _showSnackBar("This date is already marked as closed", isError: true);
    }
  }

  // NEW: Remove a closed date
  void removeClosedDate(DateTime date) {
    final dateStr = _formatDateToString(date);

    closedDates.remove(dateStr);
    selectedClosedDates.removeWhere((d) => _formatDateToString(d) == dateStr);

    // _showSnackBar("Closed date removed: ${_formatDateForDisplay(date)}");
  }

  // NEW: Clear all closed dates
  void clearAllClosedDates() {
    closedDates.clear();
    selectedClosedDates.clear();
    _showSnackBar("All closed dates cleared");
  }

  // NEW: Check if a date is closed
  bool isDateClosed(DateTime date) {
    final dateStr = _formatDateToString(date);
    return closedDates.contains(dateStr);
  }

  // NEW: Remove past closed dates (cleanup)
  void removePastClosedDates() {
    final today = DateTime.now();
    final todayStr = _formatDateToString(today);

    final futureDates = closedDates.where((dateStr) {
      return dateStr.compareTo(todayStr) >= 0;
    }).toList();

    final removedCount = closedDates.length - futureDates.length;

    if (removedCount > 0) {
      closedDates.assignAll(futureDates);
      selectedClosedDates.assignAll(
          futureDates.map((dateStr) => DateTime.parse(dateStr)).toList());

      _showSnackBar("Removed $removedCount past closed date(s)");
    } else {
      _showSnackBar("No past dates to remove");
    }
  }

  // NEW: Helper to format date to YYYY-MM-DD string
  String _formatDateToString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // NEW: Helper to format date for display
  String _formatDateForDisplay(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // NEW: Toggle medical service status
  void toggleMedicalService(String serviceName, bool isMedical) {
    medicalServices[serviceName] = isMedical;
    medicalServices.refresh();
  }

  // NEW: Check if service is medical
  bool isServiceMedical(String serviceName) {
    return medicalServices[serviceName] ?? false;
  }

  // Validation methods
  bool _validateEmail(String email) {
    if (email.isEmpty) return true;
    if (email.length > emailMaxLength) {
      _showSnackBar("Email must not exceed $emailMaxLength characters",
          isError: true);
      return false;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      _showSnackBar("Please enter a valid email address", isError: true);
      return false;
    }
    return true;
  }

  bool _validateContact(String contact) {
    if (contact.isEmpty) return true;
    if (contact.length > contactMaxLength) {
      _showSnackBar(
          "Contact number must not exceed $contactMaxLength characters",
          isError: true);
      return false;
    }
    return true;
  }

  bool _validateAddress(String address) {
    if (address.isEmpty) {
      _showSnackBar("Address is required", isError: true);
      return false;
    }
    if (address.length > addressMaxLength) {
      _showSnackBar("Address must not exceed $addressMaxLength characters",
          isError: true);
      return false;
    }
    return true;
  }

  bool _validateDescription(String description) {
    if (description.length > descriptionMaxLength) {
      _showSnackBar(
          "Description must not exceed $descriptionMaxLength characters",
          isError: true);
      return false;
    }
    return true;
  }

  // Safe getter for controller text
  String _safeGetText(TextEditingController? controller) {
    try {
      if (controller == null) return '';
      return controller.text;
    } catch (e) {
      return '';
    }
  }

  // Save clinic basic information with validation
  Future<void> saveClinicBasicInfo() async {
    if (clinic.value == null) return;

    final address = _safeGetText(addressController).trim();
    final email = _safeGetText(emailController).trim();
    final contact = _safeGetText(contactController).trim();
    final description = _safeGetText(descriptionController).trim();

    if (!_validateAddress(address)) return;
    if (!_validateEmail(email)) return;
    if (!_validateContact(contact)) return;
    if (!_validateDescription(description)) return;

    try {
      isSaving.value = true;

      final updatedData = {
        'clinicName': _safeGetText(clinicNameController).trim(),
        'address': address,
        'contact': contact,
        'email': email,
        'description': description,
      };

      await authRepository.updateClinic(clinic.value!.documentId!, updatedData);

      clinic.value = clinic.value!
        ..clinicName = _safeGetText(clinicNameController).trim()
        ..address = address
        ..contact = contact
        ..email = email
        ..description = description;

      _showSnackBar("Clinic information updated successfully!");
    } catch (e) {
      _showSnackBar("Failed to update clinic information: $e", isError: true);
    } finally {
      isSaving.value = false;
    }
  }

  // Save clinic settings
  Future<void> saveClinicSettings() async {
    if (clinicSettings.value == null) return;

    try {
      isSaving.value = true;

      final sanitizedMedicalServices = Map<String, bool>.from(medicalServices);

      for (var service in selectedServices) {
        if (!sanitizedMedicalServices.containsKey(service)) {
          sanitizedMedicalServices[service] =
              _isServiceMedicalByDefault(service);
        }
      }

      final updatedSettings = clinicSettings.value!.copyWith(
        isOpen: isClinicOpen.value,
        autoAcceptAppointments: autoAcceptAppointments.value,
        appointmentDuration: appointmentDuration.value,
        maxAdvanceBooking: maxAdvanceBooking.value,
        services: selectedServices.toList(),
        medicalServices: sanitizedMedicalServices,
        gallery: galleryImages.toList(),
        operatingHours: Map<String, Map<String, dynamic>>.from(operatingHours),
        location: selectedLocation.value,
        emergencyContact: _safeGetText(emergencyContactController).trim(),
        specialInstructions: _safeGetText(specialInstructionsController).trim(),
        dashboardPic: tempDashboardPic.value,
        closedDates: closedDates.toList(),
      );

      await authRepository.updateClinicSettings(updatedSettings);
      clinicSettings.value = updatedSettings;
      dashboardPicChanged.value = false;

      _showSnackBar("Clinic settings updated successfully!");
    } catch (e) {
      // _showSnackBar("Failed to update clinic settings: $e", isError: true);
    } finally {
      isSaving.value = false;
    }
  }

// Helper method to determine if service should be medical by default
  bool _isServiceMedicalByDefault(String service) {
    final medicalServices = [
      'General Checkup',
      'Vaccination',
      'Surgery',
      'Dental Care',
      'Emergency Care',
      'Laboratory Tests',
      'Microchipping',
      'Spay/Neuter',
      'X-Ray Imaging',
      'Ultrasound',
      'Blood Work',
      'Behavioral Consultation',
      'Nutritional Counseling',
      'Parasite Treatment',
      'Wound Care',
      'Prescription Medications',
      'Health Certificates',
    ];

    return medicalServices.contains(service);
  }

  void removeService(String service) {
    selectedServices.remove(service);
    medicalServices.remove(service); // NEW: Also remove from medical services
  }

  // NEW: Add/update dashboard picture
  Future<void> setDashboardPicture() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        isSaving.value = true;

        final file = result.files.first;

        try {
          models.File? uploadedFile;

          if (file.bytes != null) {
            final uploadedFiles =
                await authRepository.uploadClinicGalleryImages([file]);
            if (uploadedFiles.isNotEmpty) {
              uploadedFile = uploadedFiles.first;
            }
          } else if (file.path != null) {
            uploadedFile = await authRepository.uploadImage(file.path!);
          } else {
            _showSnackBar("Failed to process image", isError: true);
            return;
          }

          if (uploadedFile != null) {
            final imageId = uploadedFile.$id;
            final imageUrl =
                '${AppwriteConstants.endPoint}/storage/buckets/${AppwriteConstants.imageBucketID}/files/$imageId/view?project=${AppwriteConstants.projectID}';

            tempDashboardPic.value = imageUrl;
            dashboardPicChanged.value = true;

            _showSnackBar(
                "Dashboard picture selected. Click 'Save Picture' to confirm.");
          } else {
            _showSnackBar("Failed to upload image", isError: true);
          }
        } catch (e) {
          _showSnackBar("Failed to upload image: $e", isError: true);
        }
      }
    } catch (e) {
      _showSnackBar("Failed to select image: $e", isError: true);
    } finally {
      isSaving.value = false;
    }
  }

  // NEW: Save dashboard picture to database
  Future<void> saveDashboardPicture() async {
    if (tempDashboardPic.value.isEmpty) {
      _showSnackBar("No picture selected", isError: true);
      return;
    }

    try {
      isSaving.value = true;
      await saveClinicSettings();
    } catch (e) {
      _showSnackBar("Failed to save picture: $e", isError: true);
    } finally {
      isSaving.value = false;
    }
  }

  // NEW: Cancel dashboard picture selection
  void cancelDashboardPictureSelection() {
    if (clinicSettings.value != null) {
      tempDashboardPic.value = clinicSettings.value!.dashboardPic;
      dashboardPicChanged.value = false;
    }
  }

  // Toggle clinic status
  Future<void> toggleClinicStatus() async {
    isClinicOpen.value = !isClinicOpen.value;
    await saveClinicSettings();
  }

  // Update operating hours
  void updateOperatingHours(String day, Map<String, dynamic> hours) {
    operatingHours[day] = hours;
    operatingHours.refresh();
  }

  // Add/remove services with validation
  void toggleService(String service) {
    if (selectedServices.contains(service)) {
      selectedServices.remove(service);
    } else {
      selectedServices.add(service);
    }
  }

  void addCustomService(String service, bool isMedical) {
    final trimmedService = service.trim();

    if (trimmedService.isEmpty) {
      _showSnackBar("Service name cannot be empty", isError: true);
      return;
    }

    if (trimmedService.length > serviceNameMaxLength) {
      _showSnackBar(
          "Service name must not exceed $serviceNameMaxLength characters",
          isError: true);
      return;
    }

    if (selectedServices.contains(trimmedService)) {
      _showSnackBar("This service already exists", isError: true);
      return;
    }

    selectedServices.add(trimmedService);
    medicalServices[trimmedService] = isMedical; // NEW
    _showSnackBar("Custom service added successfully!");
  }

  // Gallery management
  Future<void> addGalleryImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        isSaving.value = true;

        final newImageUrls = <String>[];

        for (int i = 0; i < result.files.length; i++) {
          final file = result.files[i];

          try {
            if (file.bytes != null) {
              final uploadedFiles =
                  await authRepository.uploadClinicGalleryImages([file]);
              if (uploadedFiles.isNotEmpty) {
                final imageId = uploadedFiles.first.$id;
                final imageUrl =
                    '${AppwriteConstants.endPoint}/storage/buckets/${AppwriteConstants.imageBucketID}/files/$imageId/view?project=${AppwriteConstants.projectID}';
                newImageUrls.add(imageUrl);
              }
            } else if (file.path != null) {
              final imageResponse =
                  await authRepository.uploadImage(file.path!);
              final imageId = imageResponse.$id;
              final imageUrl =
                  '${AppwriteConstants.endPoint}/storage/buckets/${AppwriteConstants.imageBucketID}/files/$imageId/view?project=${AppwriteConstants.projectID}';
              newImageUrls.add(imageUrl);
            }
          } catch (e) {
            // Continue processing other images
          }
        }

        if (newImageUrls.isNotEmpty) {
          galleryImages.addAll(newImageUrls);
          await saveClinicSettings();
          _showSnackBar(
              "${newImageUrls.length} image(s) uploaded successfully!");
        } else {
          _showSnackBar("No images were uploaded successfully", isError: true);
        }
      }
    } catch (e) {
      _showSnackBar("Failed to upload images: $e", isError: true);
    } finally {
      isSaving.value = false;
    }
  }

  void removeGalleryImage(int index) {
    if (index >= 0 && index < galleryImages.length) {
      galleryImages.removeAt(index);
      saveClinicSettings();
    }
  }

  // Location management
  void updateLocation(double lat, double lng) {
    selectedLocation.value = {'lat': lat, 'lng': lng};
  }

  void clearLocation() {
    selectedLocation.value = null;
  }

  // Validation
  bool get isValidBasicInfo {
    return _safeGetText(clinicNameController).trim().isNotEmpty &&
        _safeGetText(addressController).trim().isNotEmpty &&
        _safeGetText(contactController).trim().isNotEmpty &&
        _safeGetText(emailController).trim().isNotEmpty;
  }

  bool get hasUnsavedChanges {
    if (clinic.value == null || clinicSettings.value == null) return false;

    return _safeGetText(clinicNameController).trim() !=
            clinic.value!.clinicName ||
        _safeGetText(addressController).trim() != clinic.value!.address ||
        _safeGetText(contactController).trim() != clinic.value!.contact ||
        _safeGetText(emailController).trim() != clinic.value!.email ||
        _safeGetText(descriptionController).trim() !=
            clinic.value!.description ||
        isClinicOpen.value != clinicSettings.value!.isOpen ||
        autoAcceptAppointments.value !=
            clinicSettings.value!.autoAcceptAppointments;
  }

  // Utility methods
  String get clinicStatusText => isClinicOpen.value ? "Open" : "Closed";
  Color get clinicStatusColor => isClinicOpen.value ? Colors.green : Colors.red;

  void _showSnackBar(String message, {bool isError = false}) {
    if (Get.context == null) return;

    if (isError) {
      SnackbarHelper.showError(
        context: Get.context!,
        title: "Error",
        message: message,
      );
    } else {
      SnackbarHelper.showSuccess(
        context: Get.context!,
        title: "Success",
        message: message,
      );
    }
  }

  @override
  void onClose() {
    // Safely dispose all controllers
    if (_controllersInitialized) {
      _clinicNameController?.dispose();
      _addressController?.dispose();
      _contactController?.dispose();
      _emailController?.dispose();
      _descriptionController?.dispose();
      _emergencyContactController?.dispose();
      _specialInstructionsController?.dispose();
      _controllersInitialized = false;
    }
    super.onClose();
  }

  Future<void> refreshData() async {
    // Clear all cached data
    clinic.value = null;
    clinicSettings.value = null;
    galleryImages.clear();
    selectedServices.clear();
    medicalServices.clear();
    closedDates.clear();
    selectedClosedDates.clear();
    operatingHours.clear();

    // Clear form fields
    if (_controllersInitialized) {
      clinicNameController.clear();
      addressController.clear();
      contactController.clear();
      emailController.clear();
      descriptionController.clear();
      emergencyContactController.clear();
      specialInstructionsController.clear();
    }

    // Fetch fresh data
    await initializeData();
  }
}
