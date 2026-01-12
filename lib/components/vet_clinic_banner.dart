import 'package:capstone_app/pages/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VetClinicBanner extends StatelessWidget {
  final bool isMobile;

  const VetClinicBanner({
    super.key,
    this.isMobile = false,
  });

  @override
  @override
  Widget build(BuildContext context) {
    // Get screen width for responsive padding
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate horizontal padding to match the clinic grid
    double horizontalPadding;
    if (isMobile) {
      horizontalPadding = 16;
    } else {
      // Use the same responsive padding calculation as the landing page
      const double minScreen = 1100;
      const double maxScreen = 1920;
      const double minPadding = 40;
      const double maxPadding = 200;

      if (screenWidth <= minScreen) {
        horizontalPadding = minPadding;
      } else if (screenWidth >= maxScreen) {
        horizontalPadding = maxPadding;
      } else {
        double t = (screenWidth - minScreen) / (maxScreen - minScreen);
        horizontalPadding = minPadding + t * (maxPadding - minPadding);
      }
    }

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: isMobile ? 16 : 20,
      ),
      height: isMobile ? null : 400, // Fixed height for desktop
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2C5F8D), // Deeper blue
            const Color(0xFF517399),
            const Color(0xFF6B9BC3), // Lighter blue
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(isMobile ? 20 : 24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF517399).withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles/dots pattern
          ...List.generate(20, (index) {
            return Positioned(
              top: (index * 37.5) % 280,
              left: (index * 83.3) % 100,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),

          // Main content
          Padding(
            padding: EdgeInsets.all(isMobile ? 24 : 40),
            child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Icon with glow effect
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(
            Icons.local_hospital_rounded,
            color: Colors.white,
            size: 48,
          ),
        ),
        const SizedBox(height: 20),

        // Main headline
        const Text(
          'Join PAWrtal Today!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),

        // Subtitle
        Text(
          'Register your veterinary clinic and connect with pet owners in San Jose del Monte',
          style: TextStyle(
            color: Colors.white.withOpacity(0.95),
            fontSize: 15,
            height: 1.5,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // CTA Button with gradient
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.white, Color(0xFFF5F5F5)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Get.toNamed(Routes.vetClinicRegistration),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Register Now',
                      style: TextStyle(
                        color: Color(0xFF2C5F8D),
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Color(0xFF2C5F8D),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Benefits with icons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBenefit(Icons.check_circle_rounded, 'Free'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            ),
            _buildBenefit(Icons.check_circle_rounded, 'Quick Setup'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            ),
            _buildBenefit(Icons.check_circle_rounded, 'Instant'),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive sizing based on available width
        final isCompact = constraints.maxWidth < 900;
        final iconSize = isCompact ? 48.0 : 64.0;
        final titleSize = isCompact ? 28.0 : 38.0;
        final descSize = isCompact ? 15.0 : 17.0;
        final spacing = isCompact ? 40.0 : 60.0;

        return Row(
          children: [
            // Left Side - Icon & Visual Elements
            Expanded(
              flex: isCompact ? 4 : 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Large icon with glow
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.2),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.local_hospital_rounded,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Feature list
                  _buildDesktopBenefit(Icons.verified_rounded,
                      'Verified Platform', 'Trusted by pet owners', isCompact),
                  const SizedBox(height: 16),
                  _buildDesktopBenefit(Icons.people_rounded,
                      'Reach More Clients', 'Expand your practice', isCompact),
                  const SizedBox(height: 16),
                  _buildDesktopBenefit(Icons.calendar_today_rounded,
                      'Manage Appointments', 'Easy scheduling', isCompact),
                ],
              ),
            ),

            SizedBox(width: spacing),

            // Right Side - Main Content
            Expanded(
              flex: isCompact ? 6 : 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Main headline
                  Text(
                    'Grow Your Veterinary Practice',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      height: 1.15,
                    ),
                  ),
                  SizedBox(height: isCompact ? 12 : 16),

                  // Description
                  Text(
                    'Join PAWrtal - the leading pet care platform in San Jose del Monte, Bulacan. Connect with pet owners, manage appointments, and grow your business.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: descSize,
                      height: 1.6,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isCompact ? 20 : 32),

                  // CTA Button
                  ElevatedButton(
                    onPressed: () {
                      Get.toNamed(Routes.vetClinicRegistration);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF2C5F8D),
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 28 : 40,
                        vertical: isCompact ? 16 : 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(isCompact ? 12 : 16),
                      ),
                      elevation: 8,
                      shadowColor: Colors.black.withOpacity(0.3),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Register Your Clinic',
                          style: TextStyle(
                            fontSize: isCompact ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                        SizedBox(width: isCompact ? 8 : 12),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFF2C5F8D),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: isCompact ? 18 : 20,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: isCompact ? 16 : 20),

                  // Benefits footer
                  Wrap(
                    spacing: isCompact ? 12 : 20,
                    runSpacing: 8,
                    children: [
                      _buildDesktopCheckmark('No setup fees', isCompact),
                      _buildDesktopCheckmark('Quick approval', isCompact),
                      _buildDesktopCheckmark('Free forever', isCompact),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBenefit(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.95),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopBenefit(
      IconData icon, String title, String subtitle, bool isCompact) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(isCompact ? 8 : 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(isCompact ? 10 : 12),
          ),
          child: Icon(icon, color: Colors.white, size: isCompact ? 20 : 24),
        ),
        SizedBox(width: isCompact ? 12 : 16),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isCompact ? 14 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: isCompact ? 12 : 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopCheckmark(String text, bool isCompact) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.check_circle_rounded,
          color: Colors.white.withOpacity(0.9),
          size: isCompact ? 16 : 18,
        ),
        SizedBox(width: isCompact ? 4 : 6),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.95),
            fontSize: isCompact ? 12 : 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
