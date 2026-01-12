import 'package:capstone_app/mobile/user/components/dashboard_components/dashboard_controller.dart';
import 'package:capstone_app/mobile/user/components/dashboard_components/dashboard_tile.dart';
import 'package:capstone_app/mobile/user/components/dashboard_components/search_bar.dart';
import 'package:capstone_app/mobile/user/components/dashboard_components/tags.dart';
import 'package:capstone_app/mobile/user/pages/pawmap.dart';
import 'package:capstone_app/notification/widgets/reminder_service_debug_widget.dart';
import 'package:capstone_app/web/pages/web_user_home/web_user_home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late DashboardController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(DashboardController());

    // Initialize Pawmap cache in background
    _initializePawmapCache();
  }

  Future<void> _initializePawmapCache() async {
    // Register cache controller if not already registered
    if (!Get.isRegistered<PawmapCache>()) {
      Get.put(PawmapCache());
    }

    // Initialize cache in background (non-blocking)
    PawmapCache.instance.initializeCache();
  }

  @override
  Widget build(BuildContext context) {
    final webController = Get.find<WebUserHomeController>();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: RefreshIndicator(
        onRefresh: () async {
          await controller.fetchClinics();
          // Also refresh Pawmap cache
          if (Get.isRegistered<PawmapCache>()) {
            PawmapCache.instance.clearCache();
            await PawmapCache.instance.initializeCache();
          }
        },
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.allClinics.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_hospital_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "No clinics available",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return Obx(() {
            // If map view is enabled, show Pawmap
            if (webController.showMapView.value) {
              return const Pawmap();
            }

            // Otherwise show the normal list view
            return ListView(
              children: [
                // const ReminderServiceDebugWidget(),
                // Search Bar
                Padding(
                  padding: const EdgeInsets.only(
                      left: 16, top: 16, bottom: 8, right: 16),
                  child: MySearchBar(
                    onSearchChanged: controller.updateSearchQuery,
                  ),
                ),

                // Filter Tags
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: MyTags(
                    selectedFilter: controller.selectedFilter.value,
                    onFilterChanged: controller.setFilter,
                    getFilterCount: controller.getFilterCount,
                  ),
                ),

                const SizedBox(height: 10),

                // Results Summary
                if (controller.searchQuery.value.isNotEmpty ||
                    controller.selectedFilter.value != 'All')
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "${controller.filteredClinics.length} clinics found",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),

                // Clinic List
                if (controller.filteredClinics.isEmpty &&
                    (controller.searchQuery.value.isNotEmpty ||
                        controller.selectedFilter.value != 'All'))
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            controller.searchQuery.value.isNotEmpty
                                ? "No clinics found for '${controller.searchQuery.value}'"
                                : "No clinics match the selected filter",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              controller.searchQuery.value = '';
                              controller.selectedFilter.value = 'All';
                              controller.applyFilters();
                            },
                            child: const Text("Clear filters"),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...controller.filteredClinics.map((clinic) => MyDashboardTile(
                        clinic: clinic,
                        clinicSettings: controller
                            .clinicSettingsMap[clinic.documentId ?? ''],
                        ratingStats: controller
                            .ratingStatsCache[clinic.documentId ?? ''],
                      )),
                Container(color: Colors.transparent, height: 100),
              ],
            );
          });
        }),
      ),
    );
  }
}
