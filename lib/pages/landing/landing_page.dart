import 'package:capstone_app/components/download_app_button.dart';
import 'package:capstone_app/mobile/user/components/dashboard_components/search_bar.dart';
import 'package:capstone_app/mobile/user/components/dashboard_components/tags.dart';
import 'package:capstone_app/pages/landing/landing_controller.dart';
import 'package:capstone_app/pages/landing/landing_clinic_page.dart';
import 'package:capstone_app/pages/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:capstone_app/components/vet_clinic_banner.dart';

class LandingPage extends GetView<LandingController> {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Image.asset(
          'lib/images/PAWrtal_logo.png',
          height: 35,
        ),
        actions: [
          const DownloadAppButton(isMobileLayout: true),
          TextButton(
            onPressed: () => Get.toNamed(Routes.login),
            child: const Text(
              'Login',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF517399),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton(
              onPressed: () => Get.toNamed(Routes.signup),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF517399),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text(
                'Sign Up',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.fetchClinics(),
        color: const Color(0xFF517399),
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF517399),
              ),
            );
          }

          if (controller.allClinics.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 100),
                Center(
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
                ),
              ],
            );
          }

          return ListView(
            children: [
              const VetClinicBanner(isMobile: true),
              // Welcome Banner (only for landing page)
              // Container(
              //   margin: const EdgeInsets.all(16),
              //   padding: const EdgeInsets.all(20),
              //   decoration: BoxDecoration(
              //     gradient: const LinearGradient(
              //       colors: [Color(0xFF517399), Color(0xFF6B8EB3)],
              //       begin: Alignment.topLeft,
              //       end: Alignment.bottomRight,
              //     ),
              //     borderRadius: BorderRadius.circular(16),
              //   ),
              //   child: Column(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       const Text(
              //         'Welcome to PAWrtal',
              //         style: TextStyle(
              //           fontSize: 24,
              //           fontWeight: FontWeight.bold,
              //           color: Colors.white,
              //         ),
              //       ),
              //       const SizedBox(height: 8),
              //       Text(
              //         'Find the best veterinary clinics for your pets',
              //         style: TextStyle(
              //           fontSize: 15,
              //           color: Colors.white.withOpacity(0.9),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 0, bottom: 8, right: 16),
                child: MySearchBar(
                  onSearchChanged: controller.updateSearchQuery,
                ),
              ),

              // Filter Tags
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Obx(() => MyTags(
                  selectedFilter: controller.selectedFilter.value,
                  onFilterChanged: controller.setFilter,
                  getFilterCount: controller.getFilterCount,
                )),
              ),

              const SizedBox(height: 10),

              // Results Summary
              Obx(() {
                if (controller.searchQuery.value.isNotEmpty ||
                    controller.selectedFilter.value != 'All') {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "${controller.filteredClinics.length} clinics found",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),

              // Clinic List
              Obx(() {
                if (controller.filteredClinics.isEmpty &&
                    (controller.searchQuery.value.isNotEmpty ||
                        controller.selectedFilter.value != 'All')) {
                  return Center(
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
                  );
                }

                return Column(
                  children: [
                    ...controller.filteredClinics.map((clinic) {
                      final settings = controller.clinicSettingsMap[clinic.documentId ?? ''];
                      final stats = controller.ratingStatsCache[clinic.documentId ?? ''];
                      
                      return _buildClinicCard(context, clinic, settings, stats);
                    }),
                    const SizedBox(height: 100), // Bottom padding
                  ],
                );
              }),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildClinicCard(BuildContext context, clinic, clinicSettings, ratingStats) {
    final isOpen = clinicSettings?.isOpen ?? true;
    final isOpenNow = clinicSettings?.isOpenNow() ?? true;
    final averageRating = ratingStats?.averageRating ?? 0.0;
    final totalReviews = ratingStats?.totalReviews ?? 0;

    // Check if today is a closed date
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final isTodayClosedDate = clinicSettings?.closedDates.contains(todayStr) ?? false;

    // Get image URL
    String imageUrl = '';
    if (clinicSettings != null && clinicSettings.dashboardPic.isNotEmpty) {
      imageUrl = clinicSettings.dashboardPic;
    } else if (clinicSettings != null && clinicSettings.gallery.isNotEmpty) {
      imageUrl = clinicSettings.gallery.first;
    } else {
      imageUrl = clinic.image;
    }

    // Get today's hours
    String todayHours = 'Closed';
    if (clinicSettings != null) {
      final dayName = _getDayName(today.weekday);
      final daySchedule = clinicSettings.operatingHours[dayName];
      
      if (daySchedule?['isOpen'] == true) {
        final openTime = daySchedule?['openTime'] ?? '';
        final closeTime = daySchedule?['closeTime'] ?? '';
        todayHours = _formatTimeRange(openTime, closeTime);
      }
    }

    // Get services
    List<String> services = [];
    if (clinicSettings != null && clinicSettings.services.isNotEmpty) {
      services = clinicSettings.services.take(2).toList();
    } else if (clinic.services.isNotEmpty) {
      services = clinic.services
          .split(RegExp(r'[,;|\n]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .take(2)
          .toList();
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LandingClinicPage(
              clinic: clinic,
              clinicSettings: clinicSettings,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with status badge
            Stack(
              children: [
                Container(
                  height: 200,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'lib/images/placeholder.png',
                                fit: BoxFit.cover,
                                width: double.infinity,
                              );
                            },
                          )
                        : Image.asset(
                            'lib/images/placeholder.png',
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isTodayClosedDate
                          ? Colors.red
                          : (!isOpen || !isOpenNow ? Colors.red : Colors.green),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isTodayClosedDate
                          ? 'CLOSED TODAY'
                          : (!isOpen || !isOpenNow ? 'CLOSED' : 'OPEN'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Clinic info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Clinic name and rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          clinic.clinicName,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: const Color.fromARGB(255, 81, 115, 153),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (totalReviews > 0) ...[
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 3),
                            Text(
                              averageRating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              " ($totalReviews)",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        const Row(
                          children: [
                            Icon(Icons.star_border, color: Colors.grey, size: 16),
                            SizedBox(width: 3),
                            Text(
                              "No reviews",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Address
                  Text(
                    clinic.address,
                    style: GoogleFonts.dmSans(
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 10),

                  // Hours
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          todayHours,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Services
                  if (services.isNotEmpty)
                    Row(
                      children: [
                        const Text(
                          "Services: ",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: services.map((service) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Tooltip(
                                  message: service,
                                  child: Icon(
                                    _getServiceIcon(service),
                                    size: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getServiceIcon(String service) {
    String serviceLower = service.toLowerCase();
    if (serviceLower.contains('vaccination') || serviceLower.contains('vaccine')) {
      return Icons.vaccines_outlined;
    } else if (serviceLower.contains('surgery') || serviceLower.contains('operation')) {
      return Icons.local_hospital_outlined;
    } else if (serviceLower.contains('checkup') || serviceLower.contains('examination')) {
      return Icons.health_and_safety_outlined;
    } else if (serviceLower.contains('grooming')) {
      return Icons.pets_outlined;
    } else if (serviceLower.contains('dental')) {
      return Icons.medication_outlined;
    } else if (serviceLower.contains('emergency')) {
      return Icons.emergency_outlined;
    } else {
      return Icons.medical_services_outlined;
    }
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'monday';
      case 2: return 'tuesday';
      case 3: return 'wednesday';
      case 4: return 'thursday';
      case 5: return 'friday';
      case 6: return 'saturday';
      case 7: return 'sunday';
      default: return 'monday';
    }
  }

  String _formatTimeRange(String openTime, String closeTime) {
    String format24To12(String time24) {
      try {
        final parts = time24.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
        return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
      } catch (e) {
        return time24;
      }
    }

    return '${format24To12(openTime)} - ${format24To12(closeTime)}';
  }
}