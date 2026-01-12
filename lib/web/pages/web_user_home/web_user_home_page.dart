import 'package:capstone_app/pages/user_home/user_home_page.dart';
import 'package:capstone_app/web/pages/web_user_home/web_user_home_controller.dart';
import 'package:capstone_app/web/responsive_layout.dart';
import 'package:capstone_app/web/dimensions.dart';
import 'package:capstone_app/web/user_web/desktop_web/pages/web_user_home_page.dart' as desktop;
import 'package:capstone_app/web/user_web/tablet_web/pages/web_tablet_user_homepage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WebUserHomePage extends StatefulWidget {
  const WebUserHomePage({super.key});

  @override
  State<WebUserHomePage> createState() => _WebUserHomePageState();
}

class _WebUserHomePageState extends State<WebUserHomePage> {
  String? _currentLayout;

  String _getLayoutType(double width) {
    if (width < mobileWidth) {
      return 'mobile';
    } else if (width < tabletWidth) {
      return 'tablet';
    } else {
      return 'desktop';
    }
  }

  void _handleLayoutChange(String newLayout) {
    if (_currentLayout != null && _currentLayout != newLayout) {
      // Close all open dialogs when layout changes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Close all dialogs by popping until we can't pop anymore
          while (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }
      });
    }
    _currentLayout = newLayout;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final currentLayout = _getLayoutType(constraints.maxWidth);
          _handleLayoutChange(currentLayout);

          return ResponsiveLayout(
            desktopBody: () {
              final controller = Get.find<WebUserHomeController>();
              return Obx(() => desktop.WebUserHomePage(
                selectedIndex: controller.selectedIndex.value,
                onItemSelected: controller.onItemSelected,
              ));
            },
            tabletBody: () {
              final controller = Get.find<WebUserHomeController>();
              return Obx(() => WebTabletUserHomepage(
                selectedIndex: controller.selectedIndex.value,
                onItemSelected: controller.onItemSelected,
              ));
            },
            mobileBody: () {
              final controller = Get.find<WebUserHomeController>();
              return Obx(() => UserHomePage(
                initialIndex: controller.selectedIndex.value,
                onItemSelected: controller.onItemSelected,
              ));
            },
          );
        },
      ),
    );
  }
}