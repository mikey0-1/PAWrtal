import 'package:capstone_app/web/admin_web/components/appbar/admin_web_notif.dart';
import 'package:capstone_app/web/admin_web/components/appbar/admin_web_profile.dart';
import 'package:capstone_app/web/admin_web/components/staffs/data/permission_guard.dart';
import 'package:capstone_app/web/pages/web_admin_home/web_admin_home_controller.dart';
import 'package:capstone_app/components/download_app_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminDesktopHomePage extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final bool canAccessStaffs; // Kept for compatibility

  const AdminDesktopHomePage({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.canAccessStaffs,
  });

  @override
  State<AdminDesktopHomePage> createState() => _AdminDesktopHomePageState();
}

class _AdminDesktopHomePageState extends State<AdminDesktopHomePage> {
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

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WebAdminHomeController>();

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        leadingWidth: 220,
        toolbarHeight: 80,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey.shade400,
            height: 1,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 75),
          child: InkWell(
            onTap: () => widget.onItemSelected(0),
            child: Image.asset(
              'lib/images/PAWrtal_logo.png',
            ),
          ),
        ),
        title: Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                controller.navigationLabels.length,
                (index) => _buildNavItem(
                  controller,
                  controller.navigationLabels[index],
                  index,
                  controller.selectedIndex.value == index,
                ),
              ),
            )),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 60),
            child: Row(
              children: [
                DownloadAppButton(),
                SizedBox(width: 8),
                AdminWebNotif(),
                Padding(
                  padding: EdgeInsets.only(left: 30),
                  child: AdminWebProfile(),
                ),
              ],
            ),
          )
        ],
      ),
      body: Obx(() {
        // Use controller's selectedIndex instead of widget's
        final currentIndex = controller.selectedIndex.value;
        
        // Safety check
        if (currentIndex >= controller.pages.length) {
          return const Center(child: Text('Page not found'));
        }

        // Wrap the current page with permission guard
        return _wrapWithPermissionGuard(
          controller.pages[currentIndex],
          currentIndex,
          controller,
        );
      }),
    );
  }

  Widget _buildNavItem(
    WebAdminHomeController controller,
    String title,
    int index,
    bool isSelected,
  ) {
    // Check if user has permission for this page
    final hasPermission = index == 0 || controller.hasAuthority(title);
    final isViewOnly = !hasPermission && controller.isStaff;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => widget.onItemSelected(index),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isViewOnly)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.lock_outline,
                  size: 16,
                  color: isSelected ? Colors.black54 : Colors.grey,
                ),
              ),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                color: isSelected ? Colors.black : Colors.grey,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}