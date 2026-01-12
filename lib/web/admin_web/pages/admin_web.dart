// import 'package:capstone_app/web/admin_web/components/dashboard%20appbar/admin_web_notif.dart';
// import 'package:capstone_app/web/admin_web/components/dashboard%20appbar/admin_web_profile.dart';
// import 'package:capstone_app/web/admin_web/pages/admin_web_appointments.dart';
// import 'package:capstone_app/web/admin_web/pages/admin_web_clinicpage.dart';
// import 'package:capstone_app/web/admin_web/pages/admin_web_dashboard.dart';
// import 'package:capstone_app/web/admin_web/pages/admin_web_messages.dart';
// import 'package:capstone_app/web/admin_web/pages/admin_web_staffs.dart';
// import 'package:flutter/material.dart';

// class AdminWeb extends StatefulWidget {
//   const AdminWeb({super.key});

//   @override
//   State<AdminWeb> createState() => _AdminWebState();
// }

// int _selectedIndex = 0;

// final List<Widget> _pages = const [
//   AdminWebDashboard(),
//   AdminWebClinicpage(),
//   AdminWebAppointments(),
//   AdminWebMessages(),
//   AdminWebStaffs(),
// ];

// class _AdminWebState extends State<AdminWeb> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         scrolledUnderElevation: 0,
//         backgroundColor: Colors.white,
//         centerTitle: true,
//         leadingWidth: 220,
//         toolbarHeight: 80,
//         bottom: PreferredSize(
//           preferredSize: Size.fromHeight(1.0),
//           child: Container(
//             color: Colors.grey.shade400,
//             height: 1,
//           ),
//         ),
//         leading: Padding(
//           padding: const EdgeInsets.only(left: 75),
//           child: InkWell(
//             onTap: () {
//               setState(() {
//                 _selectedIndex = 0;
//               });
//             },
//             child: Image.asset(
//               'lib/images/PAWrtal_logo.png',
//             ),
//           ),
//         ),
//         title: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             InkWell(
//               borderRadius: BorderRadius.circular(20),
//               onTap: () {
//                 setState(() {
//                   _selectedIndex = 0;
//                 });
//               },
//               child: Container(
//                 padding: const EdgeInsets.all(12),
//                 child: Text(
//                   "Home",
//                   style: TextStyle(
//                       fontSize: 18,
//                       color: _selectedIndex == 0 ? Colors.black : Colors.grey),
//                 ),
//               ),
//             ),
//             InkWell(
//               borderRadius: BorderRadius.circular(20),
//               onTap: () {
//                 setState(() {
//                   _selectedIndex = 1;
//                 });
//               },
//               child: Container(
//                 padding: const EdgeInsets.all(12),
//                 child: Text(
//                   "Clinic",
//                   style: TextStyle(
//                       fontSize: 18,
//                       color: _selectedIndex == 1 ? Colors.black : Colors.grey),
//                 ),
//               ),
//             ),
//             InkWell(
//               borderRadius: BorderRadius.circular(20),
//               onTap: () {
//                 setState(() {
//                   _selectedIndex = 2;
//                 });
//               },
//               child: Container(
//                 padding: const EdgeInsets.all(12),
//                 child: Text(
//                   "Appointments",
//                   style: TextStyle(
//                       fontSize: 18,
//                       color: _selectedIndex == 2 ? Colors.black : Colors.grey),
//                 ),
//               ),
//             ),
//             InkWell(
//               borderRadius: BorderRadius.circular(20),
//               onTap: () {
//                 setState(() {
//                   _selectedIndex = 3;
//                 });
//               },
//               child: Container(
//                 padding: const EdgeInsets.all(12),
//                 child: Text(
//                   "Messages",
//                   style: TextStyle(
//                       fontSize: 18,
//                       color: _selectedIndex == 3 ? Colors.black : Colors.grey),
//                 ),
//               ),
//             ),
//             InkWell(
//               borderRadius: BorderRadius.circular(20),
//               onTap: () {
//                 setState(() {
//                   _selectedIndex = 4;
//                 });
//               },
//               child: Container(
//                 padding: const EdgeInsets.all(12),
//                 child: Text(
//                   "Staffs",
//                   style: TextStyle(
//                       fontSize: 18,
//                       color: _selectedIndex == 4 ? Colors.black : Colors.grey),
//                 ),
//               ),
//             ),
//           ],
//         ),
//         actions: const [
//           Padding(
//             padding: EdgeInsets.only(right: 60),
//             child: Row(
//               children: [
//                 AdminWebNotif(),
//                 Padding(
//                   padding: EdgeInsets.only(left: 30),
//                   child: AdminWebProfile(),
//                 ),
//               ],
//             ),
//           )
//         ],
//       ),
//       body: _pages[_selectedIndex],
//     );
//   }
// }
