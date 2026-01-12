import 'package:appwrite/appwrite.dart';
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/clinic_settings_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:capstone_app/utils/image_helper.dart';
import 'package:get/get.dart';

import 'dart:async';

class SuperAdminHomeController extends GetxController {
  final AuthRepository authRepository;

  SuperAdminHomeController(this.authRepository);

  static SuperAdminHomeController get instance {
    if (!Get.isRegistered<SuperAdminHomeController>()) {
      Get.put(SuperAdminHomeController(Get.find<AuthRepository>()));  
    }
    return Get.find<SuperAdminHomeController>();
  }

  // Observable lists
  final RxList<Map<String, dynamic>> clinicsWithSettings =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;
  final RxString searchQuery = ''.obs;
  final RxString sortBy = 'name'.obs; // 'name', 'date', 'status'

  StreamSubscription<RealtimeMessage>? _clinicSubscription;
  StreamSubscription<RealtimeMessage>? _settingsSubscription;

  @override
  void onInit() {
    super.onInit();
    fetchAllClinics();
    setupRealtimeListeners();
  }

  @override
  void onClose() {
    _clinicSubscription?.cancel();
    _settingsSubscription?.cancel();
    super.onClose();
  }

 Future<void> fetchAllClinics() async {
  try {
    isLoading.value = true;
    errorMessage.value = '';


    // Use the enhanced method
    final clinicsData = await getClinicsWithDashboardPictures();
    
    clinicsWithSettings.value = clinicsData;

    // Apply current sorting after fetching
    sortClinics();
    
    
  } catch (e) {
    errorMessage.value = 'Error fetching clinics: ${e.toString()}';
  } finally {
    isLoading.value = false;
  }
}


  void setupRealtimeListeners() {
    try {
      final realtime = Realtime(authRepository.client);

      // Listen to clinic changes
      final clinicChannel =
          'databases.${AppwriteConstants.dbID}.collections.${AppwriteConstants.clinicsCollectionID}.documents';

      final clinicSubscription = realtime.subscribe([clinicChannel]);
      _clinicSubscription = clinicSubscription.stream.listen(
        (response) {

          // Check if it's a clinic-related event
          if (response.events.any((event) =>
              event.contains('databases') &&
              event.contains(AppwriteConstants.clinicsCollectionID))) {
            fetchAllClinics();
          }
        },
        onError: (error) {
        },
      );

      // Listen to clinic settings changes
      final settingsChannel =
          'databases.${AppwriteConstants.dbID}.collections.${AppwriteConstants.clinicSettingsCollectionID}.documents';

      final settingsSubscription = realtime.subscribe([settingsChannel]);
      _settingsSubscription = settingsSubscription.stream.listen(
        (response) {

          // Check if it's a settings-related event
          if (response.events.any((event) =>
              event.contains('databases') &&
              event.contains(AppwriteConstants.clinicSettingsCollectionID))) {
            fetchAllClinics();
          }
        },
        onError: (error) {
        },
      );

    } catch (e) {
    }
  }

  Future<List<Map<String, dynamic>>> getClinicsWithDashboardPictures() async {
  try {

    // Get all clinics with settings
    final clinicsData = await authRepository.getClinicsWithSettings();
    

    // Process each clinic to ensure dashboard picture is included
    for (var clinicData in clinicsData) {
      final settings = clinicData['settings'] as ClinicSettings?;
      final clinic = clinicData['clinic'] as Clinic;

      if (settings != null && settings.dashboardPic.isNotEmpty) {
        
        // CRITICAL: Update the clinic object with dashboard picture from settings
        clinic.dashboardPic = settings.dashboardPic;
        clinicData['clinic'] = clinic;
      } else {
      }
      
    }

    return clinicsData;
  } catch (e) {
    return [];
  }
}
Future<void> debugDashboardPictures() async {
  try {

    for (var clinicData in clinicsWithSettings) {
      final clinic = clinicData['clinic'] as Clinic;
      final settings = clinicData['settings'] as ClinicSettings?;

      
      if (clinic.dashboardPic != null && clinic.dashboardPic!.isNotEmpty) {
        final url = getDashImageUrl(clinic.dashboardPic!);
      }
      
    }

  } catch (e) {
  }
}

  void updateSearchQuery(String query) {
    searchQuery.value = query.toLowerCase().trim();
  }

  List<Map<String, dynamic>> get filteredClinics {
    List<Map<String, dynamic>> filtered;

    if (searchQuery.value.isEmpty) {
      filtered = List.from(clinicsWithSettings);
    } else {
      final query = searchQuery.value;

      filtered = clinicsWithSettings.where((clinicData) {
        final clinic = clinicData['clinic'] as Clinic;

        final clinicNameLower = clinic.clinicName.toLowerCase();
        final addressLower = clinic.address.toLowerCase();
        final emailLower = clinic.email.toLowerCase();
        final servicesLower = clinic.services.toLowerCase();

        return clinicNameLower.contains(query) ||
            addressLower.contains(query) ||
            emailLower.contains(query) ||
            servicesLower.contains(query);
      }).toList();
    }

    // Apply sorting to filtered results in real-time
    return _applySorting(filtered);
  }

  // Update sort option and trigger re-sort
  void updateSortBy(String sortOption) {
    sortBy.value = sortOption;
    sortClinics();
  }

  // Sort the main list
  void sortClinics() {
    clinicsWithSettings.value = _applySorting(clinicsWithSettings);
    clinicsWithSettings.refresh();
  }

  // Core sorting logic - used by both main list and filtered list
  List<Map<String, dynamic>> _applySorting(List<Map<String, dynamic>> clinics) {
    final List<Map<String, dynamic>> sortedList = List.from(clinics);

    switch (sortBy.value) {
      case 'name':
        // Alphabetical A-Z sorting by clinic name
        sortedList.sort((a, b) {
          final clinicA = a['clinic'] as Clinic;
          final clinicB = b['clinic'] as Clinic;

          final nameA = clinicA.clinicName.trim().toLowerCase();
          final nameB = clinicB.clinicName.trim().toLowerCase();

          return nameA.compareTo(nameB);
        });
        break;

      case 'date':
        // Sort by registration date - newest first
        sortedList.sort((a, b) {
          final clinicA = a['clinic'] as Clinic;
          final clinicB = b['clinic'] as Clinic;

          try {
            final dateA = DateTime.parse(clinicA.createdAt);
            final dateB = DateTime.parse(clinicB.createdAt);

            // Newest first (descending order)
            return dateB.compareTo(dateA);
          } catch (e) {
            return 0;
          }
        });
        break;

      case 'status':
        // Group by status: Open clinics first, then closed clinics
        // Within each group, sort alphabetically
        sortedList.sort((a, b) {
          final settingsA = a['settings'] as ClinicSettings?;
          final settingsB = b['settings'] as ClinicSettings?;

          final isOpenA = settingsA?.isOpenNow() ?? false;
          final isOpenB = settingsB?.isOpenNow() ?? false;

          // Primary sort: Open clinics first
          if (isOpenA && !isOpenB) return -1;
          if (!isOpenA && isOpenB) return 1;

          // Secondary sort: Within same status, sort alphabetically
          final clinicA = a['clinic'] as Clinic;
          final clinicB = b['clinic'] as Clinic;

          final nameA = clinicA.clinicName.trim().toLowerCase();
          final nameB = clinicB.clinicName.trim().toLowerCase();

          return nameA.compareTo(nameB);
        });
        break;
    }

    return sortedList;
  }

  Map<String, int> get clinicStats {
    int totalClinics = clinicsWithSettings.length;
    int openClinics = 0;
    int closedClinics = 0;

    for (var clinicData in clinicsWithSettings) {
      final settings = clinicData['settings'] as ClinicSettings?;
      if (settings?.isOpenNow() == true) {
        openClinics++;
      } else {
        closedClinics++;
      }
    }

    return {
      'total': totalClinics,
      'open': openClinics,
      'closed': closedClinics,
    };
  }
}
