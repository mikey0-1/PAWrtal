// enhanced_appointment_list.dart
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/mobile/admin/controllers/enhanced_clinic_appointment_controller.dart';
import 'package:capstone_app/mobile/admin/pages/appointment_list_pages/completed_page.dart';
import 'package:capstone_app/mobile/admin/pages/appointment_list_pages/in_progress_page.dart';
import 'package:capstone_app/mobile/admin/pages/appointment_list_pages/pending_page.dart';
import 'package:capstone_app/mobile/admin/pages/appointment_list_pages/scheduled_page.dart';
import 'package:capstone_app/mobile/admin/pages/appointment_list_pages/today_overview_page.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class EnhancedAppointmentListPage extends StatefulWidget {
  const EnhancedAppointmentListPage({super.key});

  @override
  State<EnhancedAppointmentListPage> createState() => _EnhancedAppointmentListPageState();
}

class _EnhancedAppointmentListPageState extends State<EnhancedAppointmentListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    // Initialize controller
    if (!Get.isRegistered<EnhancedClinicAppointmentController>()) {
      Get.put(EnhancedClinicAppointmentController(
        authRepository: Get.find<AuthRepository>(),
        session: Get.find<UserSessionService>(),
      ));
    } else {
      Get.find<EnhancedClinicAppointmentController>().fetchClinicData();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<EnhancedClinicAppointmentController>();

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 81, 115, 153),
      body: Column(
        children: [
          // Enhanced Header with Stats
          Container(
            padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Patient Care",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Obx(() {
                          final stats = controller.appointmentStats;
                          return Text(
                            "${stats['today']} today • ${stats['in_progress']} in progress",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          );
                        }),
                      ],
                    ),
                    // Stats & Refresh
                    Row(
                      children: [
                        // Today's Revenue
                        Obx(() => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              Text(
                                "₱${controller.todayRevenue.toStringAsFixed(0)}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                "Today's Revenue",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        )),
                        const SizedBox(width: 12),
                        // Refresh Button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            onPressed: () => controller.refreshAppointments(),
                            icon: const Icon(Icons.refresh, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Enhanced Tab Bar and Content
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 230, 230, 230),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: Column(
                children: [
                  // Enhanced Tab Bar
                  Container(
                    margin: const EdgeInsets.only(top: 20, left: 16, right: 16),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TabBar(
                      controller: _tabController,
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: const Color.fromARGB(255, 81, 115, 153),
                      indicatorColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color.fromARGB(255, 81, 115, 153),
                            Colors.blue.shade400,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isScrollable: true,
                      tabs: [
                        _buildTab(Icons.today, "Today", controller.appointmentStats['today'] ?? 0),
                        _buildTab(Icons.pending, "Pending", controller.appointmentStats['pending'] ?? 0),
                        _buildTab(Icons.schedule, "Scheduled", controller.appointmentStats['scheduled'] ?? 0),
                        _buildTab(Icons.medical_services, "In Progress", controller.appointmentStats['in_progress'] ?? 0),
                        _buildTab(Icons.check_circle, "Completed", controller.appointmentStats['completed'] ?? 0),
                      ],
                    ),
                  ),
                  
                  // Tab Content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: const [
                        TodayOverviewPage(),
                        PendingPage(),
                        ScheduledPage(),
                        InProgressPage(),
                        CompletedPage(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(IconData icon, String text, int count) {
    return Tab(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 6),
            Text(text, style: const TextStyle(fontSize: 12)),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getCountColor(text),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getCountColor(String tabName) {
    switch (tabName) {
      case 'Today':
        return Colors.blue;
      case 'Pending':
        return Colors.orange;
      case 'Scheduled':
        return Colors.green;
      case 'In Progress':
        return Colors.purple;
      case 'Completed':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}