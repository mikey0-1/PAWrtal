
import 'package:capstone_app/mobile/admin/controllers/enhanced_clinic_appointment_controller.dart';
import 'package:capstone_app/mobile/admin/components/appointment_tiles/enhanced_clinic_appointment_tile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ScheduledPage extends StatelessWidget {
  const ScheduledPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<EnhancedClinicAppointmentController>();

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 230, 230, 230),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final scheduledAppointments = controller.scheduled;

        if (scheduledAppointments.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () => controller.refreshAppointments(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: scheduledAppointments.length,
            itemBuilder: (context, index) {
              final appointment = scheduledAppointments[index];
              return PatientWorkflowTile(
                appointment: appointment,
                workflowStage: 'scheduled',
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Scheduled Appointments',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Accepted appointments will appear here.\nPatients are waiting for their scheduled time.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}