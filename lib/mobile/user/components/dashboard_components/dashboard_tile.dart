import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/clinic_settings_model.dart';
import 'package:capstone_app/data/models/ratings_and_review_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/mobile/user/pages/dashboard_next_page.dart';
import 'package:capstone_app/web/user_web/responsive_page_handlers/web_clinic_page_handler.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

class MyDashboardTile extends StatefulWidget {
  final Clinic clinic;
  final ClinicSettings? clinicSettings;
  final ClinicRatingStats? ratingStats; // ADD THIS

  const MyDashboardTile({
    super.key,
    required this.clinic,
    this.clinicSettings,
    this.ratingStats, // ADD THIS
  });

  @override
  State<MyDashboardTile> createState() => _MyDashboardTileState();
}

class _MyDashboardTileState extends State<MyDashboardTile> {
  // REMOVE these lines:
  // ClinicRatingStats? _ratingStats;
  // bool _isLoadingRating = true;

  // REMOVE the entire initState() method

  // REMOVE the entire _loadRatingStats() method

  Widget _buildStatusBadge() {
    // CRITICAL: Check if today is a closed date FIRST
    final isTodayClosedDate = _isTodayClosedDate();

    final isOpen = widget.clinicSettings?.isOpen ?? true;
    final isOpenNow = widget.clinicSettings?.isOpenNow() ?? true;

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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  bool _isTodayClosedDate() {
    if (widget.clinicSettings == null) return false;

    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    return widget.clinicSettings!.closedDates.contains(todayStr);
  }

  Widget _buildRatingDisplay() {
    // CHANGED: Use widget.ratingStats directly (passed from parent)
    final rating = widget.ratingStats?.averageRating ?? 0.0;
    final reviewCount = widget.ratingStats?.totalReviews ?? 0;

    if (reviewCount == 0) {
      return const Row(
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
      );
    }

    return Row(
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 16),
        const SizedBox(width: 3),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          " ($reviewCount)",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildHoursDisplay() {
    if (widget.clinicSettings == null) {
      return const SizedBox.shrink();
    }

    // Get today's operating hours
    final now = DateTime.now();
    final dayName = _getDayName(now.weekday);
    final dayHours = widget.clinicSettings!.operatingHours[dayName];

    String todayHours;
    if (dayHours?['isOpen'] == true) {
      final openTime = dayHours?['openTime'] ?? '09:00';
      final closeTime = dayHours?['closeTime'] ?? '17:00';
      todayHours = _formatTimeRange(openTime, closeTime);
    } else {
      todayHours = 'Closed';
    }

    return Row(
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
    );
  }

  List<String> _getServicesList() {
    List<String> services = [];

    if (widget.clinicSettings != null &&
        widget.clinicSettings!.services.isNotEmpty) {
      services = widget.clinicSettings!.services.take(2).toList();
    } else if (widget.clinic.services.isNotEmpty) {
      services = widget.clinic.services
          .split(RegExp(r'[,;|\n]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .take(2)
          .toList();
    }

    return services;
  }

  IconData _getServiceIcon(String service) {
    String serviceLower = service.toLowerCase();
    if (serviceLower.contains('vaccination') ||
        serviceLower.contains('vaccine')) {
      return Icons.vaccines_outlined;
    } else if (serviceLower.contains('surgery') ||
        serviceLower.contains('operation')) {
      return Icons.local_hospital_outlined;
    } else if (serviceLower.contains('checkup') ||
        serviceLower.contains('examination')) {
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

  String _getImageUrl() {
    // Use dashboardPic from settings if available
    if (widget.clinicSettings != null &&
        widget.clinicSettings!.dashboardPic.isNotEmpty) {
      return widget.clinicSettings!.dashboardPic;
    }
    // Fallback to first gallery image from settings
    if (widget.clinicSettings != null &&
        widget.clinicSettings!.gallery.isNotEmpty) {
      return widget.clinicSettings!.gallery.first;
    }
    // Final fallback to clinic.image
    return widget.clinic.image;
  }

  @override
  Widget build(BuildContext context) {
    final services = _getServicesList();
    final imageUrl = _getImageUrl();

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  WebClinicPageHandlerUpdated(clinic: widget.clinic)),
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
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
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
                  child: _buildStatusBadge(),
                ),
              ],
            ),

            // Clinic info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Clinic name and rating row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.clinic.clinicName,
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
                      _buildRatingDisplay(),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Address
                  Text(
                    widget.clinic.address,
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
                  _buildHoursDisplay(),

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


  String _formatTimeRange(String openTime, String closeTime) {
    // Convert 24-hour times to 12-hour format
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

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'monday';
      case 2:
        return 'tuesday';
      case 3:
        return 'wednesday';
      case 4:
        return 'thursday';
      case 5:
        return 'friday';
      case 6:
        return 'saturday';
      case 7:
        return 'sunday';
      default:
        return 'monday';
    }
  }
}
