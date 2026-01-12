import 'package:capstone_app/utils/logout_helper.dart';
import 'package:capstone_app/web/pages/web_super_admin_home/web_super_admin_home_controller.dart';
import 'package:capstone_app/web/super_admin/WebVersion/tile_pages/pet_owner_menu_tile.dart';
import 'package:capstone_app/web/super_admin/WebVersion/tile_pages/vet_clinic_menu_tile.dart';
import 'package:capstone_app/web/super_admin/WebVersion/tile_pages/view_report_menu_tile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SuperAdminDesktopHomePage extends GetView<WebSuperAdminHomeController> {
  const SuperAdminDesktopHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Define breakpoints
    final bool isDesktop = screenWidth > 1024;
    final bool isTablet = screenWidth > 600 && screenWidth <= 1024;
    final bool isMobile = screenWidth <= 600;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        surfaceTintColor: Colors.transparent,
        backgroundColor: const Color.fromARGB(255, 248, 253, 255),
        centerTitle: true,
        toolbarHeight: isDesktop
            ? screenHeight * 0.1
            : isTablet
                ? screenHeight * 0.09
                : screenHeight * 0.08,
        flexibleSpace: Container(
          margin: EdgeInsets.only(
            top: isDesktop
                ? 15.0
                : isTablet
                    ? 12.0
                    : 10.0,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: isDesktop
                    ? screenHeight * 0.08
                    : isTablet
                        ? screenHeight * 0.07
                        : screenHeight * 0.06,
                maxWidth: isDesktop
                    ? screenWidth * 0.3
                    : isTablet
                        ? screenWidth * 0.4
                        : screenWidth * 0.5,
              ),
              child: Image.asset(
                "lib/images/PAWrtal_logo.png",
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(
              right: isDesktop
                  ? 24.0
                  : isTablet
                      ? 20.0
                      : 16.0,
            ),
            child: _buildLogoutButton(context, isDesktop, isTablet, isMobile),
          ),
        ],
      ),
      backgroundColor: const Color.fromARGB(255, 248, 253, 255),
      body: Container(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop
                      ? constraints.maxWidth * 0.05
                      : isTablet
                          ? constraints.maxWidth * 0.04
                          : constraints.maxWidth * 0.03,
                  vertical: isDesktop
                      ? 20
                      : isTablet
                          ? 16
                          : 12,
                ),
                child: isDesktop
                    ? IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: constraints.maxWidth / 3 - 16,
                                  ),
                                  child: const VetClinicTile(),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: constraints.maxWidth / 3 - 16,
                                  ),
                                  child: const PetOwnerTile(),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: constraints.maxWidth / 3 - 16,
                                  ),
                                  child: const ViewReportTile(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : isTablet
                        ? IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6.0),
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: constraints.maxWidth / 2 - 12,
                                      ),
                                      child: const Column(
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 6.0),
                                            child: VetClinicTile(),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 6.0),
                                            child: ViewReportTile(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6.0),
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: constraints.maxWidth / 2 - 12,
                                      ),
                                      child: const Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 6.0),
                                        child: PetOwnerTile(),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: constraints.maxWidth,
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: VetClinicTile(),
                                ),
                              ),
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: constraints.maxWidth,
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: PetOwnerTile(),
                                ),
                              ),
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: constraints.maxWidth,
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: ViewReportTile(),
                                ),
                              ),
                            ],
                          ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogoutButton(
      BuildContext context, bool isDesktop, bool isTablet, bool isMobile) {
    // Responsive sizing
    double iconSize = isDesktop
        ? 28
        : isTablet
            ? 26
            : 24;
    double containerSize = isDesktop
        ? 56
        : isTablet
            ? 52
            : 48;
    double fontSize = isDesktop
        ? 13
        : isTablet
            ? 12
            : 11;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showLogoutDialog(context, isDesktop, isTablet),
        child: Container(
          width: containerSize,
          height: containerSize,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color.fromRGBO(81, 115, 153, 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color.fromRGBO(81, 115, 153, 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.logout_rounded,
                color: const Color.fromRGBO(81, 115, 153, 1),
                size: iconSize,
              ),
              SizedBox(height: isDesktop ? 4 : 3),
              Text(
                'Logout',
                style: TextStyle(
                  color: const Color.fromRGBO(81, 115, 153, 1),
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, bool isDesktop, bool isTablet) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(81, 115, 153, 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: const Color.fromRGBO(81, 115, 153, 1),
                  size: isDesktop
                      ? 28
                      : isTablet
                          ? 26
                          : 24,
                ),
              ),
              SizedBox(width: isDesktop ? 16 : 12),
              Text(
                'Confirm Logout',
                style: TextStyle(
                  fontSize: isDesktop
                      ? 22
                      : isTablet
                          ? 20
                          : 18,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromRGBO(81, 115, 153, 1),
                ),
              ),
            ],
          ),
          backgroundColor: const Color.fromARGB(255, 248, 253, 255),
          content: Text(
            'Are you sure you want to logout from your account?',
            style: TextStyle(
              fontSize: isDesktop
                  ? 16
                  : isTablet
                      ? 15
                      : 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 24 : 20,
                  vertical: isDesktop ? 14 : 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: isDesktop
                      ? 16
                      : isTablet
                          ? 15
                          : 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await LogoutHelper.logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 248, 24, 24),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 24 : 20,
                  vertical: isDesktop ? 14 : 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.logout_rounded,
                    size: isDesktop
                        ? 18
                        : isTablet
                            ? 17
                            : 16,
                  ),
                  SizedBox(width: isDesktop ? 8 : 6),
                  Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: isDesktop
                          ? 16
                          : isTablet
                              ? 15
                              : 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
