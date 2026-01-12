import 'package:capstone_app/components/download_app_button.dart';
import 'package:capstone_app/pages/landing/landing_controller.dart';
import 'package:capstone_app/pages/landing/landing_page.dart';
import 'package:capstone_app/pages/landing/web_landing_clinic_page.dart';
import 'package:capstone_app/web/dimensions.dart';
import 'package:capstone_app/web/user_web/desktop_web/pages/web_dashboard_page.dart';
import 'package:capstone_app/pages/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:capstone_app/components/vet_clinic_banner.dart';
import 'package:get/get.dart';

class WebLandingPage extends StatelessWidget {
  const WebLandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth <= mobileWidth) {
            return const LandingPage();
          } else {
            return const _DesktopTabletLanding();
          }
        },
      ),
    );
  }
}

class _DesktopTabletLanding extends StatelessWidget {
  const _DesktopTabletLanding();

  double getResponsivePadding(double screenWidth) {
    const double minScreen = 1100;
    const double maxScreen = 1920;
    const double minPadding = 40;
    const double maxPadding = 200;

    if (screenWidth <= minScreen) return minPadding;
    if (screenWidth >= maxScreen) return maxPadding;

    double t = (screenWidth - minScreen) / (maxScreen - minScreen);
    return minPadding + t * (maxPadding - minPadding);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = getResponsivePadding(screenWidth);

    // Get controller
    final controller = Get.find<LandingController>();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: RefreshIndicator(
        onRefresh: () => controller.fetchClinics(),
        child: CustomScrollView(
          slivers: [
            // ✅ Custom App Bar for Landing Page
            SliverToBoxAdapter(
              child: Container(
                height: 80,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.black26, width: 1),
                  ),
                ),
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Row(
                  children: [
                    Image.asset(
                      'lib/images/PAWrtal_logo.png',
                      height: 50,
                    ),
                    const Spacer(),
                    const DownloadAppButton(),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: () => Get.toNamed(Routes.login),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF517399),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () => Get.toNamed(Routes.signup),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF517399),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                      ),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ✅ REUSE EXACT DASHBOARD CONTENT (but pass isLandingPage: true)
            SliverToBoxAdapter(
              child: _LandingDashboardContent(
                horizontalPadding: horizontalPadding,
              ),
            ),
          ],
        ),
      ),
      // ✅ NO "Show Maps" button for landing page
    );
  }
}

// ✅ Wrapper that reuses WebDashboardPage content without the maps button
class _LandingDashboardContent extends StatelessWidget {
  final double horizontalPadding;

  const _LandingDashboardContent({
    required this.horizontalPadding,
  });

  @override
  Widget build(BuildContext context) {
    // Use the landing controller instead of WebUserHomeController
    final controller = Get.find<LandingController>();

    return Column(
      children: [
        const VetClinicBanner(isMobile: false),
        // Filters and Search (exact same as dashboard)
        Padding(
          padding: EdgeInsets.only(
            left: horizontalPadding,
            right: horizontalPadding,
            top: 16,
          ),
          child: Row(
            children: [
              _buildWebTagsStyleFilter(controller),
              const SizedBox(width: 12),
              _buildSearchBar(controller),
            ],
          ),
        ),

        // Clinic Grid (exact same as dashboard)
        Padding(
          padding: EdgeInsets.only(
            left: horizontalPadding,
            right: horizontalPadding,
            top: 16,
          ),
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 200),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text("Loading clinics..."),
                    ],
                  ),
                ),
              );
            }

            if (controller.filteredClinics.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 200),
                  child: Column(
                    children: [
                      Icon(
                        Icons.local_hospital_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        controller.searchQuery.value.isNotEmpty
                            ? "No clinics found for '${controller.searchQuery.value}'"
                            : "No clinics match the selected filter",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (controller.searchQuery.value.isNotEmpty ||
                          controller.selectedFilter.value != 'All') ...[
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
                    ],
                  ),
                ),
              );
            }

            // Same grid layout as dashboard
            return LayoutBuilder(
              builder: (context, constraints) {
                double screenWidth = constraints.maxWidth;
                const double spacing = 25;
                const double minTileWidth = 200;
                int tilesPerRow =
                    (screenWidth / (minTileWidth + spacing)).floor();
                tilesPerRow = tilesPerRow.clamp(1, 7);
                double tileWidth =
                    (screenWidth - (spacing * (tilesPerRow - 1))) / tilesPerRow;

                return Wrap(
                  spacing: spacing,
                  runSpacing: 10,
                  children: controller.filteredClinics
                      .map((clinic) => _buildClinicTile(
                            context,
                            clinic,
                            tileWidth,
                            controller,
                          ))
                      .toList(),
                );
              },
            );
          }),
        ),
        const SizedBox(height: 60),
      ],
    );
  }

  Widget _buildWebTagsStyleFilter(LandingController controller) {
    final filters = [
      'All',
      'Open',
      'Closed',
      'Popular',
    ];

    return Expanded(
      child: SizedBox(
        height: 50,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: filters.length,
          itemBuilder: (context, index) {
            final filter = filters[index];

            // ✅ Wrap ONLY the item that needs reactivity
            return Obx(() {
              final isSelected = controller.selectedFilter.value == filter;
              final count = controller.getFilterCount(filter);

              return GestureDetector(
                onTap: () => controller.setFilter(filter),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    children: [
                      Text(
                        count > 0 && filter != 'All'
                            ? '$filter ($count)'
                            : filter,
                        style: TextStyle(
                          fontSize: 16,
                          color: isSelected ? Colors.black : Colors.grey,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (isSelected)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          height: 2,
                          width: _getTextWidth(count > 0 && filter != 'All'
                              ? '$filter ($count)'
                              : filter),
                          color: Colors.black,
                        ),
                    ],
                  ),
                ),
              );
            });
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar(LandingController controller) {
    return SizedBox(
      width: 380,
      height: 50,
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search for clinics, services, locations...',
          hintStyle: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.black54),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(
              color: Colors.black,
              width: 1.5,
            ),
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Colors.grey,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: controller.updateSearchQuery,
      ),
    );
  }

  Widget _buildClinicTile(
    BuildContext context,
    dynamic clinic,
    double tileWidth,
    LandingController controller,
  ) {
    final clinicSettings =
        controller.clinicSettingsMap[clinic.documentId ?? ''];
    final ratingStats = controller.ratingStatsCache[clinic.documentId ?? ''];

    final isOpen = clinicSettings?.isOpen ?? true;
    final isOpenNow = clinicSettings?.isOpenNow() ?? true;
    final averageRating = ratingStats?.averageRating ?? 0.0;
    final totalReviews = ratingStats?.totalReviews ?? 0;

    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final isTodayClosedDate =
        clinicSettings?.closedDates.contains(todayStr) ?? false;

    String imageUrl = '';
    if (clinic.dashboardPic != null && clinic.dashboardPic!.isNotEmpty) {
      imageUrl = clinic.dashboardPic!;
    } else if (clinicSettings != null &&
        clinicSettings.dashboardPic.isNotEmpty) {
      imageUrl = clinicSettings.dashboardPic;
    } else if (clinicSettings != null && clinicSettings.gallery.isNotEmpty) {
      imageUrl = clinicSettings.gallery.first;
    } else if (clinic.image.isNotEmpty) {
      imageUrl = clinic.image;
    }

    Color statusColor;
    String statusText;
    if (isTodayClosedDate) {
      statusColor = Colors.red;
      statusText = "CLOSED TODAY";
    } else if (!isOpen) {
      statusColor = Colors.red;
      statusText = "CLOSED";
    } else if (!isOpenNow) {
      statusColor = Colors.orange;
      statusText = "CLOSED NOW";
    } else {
      statusColor = Colors.green;
      statusText = "OPEN";
    }

    final double tileHeight = tileWidth * 1.4;

    List<String> services = [];
    if (clinicSettings != null && clinicSettings.services.isNotEmpty) {
      services = clinicSettings.services.take(3).toList();
    } else if (clinic.services.isNotEmpty) {
      services = clinic.services
          .split(RegExp(r'[,;|\n]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .take(3)
          .toList();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        hoverColor: const Color(0x00000000),
        onTap: () {
          // Navigate to landing clinic page (no login required)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WebLandingClinicPage(clinic: clinic),
            ),
          );
        },
        child: SizedBox(
          width: tileWidth,
          height: tileHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: tileHeight * 0.7,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        statusText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        clinic.clinicName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (totalReviews > 0)
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
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
                      )
                    else
                      const Row(
                        children: [
                          Icon(Icons.star_border, color: Colors.grey, size: 18),
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
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      clinic.address,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child:
                        _buildHoursDisplay(clinicSettings, isTodayClosedDate),
                  ),
                ],
              ),
              if (services.isNotEmpty)
                Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Text(
                        "Services",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: services.take(2).map((service) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
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
      ),
    );
  }

  Widget _buildHoursDisplay(clinicSettings, bool isTodayClosedDate) {
    if (clinicSettings == null) return const SizedBox.shrink();

    if (isTodayClosedDate) {
      return Text(
        'Closed Today',
        style: TextStyle(
          color: Colors.red[600],
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    final today = DateTime.now().weekday;
    final dayName = _getDayName(today);
    final daySchedule = clinicSettings.operatingHours[dayName];

    if (daySchedule?['isOpen'] != true) {
      return Text(
        'Closed',
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    final openTime = daySchedule?['openTime'] ?? '';
    final closeTime = daySchedule?['closeTime'] ?? '';
    final openTime12 = _formatTimeTo12Hour(openTime);
    final closeTime12 = _formatTimeTo12Hour(closeTime);

    return Text(
      '$openTime12 - $closeTime12',
      style: TextStyle(
        color: Colors.grey[600],
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  String _getDayName(int weekday) {
    const days = [
      '',
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];
    return days[weekday];
  }

  String _formatTimeTo12Hour(String time24) {
    if (time24.isEmpty) return '';
    try {
      final parts = time24.split(':');
      if (parts.length != 2) return time24;
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return time24;
    }
  }

  IconData _getServiceIcon(String service) {
    String serviceLower = service.toLowerCase();
    if (serviceLower.contains('vaccination')) return Icons.vaccines_outlined;
    if (serviceLower.contains('surgery')) return Icons.local_hospital_outlined;
    if (serviceLower.contains('checkup'))
      return Icons.health_and_safety_outlined;
    if (serviceLower.contains('grooming')) return Icons.pets_outlined;
    if (serviceLower.contains('dental')) return Icons.medication_outlined;
    return Icons.medical_services_outlined;
  }

  double _getTextWidth(String text) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
          text: text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    return textPainter.width;
  }
}
