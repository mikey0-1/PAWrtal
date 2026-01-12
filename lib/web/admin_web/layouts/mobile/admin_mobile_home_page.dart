import 'package:capstone_app/web/admin_web/components/staffs/data/permission_guard.dart';
import 'package:capstone_app/web/pages/web_admin_home/web_admin_home_controller.dart';
import 'package:capstone_app/web/admin_web/components/appbar/admin_web_notif.dart';
import 'package:capstone_app/web/admin_web/components/appbar/admin_web_profile.dart';
import 'package:capstone_app/components/download_app_button.dart';
import 'package:capstone_app/web/admin_web/pages/admin_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminMobileHomePage extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final bool canAccessStaffs;

  const AdminMobileHomePage({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.canAccessStaffs,
  });

  @override
  State<AdminMobileHomePage> createState() => _AdminMobileHomePageState();
}

class _AdminMobileHomePageState extends State<AdminMobileHomePage> {
  Widget _wrapWithPermissionGuard(
      Widget page, int index, WebAdminHomeController controller) {
    // Home page (index 0) doesn't need permission check
    if (index == 0) return page;

    // Admin has full access to everything
    if (controller.isAdmin) return page;

    // Staff users - check if they have permission for this page
    final pageName = controller.navigationLabels[index];
    final hasPermission = controller.hasAuthority(pageName);

    return PermissionGuard(
      hasPermission: hasPermission,
      requiredPermission: pageName,
      child: page,
    );
  }

  IconData _getIconForLabel(String label) {
    switch (label) {
      case 'Home':
        return Icons.dashboard;
      case 'Clinic':
        return Icons.local_hospital;
      case 'Appointments':
        return Icons.calendar_today;
      case 'Messages':
        return Icons.message;
      case 'Staffs':
        return Icons.people;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WebAdminHomeController>();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey[400],
            height: 1,
          ),
        ),
        title: InkWell(
          onTap: () => widget.onItemSelected(0),
          child: Image.asset(
            'lib/images/PAWrtal_logo.png',
            height: 35,
          ),
        ),
        actions: [
          const DownloadAppButton(isMobileLayout: true),
          // Notification Icon with AdminWebNotif
          const AdminWebNotif(
            right: 0,
            top: 70,
            width: 400,
          ),
          const SizedBox(width: 8),
          // Profile Icon with AdminWebProfile - wrapped with custom navigation
          _buildProfileButton(controller),
        ],
      ),
      body: Obx(() {
        if (widget.selectedIndex >= controller.pages.length) {
          return const Center(child: Text('Page not found'));
        }

        return _wrapWithPermissionGuard(
          controller.pages[widget.selectedIndex],
          widget.selectedIndex,
          controller,
        );
      }),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Obx(() {
          final navItems = List.generate(
            controller.navigationLabels.length,
            (index) {
              final label = controller.navigationLabels[index];

              return BottomNavigationBarItem(
                icon: Icon(_getIconForLabel(label)),
                label: label,
              );
            },
          );

          return BottomNavigationBar(
            currentIndex: widget.selectedIndex < navItems.length
                ? widget.selectedIndex
                : 0,
            onTap: widget.onItemSelected,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color.fromARGB(255, 81, 115, 153),
            unselectedItemColor: Colors.grey,
            backgroundColor: Colors.white,
            elevation: 0,
            items: navItems,
          );
        }),
      ),
    );
  }

  Widget _buildProfileButton(WebAdminHomeController controller) {
    return Builder(
      builder: (context) => AdminWebProfile(
        right: 0,
        top: 70,
        width: 250,
      ),
    );
  }
}
