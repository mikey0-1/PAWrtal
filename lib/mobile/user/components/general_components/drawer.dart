import 'package:appwrite/models.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/web/user_web/responsive_page_handlers/web_settings_and_everything_page_handler.dart';
import 'package:flutter/material.dart';
import 'package:capstone_app/pages/user_home/user_home_controller.dart';
import 'package:get/get.dart';
import 'package:capstone_app/data/provider/appwrite_provider.dart';

class MyDrawer extends StatefulWidget {
  const MyDrawer({super.key});

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer>
    with SingleTickerProviderStateMixin {
  final UserHomeController controller =
      UserHomeController(Get.find<AuthRepository>());
  final AppWriteProvider appWriteProvider = Get.find<AppWriteProvider>();
  final AuthRepository authRepository = Get.find<AuthRepository>();

  late User currentUser;
  bool isLoading = true;
  bool isIdVerified = false;
  String? profilePictureId;
  String profilePictureUrl = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.2, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await appWriteProvider.getUser();
      if (user != null) {
        // Check ID verification status
        final verificationStatus =
            await appWriteProvider.getUserVerificationStatus(user.$id);
        // Load profile picture
        final userDoc = await appWriteProvider.getUserById(user.$id);
        String? pfpId;
        String pfpUrl = '';

        if (userDoc != null) {
          pfpId = userDoc.data['profilePictureId'] as String?;
          if (pfpId != null && pfpId.isNotEmpty) {
            pfpUrl = authRepository.getUserProfilePictureUrl(pfpId);
          }
        }

        setState(() {
          currentUser = user;
          isIdVerified = verificationStatus['isVerified'] as bool? ?? false;
          profilePictureId = pfpId;
          profilePictureUrl = pfpUrl;
          isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  double _getResponsiveSize(double screenHeight, double baseSize,
      {double minSize = 0.6, double maxSize = 1.2}) {
    double scale = (screenHeight / 800).clamp(minSize, maxSize);
    return baseSize * scale;
  }

  Widget _buildGradientContainer({required Widget child}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFAFAFA),
            Color(0xFFF5F5F5),
            Color(0xFFEEEEEE),
            Color(0xFFE8E8E8),
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: child,
    );
  }

  Widget _buildAnimatedListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenHeight = MediaQuery.of(context).size.height;

        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: _getResponsiveSize(screenHeight, 8,
                    minSize: 0.7, maxSize: 1.0),
                vertical: _getResponsiveSize(screenHeight, 4,
                    minSize: 0.5, maxSize: 1.0),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(
                    _getResponsiveSize(screenHeight, 12, minSize: 0.8)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(
                      _getResponsiveSize(screenHeight, 12, minSize: 0.8)),
                  onTap: onTap,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal:
                          _getResponsiveSize(screenHeight, 16, minSize: 0.7),
                      vertical:
                          _getResponsiveSize(screenHeight, 12, minSize: 0.6),
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                          _getResponsiveSize(screenHeight, 12, minSize: 0.8)),
                      color: Colors.white.withOpacity(0.8),
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius:
                              _getResponsiveSize(screenHeight, 8, minSize: 0.6),
                          offset: Offset(
                              0,
                              _getResponsiveSize(screenHeight, 2,
                                  minSize: 0.5)),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(_getResponsiveSize(
                              screenHeight, 8,
                              minSize: 0.6)),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1976D2).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                                _getResponsiveSize(screenHeight, 8,
                                    minSize: 0.6)),
                          ),
                          child: Icon(
                            icon,
                            color: iconColor ?? const Color(0xFF1976D2),
                            size: _getResponsiveSize(screenHeight, 20,
                                minSize: 0.7, maxSize: 1.1),
                          ),
                        ),
                        SizedBox(
                            width: _getResponsiveSize(screenHeight, 16,
                                minSize: 0.6)),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: _getResponsiveSize(screenHeight, 16,
                                  minSize: 0.8, maxSize: 1.1),
                              fontWeight: FontWeight.w500,
                              color: textColor ?? const Color(0xFF2C2C2C),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: _getResponsiveSize(screenHeight, 14,
                              minSize: 0.7, maxSize: 1.1),
                          color: Colors.grey.withOpacity(0.6),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileAvatar(double size) {
    if (profilePictureUrl.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1976D2).withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipOval(
          child: Image.network(
            profilePictureUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholderAvatar(size);
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[200],
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    strokeWidth: 2,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    return _buildPlaceholderAvatar(size);
  }

  Widget _buildPlaceholderAvatar(double size) {
    final initial = currentUser.name.isNotEmpty 
        ? currentUser.name[0].toUpperCase() 
        : 'U';
    
    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1976D2).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: Center(
          child: Text(
            initial,
            style: TextStyle(
              color: const Color(0xFF1976D2),
              fontSize: size * 0.4,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfile() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenHeight = MediaQuery.of(context).size.height;
        bool isSmallScreen = screenHeight < 700;
        
        final avatarSize = _getResponsiveSize(screenHeight, 100, 
            minSize: 0.6, maxSize: 1.0);

        // Determine if user should show ID verification (only for regular users, not admin/staff)
        final shouldShowIdVerification =
            currentUser.prefs.data["role"] == 'customer' ||
                currentUser.prefs.data["role"] == 'user' ||
                currentUser.prefs.data["role"] == null;

        return FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            padding: EdgeInsets.all(_getResponsiveSize(screenHeight, 20,
                minSize: 0.6, maxSize: 1.0)),
            child: Column(
              children: [
                // Profile Avatar with profile picture
                _buildProfileAvatar(avatarSize),
                SizedBox(
                    height: _getResponsiveSize(screenHeight, 20,
                        minSize: 0.5, maxSize: 0.8)),

                // User Name
                Text(
                  currentUser.name,
                  style: TextStyle(
                    fontSize: _getResponsiveSize(screenHeight, 24,
                        minSize: 0.8, maxSize: 1.0),
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2C2C2C),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: isSmallScreen ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(
                    height: _getResponsiveSize(screenHeight, 8,
                        minSize: 0.5, maxSize: 0.8)),

                // User Email
                Text(
                  currentUser.email,
                  style: TextStyle(
                    fontSize: _getResponsiveSize(screenHeight, 16,
                        minSize: 0.7, maxSize: 1.0),
                    color: const Color(0xFF666666).withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: isSmallScreen ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(
                    height: _getResponsiveSize(screenHeight, 16,
                        minSize: 0.5, maxSize: 0.8)),

                // ID Verification Status (only for regular users)
                if (shouldShowIdVerification)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal:
                          _getResponsiveSize(screenHeight, 16, minSize: 0.7),
                      vertical:
                          _getResponsiveSize(screenHeight, 8, minSize: 0.6),
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                          _getResponsiveSize(screenHeight, 20, minSize: 0.8)),
                      color: isIdVerified
                          ? const Color(0xFF4CAF50).withOpacity(0.1)
                          : const Color(0xFFFF9800).withOpacity(0.1),
                      border: Border.all(
                        color: isIdVerified
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFFF9800),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isIdVerified
                              ? Icons.verified_user_rounded
                              : Icons.badge_outlined,
                          color: isIdVerified
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFFF9800),
                          size: _getResponsiveSize(screenHeight, 16,
                              minSize: 0.7, maxSize: 1.0),
                        ),
                        SizedBox(
                            width: _getResponsiveSize(screenHeight, 8,
                                minSize: 0.6)),
                        Text(
                          isIdVerified ? "ID Verified" : "ID Not Verified",
                          style: TextStyle(
                            fontSize: _getResponsiveSize(screenHeight, 14,
                                minSize: 0.7, maxSize: 1.0),
                            fontWeight: FontWeight.w600,
                            color: isIdVerified
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFFF9800),
                          ),
                        ),
                        if (!isIdVerified) ...[
                          SizedBox(
                              width: _getResponsiveSize(screenHeight, 8,
                                  minSize: 0.6)),
                          GestureDetector(
                            onTap: () async {
                              Navigator.of(context).pop();
                              final result = await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const WebSettingsAndEverythingPageHandler(
                                          initialIndex: 0),
                                ),
                              );

                              authRepository.cleanupStuckVerifications(currentUser.$id);
                              
                              // Refresh data if verification was completed
                              if (result == true) {
                                await _loadUserData();
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: _getResponsiveSize(screenHeight, 8,
                                    minSize: 0.6),
                                vertical: _getResponsiveSize(screenHeight, 4,
                                    minSize: 0.5),
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1976D2),
                                borderRadius: BorderRadius.circular(
                                    _getResponsiveSize(screenHeight, 12,
                                        minSize: 0.7)),
                              ),
                              child: Text(
                                "Verify Now",
                                style: TextStyle(
                                  fontSize: _getResponsiveSize(screenHeight, 12,
                                      minSize: 0.7, maxSize: 1.0),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: _buildGradientContainer(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  double screenHeight = MediaQuery.of(context).size.height;

                  return SafeArea(
                    child: Column(
                      children: [
                        _buildUserProfile(),
                        Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: _getResponsiveSize(screenHeight, 20,
                                minSize: 0.7),
                          ),
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.grey.withOpacity(0.3),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                            height: _getResponsiveSize(screenHeight, 20,
                                minSize: 0.5, maxSize: 0.8)),
                        Expanded(
                          child: Column(
                            children: [
                              _buildAnimatedListTile(
                                  icon: Icons.person_rounded,
                                  title: "Profile",
                                  onTap: () async {
                                    Navigator.of(context).pop();
                                    final result = await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const WebSettingsAndEverythingPageHandler(
                                                initialIndex: 0),
                                      ),
                                    );
                                    
                                    // Refresh profile picture if updated
                                    if (result == true) {
                                      await _loadUserData();
                                    }
                                  }),
                              _buildAnimatedListTile(
                                icon: Icons.settings_rounded,
                                title: "Settings",
                                onTap: () {
                                  Navigator.of(context).pop();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const WebSettingsAndEverythingPageHandler(
                                              initialIndex: 1),
                                    ),
                                  );
                                },
                              ),
                              _buildAnimatedListTile(
                                icon: Icons.info_outline_rounded,
                                title: "Help",
                                onTap: () {
                                  Navigator.of(context).pop();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const WebSettingsAndEverythingPageHandler(
                                              initialIndex: 2),
                                    ),
                                  );
                                },
                              ),
                              _buildAnimatedListTile(
                                icon: Icons.help_outline_rounded,
                                title: "Give Feedback",
                                onTap: () {
                                  Navigator.of(context).pop();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const WebSettingsAndEverythingPageHandler(
                                              initialIndex: 3),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.all(_getResponsiveSize(
                              screenHeight, 16,
                              minSize: 0.6)),
                          child: _buildAnimatedListTile(
                            icon: Icons.logout_rounded,
                            title: "Sign Out",
                            onTap: () {
                              controller.logout();
                            },
                            iconColor: const Color(0xFFE53935),
                            textColor: const Color(0xFFE53935),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}