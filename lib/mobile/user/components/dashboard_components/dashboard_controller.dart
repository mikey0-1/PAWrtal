import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/clinic_settings_model.dart';
import 'package:capstone_app/data/models/ratings_and_review_model.dart';
import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:get/get.dart';

class DashboardController extends GetxController {
  final AppWriteProvider appwrite = AppWriteProvider();
  final AuthRepository authRepository = Get.find<AuthRepository>();

  var allClinics = <Clinic>[].obs;
  var filteredClinics = <Clinic>[].obs;
  var clinicSettingsMap = <String, ClinicSettings?>{}.obs;
  var ratingStatsCache = <String, ClinicRatingStats>{}.obs;
  var isLoading = true.obs;
  var searchQuery = ''.obs;
  var selectedFilter = 'All'.obs;

  // Cache management
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheValidity = Duration(minutes: 5);

  @override
  void onInit() {
    super.onInit();
    fetchClinics();
  }

  bool _isCacheValid(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheValidity;
  }

  Future<void> fetchClinics({bool forceRefresh = false}) async {
    try {
      isLoading.value = true;

      // Check cache validity
      if (!forceRefresh && _isCacheValid('clinics') && allClinics.isNotEmpty) {
        isLoading.value = false;
        return;
      }

      // ✨ OPTIMIZATION 1: Single database call for all clinics
      final result = await appwrite.databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.clinicsCollectionID,
      );

      // Create clinic objects
      final clinics = result.documents.map((doc) {
        final clinic = Clinic.fromMap(doc.data);
        clinic.documentId = doc.$id;
        return clinic;
      }).toList();

      final clinicIds = clinics
          .map((c) => c.documentId ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

      // ✨ OPTIMIZATION 2: Parallel loading of settings and ratings
      final results = await Future.wait([
        _batchLoadSettings(clinicIds),
        _batchLoadRatingStats(clinicIds),
      ]);

      final settingsMap = results[0] as Map<String, ClinicSettings?>;
      final statsCache = results[1] as Map<String, ClinicRatingStats>;

      // Update state once
      allClinics.assignAll(clinics);
      clinicSettingsMap.assignAll(settingsMap);
      ratingStatsCache.assignAll(statsCache);

      // Update cache timestamp
      _cacheTimestamps['clinics'] = DateTime.now();

      applyFilters();
    } catch (e) {
    } finally {
      isLoading.value = false;
    }
  }

  // ✨ NEW: Batch load settings in parallel
  Future<Map<String, ClinicSettings?>> _batchLoadSettings(
    List<String> clinicIds,
  ) async {
    final settingsMap = <String, ClinicSettings?>{};

    final futures = clinicIds.map((clinicId) async {
      try {
        final settings = await authRepository.getClinicSettingsByClinicId(clinicId);
        return MapEntry(clinicId, settings);
      } catch (e) {
        return MapEntry(clinicId, null);
      }
    });

    final results = await Future.wait(futures);

    for (final entry in results) {
      settingsMap[entry.key] = entry.value;
    }

    return settingsMap;
  }

  // ✨ NEW: Batch load rating stats in parallel
  Future<Map<String, ClinicRatingStats>> _batchLoadRatingStats(
    List<String> clinicIds,
  ) async {
    final statsCache = <String, ClinicRatingStats>{};

    final futures = clinicIds.map((clinicId) async {
      try {
        final stats = await authRepository.getClinicRatingStats(clinicId);
        return MapEntry(clinicId, stats);
      } catch (e) {
        return MapEntry(
          clinicId,
          ClinicRatingStats(
            averageRating: 0.0,
            totalReviews: 0,
            ratingDistribution: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
            reviewsWithText: 0,
            reviewsWithImages: 0,
          ),
        );
      }
    });

    final results = await Future.wait(futures);

    for (final entry in results) {
      statsCache[entry.key] = entry.value;
    }

    return statsCache;
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
    _debounceFilter();
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
    applyFilters();
  }

  // ✨ OPTIMIZATION 3: Debounce search
  Worker? _debounceWorker;
  void _debounceFilter() {
    _debounceWorker?.dispose();
    _debounceWorker = debounce(
      searchQuery,
      (_) => applyFilters(),
      time: const Duration(milliseconds: 300),
    );
  }

  void applyFilters() {
    var filtered = allClinics.toList();

    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      filtered = filtered.where((clinic) {
        final settings = clinicSettingsMap[clinic.documentId ?? ''];
        final services = settings?.services.join(' ') ?? clinic.services;

        return clinic.clinicName.toLowerCase().contains(query) ||
            clinic.address.toLowerCase().contains(query) ||
            services.toLowerCase().contains(query);
      }).toList();
    }

    // Apply status filter
    switch (selectedFilter.value) {
      case 'Open':
        filtered = _filterOpenClinics(filtered);
        break;

      case 'Available Today':
        filtered = _filterAvailableToday(filtered);
        break;

      case 'Closed':
        filtered = _filterClosedClinics(filtered);
        break;

      case 'Popular':
        filtered = _filterPopularClinics(filtered);
        break;

      case 'All':
      default:
        filtered = _sortAllClinics(filtered);
        break;
    }

    filteredClinics.assignAll(filtered);
  }

  // ✨ OPTIMIZATION 4: Extract filter logic
  List<Clinic> _filterOpenClinics(List<Clinic> clinics) {
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    return clinics.where((clinic) {
      final settings = clinicSettingsMap[clinic.documentId ?? ''];
      if (settings == null) return false;

      final isTodayClosedDate = settings.closedDates.contains(todayStr);
      return settings.isOpen && settings.isOpenNow() && !isTodayClosedDate;
    }).toList();
  }

  List<Clinic> _filterAvailableToday(List<Clinic> clinics) {
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    return clinics.where((clinic) {
      final settings = clinicSettingsMap[clinic.documentId ?? ''];
      if (settings == null) return false;

      final isTodayClosedDate = settings.closedDates.contains(todayStr);
      return settings.isOpen && settings.isOpenToday() && !isTodayClosedDate;
    }).toList();
  }

  List<Clinic> _filterClosedClinics(List<Clinic> clinics) {
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    return clinics.where((clinic) {
      final settings = clinicSettingsMap[clinic.documentId ?? ''];
      if (settings == null) return false;

      final isTodayClosedDate = settings.closedDates.contains(todayStr);
      return !settings.isOpen || !settings.isOpenNow() || isTodayClosedDate;
    }).toList();
  }

  List<Clinic> _filterPopularClinics(List<Clinic> clinics) {
    final popular = clinics.where((clinic) {
      final stats = ratingStatsCache[clinic.documentId ?? ''];
      return (stats?.totalReviews ?? 0) > 0 && (stats?.averageRating ?? 0.0) > 0.0;
    }).toList();

    popular.sort((a, b) {
      final aStats = ratingStatsCache[a.documentId ?? ''];
      final bStats = ratingStatsCache[b.documentId ?? ''];

      final aReviews = aStats?.totalReviews ?? 0;
      final bReviews = bStats?.totalReviews ?? 0;

      if (aReviews != bReviews) {
        return bReviews.compareTo(aReviews);
      }

      final aRating = aStats?.averageRating ?? 0.0;
      final bRating = bStats?.averageRating ?? 0.0;
      return bRating.compareTo(aRating);
    });

    return popular;
  }

  List<Clinic> _sortAllClinics(List<Clinic> clinics) {
    clinics.sort((a, b) {
      final aSettings = clinicSettingsMap[a.documentId ?? ''];
      final bSettings = clinicSettingsMap[b.documentId ?? ''];

      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final aIsClosedDate = aSettings?.closedDates.contains(todayStr) ?? false;
      final bIsClosedDate = bSettings?.closedDates.contains(todayStr) ?? false;

      final aIsOpen = (aSettings?.isOpen ?? true) &&
          (aSettings?.isOpenNow() ?? false) &&
          !aIsClosedDate;
      final bIsOpen = (bSettings?.isOpen ?? true) &&
          (bSettings?.isOpenNow() ?? false) &&
          !bIsClosedDate;

      if (aIsOpen && !bIsOpen) return -1;
      if (!aIsOpen && bIsOpen) return 1;

      return a.clinicName.compareTo(b.clinicName);
    });

    return clinics;
  }

  int getFilterCount(String filter) {
    switch (filter) {
      case 'All':
        return allClinics.length;
      case 'Open':
        return _filterOpenClinics(allClinics).length;
      case 'Available Today':
        return _filterAvailableToday(allClinics).length;
      case 'Closed':
        return _filterClosedClinics(allClinics).length;
      case 'Popular':
        return _filterPopularClinics(allClinics).length;
      default:
        return 0;
    }
  }

  @override
  void onClose() {
    _debounceWorker?.dispose();
    super.onClose();
  }
}