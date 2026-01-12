import 'package:capstone_app/web/super_admin/WebVersion/tile_pages/vet_clinic_menu_tile.dart';
import 'package:capstone_app/web/super_admin/WebVersion/tile_pages/pet_owner_menu_tile.dart';
import 'package:capstone_app/web/super_admin/WebVersion/tile_pages/view_report_menu_tile.dart';

import 'package:flutter/material.dart';

class SuperAdminHomePage extends StatefulWidget {
  const SuperAdminHomePage({super.key});

  @override
  State<SuperAdminHomePage> createState() => _MySuperAdminHomePage();
}

class _MySuperAdminHomePage extends State<SuperAdminHomePage> {
  @override
  Widget build(BuildContext context) {
    //final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: const Color.fromARGB(255, 248, 253, 255),
        centerTitle: true,
        toolbarHeight: screenHeight * 0.1,
        flexibleSpace: Container(
          margin: const EdgeInsets.only(top: 15.0),
          child: Center(
            child: Image.asset(
              "lib/images/PAWrtal_logo.png",
              height: screenHeight * 0.08,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 248, 253, 255),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 60),
              child: constraints.maxWidth > 800
                  ? const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(child: VetClinicTile()),
                        Expanded(child: PetOwnerTile()),
                        Expanded(child: ViewReportTile()),
                      ],
                    )
                  : const SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Column(
                        children: [
                          VetClinicTile(),
                          PetOwnerTile(),
                          ViewReportTile(),
                        ],
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}
