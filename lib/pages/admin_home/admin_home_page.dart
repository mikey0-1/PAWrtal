import 'package:capstone_app/mobile/admin/components/gnav_bar.dart';
import 'package:capstone_app/mobile/admin/pages/admin_landing_page.dart';
import 'package:capstone_app/mobile/admin/pages/appointment_list.dart';
import 'package:capstone_app/mobile/admin/pages/messages.dart';
import 'package:capstone_app/mobile/admin/pages/staff_account_list.dart';
import 'package:capstone_app/pages/admin_home/admin_home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => AdminHomePageState();  
}

class AdminHomePageState extends State<AdminHomePage> {
  int _selectedPage = 0;
  final AdminHomeController _adminController = Get.find<AdminHomeController>();

  void navigateBottomBar(int index) {
    setState(() {
      _selectedPage = index;
    });
  }

  // Build the messages page when needed
  Widget _buildMessagesPage() {
    final clinicId = _adminController.clinic.value?.documentId;
    if (clinicId != null) {
      return MessagesPage(clinicId: clinicId);
    } else {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color.fromARGB(255, 81, 115, 153),
            ),
            SizedBox(height: 16),
            Text('Loading clinic information...'),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: GnavBar(
        selectedIndex: _selectedPage,
        onTabChange: (index) => navigateBottomBar(index),
      ),
      body: IndexedStack(
        index: _selectedPage,
        children: [
          const AdminLandingPage(),
          const EnhancedAppointmentListPage(),
          _buildMessagesPage(), // Build when needed, not reactive
          const StaffAccountsPage(),
        ],
      ),
    );
  }
}