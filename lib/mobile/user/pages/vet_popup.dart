import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/clinic_settings_model.dart';
import 'package:capstone_app/data/models/ratings_and_review_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/web/dimensions.dart';
import 'package:capstone_app/web/user_web/responsive_page_handlers/web_clinic_page_handler.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:get/get.dart';

class VetPopup extends StatefulWidget {
  final Clinic clinic;
  final ClinicSettings? clinicSettings;

  const VetPopup({
    super.key,
    required this.clinic,
    this.clinicSettings,
  });

  @override
  State<VetPopup> createState() => _VetPopupState();
}

class _VetPopupState extends State<VetPopup> {
  ClinicRatingStats? _ratingStats;
  bool _isLoadingRating = true;

  @override
  void initState() {
    super.initState();
    _loadRatingStats();
  }

  Future<void> _loadRatingStats() async {
    try {
      final authRepository = Get.find<AuthRepository>();
      final stats = await authRepository
          .getClinicRatingStats(widget.clinic.documentId ?? '');
      if (mounted) {
        setState(() {
          _ratingStats = stats;
          _isLoadingRating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRating = false;
        });
      }
    }
  }

  Color getStatusColor() {
    final settings = widget.clinicSettings;
    if (settings == null) return Colors.grey;

    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final isTodayClosedDate = settings.closedDates.contains(todayStr);

    if (isTodayClosedDate) {
      return Colors.red;
    } else if (!settings.isOpen) {
      return Colors.red;
    } else if (settings.isOpenNow()) {
      return Colors.green;
    } else if (settings.isOpenToday()) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String getStatusText() {
    final settings = widget.clinicSettings;
    if (settings == null) return "Unknown";

    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final isTodayClosedDate = settings.closedDates.contains(todayStr);

    if (isTodayClosedDate) {
      return "CLOSED TODAY";
    } else if (!settings.isOpen) {
      return "CLOSED";
    } else if (settings.isOpenNow()) {
      return "OPEN";
    } else if (settings.isOpenToday()) {
      return "CLOSED NOW";
    } else {
      return "CLOSED";
    }
  }

  String _getImageUrl() {
    if (widget.clinicSettings != null &&
        widget.clinicSettings!.dashboardPic.isNotEmpty) {
      return widget.clinicSettings!.dashboardPic;
    }
    if (widget.clinicSettings != null &&
        widget.clinicSettings!.gallery.isNotEmpty) {
      return widget.clinicSettings!.gallery.first;
    }
    return widget.clinic.image;
  }

  Widget _buildRatingDisplay() {
    if (_isLoadingRating) {
      return const SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    final rating = _ratingStats?.averageRating ?? 0.0;
    final reviewCount = _ratingStats?.totalReviews ?? 0;

    if (reviewCount == 0) {
      return const Text(
        "No reviews",
        style: TextStyle(
          fontSize: 11,
          color: Colors.white70,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 14),
        const SizedBox(width: 3),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        Text(
          " ($reviewCount)",
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  @override
Widget build(BuildContext context) {
  final imageUrl = _getImageUrl();
  final description = widget.clinic.description.isNotEmpty
      ? widget.clinic.description
      : "No description available.";

  // Get screen width for responsiveness
  final screenWidth = MediaQuery.of(context).size.width;
  final isMobile = screenWidth < mobileWidth;
  
  // Responsive dimensions
  final cardWidth = isMobile ? screenWidth * 0.85 : 250.0;
  final imageHeight = isMobile ? 120.0 : 150.0;
  final borderRadius = isMobile ? 20.0 : 30.0;
  final titleFontSize = isMobile ? 14.0 : 16.0;
  final descriptionFontSize = isMobile ? 11.0 : 12.0;
  final padding = isMobile ? 8.0 : 10.0;
  final maxDescriptionLines = isMobile ? 2 : 3;
  final maxContentHeight = isMobile ? 160.0 : 200.0;

  return Container(
    width: double.infinity,
    alignment: Alignment.center,
    padding: EdgeInsets.symmetric(vertical: isMobile ? 5 : 10),
    child: SizedBox(
      width: cardWidth,
      child: Card(
        color: const Color.fromARGB(255, 39, 86, 139),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: BorderSide(color: Colors.white, width: isMobile ? 1.5 : 2),
        ),
        elevation: 5,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(borderRadius),
                topRight: Radius.circular(borderRadius),
              ),
              child: SizedBox(
                width: cardWidth,
                height: imageHeight,
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'lib/images/placeholder.png',
                            fit: BoxFit.cover,
                          );
                        },
                      )
                    : Image.asset(
                        'lib/images/placeholder.png',
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(padding),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(isMobile ? 15 : 30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 75.0, sigmaY: 75.0),
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: maxContentHeight,
                    ),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(50, 71, 161, 196),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    width: cardWidth,
                    padding: EdgeInsets.all(padding),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            widget.clinic.clinicName,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: isMobile ? 4 : 5),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 6 : 8,
                                vertical: isMobile ? 3 : 4),
                            decoration: BoxDecoration(
                              color: getStatusColor(),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              getStatusText(),
                              style: TextStyle(
                                  fontSize: isMobile ? 10 : 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(height: isMobile ? 4 : 5),
                          _buildRatingDisplay(),
                          SizedBox(height: isMobile ? 4 : 5),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: descriptionFontSize,
                              color: Colors.white,
                            ),
                            maxLines: maxDescriptionLines,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: isMobile ? 8 : 10),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      WebClinicPageHandlerUpdated(
                                    clinic: widget.clinic,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 201, 221, 238),
                              foregroundColor: Colors.black,
                              minimumSize: Size(
                                  double.infinity, isMobile ? 36 : 40),
                              padding: EdgeInsets.symmetric(
                                  vertical: isMobile ? 8 : 10),
                            ),
                            child: Text(
                              "More Info",
                              style: TextStyle(
                                  fontSize: isMobile ? 12 : 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
