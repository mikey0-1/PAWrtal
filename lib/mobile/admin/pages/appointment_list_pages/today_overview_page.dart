import 'package:capstone_app/mobile/admin/controllers/enhanced_clinic_appointment_controller.dart';
import 'package:capstone_app/mobile/admin/components/appointment_tiles/enhanced_clinic_appointment_tile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class TodayOverviewPage extends StatelessWidget {
  const TodayOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<EnhancedClinicAppointmentController>();

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 230, 230, 230),
      body: RefreshIndicator(
        onRefresh: () => controller.refreshAppointments(),
        child: CustomScrollView(
          slivers: [
            // Today's Stats Header
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color.fromARGB(255, 81, 115, 153),
                      Colors.blue.shade400,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('EEEE, MMMM dd, yyyy').format(DateTime.now()),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Today's Overview",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.today,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Today's Statistics
                    Obx(() {
                      final stats = controller.appointmentStats;
                      final todayAppointments = controller.todayAppointments;
                      final todayRevenue = controller.todayRevenue;
                      
                      return Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Total',
                              stats['today'].toString(),
                              Icons.calendar_today,
                              Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'In Progress',
                              stats['in_progress'].toString(),
                              Icons.medical_services,
                              Colors.orange.shade100,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Completed',
                              stats['completed'].toString(),
                              Icons.check_circle,
                              Colors.green.shade100,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Revenue',
                              '₱${todayRevenue.toStringAsFixed(0)}',
                              Icons.attach_money,
                              Colors.yellow.shade100,
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Today's Appointments List
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Today's Appointments",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 81, 115, 153),
                      ),
                    ),
                    Obx(() => Text(
                      '${controller.todayAppointments.length} appointments',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    )),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Today's Appointments List
            Obx(() {
              if (controller.isLoading.value) {
                return const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final todayAppointments = controller.todayAppointments;

              if (todayAppointments.isEmpty) {
                return SliverToBoxAdapter(
                  child: _buildEmptyState(),
                );
              }

              // Group appointments by status for better organization
              final groupedAppointments = <Map<String, dynamic>>[
                {'status': 'pending', 'appointments': todayAppointments.where((a) => a.status == 'pending').toList()},
                {'status': 'accepted', 'appointments': todayAppointments.where((a) => a.status == 'accepted').toList()},
                {'status': 'in_progress', 'appointments': todayAppointments.where((a) => a.status == 'in_progress').toList()},
                {'status': 'completed', 'appointments': todayAppointments.where((a) => a.status == 'completed').toList()},
              ].where((group) => (group['appointments'] as List).isNotEmpty).toList();

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= groupedAppointments.length) return null;
                    
                    final group = groupedAppointments[index];
                    final status = group['status'] as String;
                    final appointments = group['appointments'] as List;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Section Header
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                _getStatusIcon(status),
                                color: _getStatusColor(status),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_getStatusDisplayName(status)} (${appointments.length})',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(status),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Appointments in this status
                        ...appointments.map((appointment) => PatientWorkflowTile(
                          appointment: appointment,
                          workflowStage: status,
                        )),
                        
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                  childCount: groupedAppointments.length,
                ),
              );
            }),

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: const Color.fromARGB(255, 81, 115, 153),
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 81, 115, 153),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Appointments Today',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your schedule is clear for today!\nTime to catch up on other tasks.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Switch to pending tab to see tomorrow's appointments
                Get.snackbar('Info', 'Check the Pending tab for future appointments');
              },
              icon: const Icon(Icons.schedule),
              label: const Text('View Upcoming'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods for status styling
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending;
      case 'accepted':
        return Icons.schedule;
      case 'in_progress':
        return Icons.medical_services;
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'in_progress':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'pending':
        return 'Pending Review';
      case 'accepted':
        return 'Scheduled';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }

  // Dialog methods for quick actions
  void _showEmergencyDialog(BuildContext context) {
    Get.snackbar(
      'Emergency Check-in',
      'Emergency check-in feature will be implemented',
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  void _showWalkInDialog(BuildContext context) {
    Get.snackbar(
      'Walk-in Patient',
      'Walk-in patient registration feature will be implemented',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }

  void _showFollowUpDialog(BuildContext context) {
    Get.snackbar(
      'Schedule Follow-up',
      'Follow-up scheduling feature will be implemented',
      backgroundColor: Colors.purple,
      colorText: Colors.white,
    );
  }

  void _showMedicalRecordsDialog(BuildContext context) {
    Get.snackbar(
      'Medical Records',
      'Medical records viewer will be implemented',
      backgroundColor: Colors.teal,
      colorText: Colors.white,
    );
  }
}