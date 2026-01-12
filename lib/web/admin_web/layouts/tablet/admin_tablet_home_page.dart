import 'package:capstone_app/web/admin_web/components/appbar/admin_web_notif.dart';
import 'package:capstone_app/web/admin_web/components/appbar/admin_web_profile.dart';
import 'package:capstone_app/web/admin_web/components/staffs/data/permission_guard.dart';
import 'package:capstone_app/web/pages/web_admin_home/web_admin_home_controller.dart';
import 'package:capstone_app/components/download_app_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminTabletHomePage extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final bool canAccessStaffs;

  const AdminTabletHomePage({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.canAccessStaffs,
  });

  @override
  State<AdminTabletHomePage> createState() => _AdminTabletHomePageState();
}

class _AdminTabletHomePageState extends State<AdminTabletHomePage> {
  late final WebAdminHomeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<WebAdminHomeController>();
  }

  Widget _wrapWithPermissionGuard(
      Widget page, int index, WebAdminHomeController controller) {
    if (index == 0) return page;

    if (controller.isAdmin) return page;

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
    final screenSize = MediaQuery.of(context).size;
    final isPortrait = screenSize.height > screenSize.width;

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        toolbarHeight: isPortrait ? 70 : 65,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey.shade400,
            height: 1,
          ),
        ),
        title: InkWell(
          onTap: () => widget.onItemSelected(0),
          child: Image.asset(
            'lib/images/PAWrtal_logo.png',
            height: isPortrait ? 35 : 30,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isPortrait ? 20 : 15,
            ),
            child: const Row(
              children: [
                DownloadAppButton(isMobileLayout: true),
                SizedBox(width: 8),
                AdminWebNotif(),
                SizedBox(width: 16),
                AdminWebProfile(),
              ],
            ),
          )
        ],
      ),
      body: Obx(() {
        if (widget.selectedIndex >= _controller.pages.length) {
          return const Center(child: Text('Page not found'));
        }

        return _wrapWithPermissionGuard(
          _controller.pages[widget.selectedIndex],
          widget.selectedIndex,
          _controller,
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
            _controller.navigationLabels.length,
            (index) {
              final label = _controller.navigationLabels[index];

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
}
