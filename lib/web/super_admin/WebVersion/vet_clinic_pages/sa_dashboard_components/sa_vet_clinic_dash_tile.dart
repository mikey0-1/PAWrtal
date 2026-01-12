import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/clinic_settings_model.dart';
import 'package:capstone_app/utils/image_helper.dart';
import 'package:capstone_app/web/dimensions.dart';
import 'package:flutter/material.dart';

class SuperAdminVetClinicTile extends StatefulWidget {
  final Clinic clinic;
  final ClinicSettings? settings;
  final bool isMobile;
  final bool isTablet;

  const SuperAdminVetClinicTile({
    super.key,
    required this.clinic,
    this.settings,
    this.isMobile = false,
    this.isTablet = false,
  });

  @override
  State<SuperAdminVetClinicTile> createState() =>
      _SuperAdminVetClinicTileState();
}

class _SuperAdminVetClinicTileState extends State<SuperAdminVetClinicTile>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late AnimationController _addressPulseController;
  late AnimationController _hoverController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _addressPulseAnimation;
  late Animation<double> _hoverAnimation;

  bool _imageLoaded = false;
  bool _imageError = false;
  String? _cachedImageUrl;
  bool _isHovered = false;

  // Responsive configuration
  late ResponsiveConfig _config;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _updateImageUrl();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _addressPulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _addressPulseAnimation = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _addressPulseController, curve: Curves.easeInOut),
    );

    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _hoverAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shimmerController.dispose();
    _addressPulseController.dispose();
    _hoverController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SuperAdminVetClinicTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.clinic.image != widget.clinic.image ||
        oldWidget.clinic.dashboardPic != widget.clinic.dashboardPic ||
        oldWidget.clinic.clinicName != widget.clinic.clinicName ||
        oldWidget.clinic.services != widget.clinic.services ||
        oldWidget.settings?.gallery != widget.settings?.gallery) {

      setState(() {
        _imageLoaded = false;
        _imageError = false;
      });

      _updateImageUrl();
    }
  }

  void _updateImageUrl() {
    // PRIORITY 1: Check for dashboardPic
    if (widget.clinic.dashboardPic != null &&
        widget.clinic.dashboardPic!.isNotEmpty) {
      final newUrl = getDashImageUrl(widget.clinic.dashboardPic!);
      if (newUrl != _cachedImageUrl) {
        setState(() {
          _cachedImageUrl = newUrl;
        });
      }
      return;
    }

    // PRIORITY 2: Fallback to regular clinic image
    if (widget.clinic.image.isNotEmpty) {
      final newUrl = getDashImageUrl(widget.clinic.image);
      if (newUrl != _cachedImageUrl) {
        setState(() {
          _cachedImageUrl = newUrl;
        });
      }
      return;
    }

    setState(() {
      _cachedImageUrl = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    _config = ResponsiveConfig.fromContext(
      context,
      isMobile: widget.isMobile,
      isTablet: widget.isTablet,
    );

    final isOpen = widget.settings?.isOpenNow() ?? false;
    final detailedStatus = widget.settings?.getDetailedStatus() ?? 'Unknown';
    final galleryCount = widget.settings?.gallery.length ?? 0;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _hoverController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _hoverController.reverse();
      },
      child: AnimatedBuilder(
        animation: _hoverAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _hoverAnimation.value,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 400),
              tween: Tween(begin: 0.92, end: 1.0),
              curve: Curves.easeOutCubic,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(_config.cardRadius),
                      boxShadow: [
                        BoxShadow(
                          color: _isHovered
                              ? const Color.fromRGBO(81, 115, 153, 0.15)
                              : const Color.fromRGBO(81, 115, 153, 0.08),
                          blurRadius: _isHovered ? _config.shadowBlur * 1.6 : _config.shadowBlur,
                          offset: Offset(0, _isHovered ? _config.shadowOffset * 1.5 : _config.shadowOffset),
                        ),
                        BoxShadow(
                          color: _isHovered
                              ? const Color.fromRGBO(81, 115, 153, 0.25)
                              : const Color.fromRGBO(81, 115, 153, 0.15),
                          blurRadius: _isHovered ? _config.shadowBlur * 2.8 : _config.shadowBlur * 2,
                          offset: Offset(0, _isHovered ? _config.shadowOffset * 3 : _config.shadowOffset * 2),
                          spreadRadius: _isHovered ? 3 : 2,
                        ),
                      ],
                    ),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_config.cardRadius),
                        side: BorderSide(
                          color: _isHovered
                              ? const Color.fromRGBO(81, 115, 153, 0.25)
                              : const Color.fromRGBO(81, 115, 153, 0.15),
                          width: _isHovered ? 2.5 : 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image Section - Dynamic flex based on device
                          Expanded(
                            flex: _config.imageFlex,
                            child: _buildImageSection(
                                isOpen, detailedStatus, galleryCount),
                          ),

                          // Info Section
                          Expanded(
                            flex: _config.infoFlex,
                            child: _buildInfoSection(),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageSection(
      bool isOpen, String detailedStatus, int galleryCount) {
    return Stack(
      children: [
        // Main Image with Smooth Transitions
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.92, end: 1.0).animate(animation),
                child: child,
              ),
            );
          },
          child: Container(
            key: ValueKey(_cachedImageUrl ?? 'placeholder'),
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(_config.cardRadius - 2),
              ),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF8FAFC),
                  Color.fromRGBO(81, 115, 153, 0.05),
                ],
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(_config.cardRadius - 2),
              ),
              child: _cachedImageUrl != null
                  ? _buildNetworkImage()
                  : _buildPlaceholder(),
            ),
          ),
        ),

        // Gradient Overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(_config.cardRadius - 2),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.35),
                  Colors.black.withOpacity(0.65),
                ],
                stops: const [0.5, 0.8, 1.0],
              ),
            ),
          ),
        ),

        // Open/Closed Status Badge
        Positioned(
          top: _config.badgePosition,
          right: _config.badgePosition,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: isOpen ? _pulseAnimation.value : 1.0,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: _config.badgePaddingH,
                    vertical: _config.badgePaddingV,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isOpen
                          ? [const Color(0xFF10B981), const Color(0xFF059669)]
                          : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                    ),
                    borderRadius: BorderRadius.circular(_config.badgeRadius),
                    boxShadow: [
                      BoxShadow(
                        color: (isOpen
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444))
                            .withOpacity(0.4),
                        blurRadius: _config.badgeShadowBlur,
                        spreadRadius: _config.badgeShadowSpread,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: _config.statusDotSize,
                        height: _config.statusDotSize,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.8),
                              blurRadius: _config.statusDotGlow,
                              spreadRadius: _config.statusDotGlow * 0.3,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: _config.badgeSpacing),
                      Text(
                        isOpen ? 'OPEN' : 'CLOSED',
                        style: TextStyle(
                          fontSize: _config.badgeFontSize,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Gallery Count Badge
        if (galleryCount > 0)
          Positioned(
            bottom: _config.badgePosition,
            left: _config.badgePosition,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: _config.galleryBadgePaddingH,
                vertical: _config.galleryBadgePaddingV,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.75),
                    Colors.black.withOpacity(0.65),
                  ],
                ),
                borderRadius: BorderRadius.circular(_config.galleryBadgeRadius),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: _config.galleryBadgeShadow,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.photo_library_rounded,
                    color: Colors.white,
                    size: _config.galleryIconSize,
                  ),
                  SizedBox(width: _config.gallerySpacing),
                  Text(
                    '$galleryCount',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: _config.galleryCountSize,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    galleryCount == 1 ? 'photo' : 'photos',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: _config.galleryLabelSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNetworkImage() {
    return Image.network(
      _cachedImageUrl!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _imageError = true;
              _imageLoaded = false;
            });
          }
        });
        return _buildPlaceholder(isError: true);
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_imageLoaded) {
              setState(() {
                _imageLoaded = true;
                _imageError = false;
              });
            }
          });
          return child;
        }
        return _buildShimmerLoading();
      },
    );
  }

  Widget _buildShimmerLoading() {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFF8FAFC),
                const Color.fromRGBO(81, 115, 153, 0.08),
                const Color(0xFFF8FAFC),
              ],
              stops: [
                (_shimmerAnimation.value - 1).clamp(0.0, 1.0),
                _shimmerAnimation.value.clamp(0.0, 1.0),
                (_shimmerAnimation.value + 1).clamp(0.0, 1.0),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(_config.loaderPadding),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromRGBO(81, 115, 153, 0.2),
                        blurRadius: _config.loaderShadow,
                        spreadRadius: _config.loaderShadow * 0.25,
                      ),
                    ],
                  ),
                  child: CircularProgressIndicator(
                    strokeWidth: _config.loaderStroke,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color.fromRGBO(81, 115, 153, 1),
                    ),
                  ),
                ),
                SizedBox(height: _config.loaderSpacing),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: _config.loaderTextPaddingH,
                    vertical: _config.loaderTextPaddingV,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromRGBO(81, 115, 153, 0.15),
                        blurRadius: _config.loaderTextShadow,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    'Loading image...',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: _config.loaderTextSize,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder({bool isError = false}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF8FAFC),
            Color.fromRGBO(81, 115, 153, 0.08),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(_config.placeholderPadding),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color.fromRGBO(81, 115, 153, 0.15),
                    Color.fromRGBO(81, 115, 153, 0.08),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromRGBO(81, 115, 153, 0.2),
                    blurRadius: _config.placeholderShadow,
                    spreadRadius: _config.placeholderShadow * 0.25,
                  ),
                ],
              ),
              child: Icon(
                isError ? Icons.broken_image_rounded : Icons.pets_rounded,
                size: _config.placeholderIconSize,
                color: const Color.fromRGBO(81, 115, 153, 0.6),
              ),
            ),
            SizedBox(height: _config.placeholderSpacing),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: _config.placeholderTextPaddingH,
                vertical: _config.placeholderTextPaddingV,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromRGBO(81, 115, 153, 0.15),
                    blurRadius: _config.placeholderTextShadow,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                isError ? 'Image failed to load' : 'No Image Available',
                style: TextStyle(
                  color: const Color.fromRGBO(81, 115, 153, 1),
                  fontSize: _config.placeholderTextSize,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: EdgeInsets.all(_config.infoPadding),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(_config.cardRadius - 2),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableHeight = constraints.maxHeight;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Clinic Name with Animation
              Flexible(
                flex: 2,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.1),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    widget.clinic.clinicName,
                    key: ValueKey(widget.clinic.clinicName),
                    style: TextStyle(
                      fontSize: _config.clinicNameSize,
                      fontWeight: FontWeight.w900,
                      color: const Color.fromRGBO(81, 115, 153, 1),
                      height: 1.2,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              SizedBox(height: _config.infoSpacing),

              // Creative Address Section with Animated Pin
              Flexible(
                flex: 3,
                child: AnimatedBuilder(
                  animation: _addressPulseAnimation,
                  builder: (context, child) {
                    return Container(
                      padding: EdgeInsets.all(_config.addressContainerPadding),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.fromRGBO(81, 115, 153, 0.12),
                            Color.fromRGBO(81, 115, 153, 0.06),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(_config.addressRadius),
                        border: Border.all(
                          color: const Color.fromRGBO(81, 115, 153, 0.25),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromRGBO(81, 115, 153, 0.15),
                            blurRadius: _config.addressShadow,
                            offset: const Offset(0, 3),
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Animated Location Pin
                          Transform.scale(
                            scale: _addressPulseAnimation.value,
                            child: Container(
                              padding: EdgeInsets.all(_config.locationPinPadding),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color.fromRGBO(81, 115, 153, 1),
                                    Color.fromRGBO(81, 115, 153, 0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(_config.locationPinRadius),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color.fromRGBO(81, 115, 153, 0.3),
                                    blurRadius: _config.locationPinShadow,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.location_on_rounded,
                                size: _config.locationIconSize,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          SizedBox(width: _config.addressRowSpacing),

                          // Address Text
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'LOCATION',
                                  style: TextStyle(
                                    fontSize: _config.locationLabelSize,
                                    fontWeight: FontWeight.w900,
                                    color: const Color.fromRGBO(81, 115, 153, 0.6),
                                    letterSpacing: 1.3,
                                  ),
                                ),
                                SizedBox(height: _config.locationLabelSpacing),
                                Flexible(
                                  child: Text(
                                    widget.clinic.address,
                                    style: TextStyle(
                                      fontSize: _config.addressTextSize,
                                      color: const Color.fromRGBO(81, 115, 153, 1),
                                      height: 1.3,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                                    maxLines: _config.addressMaxLines,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// RESPONSIVE CONFIGURATION CLASS
// Clean, centralized responsive sizing configuration
// ═══════════════════════════════════════════════════════════════

class ResponsiveConfig {
  final bool isMobile;
  final bool isTablet;
  final double screenWidth;

  // Card dimensions
  final double cardRadius;
  final double shadowBlur;
  final double shadowOffset;
  final int imageFlex;
  final int infoFlex;

  // Badge styling
  final double badgePosition;
  final double badgePaddingH;
  final double badgePaddingV;
  final double badgeRadius;
  final double badgeShadowBlur;
  final double badgeShadowSpread;
  final double statusDotSize;
  final double statusDotGlow;
  final double badgeSpacing;
  final double badgeFontSize;

  // Gallery badge
  final double galleryBadgePaddingH;
  final double galleryBadgePaddingV;
  final double galleryBadgeRadius;
  final double galleryBadgeShadow;
  final double galleryIconSize;
  final double gallerySpacing;
  final double galleryCountSize;
  final double galleryLabelSize;

  // Loading & Placeholder
  final double loaderPadding;
  final double loaderShadow;
  final double loaderStroke;
  final double loaderSpacing;
  final double loaderTextPaddingH;
  final double loaderTextPaddingV;
  final double loaderTextShadow;
  final double loaderTextSize;
  final double placeholderPadding;
  final double placeholderShadow;
  final double placeholderIconSize;
  final double placeholderSpacing;
  final double placeholderTextPaddingH;
  final double placeholderTextPaddingV;
  final double placeholderTextShadow;
  final double placeholderTextSize;

  // Info section
  final double infoPadding;
  final double clinicNameSize;
  final double infoSpacing;
  final double addressContainerPadding;
  final double addressRadius;
  final double addressShadow;
  final double locationPinPadding;
  final double locationPinRadius;
  final double locationPinShadow;
  final double locationIconSize;
  final double addressRowSpacing;
  final double locationLabelSize;
  final double locationLabelSpacing;
  final double addressTextSize;
  final int addressMaxLines;

  ResponsiveConfig._({
    required this.isMobile,
    required this.isTablet,
    required this.screenWidth,
    required this.cardRadius,
    required this.shadowBlur,
    required this.shadowOffset,
    required this.imageFlex,
    required this.infoFlex,
    required this.badgePosition,
    required this.badgePaddingH,
    required this.badgePaddingV,
    required this.badgeRadius,
    required this.badgeShadowBlur,
    required this.badgeShadowSpread,
    required this.statusDotSize,
    required this.statusDotGlow,
    required this.badgeSpacing,
    required this.badgeFontSize,
    required this.galleryBadgePaddingH,
    required this.galleryBadgePaddingV,
    required this.galleryBadgeRadius,
    required this.galleryBadgeShadow,
    required this.galleryIconSize,
    required this.gallerySpacing,
    required this.galleryCountSize,
    required this.galleryLabelSize,
    required this.loaderPadding,
    required this.loaderShadow,
    required this.loaderStroke,
    required this.loaderSpacing,
    required this.loaderTextPaddingH,
    required this.loaderTextPaddingV,
    required this.loaderTextShadow,
    required this.loaderTextSize,
    required this.placeholderPadding,
    required this.placeholderShadow,
    required this.placeholderIconSize,
    required this.placeholderSpacing,
    required this.placeholderTextPaddingH,
    required this.placeholderTextPaddingV,
    required this.placeholderTextShadow,
    required this.placeholderTextSize,
    required this.infoPadding,
    required this.clinicNameSize,
    required this.infoSpacing,
    required this.addressContainerPadding,
    required this.addressRadius,
    required this.addressShadow,
    required this.locationPinPadding,
    required this.locationPinRadius,
    required this.locationPinShadow,
    required this.locationIconSize,
    required this.addressRowSpacing,
    required this.locationLabelSize,
    required this.locationLabelSpacing,
    required this.addressTextSize,
    required this.addressMaxLines,
  });

  factory ResponsiveConfig.fromContext(
    BuildContext context, {
    required bool isMobile,
    required bool isTablet,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = !isMobile && !isTablet;

    if (isMobile) {
      return ResponsiveConfig._(
        isMobile: true,
        isTablet: false,
        screenWidth: screenWidth,
        cardRadius: 20.0,
        shadowBlur: 10.0,
        shadowOffset: 4.0,
        imageFlex: 5,
        infoFlex: 4,
        badgePosition: 12.0,
        badgePaddingH: 14.0,
        badgePaddingV: 9.0,
        badgeRadius: 24.0,
        badgeShadowBlur: 10.0,
        badgeShadowSpread: 1.0,
        statusDotSize: 8.0,
        statusDotGlow: 6.0,
        badgeSpacing: 7.0,
        badgeFontSize: 11.0,
        galleryBadgePaddingH: 12.0,
        galleryBadgePaddingV: 8.0,
        galleryBadgeRadius: 20.0,
        galleryBadgeShadow: 8.0,
        galleryIconSize: 16.0,
        gallerySpacing: 6.0,
        galleryCountSize: 13.0,
        galleryLabelSize: 11.0,
        loaderPadding: 16.0,
        loaderShadow: 14.0,
        loaderStroke: 2.5,
        loaderSpacing: 12.0,
        loaderTextPaddingH: 14.0,
        loaderTextPaddingV: 7.0,
        loaderTextShadow: 8.0,
        loaderTextSize: 12.0,
        placeholderPadding: 20.0,
        placeholderShadow: 16.0,
        placeholderIconSize: 60.0,
        placeholderSpacing: 14.0,
        placeholderTextPaddingH: 18.0,
        placeholderTextPaddingV: 9.0,
        placeholderTextShadow: 10.0,
        placeholderTextSize: 13.0,
        infoPadding: 16.0,
        clinicNameSize: 17.0,
        infoSpacing: 12.0,
        addressContainerPadding: 13.0,
        addressRadius: 16.0,
        addressShadow: 8.0,
        locationPinPadding: 8.5,
        locationPinRadius: 11.0,
        locationPinShadow: 6.0,
        locationIconSize: 19.0,
        addressRowSpacing: 11.0,
        locationLabelSize: 9.0,
        locationLabelSpacing: 4.5,
        addressTextSize: 12.5,
        addressMaxLines: 3,
      );
    } else if (isTablet) {
      return ResponsiveConfig._(
        isMobile: false,
        isTablet: true,
        screenWidth: screenWidth,
        cardRadius: 22.0,
        shadowBlur: 11.0,
        shadowOffset: 5.0,
        imageFlex: 6,
        infoFlex: 5,
        badgePosition: 14.0,
        badgePaddingH: 15.0,
        badgePaddingV: 9.5,
        badgeRadius: 24.0,
        badgeShadowBlur: 11.0,
        badgeShadowSpread: 1.5,
        statusDotSize: 9.0,
        statusDotGlow: 7.0,
        badgeSpacing: 7.5,
        badgeFontSize: 11.5,
        galleryBadgePaddingH: 13.0,
        galleryBadgePaddingV: 9.0,
        galleryBadgeRadius: 20.0,
        galleryBadgeShadow: 10.0,
        galleryIconSize: 17.0,
        gallerySpacing: 7.0,
        galleryCountSize: 13.5,
        galleryLabelSize: 11.5,
        loaderPadding: 18.0,
        loaderShadow: 16.0,
        loaderStroke: 2.75,
        loaderSpacing: 14.0,
        loaderTextPaddingH: 15.0,
        loaderTextPaddingV: 7.5,
        loaderTextShadow: 9.0,
        loaderTextSize: 12.5,
        placeholderPadding: 22.0,
        placeholderShadow: 18.0,
        placeholderIconSize: 64.0,
        placeholderSpacing: 15.0,
        placeholderTextPaddingH: 19.0,
        placeholderTextPaddingV: 9.5,
        placeholderTextShadow: 11.0,
        placeholderTextSize: 13.5,
        infoPadding: 17.0,
        clinicNameSize: 15.0,
        infoSpacing: 11.0,
        addressContainerPadding: 11.5,
        addressRadius: 17.0,
        addressShadow: 10.0,
        locationPinPadding: 8.0,
        locationPinRadius: 12.0,
        locationPinShadow: 7.0,
        locationIconSize: 18.0,
        addressRowSpacing: 10.0,
        locationLabelSize: 8.0,
        locationLabelSpacing: 4.0,
        addressTextSize: 10.5,
        addressMaxLines: 2,
      );
    } else {
      // Desktop
      return ResponsiveConfig._(
        isMobile: false,
        isTablet: false,
        screenWidth: screenWidth,
        cardRadius: 26.0,
        shadowBlur: 14.0,
        shadowOffset: 6.0,
        imageFlex: 5,
        infoFlex: 4,
        badgePosition: 18.0,
        badgePaddingH: 16.0,
        badgePaddingV: 10.0,
        badgeRadius: 24.0,
        badgeShadowBlur: 14.0,
        badgeShadowSpread: 2.0,
        statusDotSize: 10.0,
        statusDotGlow: 8.0,
        badgeSpacing: 8.0,
        badgeFontSize: 12.0,
        galleryBadgePaddingH: 14.0,
        galleryBadgePaddingV: 10.0,
        galleryBadgeRadius: 20.0,
        galleryBadgeShadow: 12.0,
        galleryIconSize: 18.0,
        gallerySpacing: 8.0,
        galleryCountSize: 14.0,
        galleryLabelSize: 12.0,
        loaderPadding: 20.0,
        loaderShadow: 20.0,
        loaderStroke: 3.0,
        loaderSpacing: 16.0,
        loaderTextPaddingH: 16.0,
        loaderTextPaddingV: 8.0,
        loaderTextShadow: 10.0,
        loaderTextSize: 13.0,
        placeholderPadding: 24.0,
        placeholderShadow: 20.0,
        placeholderIconSize: 68.0,
        placeholderSpacing: 16.0,
        placeholderTextPaddingH: 20.0,
        placeholderTextPaddingV: 10.0,
        placeholderTextShadow: 12.0,
        placeholderTextSize: 14.0,
        infoPadding: 18.0,
        clinicNameSize: 17.0,
        infoSpacing: 13.0,
        addressContainerPadding: 13.0,
        addressRadius: 18.0,
        addressShadow: 12.0,
        locationPinPadding: 9.0,
        locationPinRadius: 13.0,
        locationPinShadow: 8.0,
        locationIconSize: 19.0,
        addressRowSpacing: 12.0,
        locationLabelSize: 9.0,
        locationLabelSpacing: 5.0,
        addressTextSize: 12.0,
        addressMaxLines: 3,
      );
    }
  }
}