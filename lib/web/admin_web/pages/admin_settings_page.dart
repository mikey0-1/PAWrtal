import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' hide User;
import 'package:capstone_app/data/models/feedback_and_report_model.dart';
import 'package:capstone_app/data/models/staff_model.dart';
import 'package:capstone_app/data/models/user_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:capstone_app/web/admin_web/components/appbar/admin_change_pass_controller.dart';
import 'package:capstone_app/web/admin_web/components/appbar/admin_feedback_controller.dart';
import 'package:capstone_app/web/admin_web/components/appbar/admin_pfp_controller.dart';
import 'package:capstone_app/web/admin_web/components/appbar/admin_verify_user_controller.dart';
import 'package:capstone_app/web/admin_web/components/appbar/staff_change_pass_controller.dart';
import 'package:capstone_app/web/admin_web/pages/admin_web_clinicpage.dart';
import 'package:capstone_app/web/pages/web_admin_home/web_admin_home_controller.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get_storage/get_storage.dart';
import 'package:capstone_app/utils/logout_helper.dart';

class FAQItem {
  final String question;
  final String answer;
  bool isExpanded;

  FAQItem({
    required this.question,
    required this.answer,
    this.isExpanded = false,
  });
}

List<FAQItem> faqItems = [
  FAQItem(
    question: 'How do I manage my clinic?',
    answer: '''Managing your clinic involves several key areas:

1. Go to Dashboard
2. Click on Clinic Settings
3. Update clinic information including:
   • Clinic name and contact details
   • Operating hours
   • Services offered
   • Staff management
4. Save your changes

For staff management, use the Staff section to add, edit, or remove staff members.''',
  ),
  FAQItem(
    question: 'How do I view appointment requests?',
    answer: '''To view and manage appointment requests:

1. Navigate to Appointments section
2. Filter by status (Pending, Accepted, Declined)
3. Click on an appointment to view details
4. Accept or decline the appointment
5. Add notes if needed
6. Save changes

You can also reschedule appointments from this view.''',
  ),
  FAQItem(
    question: 'How do I manage staff members?',
    answer: '''To manage your clinic staff:

1. Go to Staff Management
2. Click "Add New Staff" to create staff accounts
3. Assign staff to specific departments
4. Set staff authorities and permissions
5. View active and inactive staff members
6. Edit staff information as needed
7. Deactivate or remove staff members

Each staff member can be assigned specific authorities based on their role.''',
  ),
//   FAQItem(
//     question: 'How do I view clinic analytics?',
//     answer: '''To view your clinic analytics:

// 1. Go to Dashboard
// 2. View appointment statistics:
//    • Total appointments
//    • This month's appointments
//    • Pending, accepted, and declined counts
// 3. View staff statistics
// 4. Monitor customer satisfaction through reviews
// 5. Export reports for further analysis

// Analytics update in real-time as appointments are processed.''',
//   ),
];

class AdminSettingsPage extends StatefulWidget {
  final int initialIndex;

  const AdminSettingsPage({super.key, this.initialIndex = 0});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  int selectedIndex = 0;
  final GetStorage storage = GetStorage();

  final TextEditingController _searchController = TextEditingController();
  User? _searchedUser;
  bool _isSearching = false;
  String? _searchError;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToDashboard() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Widget _buildBackButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Center(
        child: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back, size: 24, color: Colors.grey[700]),
          padding: const EdgeInsets.all(8),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex;
  }

  void _showSnackbar(String title, String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  bool get _isMobile => MediaQuery.of(context).size.width < 768;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, Object? result) {},
      child: KeyboardListener(
        focusNode: FocusNode(),
        autofocus: true,
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.keyS &&
                (HardwareKeyboard.instance.isControlPressed ||
                    HardwareKeyboard.instance.isMetaPressed)) {
              return;
            }
            if (event.logicalKey == LogicalKeyboardKey.escape) {
              Navigator.of(context).pop();
              return;
            }
          }
        },
        child: Scaffold(
          backgroundColor: Colors.grey[50],
          body: _isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Column(
      children: [
        Container(
          height: 81,
          decoration: const BoxDecoration(
              color: Colors.white,
              border:
                  Border(bottom: BorderSide(color: Colors.black26, width: 1))),
          child: Column(
            children: [
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: _getResponsivePadding()),
                child: SizedBox(
                  height: 80,
                  child: Row(
                    children: [
                      _buildBackButton(),
                      const Spacer(flex: 1),
                      InkWell(
                        onTap: _navigateToDashboard,
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
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Container(
                width: 240,
                color: Colors.white,
                child: Column(
                  children: [
                    _buildSidebarItem('Profile', Icons.person, 0),
                    _buildSidebarItem('Settings', Icons.settings, 1),
                    _buildSidebarItem('Verify User', Icons.verified_user, 2),
                    _buildSidebarItem('Help', Icons.help_outline, 3),
                    _buildSidebarItem(
                        'Send Feedback', Icons.feedback_outlined, 4),
                    const Divider(color: Colors.grey),
                    _buildSidebarItem('Sign out', Icons.logout, -1,
                        isDestructive: true),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  color: Colors.grey[50],
                  child: _buildContentArea(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: _buildMobileBackButton(),
        ),
        title: Center(
          child: InkWell(
            onTap: _navigateToDashboard,
            child: Image.asset(
              'lib/images/PAWrtal_logo.png',
              width: 100,
              height: 60,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Builder(
              builder: (context) => IconButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: Icon(Icons.menu, color: Colors.grey[700], size: 24),
                padding: const EdgeInsets.all(8),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.black26,
            height: 1,
          ),
        ),
      ),
      drawer: _buildMobileDrawer(),
      body: Container(
        color: Colors.grey[50],
        child: _buildContentArea(),
      ),
    );
  }

  Widget _buildMobileDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple[400]!, Colors.blue[400]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.admin_panel_settings,
                      color: Colors.purple, size: 32),
                ),
                const SizedBox(height: 12),
                Text(
                  storage.read("name") ?? "Admin",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  storage.read("email") ?? "admin@example.com",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 8),
                _buildDrawerItem('Profile', Icons.person, 0),
                _buildDrawerItem('Settings', Icons.settings, 1),
                _buildDrawerItem('Verify User', Icons.verified_user, 2),
                _buildDrawerItem('Help', Icons.help_outline, 3),
                _buildDrawerItem('Send Feedback', Icons.feedback_outlined, 4),
                const Divider(color: Colors.grey),
                _buildDrawerItem('Sign out', Icons.logout, -1,
                    isDestructive: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(String title, IconData icon, int index,
      {bool isDestructive = false}) {
    final isSelected = selectedIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: isSelected
            ? LinearGradient(
                colors: [Colors.blue[50]!, Colors.blue[100]!.withOpacity(0.3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (title == 'Sign out') {
              Navigator.pop(context); // Close drawer
              _showLogoutDialog();
            } else {
              setState(() => selectedIndex = index);
              Navigator.pop(context); // Close drawer after selection
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? Colors.red.withOpacity(0.1)
                        : isSelected
                            ? Colors.blue.withOpacity(0.15)
                            : Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isDestructive
                        ? Colors.red[600]
                        : isSelected
                            ? Colors.blue[700]
                            : Colors.grey[600],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isDestructive
                          ? Colors.red[600]
                          : isSelected
                              ? Colors.blue[700]
                              : Colors.grey[700],
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.blue[600],
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileBackButton() {
    return IconButton(
      onPressed: () => Navigator.pop(context),
      icon: Icon(Icons.arrow_back, size: 24, color: Colors.grey[700]),
      padding: const EdgeInsets.all(8),
    );
  }

  double _getResponsivePadding() => MediaQuery.of(context).size.width * 0.02;

  Widget _buildSidebarItem(String title, IconData icon, int index,
      {bool isDestructive = false}) {
    final isSelected = selectedIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: isSelected
            ? LinearGradient(
                colors: [Colors.blue[50]!, Colors.blue[100]!.withOpacity(0.3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (title == 'Sign out') {
              _showLogoutDialog();
            } else {
              setState(() => selectedIndex = index);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? Colors.red.withOpacity(0.1)
                        : isSelected
                            ? Colors.blue.withOpacity(0.15)
                            : Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isDestructive
                        ? Colors.red[600]
                        : isSelected
                            ? Colors.blue[700]
                            : Colors.grey[600],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isDestructive
                          ? Colors.red[600]
                          : isSelected
                              ? Colors.blue[700]
                              : Colors.grey[700],
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.blue[600],
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentArea() {
    switch (selectedIndex) {
      case 0:
        return _buildProfileContent();
      case 1:
        return _buildSettingsContent();
      case 2:
        return _buildVerifyUserContent();
      case 3:
        return _buildHelpContent();
      case 4:
        return _buildFeedbackContent();
      default:
        return _buildProfileContent();
    }
  }

  Widget _buildProfileContent() {
    final userName = storage.read("name") ?? "Admin";
    final userRole = storage.read("role") ?? "admin";
    final clinicName = storage.read("clinicName") ?? "N/A";
    final clinicId = storage.read("clinicId") ?? "";
    final userJoinDate = storage.read("joinDate") ?? "January 2024";

    // Determine if user is staff
    final isStaff = userRole == 'staff';

    // Initialize profile picture controller with unique tag
    final profilePictureController = Get.put(
      AdminPfpController(authRepository: Get.find<AuthRepository>()),
      tag:
          'profile_picture_${userRole}_${DateTime.now().millisecondsSinceEpoch}',
    );

    // CRITICAL: Fetch staff data immediately on widget build
    if (isStaff) {
      final staffId = storage.read("staffId") as String?;

      if (staffId != null && staffId.isNotEmpty) {
        // Fetch staff data synchronously using FutureBuilder
        return FutureBuilder<Staff?>(
          future: Get.find<AuthRepository>().getStaffByDocumentId(staffId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.blue[600]),
                    const SizedBox(height: 16),
                    Text(
                      'Loading profile...',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            String profilePictureId = '';
            String userEmail = "N/A";

            if (snapshot.hasData && snapshot.data != null) {
              final staff = snapshot.data!;
              profilePictureId = staff.image;
              userEmail = staff.email.isNotEmpty ? staff.email : 'N/A';

              // Update storage
              storage.write('staffProfilePictureId', profilePictureId);
              storage.write('email', userEmail);
              storage.write('name', staff.name);

              // Set profile picture in controller
              if (profilePictureId.isNotEmpty) {
                profilePictureController
                    .setCurrentProfilePicture(profilePictureId);
              } else {}
            } else {
              // Fallback to storage values
              profilePictureId =
                  storage.read("staffProfilePictureId") as String? ?? '';
              userEmail = storage.read("email") as String? ?? "N/A";
            }

            // BUILD THE ACTUAL PROFILE UI
            return _buildProfileUI(
              userName: userName,
              userEmail: userEmail,
              userRole: userRole,
              clinicName: clinicName,
              clinicId: clinicId,
              userJoinDate: userJoinDate,
              isStaff: isStaff,
              profilePictureController: profilePictureController,
            );
          },
        );
      } else {}
    } else {
      // ADMIN: Use clinic profile picture
      final profilePictureId =
          storage.read("clinicProfilePictureId") as String?;
      final userEmail = storage.read("email") as String? ?? "admin@example.com";

      // Set current profile picture if available
      if (profilePictureId != null && profilePictureId.isNotEmpty) {
        profilePictureController.setCurrentProfilePicture(profilePictureId);
      }
    }

    // Fallback UI (for admin or staff without ID)
    final fallbackEmail = storage.read("email") as String? ?? "N/A";

    return _buildProfileUI(
      userName: userName,
      userEmail: fallbackEmail,
      userRole: userRole,
      clinicName: clinicName,
      clinicId: clinicId,
      userJoinDate: userJoinDate,
      isStaff: isStaff,
      profilePictureController: profilePictureController,
    );
  }

  Widget _buildProfileImagePreview(
    AdminPfpController controller,
    bool isStaff,
  ) {
    return Obx(() {
      // If a new file is selected, show it
      if (controller.selectedFile.value != null &&
          controller.selectedFile.value!.bytes != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(60),
          child: Image.memory(
            controller.selectedFile.value!.bytes!,
            width: 96,
            height: 96,
            fit: BoxFit.cover,
          ),
        );
      }

      // If there's a current profile picture from database
      var currentPictureId = controller.currentProfilePictureId.value;

      // ✅ CRITICAL: Clean the picture ID using the helper method
      if (currentPictureId.isNotEmpty) {
        final cleanedId = _extractFileIdFromUrl(currentPictureId);

        if (currentPictureId != cleanedId) {
          currentPictureId = cleanedId;

          // Update the controller with the cleaned ID
          controller.currentProfilePictureId.value = cleanedId;
        }

        if (currentPictureId.isNotEmpty) {
          final imageUrl =
              Get.find<AuthRepository>().getImageUrl(currentPictureId);

          return ClipRRect(
            borderRadius: BorderRadius.circular(60),
            child: Image.network(
              imageUrl,
              width: 96,
              height: 96,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    color: Colors.purple,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return _buildPlaceholderAvatar(isStaff);
              },
            ),
          );
        }
      }

      // Show placeholder
      return _buildPlaceholderAvatar(isStaff);
    });
  }

  Widget _buildPlaceholderAvatar(bool isStaff) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Colors.purple.withOpacity(0.7), Colors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        isStaff ? Icons.person : Icons.local_hospital,
        color: Colors.white,
        size: 40,
      ),
    );
  }

  Future<void> _fetchAndSetStaffProfilePicture(
    String staffId,
    AdminPfpController controller,
  ) async {
    try {
      final authRepository = Get.find<AuthRepository>();

      // SIMPLIFIED: Use the new direct method
      final staff = await authRepository.getStaffByDocumentId(staffId);

      if (staff != null) {
        // Store and set the staff's profile picture ID from the "image" field
        if (staff.image.isNotEmpty) {
          // ✅ Clean the ID before storing
          final cleanedId = _extractFileIdFromUrl(staff.image);

          if (cleanedId != staff.image) {}

          storage.write('staffProfilePictureId', cleanedId);
          controller.setCurrentProfilePicture(cleanedId);
        } else {
          storage.write('staffProfilePictureId', '');
        }

        // ALSO UPDATE EMAIL IN STORAGE
        final staffEmail = staff.email.isNotEmpty ? staff.email : 'N/A';
        storage.write('email', staffEmail);
      } else {
        storage.write('staffProfilePictureId', '');
        storage.write('email', 'N/A');
      }
    } catch (e) {
      // Set defaults on error
      storage.write('staffProfilePictureId', '');
      storage.write('email', 'N/A');
    }
  }

  Widget _buildProfileUI({
    required String userName,
    required String userEmail,
    required String userRole,
    required String clinicName,
    required String clinicId,
    required String userJoinDate,
    required bool isStaff,
    required AdminPfpController profilePictureController,
  }) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(_isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple[400]!, Colors.blue[400]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isStaff ? Icons.person : Icons.admin_panel_settings,
                    color: Colors.purple[600],
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isStaff ? 'Staff Profile' : 'Admin Profile',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isStaff
                          ? 'Manage your staff account information'
                          : 'Manage your admin account and clinic information',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Profile Card with Picture
          Obx(() => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple[50]!, Colors.blue[50]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Container(
                  padding: EdgeInsets.all(_isMobile ? 16 : 28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.purple.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _isMobile
                          ? _buildMobileProfileHeader(
                              userName,
                              userEmail,
                              userRole,
                              profilePictureController,
                              isStaff,
                            )
                          : _buildDesktopProfileHeader(
                              userName,
                              userEmail,
                              userRole,
                              profilePictureController,
                              isStaff,
                            ),
                      if (profilePictureController.hasChanges()) ...[
                        const SizedBox(height: 20),
                        const Divider(color: Colors.grey),
                        const SizedBox(height: 16),
                        _buildProfilePictureSaveButtons(
                          profilePictureController,
                          isStaff,
                          clinicId,
                        ),
                      ],
                    ],
                  ),
                ),
              )),

          const SizedBox(height: 28),

          // Information Cards
          _buildModernCard(
            title: isStaff ? 'Staff Information' : 'Admin Information',
            icon: Icons.badge_outlined,
            iconColor: Colors.purple,
            children: [
              _buildModernInfoTile(
                icon: Icons.local_hospital_outlined,
                label: 'Clinic Name',
                value: clinicName,
                iconColor: Colors.green,
              ),
              // _buildModernInfoTile(
              //   icon: Icons.person_outline,
              //   label: 'Full Name',
              //   value: userName,
              //   iconColor: Colors.purple,
              // ),
              _buildModernInfoTile(
                icon: Icons.email_outlined,
                label: 'Email Address',
                value: userEmail, // NOW CORRECTLY SHOWS STAFF EMAIL OR "N/A"
                iconColor: Colors.blue,
              ),
              // _buildModernInfoTile(
              //   icon: Icons.calendar_today_outlined,
              //   label: 'Member Since',
              //   value: userJoinDate,
              //   iconColor: Colors.orange,
              //   isLast: true,
              // ),
            ],
          ),

          const SizedBox(height: 20),

          // Security Card
          _buildModernCard(
            title: 'Account Security',
            icon: Icons.security,
            iconColor: Colors.green,
            children: [
              _buildSecurityOption(
                icon: Icons.lock_outline,
                title: 'Change Password',
                subtitle: isStaff
                    ? 'Update your staff account password'
                    : 'Update your admin account password',
                color: Colors.blue,
                onTap: _showChangePasswordDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }

// NEW METHOD: Build profile picture save buttons
  Widget _buildProfilePictureSaveButtons(
    AdminPfpController controller,
    bool isStaff,
    String clinicId,
  ) {
    return Row(
      children: [
        const Spacer(),
        OutlinedButton(
          onPressed: () => controller.cancelChanges(),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.grey),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
          ),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 12),
        Obx(() => ElevatedButton(
              onPressed: controller.isUploading.value
                  ? null
                  : () async {
                      if (isStaff) {
                        // Save staff profile picture
                        final staffId = storage.read("staffId") as String?;
                        if (staffId != null && staffId.isNotEmpty) {
                          final newFileId =
                              await controller.saveStaffProfilePicture(staffId);
                          if (newFileId != null) {
                            storage.write('staffProfilePictureId', newFileId);
                            _showSnackbar(
                              'Success',
                              'Profile picture updated successfully',
                              Colors.green,
                            );
                          }
                        } else {
                          _showSnackbar(
                            'Error',
                            'Staff ID not found',
                            Colors.red,
                          );
                        }
                      } else {
                        // Save clinic profile picture (admin)
                        if (clinicId.isNotEmpty) {
                          final newFileId =
                              await controller.saveProfilePicture(clinicId);
                          if (newFileId != null) {
                            storage.write('clinicProfilePictureId', newFileId);
                            _showSnackbar(
                              'Success',
                              'Profile picture updated successfully',
                              Colors.green,
                            );
                          }
                        } else {
                          _showSnackbar(
                            'Error',
                            'Clinic ID not found',
                            Colors.red,
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: controller.isUploading.value
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Save Profile Picture'),
            )),
      ],
    );
  }

  Widget _buildMobileProfileHeader(
    String userName,
    String userEmail,
    String userRole,
    AdminPfpController profilePictureController,
    bool isStaff,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => profilePictureController.pickProfilePicture(),
                  borderRadius: BorderRadius.circular(60),
                  child: _buildProfileImagePreview(
                      profilePictureController, isStaff),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue[600],
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          userName,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.email_outlined, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                userEmail,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildRoleBadges(userRole, isStaff),
      ],
    );
  }

// NEW METHOD: Build desktop profile header
  Widget _buildDesktopProfileHeader(
    String userName,
    String userEmail,
    String userRole,
    AdminPfpController profilePictureController,
    bool isStaff,
  ) {
    return Row(
      children: [
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => profilePictureController.pickProfilePicture(),
                  borderRadius: BorderRadius.circular(60),
                  child: _buildProfileImagePreview(
                      profilePictureController, isStaff),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue[600],
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.email_outlined, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      userEmail,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildRoleBadges(userRole, isStaff),
            ],
          ),
        ),
      ],
    );
  }

// NEW METHOD: Build role badges
  Widget _buildRoleBadges(String userRole, bool isStaff) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple[100]!, Colors.purple[50]!],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.purple[200]!, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isStaff ? Icons.person : Icons.admin_panel_settings,
                size: 14,
                color: Colors.purple[700],
              ),
              const SizedBox(width: 6),
              Text(
                userRole.toUpperCase(),
                style: TextStyle(
                  color: Colors.purple[700],
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        // Container(
        //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        //   decoration: BoxDecoration(
        //     gradient: LinearGradient(
        //       colors: [Colors.green[100]!, Colors.green[50]!],
        //     ),
        //     borderRadius: BorderRadius.circular(20),
        //     border: Border.all(color: Colors.green[200]!, width: 1),
        //   ),
        //   child: Row(
        //     mainAxisSize: MainAxisSize.min,
        //     children: [
        //       Container(
        //         width: 8,
        //         height: 8,
        //         decoration: BoxDecoration(
        //           color: Colors.green[600],
        //           shape: BoxShape.circle,
        //           boxShadow: [
        //             BoxShadow(
        //               color: Colors.green.withOpacity(0.5),
        //               blurRadius: 4,
        //               spreadRadius: 1,
        //             ),
        //           ],
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
      ],
    );
  }

  Widget _buildSettingsContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(_isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple[400]!, Colors.pink[400]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child:
                      Icon(Icons.settings, color: Colors.purple[600], size: 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Settings',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Customize your clinic and system preferences',
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 14, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Clinic Settings Card - NOW FUNCTIONAL
          _buildModernCard(
            title: 'Clinic Settings',
            icon: Icons.local_hospital_outlined,
            iconColor: Colors.purple,
            children: [
              _buildModernSettingTile(
                icon: Icons.business_outlined,
                title: 'Clinic Profile',
                subtitle: 'Manage clinic information and contact details',
                iconColor: Colors.purple,
                isSwitch: false,
                onTap: _navigateToClinicPreview, // ✅ NOW FUNCTIONAL
              ),
              const SizedBox(height: 12),
              _buildModernSettingTile(
                icon: Icons.schedule_outlined,
                title: 'Operating Hours',
                subtitle: 'Set clinic working hours',
                iconColor: Colors.blue,
                isSwitch: false,
                onTap:
                    _navigateToClinicScheduleTab, // ✅ NOW FUNCTIONAL - Opens Schedule tab
              ),
              const SizedBox(height: 12),
              _buildModernSettingTile(
                icon: Icons.medical_services_outlined,
                title: 'Services',
                subtitle: 'Manage clinic services',
                iconColor: Colors.green,
                isSwitch: false,
                onTap:
                    _navigateToClinicPreview, // ✅ NOW FUNCTIONAL - Services shown in preview
              ),
            ],
          ),
          const SizedBox(height: 20),

          // The rest of your settings content continues here...
          // This includes any other settings cards you have, such as:
          // - Notifications (if you have it)
          // - Privacy & Security (if you have it)
          // - Any other settings sections

          // For example, if you have these sections, they stay the same:
          // _buildModernCard(
          //   title: 'Notifications',
          //   icon: Icons.notifications_outlined,
          //   iconColor: Colors.orange,
          //   children: [ ... ],
          // ),
          // _buildModernCard(
          //   title: 'Privacy & Security',
          //   icon: Icons.shield_outlined,
          //   iconColor: Colors.green,
          //   children: [ ... ],
          // ),
        ],
      ),
    );
  }

  Widget _buildHelpContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(_isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[400]!, Colors.teal[400]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.help_outline,
                      color: Colors.green[600], size: 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Help & Support',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Find answers about managing your clinic',
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 14, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Colors.blue[50]!, Colors.cyan[50]!]),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(Icons.quiz_outlined,
                            color: Colors.blue[700], size: 22),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'Frequently Asked Questions',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                ...faqItems.asMap().entries.map((entry) {
                  int index = entry.key;
                  FAQItem item = entry.value;

                  return Column(
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => setState(
                              () => item.isExpanded = !item.isExpanded),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: item.isExpanded
                                  ? Colors.blue.withOpacity(0.04)
                                  : Colors.transparent,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: item.isExpanded
                                        ? Colors.blue.withOpacity(0.15)
                                        : Colors.grey.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    item.isExpanded ? Icons.remove : Icons.add,
                                    color: item.isExpanded
                                        ? Colors.blue[700]
                                        : Colors.grey[600],
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    item.question,
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                      fontSize: 14,
                                      fontWeight: item.isExpanded
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (item.isExpanded)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.04)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.blue.withOpacity(0.1)),
                                ),
                                child: Text(
                                  item.answer,
                                  style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 13,
                                      height: 1.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (index < faqItems.length - 1)
                        Divider(height: 1, color: Colors.grey[200]),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackContent() {
    final feedbackController = Get.put(AdminFeedbackController(
      authRepository: Get.find<AuthRepository>(),
      session: Get.find<UserSessionService>(),
    ));

    return Obx(() => SingleChildScrollView(
          padding: EdgeInsets.all(_isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[400]!, Colors.blue[600]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.feedback,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Report Issue or Send Feedback',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Help us improve by reporting system issues or sharing feedback',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Container(
                padding: EdgeInsets.all(_isMobile ? 20 : 32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'What type of feedback is this?',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: FeedbackType.values.map((type) {
                        final isSelected =
                            feedbackController.selectedType.value == type;
                        return InkWell(
                          onTap: () =>
                              feedbackController.selectedType.value = type,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _getFeedbackTypeColor(type)
                                      .withOpacity(0.15)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? _getFeedbackTypeColor(type)
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getFeedbackTypeIcon(type),
                                  color: isSelected
                                      ? _getFeedbackTypeColor(type)
                                      : Colors.grey[600],
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  type.displayName,
                                  style: TextStyle(
                                    color: isSelected
                                        ? _getFeedbackTypeColor(type)
                                        : Colors.grey[700],
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Which area does this relate to?',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<FeedbackCategory>(
                      dropdownColor: Colors.white,
                      value: feedbackController.selectedCategory.value,
                      decoration: InputDecoration(
                        hintText: 'Select a category',
                        prefixIcon: const Icon(Icons.category),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Colors.blue, width: 2),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      items: FeedbackCategory.values.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category.displayName),
                        );
                      }).toList(),
                      onChanged: (category) {
                        if (category != null) {
                          feedbackController.selectedCategory.value = category;
                        }
                      },
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Subject',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Brief summary of your feedback',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      maxLength: 100,
                      onChanged: (value) =>
                          feedbackController.subject.value = value,
                      decoration: InputDecoration(
                        hintText: 'e.g., Dashboard loading is slow',
                        hintStyle:
                            TextStyle(color: Colors.grey[400], fontSize: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Colors.blue, width: 2),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                        counterStyle:
                            TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Details',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Please provide as much detail as possible (minimum 20 characters)',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      maxLines: 6,
                      maxLength: 1000,
                      onChanged: (value) =>
                          feedbackController.description.value = value,
                      decoration: InputDecoration(
                        hintText:
                            'Describe what happened, when it happened, and steps to reproduce...',
                        hintStyle:
                            TextStyle(color: Colors.grey[400], fontSize: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Colors.blue, width: 2),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                        counterStyle:
                            TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.blue.withOpacity(0.1), width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.attachment,
                                  color: Colors.blue[700], size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Attachments (Optional)',
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      feedbackController.selectedFiles.isEmpty
                                          ? Colors.blue[100]
                                          : Colors.green[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${feedbackController.selectedFiles.length}/5',
                                  style: TextStyle(
                                    color:
                                        feedbackController.selectedFiles.isEmpty
                                            ? Colors.blue[800]
                                            : Colors.green[800],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Screenshots or images (Max 5 images, 5MB each)',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Allowed formats: JPG, PNG, GIF, WEBP',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Maximum file size: 5MB per image',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
                          ),
                          const SizedBox(height: 16),
                          if (feedbackController.selectedFiles.isEmpty)
                            InkWell(
                              onTap: () => feedbackController.pickFiles(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 32, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Colors.grey[300]!,
                                      width: 2,
                                      style: BorderStyle.solid),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.cloud_upload_outlined,
                                        color: Colors.grey[400], size: 40),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Click to upload files',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Images only: JPG, PNG, GIF, WEBP (Max 5MB each)',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (feedbackController.selectedFiles.isNotEmpty) ...[
                            ...feedbackController.selectedFiles.map((file) =>
                                Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          feedbackController
                                              .getFileIcon(file.extension),
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              file.name,
                                              style: const TextStyle(
                                                color: Colors.black87,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              feedbackController
                                                  .getFileSize(file.size),
                                              style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, size: 18),
                                        color: Colors.grey[600],
                                        onPressed: () =>
                                            feedbackController.removeFile(file),
                                        padding: const EdgeInsets.all(4),
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                )),
                            const SizedBox(height: 8),
                            if (feedbackController.selectedFiles.length < 5)
                              OutlinedButton.icon(
                                onPressed: () => feedbackController.pickFiles(),
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Add more files'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blue[700],
                                  side: BorderSide(
                                      color: Colors.blue.withOpacity(0.3)),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: feedbackController.isSubmitting.value
                            ? null
                            : () async {
                                final success =
                                    await feedbackController.submitFeedback();
                                if (success) {
                                  setState(() => selectedIndex = 2);
                                  _showSnackbar(
                                      'Success',
                                      'Feedback submitted successfully',
                                      Colors.green);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                          disabledBackgroundColor: Colors.grey[300],
                        ),
                        child: feedbackController.isSubmitting.value
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.send, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Submit Feedback',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }

  Color _getFeedbackTypeColor(FeedbackType type) {
    switch (type) {
      case FeedbackType.bug:
        return Colors.red;
      case FeedbackType.feature:
        return Colors.green;
      case FeedbackType.complaint:
        return Colors.orange;
      case FeedbackType.question:
        return Colors.purple;
      case FeedbackType.compliment:
        return Colors.teal;
      case FeedbackType.systemIssue:
        return Colors.deepOrange;
    }
  }

  IconData _getFeedbackTypeIcon(FeedbackType type) {
    switch (type) {
      case FeedbackType.bug:
        return Icons.bug_report;
      case FeedbackType.feature:
        return Icons.lightbulb_outline;
      case FeedbackType.complaint:
        return Icons.sentiment_dissatisfied;
      case FeedbackType.question:
        return Icons.help_outline;
      case FeedbackType.compliment:
        return Icons.sentiment_satisfied;
      case FeedbackType.systemIssue:
        return Icons.error_outline;
    }
  }

  Widget _buildModernCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
    Widget? action,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                if (action != null) action,
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildModernInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!isLast) const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSecurityOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    bool value = false,
    bool isSwitch = true,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isSwitch ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ),
              if (isSwitch)
                Switch(
                  value: value,
                  onChanged: (v) => _showSnackbar(
                      'Settings', 'Setting updated', Colors.green),
                  activeColor: iconColor,
                )
              else
                Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final storage = GetStorage();
    final userRole = storage.read('role') ?? 'admin';
    final isStaff = userRole == 'staff';

    if (isStaff) {
      final changePasswordController = Get.put(
        StaffChangePasswordController(Get.find<AuthRepository>()),
        tag: 'staff_change_password',
      );
      changePasswordController.clearFields();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return _buildPasswordDialog(
            dialogContext: dialogContext,
            controller: changePasswordController,
            isStaff: true,
          );
        },
      );
    } else {
      final changePasswordController = Get.put(
        AdminChangePasswordController(Get.find<AuthRepository>()),
        tag: 'admin_change_password',
      );
      changePasswordController.clearFields();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return _buildPasswordDialog(
            dialogContext: dialogContext,
            controller: changePasswordController,
            isStaff: false,
          );
        },
      );
    }
  }

  Widget _buildPasswordDialog({
    required BuildContext dialogContext,
    required dynamic controller,
    required bool isStaff,
  }) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: PopScope(
        canPop: false, // Prevent back button from closing without confirmation
        onPopInvokedWithResult: (bool didPop, Object? result) async {
          if (!didPop) {
            // Check if there are unsaved changes
            if (controller.hasUnsavedChanges()) {
              final shouldDiscard =
                  await _showDiscardChangesDialog(dialogContext);
              if (shouldDiscard == true) {
                controller.clearFields();
                Navigator.of(dialogContext).pop();
              }
            } else {
              controller.clearFields();
              Navigator.of(dialogContext).pop();
            }
          }
        },
        child: Container(
          width: _isMobile ? double.infinity : 550,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Form(
            key: controller.formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  _buildPasswordDialogHeader(
                      dialogContext, controller, isStaff),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Error Message
                        _buildErrorMessage(controller),

                        // Current Password
                        _buildCurrentPasswordField(controller),
                        const SizedBox(height: 24),

                        // New Password
                        _buildNewPasswordField(controller),
                        const SizedBox(height: 24),

                        // Confirm Password
                        _buildConfirmPasswordField(controller),
                        const SizedBox(height: 32),

                        // Action Buttons
                        _buildDialogActions(dialogContext, controller),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage(dynamic controller) {
    return Obx(() {
      if (controller.errorMessage.value.isEmpty) {
        return const SizedBox.shrink();
      }
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[700], size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                controller.errorMessage.value,
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, size: 18, color: Colors.red[700]),
              onPressed: () => controller.errorMessage.value = '',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPasswordDialogHeader(
    BuildContext dialogContext,
    dynamic controller,
    bool isStaff,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.lock_reset, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Change Password',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Create a strong, secure password',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              // Check for unsaved changes before closing
              if (controller.hasUnsavedChanges()) {
                final shouldDiscard =
                    await _showDiscardChangesDialog(dialogContext);
                if (shouldDiscard == true) {
                  controller.clearFields();
                  Navigator.of(dialogContext).pop();
                }
              } else {
                controller.clearFields();
                Navigator.of(dialogContext).pop();
              }
            },
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPasswordField(dynamic controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Current Password',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() => TextFormField(
              controller: controller.currentPasswordController,
              obscureText: !controller.isCurrentPasswordVisible.value,
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'Enter your current password',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[600]),
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.isCurrentPasswordVisible.value
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.grey[600],
                  ),
                  onPressed: controller.toggleCurrentPasswordVisibility,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              validator: controller.validateCurrentPassword,
            )),
      ],
    );
  }

  Widget _buildNewPasswordField(dynamic controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'New Password',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() => TextFormField(
              controller: controller.newPasswordController,
              obscureText: !controller.isNewPasswordVisible.value,
              style: const TextStyle(color: Colors.black87),
              onChanged: (value) => controller.checkPasswordRequirements(value),
              decoration: InputDecoration(
                hintText: 'Enter your new password',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[600]),
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.isNewPasswordVisible.value
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.grey[600],
                  ),
                  onPressed: controller.toggleNewPasswordVisibility,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              validator: controller.validateNewPassword,
            )),
        const SizedBox(height: 16),
        // Password strength indicator - NO Obx wrapper here, it's inside the widget
        _buildPasswordStrengthIndicator(controller),
      ],
    );
  }

  Widget _buildConfirmPasswordField(dynamic controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Confirm New Password',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() => TextFormField(
              controller: controller.confirmPasswordController,
              obscureText: !controller.isConfirmPasswordVisible.value,
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'Re-enter your new password',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[600]),
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.isConfirmPasswordVisible.value
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.grey[600],
                  ),
                  onPressed: controller.toggleConfirmPasswordVisibility,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              validator: controller.validateConfirmPassword,
            )),
      ],
    );
  }

  Widget _buildPasswordStrengthIndicator(dynamic controller) {
    return Obx(() {
      // MUST read at least one observable FIRST before any conditional return
      // This ensures GetX knows this widget is tracking something
      final hasMinLength = controller.hasMinLength.value;
      final hasUpperCase = controller.hasUpperCase.value;
      final hasNumber = controller.hasNumber.value;
      final hasSpecialChar = controller.hasSpecialChar.value;

      // NOW we can safely check if password is empty and return early
      final passwordText = controller.newPasswordController.text;
      if (passwordText.isEmpty) {
        return const SizedBox.shrink();
      }

      // Access remaining observable values for the actual UI
      final strength = controller.getPasswordStrength();
      final strengthColor = controller.getPasswordStrengthColor();
      final strengthLabel = controller.getPasswordStrengthLabel();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: strength / 4,
                    backgroundColor: Colors.grey[200],
                    color: strengthColor,
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                strengthLabel,
                style: TextStyle(
                  color: strengthColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Password Requirements:',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _buildPasswordRequirement(
                    'At least 8 characters', hasMinLength),
                const SizedBox(height: 8),
                _buildPasswordRequirement(
                    'One uppercase letter (A-Z)', hasUpperCase),
                const SizedBox(height: 8),
                _buildPasswordRequirement('One number (0-9)', hasNumber),
                const SizedBox(height: 8),
                _buildPasswordRequirement(
                    'One special character (!@#\$%^&*)', hasSpecialChar),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildPasswordRequirement(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.cancel,
          size: 16,
          color: isMet ? Colors.green : Colors.grey[400],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: isMet ? Colors.green[700] : Colors.grey[600],
              fontSize: 12,
              fontWeight: isMet ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDialogActions(BuildContext dialogContext, dynamic controller) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () async {
              // Check for unsaved changes before canceling
              if (controller.hasUnsavedChanges()) {
                final shouldDiscard =
                    await _showDiscardChangesDialog(dialogContext);
                if (shouldDiscard == true) {
                  controller.clearFields();
                  Navigator.of(dialogContext).pop();
                }
              } else {
                controller.clearFields();
                Navigator.of(dialogContext).pop();
              }
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey[400]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Obx(() => ElevatedButton(
                onPressed: controller.isLoading.value
                    ? null
                    : () async {
                        final success = await controller.changePassword();
                        if (success) {
                          Navigator.of(dialogContext).pop();
                          _showPasswordChangeSuccessDialog();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: controller.isLoading.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Change Password',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              )),
        ),
      ],
    );
  }

  Future<bool?> _showDiscardChangesDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: _isMobile ? double.infinity : 400,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Warning Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange[400]!, Colors.orange[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.warning_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Discard Changes?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Your progress will be lost',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.orange[700],
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'You have unsaved changes. Are you sure you want to discard them?',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(false),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey[400]!),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text(
                                'Keep Editing',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange[600],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Discard',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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
      },
    );
  }

  void _showPasswordChangeSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: _isMobile ? double.infinity : 400,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success Icon
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green[400]!, Colors.green[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_outline,
                          color: Colors.white,
                          size: 64,
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const Text(
                        'Password Changed!',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your password has been successfully changed. You can now use your new password to sign in.',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Got it',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
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

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title:
              const Text('Sign out', style: TextStyle(color: Colors.black87)),
          content: const Text('Are you sure you want to sign out?',
              style: TextStyle(color: Colors.black87)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                await LogoutHelper.logout();
              },
              child:
                  const Text('Sign out', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  String _extractFileIdFromUrl(String urlOrId) {
    // If it's already just an ID, return it
    if (!urlOrId.contains('http')) {
      return urlOrId;
    }

    // If it's a URL, extract the file ID
    try {
      final uri = Uri.parse(urlOrId);
      final pathSegments = uri.pathSegments;
      final filesIndex = pathSegments.indexOf('files');
      if (filesIndex != -1 && filesIndex + 1 < pathSegments.length) {
        return pathSegments[filesIndex + 1];
      }
    } catch (e) {}

    return urlOrId;
  }

  Widget _buildUserDetailRow(
    IconData icon,
    String label,
    String value,
    Color iconColor,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _searchUserForVerification() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _searchError = 'Please enter an email address';
        _searchedUser = null;
      });
      return;
    }

    // Basic email validation
    if (!_isValidEmail(query)) {
      setState(() {
        _searchError = 'Please enter a valid email address';
        _searchedUser = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchError = null;
      _searchedUser = null;
    });

    try {
      final authRepository = Get.find<AuthRepository>();

      // Search by email ONLY (more secure)
      final emailResults =
          await authRepository.appWriteProvider.databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.usersCollectionID,
        queries: [
          Query.equal('email', query),
          Query.limit(1),
        ],
      );

      if (emailResults.documents.isNotEmpty) {
        final userDoc = emailResults.documents.first;
        final user = User.fromMap(userDoc.data);
        user.documentId = userDoc.$id;

        setState(() {
          _searchedUser = user;
          _isSearching = false;
          _searchError = null;
        });
      } else {
        setState(() {
          _searchedUser = null;
          _isSearching = false;
          _searchError =
              'No user found with this email address. Please check the email and try again.';
        });
      }
    } catch (e) {
      setState(() {
        _searchedUser = null;
        _isSearching = false;
        _searchError = 'Error searching for user. Please try again.';
      });
    }
  }

  bool _isValidEmail(String email) {
    // Basic email regex pattern
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

// Clear search results
  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchedUser = null;
      _searchError = null;
    });
  }

  Widget _buildVerifyUserContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(_isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[400]!, Colors.teal[400]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.verified_user,
                      color: Colors.green[600], size: 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Verify User',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Search and verify users by email address',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Search Section
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.search,
                            color: Colors.blue[700], size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Search User',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Security Note
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.security, color: Colors.blue[700], size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Search by email address only for security purposes',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText:
                                'Enter user email address (e.g., user@example.com)',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            prefixIcon: Icon(Icons.email_outlined,
                                color: Colors.grey[600]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Colors.blue, width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Colors.red, width: 1),
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          onSubmitted: (_) => _searchUserForVerification(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed:
                            _isSearching ? null : _searchUserForVerification,
                        icon: _isSearching
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Icon(Icons.search, size: 18),
                        label: Text(_isSearching ? 'Searching...' : 'Search'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),

                  // Error message
                  if (_searchError != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: Colors.red[700], size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _searchError!,
                              style: TextStyle(
                                  color: Colors.red[700], fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // User Info Card
          _buildUserInfoCard(),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard() {
    if (_searchedUser == null) {
      return Container(
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child:
                    Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
              ),
              const SizedBox(height: 16),
              Text(
                'No user searched yet',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Search for a user by email address to view their details',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // User found - display info
    final user = _searchedUser!;
    final isAlreadyVerified = user.idVerified;

    final verifyController = Get.put(
      AdminVerifyUserController(Get.find<AuthRepository>()),
      tag: 'verify_user_${user.userId}',
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with user status
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[50]!, Colors.cyan[50]!],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(Icons.person, color: Colors.blue[700], size: 22),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'User Information',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        user.isArchived ? Colors.red[100] : Colors.green[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: user.isArchived
                          ? Colors.red[300]!
                          : Colors.green[300]!,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: user.isArchived
                              ? Colors.red[600]
                              : Colors.green[600],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        user.isArchived ? 'ARCHIVED' : 'ACTIVE',
                        style: TextStyle(
                          color: user.isArchived
                              ? Colors.red[700]
                              : Colors.green[700],
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // User Details
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Profile Picture and Name
                Row(
                  children: [
                    _buildUserProfilePicture(user),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 20),

                // User Details Grid
                _buildUserDetailRow(
                  Icons.email_outlined,
                  'Email',
                  user.email,
                  Colors.blue,
                ),
                const SizedBox(height: 16),
                _buildUserDetailRow(
                  Icons.phone_outlined,
                  'Phone',
                  user.phone?.isNotEmpty == true ? user.phone! : 'Not provided',
                  Colors.green,
                ),
                const SizedBox(height: 16),
                _buildUserDetailRow(
                  Icons.shield_outlined,
                  'Role',
                  user.role.toUpperCase(),
                  Colors.orange,
                ),
                const SizedBox(height: 16),
                _buildUserDetailRow(
                  Icons.verified_outlined,
                  'ID Verification Status',
                  isAlreadyVerified ? 'Verified' : 'Not Verified',
                  isAlreadyVerified ? Colors.green : Colors.red,
                ),

                const SizedBox(height: 32),

                // Verify Button or Status Messages
                Obx(() {
                  if (verifyController.isVerifying.value) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.blue[700]!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Verifying user...',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (isAlreadyVerified) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.green[700], size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'User Already Verified',
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (user.idVerifiedAt != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Verified on: ${DateTime.parse(user.idVerifiedAt!).toString().split(' ')[0]}',
                                    style: TextStyle(
                                      color: Colors.green[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (user.isArchived) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.block, color: Colors.red[700], size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Cannot verify archived user',
                              style: TextStyle(
                                color: Colors.red[700],
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _showVerifyConfirmationDialog(user, verifyController),
                      icon: const Icon(Icons.verified, size: 20),
                      label: const Text(
                        'Verify User',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  );
                }),

                // Error message
                Obx(() {
                  if (verifyController.errorMessage.value.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: Colors.red[700], size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            verifyController.errorMessage.value,
                            style:
                                TextStyle(color: Colors.red[700], fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfilePicture(User user) {
    // Check if user has a profile picture
    if (user.hasProfilePicture) {
      final imageUrl = Get.find<AuthRepository>()
          .getUserProfilePictureUrl(user.profilePictureId!);

      return ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: Image.network(
          imageUrl,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: 80,
              height: 80,
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
                  color: Colors.purple[600],
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultUserAvatar(user.name);
          },
        ),
      );
    }

    // Show default avatar if no profile picture
    return _buildDefaultUserAvatar(user.name);
  }

  Widget _buildDefaultUserAvatar(String userName) {
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Colors.purple.withOpacity(0.7), Colors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Future<void> _showVerifyConfirmationDialog(
      User user, AdminVerifyUserController controller) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: _isMobile ? double.infinity : 450,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green[400]!, Colors.green[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.verified_user,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Verify User',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Confirm verification',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // User info summary
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                _buildUserProfilePicture(user),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.name,
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        user.email,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Confirmation message
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.green.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.green[700], size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Are you sure you want to verify this user? This action will mark them as a verified user.',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(false),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey[400]!),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[600],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Verify User',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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
      },
    );

    // If user confirmed, proceed with verification
    if (confirmed == true) {
      final success = await controller.verifyUser(user);

      if (success) {
        _showSnackbar(
          'Success',
          'User ${user.name} verified successfully',
          Colors.green,
        );

        // Refresh user data
        setState(() {
          _searchedUser = user.copyWith(
            idVerified: true,
            idVerifiedAt: DateTime.now().toIso8601String(),
          );
        });
      } else {
        _showSnackbar(
          'Error',
          controller.errorMessage.value.isNotEmpty
              ? controller.errorMessage.value
              : 'Failed to verify user',
          Colors.red,
        );
      }
    }
  }

  void _navigateToClinicPreview() {
    // Get the WebAdminHomeController
    final homeController = Get.find<WebAdminHomeController>();

    // Check permissions
    if (!homeController.hasAuthority('Clinic')) {
      homeController.showPermissionDeniedDialog('Clinic Settings');
      return;
    }

    // Find the index of the Clinic page
    final clinicIndex = homeController.navigationLabels.indexOf('Clinic');

    if (clinicIndex != -1) {
      // Set the selected index to Clinic page
      homeController.setSelectedIndex(clinicIndex);

      // Close the settings page
      Navigator.of(context).pop();
    } else {
      _showSnackbar(
        'Error',
        'Clinic page not available',
        Colors.red,
      );
    }
  }

  void _navigateToClinicScheduleTab() {
    // Get the WebAdminHomeController
    final homeController = Get.find<WebAdminHomeController>();

    // Check permissions
    if (!homeController.hasAuthority('Clinic')) {
      homeController.showPermissionDeniedDialog('Operating Hours');
      return;
    }

    // Find the index of the Clinic page
    final clinicIndex = homeController.navigationLabels.indexOf('Clinic');

    if (clinicIndex != -1) {
      // Set the selected index to Clinic page
      homeController.setSelectedIndex(clinicIndex);

      // Store the initial tab index for AdminWebClinicpage to read
      Get.find<GetStorage>()
          .write('clinicPageInitialTab', 1); // 1 = Schedule tab

      // Close the settings page
      Navigator.of(context).pop();

      // Clear the stored tab after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        Get.find<GetStorage>().remove('clinicPageInitialTab');
      });
    } else {
      _showSnackbar(
        'Error',
        'Clinic page not available',
        Colors.red,
      );
    }
  }
}
