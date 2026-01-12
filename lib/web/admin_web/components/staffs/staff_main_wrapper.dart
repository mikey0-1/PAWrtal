import 'package:capstone_app/web/admin_web/components/staffs/data/permission_guard.dart';
import 'package:capstone_app/web/admin_web/components/staffs/data/staff_auth_controller.dart';
import 'package:capstone_app/web/admin_web/pages/admin_web_appointments.dart';
import 'package:capstone_app/web/admin_web/pages/admin_web_clinicpage.dart';
import 'package:capstone_app/web/admin_web/pages/admin_web_dashboard.dart';
import 'package:capstone_app/web/admin_web/pages/admin_web_messages.dart';
import 'package:capstone_app/web/admin_web/pages/admin_web_staffs.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/user_session_service.dart';

class StaffMainWrapper extends StatefulWidget {
  const StaffMainWrapper({super.key});

  @override
  State<StaffMainWrapper> createState() => _StaffMainWrapperState();
}

class _StaffMainWrapperState extends State<StaffMainWrapper> {
  late StaffAuthController staffController;
  int _selectedIndex = 0;
  bool _isLoading = true;

  static const Color primaryBlue = Color(0xFF4A6FA5);
  static const Color primaryTeal = Color(0xFF5B9BD5);
  static const Color vetOrange = Color(0xFFF59E0B);
  static const Color mediumGray = Color(0xFF9CA3AF);

  @override
  void initState() {
    super.initState();
    _initializeStaffController();
  }

  Future<void> _initializeStaffController() async {
    if (!Get.isRegistered<StaffAuthController>()) {
      staffController = Get.put(StaffAuthController(
        authRepository: Get.find<AuthRepository>(),
        userSession: Get.find<UserSessionService>(),
      ));
    } else {
      staffController = Get.find<StaffAuthController>();
    }

    await staffController.loadStaffData();

    setState(() {
      _isLoading = false;
    });
  }

  // ALL PAGES are now available - staff can see all pages
  List<Map<String, dynamic>> get _availablePages {
    final pages = <Map<String, dynamic>>[];

    // Home page is always available
    pages.add({
      'title': 'Home',
      'icon': Icons.home,
      'permission': null,
      'widget': const AdminWebDashboard(),
    });

    // Clinic page
    pages.add({
      'title': 'Clinic',
      'icon': Icons.local_hospital,
      'permission': 'Clinic',
      'widget': const AdminWebClinicpage(),
    });

    // Appointments page
    pages.add({
      'title': 'Appointments',
      'icon': Icons.calendar_month,
      'permission': 'Appointments',
      'widget': const AdminWebAppointments(),
    });

    // Messages page
    pages.add({
      'title': 'Messages',
      'icon': Icons.message,
      'permission': 'Messages',
      'widget': const AdminWebMessages(),
    });

    // Staffs page - ALWAYS SHOWN but in view-only mode
    pages.add({
      'title': 'Staffs',
      'icon': Icons.group,
      'permission': 'Staffs', // Staff will never have this authority
      'widget': const AdminWebStaffs(),
    });

    return pages;
  }

  Widget _buildCurrentPage() {
    final pages = _availablePages;

    if (_selectedIndex >= pages.length) {
      _selectedIndex = 0;
    }

    final currentPage = pages[_selectedIndex];
    final permission = currentPage['permission'] as String?;

    // Home page doesn't need permission check
    if (permission == null) {
      return currentPage['widget'] as Widget;
    }

    // For Staffs page, staff will NEVER have permission (always view-only)
    // For other pages, check if they have the authority
    final hasPermission = staffController.hasAuthority(permission);

    return PermissionGuard(
      hasPermission: hasPermission,
      requiredPermission: permission,
      child: currentPage['widget'] as Widget,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(),

          // Main Content
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(child: _buildCurrentPage()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final pages = _availablePages;

    return Container(
      width: 250,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [primaryBlue, primaryTeal],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.medical_services_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Obx(() => Text(
                      staffController.currentStaff.value?.name ?? 'Staff',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    )),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Staff Account',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white24, height: 1),

          // Navigation Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: pages.length,
              itemBuilder: (context, index) {
                final page = pages[index];
                final isSelected = _selectedIndex == index;
                final permission = page['permission'] as String?;

                // Check if this is a view-only page
                final isViewOnly = permission != null &&
                    !staffController.hasAuthority(permission);

                return _buildNavItem(
                  icon: page['icon'] as IconData,
                  title: page['title'] as String,
                  isSelected: isSelected,
                  isViewOnly: isViewOnly,
                  onTap: () => setState(() => _selectedIndex = index),
                );
              },
            ),
          ),

          // Logout Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () => _showLogoutDialog(),
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text(
                'Logout',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required bool isViewOnly,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: Colors.white.withOpacity(0.3))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
                if (isViewOnly)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: vetOrange.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Obx(() {
            final pages = _availablePages;
            if (_selectedIndex >= pages.length) return const SizedBox();

            final currentPage = pages[_selectedIndex];
            return Text(
              currentPage['title'] as String,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            );
          }),
          const Spacer(),

          // Permission Badge
          Obx(() => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: primaryTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primaryTeal.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.security, color: primaryTeal, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '${staffController.staffAuthorities.length} Permissions',
                      style: const TextStyle(
                        color: primaryTeal,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout, color: vetOrange),
            SizedBox(width: 12),
            Text('Logout Confirmation'),
          ],
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: mediumGray)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              staffController.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: vetOrange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
