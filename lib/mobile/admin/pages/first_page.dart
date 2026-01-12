// import 'package:capstone_app/mobile/admin/components/gnav_bar.dart';
// import 'package:capstone_app/mobile/admin/pages/admin_landing_page.dart';
// import 'package:capstone_app/mobile/admin/pages/appointment_list.dart';
// import 'package:capstone_app/mobile/admin/pages/messages.dart';
// import 'package:capstone_app/mobile/admin/pages/staff_account_list.dart';
// import 'package:flutter/material.dart';

// class FirstPage extends StatefulWidget {
//   const FirstPage({super.key});

//   @override
//   State<FirstPage> createState() => _FirstPageState();
// }

// class _FirstPageState extends State<FirstPage> {
//   int _selectedPage = 0;

//   void _navigateBottomBar(int index) {
//     setState(() {
//       _selectedPage = index;
//     });
//   }

//   final List _pages = [
//     const AdminLandingPage(),
//     const EnhancedAppointmentListPage(),
//     const MessagesPage(),
//     const StaffAccountsPage(),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       bottomNavigationBar: GnavBar(
//         onTabChange: (index) => _navigateBottomBar(index),
//       ),
//       body: _pages[_selectedPage],
//     );
//   }
// }
