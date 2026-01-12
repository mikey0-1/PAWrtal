import 'package:capstone_app/utils/logout_helper.dart';
import 'package:capstone_app/web/pages/web_super_admin_home/web_super_admin_home_controller.dart';
import 'package:capstone_app/web/super_admin/WebVersion/tile_pages/pet_owner_menu_tile.dart';
import 'package:capstone_app/web/super_admin/WebVersion/tile_pages/vet_clinic_menu_tile.dart';
import 'package:capstone_app/web/super_admin/WebVersion/tile_pages/view_report_menu_tile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SuperAdminTabletHomePage extends GetView<WebSuperAdminHomeController> {
  const SuperAdminTabletHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        surfaceTintColor: Colors.transparent,
        backgroundColor: const Color.fromARGB(255, 248, 253, 255),
        centerTitle: true,
        toolbarHeight: screenHeight * 0.08,
        title: Image.asset(
          "lib/images/PAWrtal_logo.png",
          height: 40,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: _buildLogoutButton(context, screenWidth),
          ),
        ],
      ),
      backgroundColor: const Color.fromARGB(255, 248, 253, 255),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(
            top: 20,
            bottom: 60,
            left: 20,
            right: 20,
          ),
          child: Column(
            children: [
              const Row(
                children: [
                  Expanded(child: VetClinicTile()),
                  Expanded(child: PetOwnerTile()),
                ],
              ),
              const SizedBox(height: 20),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: const ViewReportTile(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, double screenWidth) {
    // Responsive sizing based on screen width
    double containerSize = screenWidth * 0.065;
    if (containerSize < 48) containerSize = 48;
    if (containerSize > 60) containerSize = 60;

    double iconSize = containerSize * 0.5;
    if (iconSize < 24) iconSize = 24;
    if (iconSize > 30) iconSize = 30;

    double fontSize = containerSize * 0.22;
    if (fontSize < 11) fontSize = 11;
    if (fontSize > 13) fontSize = 13;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showLogoutDialog(context, screenWidth),
        child: Container(
          width: containerSize,
          height: containerSize,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromRGBO(81, 115, 153, 0.85),
                Color.fromRGBO(81, 115, 153, 1),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color.fromRGBO(81, 115, 153, 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(-2, -2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Glossy effect overlay
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: containerSize * 0.4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(14),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Main content
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.logout_rounded,
                    color: Colors.white,
                    size: iconSize,
                  ),
                  SizedBox(height: containerSize * 0.08),
                  Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.2),
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Decorative dot
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, double screenWidth) {
    // Responsive dialog sizing
    double iconSize = screenWidth * 0.045;
    if (iconSize < 32) iconSize = 32;
    if (iconSize > 44) iconSize = 44;

    double titleFontSize = screenWidth * 0.028;
    if (titleFontSize < 19) titleFontSize = 19;
    if (titleFontSize > 24) titleFontSize = 24;

    double contentFontSize = screenWidth * 0.020;
    if (contentFontSize < 15) contentFontSize = 15;
    if (contentFontSize > 17) contentFontSize = 17;

    double buttonPadding = screenWidth * 0.024;
    if (buttonPadding < 18) buttonPadding = 18;
    if (buttonPadding > 24) buttonPadding = 24;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: const Color.fromARGB(255, 248, 253, 255),
          contentPadding: EdgeInsets.all(buttonPadding * 1.2),
          title: Column(
            children: [
              Container(
                padding: EdgeInsets.all(buttonPadding * 0.8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.fromRGBO(81, 115, 153, 0.15),
                      Color.fromRGBO(81, 115, 153, 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color.fromRGBO(81, 115, 153, 0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: const Color.fromRGBO(81, 115, 153, 1),
                  size: iconSize,
                ),
              ),
              SizedBox(height: buttonPadding * 0.8),
              Text(
                'Confirm Logout',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromRGBO(81, 115, 153, 1),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: buttonPadding * 0.8,
                  vertical: buttonPadding * 0.6,
                ),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(81, 115, 153, 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Are you sure you want to logout from your account?',
                  style: TextStyle(
                    fontSize: contentFontSize,
                    color: Colors.grey[700],
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: buttonPadding * 0.7,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: const Color.fromRGBO(81, 115, 153, 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: contentFontSize,
                        color: const Color.fromRGBO(81, 115, 153, 0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: buttonPadding * 0.6),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await LogoutHelper.logout();
                    },
                    style: ElevatedButton.styleFrom(
                     backgroundColor: const Color.fromARGB(255, 248, 24, 24),
                    foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: buttonPadding * 0.7,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                      shadowColor: const Color.fromRGBO(81, 115, 153, 0.4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          size: contentFontSize * 1.2,
                        ),
                        SizedBox(width: buttonPadding * 0.4),
                        Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: contentFontSize,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: EdgeInsets.fromLTRB(
            buttonPadding * 1.2,
            buttonPadding * 0.4,
            buttonPadding * 1.2,
            buttonPadding * 1.2,
          ),
        );
      },
    );
  }
}
