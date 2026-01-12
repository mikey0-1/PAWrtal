import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/clinic_settings_model.dart';
import 'package:capstone_app/data/models/ratings_and_review_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:get/get.dart';

class LandingController extends GetxController {
  final AuthRepository _authRepository;

  LandingController(this._authRepository);

  final isLoading = true.obs;
  final searchQuery = ''.obs;
  final selectedFilter = 'All'.obs;

  final allClinics = <Clinic>[].obs;
  final filteredClinics = <Clinic>[].obs;
  final clinicSettingsMap = <String, ClinicSettings?>{}.obs;
  final ratingStatsCache = <String, ClinicRatingStats>{}.obs;

  // Cache timestamps to manage cache invalidation
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

      // Fetch clinics with settings in a single call (already optimized in your repo)
      final clinicsWithSettings = await _authRepository.getClinicsWithSettings();

      final clinics = <Clinic>[];
      final settingsMap = <String, ClinicSettings?>{};
      final statsCache = <String, ClinicRatingStats>{};

      // ✨ OPTIMIZATION 1: Prepare all clinic IDs upfront
      final clinicIds = <String>[];
      for (final data in clinicsWithSettings) {
        final clinic = data['clinic'] as Clinic;
        final settings = data['settings'] as ClinicSettings?;
        final clinicDocId = clinic.documentId ?? '';

        if (clinicDocId.isNotEmpty) {
          clinics.add(clinic);
          settingsMap[clinicDocId] = settings;
          clinicIds.add(clinicDocId);
        }
      }

      // ✨ OPTIMIZATION 2: Batch load rating stats in parallel
      await _batchLoadRatingStats(clinicIds, statsCache);

      // Update state once
      allClinics.value = clinics;
      clinicSettingsMap.value = settingsMap;
      ratingStatsCache.value = statsCache;
      
      // Update cache timestamp
      _cacheTimestamps['clinics'] = DateTime.now();
      
      applyFilters();

    } catch (e) {
    } finally {
      isLoading.value = false;
    }
  }

  // ✨ NEW: Batch load rating stats in parallel with error handling
  Future<void> _batchLoadRatingStats(
    List<String> clinicIds,
    Map<String, ClinicRatingStats> statsCache,
  ) async {
    // Create futures for all rating stats requests
    final futures = clinicIds.map((clinicId) async {
      try {
        final stats = await _authRepository.getClinicRatingStats(clinicId);
        return MapEntry(clinicId, stats);
      } catch (e) {
        // Return empty stats on error
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

    // Wait for all requests to complete in parallel
    final results = await Future.wait(futures);

    // Populate the cache
    for (final entry in results) {
      statsCache[entry.key] = entry.value;
    }
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
    _debounceFilter();
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
    applyFilters();
  }

  // ✨ OPTIMIZATION 3: Debounce search to reduce filter calls
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

    // Apply tag filter
    switch (selectedFilter.value) {
      case 'Open':
        filtered = _filterOpenClinics(filtered);
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

    filteredClinics.value = filtered;
  }

  // ✨ OPTIMIZATION 4: Extract filter logic into separate methods for clarity
  List<Clinic> _filterOpenClinics(List<Clinic> clinics) {
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    return clinics.where((clinic) {
      final settings = clinicSettingsMap[clinic.documentId ?? ''];
      if (settings == null) return true;

      final isTodayClosedDate = settings.closedDates.contains(todayStr);
      return settings.isOpen && settings.isOpenNow() && !isTodayClosedDate;
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
    // Filter first, then sort
    final popular = clinics.where((clinic) {
      final stats = ratingStatsCache[clinic.documentId ?? ''];
      return (stats?.totalReviews ?? 0) > 0;
    }).toList();

    // Sort by review count (primary) then rating (secondary)
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

      final aIsOpen = aSettings?.isOpen ?? true;
      final bIsOpen = bSettings?.isOpen ?? true;

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