import 'package:capstone_app/data/models/appointment_model.dart';
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/mobile/user/components/appointment_tabs/appointments_1st_tab.dart';
import 'package:capstone_app/mobile/user/components/appointment_tabs/appointments_2nd_tab.dart';
import 'package:capstone_app/mobile/user/components/appointment_tabs/appointments_3rd_tab.dart';
import 'package:capstone_app/mobile/user/components/appointment_tabs/appointments_4th_tab.dart';
import 'package:capstone_app/mobile/user/components/appointment_tabs/components/user_appointment_controller.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class EnhancedAppointmentPage extends StatefulWidget {
  const EnhancedAppointmentPage({super.key});

  @override
  State<EnhancedAppointmentPage> createState() => _EnhancedAppointmentPageState();
}

class _EnhancedAppointmentPageState extends State<EnhancedAppointmentPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  final List<TabData> _tabs = [
    TabData(
      icon: Icons.pending_rounded,
      text: "Pending",
      color: Colors.orange,
    ),
    TabData(
      icon: Icons.event_available_rounded,
      text: "Upcoming",
      color: Colors.blue,
    ),
    TabData(
      icon: Icons.check_circle_rounded,
      text: "Completed",
      color: Colors.green,
    ),
    TabData(
      icon: Icons.history_rounded,
      text: "History",
      color: Colors.grey,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedIndex = _tabController.index;
        });
      }
    });

    if (!Get.isRegistered<EnhancedUserAppointmentController>()) {
      Get.put(EnhancedUserAppointmentController(
        authRepository: Get.find<AuthRepository>(),
        session: Get.find<UserSessionService>(),
      ));
    } else {
      Get.find<EnhancedUserAppointmentController>().fetchAppointments();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

@override
Widget build(BuildContext context) {
  final controller = Get.find<EnhancedUserAppointmentController>();
  DateTime now = DateTime.now();
  String formattedDate = DateFormat('EEEE, MMMM dd, yyyy').format(now);
  
  return Scaffold(
    backgroundColor: const Color.fromARGB(255, 81, 115, 153),
    body: Column(
      children: [
        // Enhanced Header
        Container(
          padding: const EdgeInsets.only(top: 20, bottom: 20, left: 20, right: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formattedDate,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Obx(() {
                          final stats = controller.userStats;
                          return Text(
                            "${stats['total']} total appointments",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  // Upcoming & In Progress
                  Obx(() {
                    final stats = controller.userStats;
                    final inProgressAppointments = controller.inProgress;
                    
                    return Column(
                      children: [
                        if (inProgressAppointments.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _showInProgressDialog(context, inProgressAppointments),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.4),
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.greenAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "In Progress",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      "${inProgressAppointments.length}",
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color.fromARGB(255, 81, 115, 153),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
        
        Expanded(
          child: Container(
            width: double.maxFinite,
            height: double.maxFinite,
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 230, 230, 230),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            child: Column(
              children: [
                // Custom Dynamic Tab Bar
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
                  child: Obx(() {
                    final stats = controller.userStats;
                    return Row(
                      children: List.generate(4, (index) {
                        final isSelected = _selectedIndex == index;
                        final tab = _tabs[index];
                        int count = 0;
                        
                        switch (index) {
                          case 0:
                            count = stats['pending'] ?? 0;
                            break;
                          case 1:
                            count = stats['upcoming'] ?? 0;
                            break;
                          case 2:
                            count = stats['completed'] ?? 0;
                            break;
                          case 3:
                            count = stats['history'] ?? 0;
                            break;
                        }

                        return Expanded(
                          flex: isSelected ? 3 : 1,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: InkWell(
                              onTap: () {
                                _tabController.animateTo(index);
                                setState(() {
                                  _selectedIndex = index;
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? LinearGradient(
                                          colors: [
                                            const Color.fromARGB(255, 81, 115, 153),
                                            Colors.blue.shade400,
                                          ],
                                        )
                                      : null,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: isSelected
                                    ? Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            tab.icon,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              tab.text,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (count > 0) ...[
                                            const SizedBox(width: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                count.toString(),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: tab.color,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      )
                                    : Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Icon(
                                            tab.icon,
                                            size: 20,
                                            color: const Color.fromARGB(255, 81, 115, 153)
                                                .withOpacity(0.6),
                                          ),
                                          if (count > 0)
                                            Positioned(
                                              right: 0,
                                              top: 0,
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: tab.color,
                                                  shape: BoxShape.circle,
                                                ),
                                                constraints: const BoxConstraints(
                                                  minWidth: 16,
                                                  minHeight: 16,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    count > 9 ? '9+' : count.toString(),
                                                    style: const TextStyle(
                                                      fontSize: 8,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  }),
                ),
                
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: const [
                      EnhancedAPSecondTab(), // Pending
                      EnhancedAPFirstTab(),  // Upcoming
                      EnhancedAPThirdTab(),  // Completed
                      EnhancedAPFourthTab(), // History
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
}

void _showInProgressDialog(BuildContext context, List<Appointment> appointments) {
  final controller = Get.find<EnhancedUserAppointmentController>();
  
  showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.shade400,
                    Colors.green.shade600,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.medical_services,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Appointments In Progress',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${appointments.length} active ${appointments.length == 1 ? 'appointment' : 'appointments'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // Appointments List
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                shrinkWrap: true,
                itemCount: appointments.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final appointment = appointments[index];
                  final clinic = controller.getClinicForAppointment(appointment);
                  final pet = controller.getPetForAppointment(appointment);
                  
                  return _buildMobileInProgressCard(
                    context,
                    appointment,
                    clinic,
                    pet,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// Add this method to _EnhancedAppointmentPageState class
Widget _buildMobileInProgressCard(
  BuildContext context,
  Appointment appointment,
  Clinic? clinic,
  Pet? pet,
) {
  String statusText = '';
  IconData statusIcon = Icons.medical_services;
  Color statusColor = Colors.blue;

  if (appointment.checkedInAt != null && appointment.serviceStartedAt == null) {
    statusText = 'Checked In - Waiting';
    statusIcon = Icons.login;
    statusColor = Colors.orange;
  } else if (appointment.serviceStartedAt != null && appointment.serviceCompletedAt == null) {
    statusText = 'Treatment in Progress';
    statusIcon = Icons.healing;
    statusColor = Colors.green;
  }

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
      boxShadow: [
        BoxShadow(
          color: statusColor.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusIcon, size: 16, color: statusColor),
              const SizedBox(width: 6),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        // Clinic Info
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.local_hospital,
                size: 20,
                color: Colors.blue.shade600,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    clinic?.clinicName ?? 'Unknown Clinic',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    clinic?.address ?? 'Address not available',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Divider
        Divider(color: Colors.grey.shade200, height: 1),
        const SizedBox(height: 12),
        
        // Service & Pet Info
        Row(
          children: [
            Icon(Icons.medical_services_outlined, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                appointment.service,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.pets, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                pet?.name ?? appointment.petId,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Time Info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(Icons.schedule, size: 18, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                DateFormat('EEEE, MMM dd • h:mm a').format(appointment.dateTime),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
        ),
        
        // Progress Timeline
        if (appointment.checkedInAt != null || appointment.serviceStartedAt != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                if (appointment.checkedInAt != null)
                  _buildMobileProgressStep(
                    'Checked In',
                    DateFormat('h:mm a').format(appointment.checkedInAt!),
                    Icons.login,
                    Colors.green,
                    true,
                  ),
                if (appointment.checkedInAt != null && appointment.serviceStartedAt != null)
                  _buildProgressConnector(),
                if (appointment.serviceStartedAt != null)
                  _buildMobileProgressStep(
                    'Service Started',
                    DateFormat('h:mm a').format(appointment.serviceStartedAt!),
                    Icons.play_arrow,
                    Colors.blue,
                    true,
                  ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}

Widget _buildMobileProgressStep(
  String label,
  String time,
  IconData icon,
  Color color,
  bool isCompleted,
) {
  return Row(
    children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isCompleted ? color : Colors.grey.shade300,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 14,
          color: Colors.white,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isCompleted ? Colors.black87 : Colors.grey.shade600,
              ),
            ),
            Text(
              time,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

Widget _buildProgressConnector() {
  return Container(
    margin: const EdgeInsets.only(left: 14, top: 4, bottom: 4),
    width: 2,
    height: 20,
    color: Colors.grey.shade300,
  );
}

class TabData {
  final IconData icon;
  final String text;
  final Color color;

  TabData({
    required this.icon,
    required this.text,
    required this.color,
  });
}