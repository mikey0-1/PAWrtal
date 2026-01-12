// import 'package:capstone_app/web/pages/web_super_admin_home/web_super_admin_home_controller.dart';
// import 'package:capstone_app/web/super_admin/WebVersion/main_components/pet_owner_menu_tile.dart';
// import 'package:capstone_app/web/super_admin/WebVersion/main_components/vet_clinic_menu_tile.dart';
// import 'package:capstone_app/web/super_admin/WebVersion/main_components/view_report_menu_tile.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// class WebSuperAdminHomePage extends GetView<WebSuperAdminHomeController> {
//   const WebSuperAdminHomePage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final screenHeight = MediaQuery.of(context).size.height;

//     return Scaffold(
//       appBar: AppBar(
//         surfaceTintColor: Colors.transparent,
//         backgroundColor: const Color.fromARGB(255, 248, 253, 255),
//         centerTitle: true,
//         toolbarHeight: screenHeight * 0.1,
//         flexibleSpace: Container(
//           margin: const EdgeInsets.only(top: 15.0),
//           child: Center(
//             child: Image.asset(
//               "lib/images/PAWrtal_logo.png",
//               height: double.infinity,
//               width: double.infinity,
//               fit: BoxFit.contain,
//             ),
//           ),
//         ),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 20.0),
//             child: Obx(() => TextButton.icon(
//               onPressed: controller.isLoggingOut.value ? null : controller.logout,
//               icon: controller.isLoggingOut.value
//                   ? const SizedBox(
//                       width: 16,
//                       height: 16,
//                       child: CircularProgressIndicator(
//                         strokeWidth: 2,
//                         valueColor: AlwaysStoppedAnimation<Color>(
//                           Color.fromRGBO(81, 115, 153, 0.8),
//                         ),
//                       ),
//                     )
//                   : const Icon(Icons.logout,
//                       color: Color.fromRGBO(81, 115, 153, 0.8)),
//               label: Text(
//                 controller.isLoggingOut.value ? 'Logging Out...' : 'Log Out',
//                 style: const TextStyle(color: Color.fromRGBO(81, 115, 153, 0.8)),
//               ),
//               style: TextButton.styleFrom(
//                 foregroundColor: const Color.fromRGBO(81, 115, 153, 0.8),
//               ),
//             )),
//           ),
//         ],
//       ),
//       backgroundColor: const Color.fromARGB(255, 248, 253, 255),
//       body: LayoutBuilder(
//         builder: (BuildContext context, BoxConstraints constraints) {
//           return SingleChildScrollView(
//             child: Padding(
//               padding: const EdgeInsets.only(top: 20, bottom: 60),
//               child: constraints.maxWidth > 800
//                   ? const Row(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Expanded(child: VetClinicTile()),
//                         Expanded(child: PetOwnerTile()),
//                         Expanded(child: ViewReportTile()),
//                       ],
//                     )
//                   : const SingleChildScrollView(
//                       scrollDirection: Axis.vertical,
//                       child: Column(
//                         children: [
//                           VetClinicTile(),
//                           PetOwnerTile(),
//                           ViewReportTile(),
//                         ],
//                       ),
//                     ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// FOR RESPONSIVE LAYOUT (Wrapper)

import 'package:capstone_app/web/pages/web_super_admin_home/web_super_admin_home_controller.dart';
import 'package:capstone_app/web/responsive_layout.dart';
import 'package:capstone_app/web/super_admin/desktop/super_admin_desktop_home_page.dart';
import 'package:capstone_app/web/super_admin/mobile/super_admin_mobile_home_page.dart';
import 'package:capstone_app/web/super_admin/tablet/super_admin_tablet_home_page.dart'
    as tablet;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WebSuperAdminHomePage extends GetView<WebSuperAdminHomeController> {
  const WebSuperAdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveLayout(
        desktopBody: () => const SuperAdminDesktopHomePage(),
        tabletBody: () => const tablet.SuperAdminTabletHomePage(),
        mobileBody: () => const SuperAdminMobileHomePage(),
      ),
    );
  }
}
