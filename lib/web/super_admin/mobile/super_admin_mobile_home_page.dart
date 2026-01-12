import 'package:capstone_app/utils/logout_helper.dart';
import 'package:capstone_app/web/pages/web_super_admin_home/web_super_admin_home_controller.dart';
import 'package:capstone_app/web/super_admin/WebVersion/tile_pages/pet_owner_menu_tile.dart';
import 'package:capstone_app/web/super_admin/WebVersion/tile_pages/vet_clinic_menu_tile.dart';
import 'package:capstone_app/web/super_admin/WebVersion/tile_pages/view_report_menu_tile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SuperAdminMobileHomePage extends GetView<WebSuperAdminHomeController> {
  const SuperAdminMobileHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height * 0.6;
    final isTablet = screenWidth > 600;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        surfaceTintColor: Colors.transparent,
        backgroundColor: const Color.fromARGB(255, 248, 253, 255),
        centerTitle: true,
        toolbarHeight: isTablet ? 80 : 70,
        title: Image.asset(
          "lib/images/PAWrtal_logo.png",
          height: isTablet ? 45 : 35,
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: isTablet ? 16.0 : 12.0),
            child: _buildLogoutButton(context, isTablet),
          ),
        ],
      ),
      backgroundColor: const Color.fromARGB(255, 248, 253, 255),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? screenWidth * 0.1 : 16,
            vertical: 20,
          ).copyWith(bottom: 60),
          child: _buildMenuTiles(isTablet, isLandscape, screenWidth),
        ),
      ),
    );
  }

  Widget _buildMenuTiles(bool isTablet, bool isLandscape, double screenWidth) {
    const menuTiles = [
      VetClinicTile(),
      PetOwnerTile(),
      ViewReportTile(),
    ];

    // For tablets or landscape mode, use grid layout
    if (isTablet || isLandscape) {
      final crossAxisCount =
          isTablet ? (screenWidth > 900 ? 3 : 2) : (screenWidth > 700 ? 2 : 1);

      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: isTablet ? 1.2 : 1.5,
        children: menuTiles,
      );
    }

    // For mobile portrait, use column layout
    return Column(
      children: menuTiles
          .map((tile) => Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: tile,
              ))
          .toList(),
    );
  }

  Widget _buildLogoutButton(BuildContext context, bool isTablet) {
    double iconSize = isTablet ? 26 : 24;
    double containerSize = isTablet ? 50 : 46;

    return GestureDetector(
      onTap: () => _showLogoutDialog(context),
      child: Container(
        width: containerSize,
        height: containerSize,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromRGBO(81, 115, 153, 0.9),
              Color.fromRGBO(81, 115, 153, 1),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(81, 115, 153, 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                Icons.logout_rounded,
                color: Colors.white,
                size: iconSize,
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: const Color.fromARGB(255, 248, 253, 255),
          title: Column(
            children: [
              Container(
                padding: EdgeInsets.all(isTablet ? 16 : 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.fromRGBO(81, 115, 153, 0.1),
                      Color.fromRGBO(81, 115, 153, 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: const Color.fromRGBO(81, 115, 153, 1),
                  size: isTablet ? 40 : 36,
                ),
              ),
              SizedBox(height: isTablet ? 16 : 12),
              Text(
                'Confirm Logout',
                style: TextStyle(
                  fontSize: isTablet ? 22 : 20,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromRGBO(81, 115, 153, 1),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to logout from your account?',
            style: TextStyle(
              fontSize: isTablet ? 16 : 15,
              color: Colors.grey[700],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: isTablet ? 16 : 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.grey[300]!,
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 15,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: isTablet ? 12 : 10),
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
                        vertical: isTablet ? 16 : 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          size: isTablet ? 20 : 18,
                        ),
                        SizedBox(width: isTablet ? 8 : 6),
                        Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 15,
                            fontWeight: FontWeight.w600,
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
            isTablet ? 20 : 16,
            0,
            isTablet ? 20 : 16,
            isTablet ? 20 : 16,
          ),
        );
      },
    );
  }
}