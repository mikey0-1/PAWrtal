import 'package:capstone_app/pages/routes/app_pages.dart';
import 'package:capstone_app/web/user_web/desktop_web/components/appbar_components/user_web_notification_icon.dart';
import 'package:capstone_app/web/user_web/desktop_web/components/appbar_components/user_web_profile_icon.dart';
import 'package:capstone_app/web/user_web/desktop_web/components/clinic_page_components/web_appointment_panel.dart';
import 'package:capstone_app/web/user_web/desktop_web/components/clinic_page_components/web_clinic_description.dart';
import 'package:capstone_app/web/user_web/desktop_web/components/clinic_page_components/web_clinic_location.dart';
import 'package:capstone_app/web/user_web/desktop_web/components/clinic_page_components/web_clinic_services.dart';
import 'package:capstone_app/web/user_web/desktop_web/components/clinic_page_components/web_like.dart';
import 'package:capstone_app/web/user_web/desktop_web/components/clinic_page_components/web_picture_gallery.dart';
import 'package:capstone_app/web/user_web/desktop_web/components/clinic_page_components/web_share_button.dart';
import 'package:capstone_app/web/user_web/desktop_web/components/clinic_page_components/web_hover_underline_text.dart';
import 'package:capstone_app/web/user_web/desktop_web/components/clinic_page_components/web_ratings_and_reviews.dart';
import 'package:capstone_app/web/user_web/desktop_web/components/dashboard_components/web_search_bar.dart';
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/web/user_web/controllers/user_web_appointment_controller.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:capstone_app/data/id_verification/guards/unified_verification_guard.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WebLandingClinicPage extends StatefulWidget {
  final Clinic clinic;

  const WebLandingClinicPage({super.key, required this.clinic});

  @override
  State<WebLandingClinicPage> createState() => _WebLandingClinicPageState();
}

class _WebLandingClinicPageState extends State<WebLandingClinicPage> {
  final ScrollController _scrollController = ScrollController();
  bool _showWidget = false;
  bool _showAppointmentPanel = false;

  final galleryKey = GlobalKey();
  final servicesKey = GlobalKey();
  final locationKey = GlobalKey();
  final reviewsKey = GlobalKey();
  final appointmentKey = GlobalKey();

  late WebAppointmentController _appointmentController;
  late UnifiedVerificationGuard _verificationGuard; // NEW

  String _clinicProfilePictureUrl = '';
  bool _isLoadingProfilePicture = true;

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.6,
      );
    }
  }

  // MODIFIED: Add verification check before toggling panel
  Future<void> _toggleAppointmentPanel() async {
    final session = Get.find<UserSessionService>();

    // Check verification before showing appointment panel
    final canAccess = await _verificationGuard.canAccessFeature(
      context: context,
      userId: session.userId,
      email: session.userEmail,
      userRole: session.userRole,
      featureName: 'appointment',
    );

    if (canAccess) {
      setState(() {
        _showAppointmentPanel = !_showAppointmentPanel;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _appointmentController = Get.put(
      WebAppointmentController(
        authRepository: Get.find<AuthRepository>(),
        session: Get.find<UserSessionService>(),
        clinic: widget.clinic,
      ),
      tag: widget.clinic.documentId,
    );

    _verificationGuard = UnifiedVerificationGuard(Get.find<AuthRepository>());

    // NEW: Load clinic profile picture
    _loadClinicProfilePicture();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    Get.delete<WebAppointmentController>(tag: widget.clinic.documentId);
    super.dispose();
  }

  double getResponsivePadding(double screenWidth) {
    const double minScreen = 1100;
    const double maxScreen = 1920;
    const double minPadding = 16;
    const double maxPadding = 380;

    if (screenWidth <= minScreen) return minPadding;
    if (screenWidth >= maxScreen) return maxPadding;

    double t = (screenWidth - minScreen) / (maxScreen - minScreen);
    return minPadding + t * (maxPadding - minPadding);
  }

  double responsiveRight(
      {required double screenWidth,
      required double desiredMaxRight,
      required double desiredMinRight}) {
    const double minScreen = 1100;
    const double maxScreen = 1920;

    if (screenWidth <= minScreen) return desiredMinRight;
    if (screenWidth >= maxScreen) return desiredMaxRight;

    double t = (screenWidth - minScreen) / (maxScreen - minScreen);
    return desiredMinRight + t * (desiredMaxRight - desiredMinRight);
  }

  double getAppointmentPanelMaxHeight(double screenHeight) {
    if (screenHeight <= 768) {
      return screenHeight * 0.75;
    } else if (screenHeight <= 1080) {
      return screenHeight * 0.7;
    } else {
      return 800;
    }
  }

  bool shouldUseCompactMode(double screenHeight) {
    return screenHeight <= 900;
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _isLoadingProfilePicture
                  ? Container(
                      height: 40,
                      width: 40,
                      color: Colors.grey[200],
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : _clinicProfilePictureUrl.isNotEmpty
                      ? Image.network(
                          _clinicProfilePictureUrl,
                          height: 40,
                          width: 40,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 40,
                              width: 40,
                              color: Colors.grey[200],
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 40,
                              width: 40,
                              color: Colors.grey[300],
                              child: Icon(Icons.business,
                                  color: Colors.grey[600], size: 24),
                            );
                          },
                        )
                      : Container(
                          height: 40,
                          width: 40,
                          color: Colors.grey[300],
                          child: Icon(Icons.business,
                              color: Colors.grey[600], size: 24),
                        ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                widget.clinic.clinicName,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: SizedBox(
            width: double.infinity,
            child: Divider(
              height: 1,
              thickness: 0.5,
              color: Colors.grey,
            ),
          ),
        ),
        WebClinicDescriptionUpdated(clinic: widget.clinic),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: SizedBox(
            width: double.infinity,
            child: Divider(
              height: 1,
              thickness: 0.5,
              color: Colors.grey,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Text(
                'Services offered',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 22),
              )
            ],
          ),
        ),
        WebClinicServicesUpdated(
          key: servicesKey,
          clinic: widget.clinic,
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: SizedBox(
            width: double.infinity,
            child: Divider(
              height: 1,
              thickness: 0.5,
              color: Colors.grey,
            ),
          ),
        ),
        WebRatingsAndReviews(
          key: reviewsKey,
          clinicId: widget.clinic.documentId!,
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: SizedBox(
            width: double.infinity,
            child: Divider(
              height: 1,
              thickness: 0.5,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final horizontalPadding = getResponsivePadding(screenWidth);

    double iconRight = responsiveRight(
        screenWidth: screenWidth, desiredMaxRight: 395, desiredMinRight: 30);

    double notifRight = responsiveRight(
        screenWidth: screenWidth, desiredMaxRight: 445, desiredMinRight: 80);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Container(
                  height: 81,
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                          bottom: BorderSide(color: Colors.black26, width: 1))),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: SizedBox(
                      height: 80,
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            child: Image.asset(
                              'lib/images/PAWrtal_logo.png',
                              width: 150,
                              height: 100,
                            ),
                          ),
                          const Spacer(flex: 1),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Clinic name and gallery
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.clinic.clinicName,
                                style: const TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        WebPictureGalleryUpdated(
                          key: galleryKey,
                          clinic: widget.clinic,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Main content - single column layout
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: _buildContent(),
                ),
              ),

              // Location section
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: const Padding(
                        padding: EdgeInsets.only(top: 64, bottom: 64),
                        child: Divider(
                          height: 1,
                          thickness: 0.5,
                        ),
                      ),
                    ),
                    WebClinicLocationUpdated(
                      key: locationKey,
                      clinic: widget.clinic,
                    ),
                    const SizedBox(height: 64),
                  ],
                ),
              ),
            ],
          ),

          // Navigation bar overlay
          if (_showWidget)
            Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  height: 80,
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                          bottom: BorderSide(color: Colors.black26, width: 1))),
                  child: Row(
                    spacing: 18,
                    children: [
                      WebHoverUnderlineText(
                        text: "Gallery",
                        onTap: () => _scrollToSection(galleryKey),
                      ),
                      WebHoverUnderlineText(
                        text: "Services",
                        onTap: () => _scrollToSection(servicesKey),
                      ),
                      WebHoverUnderlineText(
                        text: "Reviews & Ratings",
                        onTap: () => _scrollToSection(reviewsKey),
                      ),
                      WebHoverUnderlineText(
                        text: "Location",
                        onTap: () => _scrollToSection(locationKey),
                      )
                    ],
                  ),
                )),

          // Floating Appointment Panel (Chat-style)
          if (_showAppointmentPanel)
            Positioned(
              right: 24,
              bottom: 24,
              child: Container(
                width: 420,
                height: screenHeight * 0.75,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header
                    InkWell(
                      onTap: _toggleAppointmentPanel,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5173B8),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Book Appointment',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: _toggleAppointmentPanel,
                              icon: const Icon(Icons.close,
                                  color: Colors.white, size: 20),
                              tooltip: 'Close',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Scrollable content
                    Expanded(
                      child: Container(
                        color: Colors.grey.shade50,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: EnhancedWebAppointmentPanel(
                            key: appointmentKey,
                            clinic: widget.clinic,
                            maxHeight:
                                getAppointmentPanelMaxHeight(screenHeight),
                            compact: true,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: !_showAppointmentPanel
          ? FloatingActionButton.extended(
              onPressed:
                  () => _showLoginPrompt(context, 'book an appointment'), // Already has guard
              backgroundColor: const Color(0xFF5173B8),
              icon: const Icon(Icons.calendar_today, color: Colors.white),
              label: const Text(
                'Book Appointment',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
    );
  }

  Future<void> _loadClinicProfilePicture() async {
    try {
      final authRepository = Get.find<AuthRepository>();

      if (widget.clinic.profilePictureId != null &&
          widget.clinic.profilePictureId!.isNotEmpty) {
        final profilePicUrl = authRepository
            .getClinicProfilePictureUrl(widget.clinic.profilePictureId!);

        setState(() {
          _clinicProfilePictureUrl = profilePicUrl;
          _isLoadingProfilePicture = false;
        });

      } else {
        // Fallback to clinic.image if no profile picture
        setState(() {
          _clinicProfilePictureUrl = widget.clinic.image;
          _isLoadingProfilePicture = false;
        });
      }
    } catch (e) {
      setState(() {
        _clinicProfilePictureUrl = widget.clinic.image;
        _isLoadingProfilePicture = false;
      });
    }
  }

  void _showLoginPrompt(BuildContext context, String action) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.login,
              color: Color(0xFF517399),
            ),
            const SizedBox(width: 12),
            const Text('Login Required'),
          ],
        ),
        content: Text(
          'Please log in to $action with this clinic.',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Get.toNamed(Routes.login);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF517399),
            ),
            child: const Text(
              'Login',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
