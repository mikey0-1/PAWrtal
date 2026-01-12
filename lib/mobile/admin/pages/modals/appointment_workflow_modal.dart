import 'package:capstone_app/data/models/appointment_model.dart';
import 'package:capstone_app/mobile/admin/controllers/enhanced_clinic_appointment_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AppointmentWorkflowModal extends StatelessWidget {
  final Appointment appointment;
  final String workflowStage;

  const AppointmentWorkflowModal({
    super.key,
    required this.appointment,
    required this.workflowStage,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<EnhancedClinicAppointmentController>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Modal content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with pet info
                  _buildHeader(controller),
                  const SizedBox(height: 24),

                  // Appointment details
                  _buildAppointmentDetails(),
                  const SizedBox(height: 24),

                  // Workflow progress
                  _buildWorkflowProgress(),
                  const SizedBox(height: 24),

                  // Show pending vitals indicator if they exist
                  if (controller.hasPendingVitals(appointment.documentId!)) ...[
                    _buildPendingVitalsIndicator(controller),
                    const SizedBox(height: 24),
                  ],

                  // Medical record link for completed appointments
                  if (appointment.status == 'completed') ...[
                    _buildMedicalRecordLink(context, controller),
                    const SizedBox(height: 24),
                  ],

                  // Action buttons
                  _buildActionButtons(context, controller),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(EnhancedClinicAppointmentController controller) {
    return Row(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            gradient: LinearGradient(
              colors: _getStatusGradient(appointment.status),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(
            Icons.pets,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                controller.getPetName(appointment.petId),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 81, 115, 153),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Owner: ${controller.getOwnerName(appointment.userId)}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${controller.getPetType(appointment.petId)} • ${controller.getPetBreed(appointment.petId)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getStatusColor(appointment.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _getStatusColor(appointment.status).withOpacity(0.3),
            ),
          ),
          child: Text(
            _getStatusDisplayText(appointment.status),
            style: TextStyle(
              color: _getStatusColor(appointment.status),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppointmentDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Appointment Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 81, 115, 153),
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.schedule,
            'Scheduled Time',
            DateFormat('EEEE, MMMM dd, yyyy • hh:mm a')
                .format(appointment.dateTime),
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            Icons.medical_services,
            'Service',
            appointment.service,
          ),
          if (appointment.notes != null) ...[
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.note,
              'Booking Notes',
              appointment.notes!,
            ),
          ],
          if (appointment.totalCost != null) ...[
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.attach_money,
              'Cost',
              '₱${appointment.totalCost!.toStringAsFixed(2)}',
            ),
          ],
          if (appointment.followUpInstructions != null) ...[
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.event_repeat,
              'Follow-up Instructions',
              appointment.followUpInstructions!,
            ),
          ],
          if (appointment.nextAppointmentDate != null) ...[
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.calendar_today,
              'Next Appointment',
              DateFormat('MMMM dd, yyyy')
                  .format(appointment.nextAppointmentDate!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          flex: 1,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkflowProgress() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Workflow Progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 81, 115, 153),
            ),
          ),
          const SizedBox(height: 16),

          // Timeline
          _buildTimelineItem(
            'Scheduled',
            appointment.status != 'pending',
            Colors.blue,
            appointment.createdAt,
            isFirst: true,
          ),
          _buildTimelineItem(
            'Patient Arrived',
            appointment.hasArrived,
            Colors.orange,
            appointment.checkedInAt,
          ),
          _buildTimelineItem(
            'Treatment Started',
            appointment.hasServiceStarted,
            Colors.purple,
            appointment.serviceStartedAt,
          ),
          _buildTimelineItem(
            'Service Completed',
            appointment.hasServiceCompleted,
            Colors.green,
            appointment.serviceCompletedAt,
            isLast: true,
          ),

          // Show waiting times
          if (appointment.waitingTime != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Waiting time: ${_formatDuration(appointment.waitingTime!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (appointment.serviceDuration != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer, size: 16, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Service duration: ${_formatDuration(appointment.serviceDuration!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    String title,
    bool isCompleted,
    Color color,
    DateTime? timestamp, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Row(
      children: [
        Column(
          children: [
            if (!isFirst)
              Container(
                width: 2,
                height: 16,
                color: isCompleted ? color : Colors.grey[300],
              ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isCompleted ? color : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 16,
                color: isCompleted ? color : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isCompleted ? color : Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              if (timestamp != null)
                Text(
                  DateFormat('MMM dd, hh:mm a').format(timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // Show pending vitals indicator (vitals not saved to appointment yet)
  Widget _buildPendingVitalsIndicator(
      EnhancedClinicAppointmentController controller) {
    final pendingVitals = controller.getPendingVitals(appointment.documentId!);
    if (pendingVitals == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Colors.orange[700], size: 24),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Vitals Recorded (Not Saved Yet)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Vital signs have been recorded temporarily and will be saved to the medical record when you complete the service.',
            style: TextStyle(fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 12),

          // Display pending vitals
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (pendingVitals['temperature'] != null)
                _buildPendingVitalChip(
                    'Temp: ${pendingVitals['temperature']}°C'),
              if (pendingVitals['weight'] != null)
                _buildPendingVitalChip('Weight: ${pendingVitals['weight']}kg'),
              if (pendingVitals['bloodPressure'] != null)
                _buildPendingVitalChip('BP: ${pendingVitals['bloodPressure']}'),
              if (pendingVitals['heartRate'] != null)
                _buildPendingVitalChip('HR: ${pendingVitals['heartRate']} bpm'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingVitalChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange[300]!),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.orange[900],
        ),
      ),
    );
  }

  // Medical record link for completed appointments
  Widget _buildMedicalRecordLink(
      BuildContext context, EnhancedClinicAppointmentController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medical_information,
                  color: Colors.teal[700], size: 24),
              const SizedBox(width: 8),
              const Text(
                'Medical Record',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'This appointment has been completed. Medical records including diagnosis, treatment, and vital signs are available in the Medical Records section.',
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Get.snackbar(
                  'Info',
                  'Navigation to medical records will be implemented',
                  backgroundColor: Colors.teal,
                  colorText: Colors.white,
                );
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('View Medical Record'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
      BuildContext context, EnhancedClinicAppointmentController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 81, 115, 153),
            ),
          ),
          const SizedBox(height: 12),

          // Action buttons based on status
          _getActionButtons(context, controller),
        ],
      ),
    );
  }

  Widget _getActionButtons(
      BuildContext context, EnhancedClinicAppointmentController controller) {
    switch (appointment.status) {
      case 'pending':
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  controller.acceptAppointment(appointment);
                },
                icon: const Icon(Icons.check),
                label: const Text('Accept Appointment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  controller.declineAppointment(appointment);
                },
                icon: const Icon(Icons.close),
                label: const Text('Decline'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        );

      case 'accepted':
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  controller.checkInPatient(appointment);
                },
                icon: const Icon(Icons.login),
                label: const Text('Check In Patient'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  controller.markNoShow(appointment);
                },
                icon: const Icon(Icons.person_off),
                label: const Text('Mark as No Show'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        );

      case 'in_progress':
        return Column(
          children: [
            if (!appointment.hasServiceStarted) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    controller.startService(appointment);
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Service'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showVitalsDialog(context, controller),
                icon: const Icon(Icons.favorite),
                label: Text(
                  controller.hasPendingVitals(appointment.documentId!)
                      ? 'Update Vitals'
                      : 'Record Vitals',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            if (appointment.hasServiceStarted) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _showCompleteServiceDialog(context, controller),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Complete Service'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        );

      case 'completed':
        return Column(
          children: [
            if (!appointment.isPaid) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showPaymentDialog(context, controller),
                  icon: const Icon(Icons.payment),
                  label: const Text('Process Payment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _viewMedicalRecord(context, controller),
                icon: const Icon(Icons.medical_information),
                label: const Text('View Medical Record'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.teal,
                  side: const BorderSide(color: Colors.teal),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _printMedicalRecord(context),
                icon: const Icon(Icons.print),
                label: const Text('Print Medical Record'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  side: const BorderSide(color: Colors.blue),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        );

      default:
        return const Text('No actions available');
    }
  }

  // Helper methods for dialogs
  void _showVitalsDialog(
      BuildContext context, EnhancedClinicAppointmentController controller) {
    // Get existing vitals if any
    final existingVitals = controller.getPendingVitals(appointment.documentId!);

    final tempController = TextEditingController(
      text: existingVitals?['temperature']?.toString() ?? '',
    );
    final weightController = TextEditingController(
      text: existingVitals?['weight']?.toString() ?? '',
    );
    final bpController = TextEditingController(
      text: existingVitals?['bloodPressure']?.toString() ?? '',
    );
    final hrController = TextEditingController(
      text: existingVitals?['heartRate']?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record Vital Signs'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tempController,
                decoration: const InputDecoration(
                  labelText: 'Temperature (°C)',
                  hintText: '38.5',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: weightController,
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  hintText: '5.2',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bpController,
                decoration: const InputDecoration(
                  labelText: 'Blood Pressure',
                  hintText: '120/80',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: hrController,
                decoration: const InputDecoration(
                  labelText: 'Heart Rate (bpm)',
                  hintText: '80',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: const Text(
                  '⚠️ Note: Vitals will be stored temporarily and saved to the medical record when you complete the service.',
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.recordVitalsLocally(
                appointmentId: appointment.documentId!,
                temperature: double.tryParse(tempController.text),
                weight: double.tryParse(weightController.text),
                bloodPressure:
                    bpController.text.isEmpty ? null : bpController.text,
                heartRate: int.tryParse(hrController.text),
              );

              Navigator.pop(context); // Close vitals dialog
              Navigator.pop(context); // Close workflow modal

              Get.snackbar(
                'Success',
                'Vitals recorded! They will be saved when you complete the service.',
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Save Vitals',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCompleteServiceDialog(
      BuildContext context, EnhancedClinicAppointmentController controller) {
    final diagnosisController = TextEditingController();
    final treatmentController = TextEditingController();
    final prescriptionController = TextEditingController();
    final notesController = TextEditingController();
    final costController = TextEditingController();
    final followUpController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Service'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Show pending vitals summary if available
              if (controller.hasPendingVitals(appointment.documentId!)) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.green[700], size: 16),
                          const SizedBox(width: 8),
                          const Text(
                            'Vitals Recorded',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Vital signs will be saved to the medical record',
                        style:
                            TextStyle(fontSize: 12, color: Colors.green[700]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              TextField(
                controller: diagnosisController,
                decoration: const InputDecoration(
                  labelText: 'Diagnosis *',
                  hintText: 'Enter diagnosis',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: treatmentController,
                decoration: const InputDecoration(
                  labelText: 'Treatment *',
                  hintText: 'Enter treatment given',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: prescriptionController,
                decoration: const InputDecoration(
                  labelText: 'Prescription',
                  hintText: 'Enter medications prescribed',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Veterinary Notes',
                  hintText: 'Additional notes',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: costController,
                decoration: const InputDecoration(
                  labelText: 'Total Cost (₱)',
                  hintText: '500.00',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: followUpController,
                decoration: const InputDecoration(
                  labelText: 'Follow-up Instructions',
                  hintText: 'Instructions for pet owner',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (diagnosisController.text.isEmpty ||
                  treatmentController.text.isEmpty) {
                Get.snackbar(
                  'Error',
                  'Diagnosis and Treatment are required',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }

              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close modal

              controller.completeServiceWithRecord(
                appointment: appointment,
                diagnosis: diagnosisController.text,
                treatment: treatmentController.text,
                prescription: prescriptionController.text.isEmpty
                    ? null
                    : prescriptionController.text,
                vetNotes:
                    notesController.text.isEmpty ? null : notesController.text,
                totalCost: double.tryParse(costController.text),
                followUpInstructions: followUpController.text.isEmpty
                    ? null
                    : followUpController.text,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Complete Service',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(
      BuildContext context, EnhancedClinicAppointmentController controller) {
    final amountController = TextEditingController(
      text: appointment.totalCost?.toString() ?? '',
    );
    String selectedMethod = 'cash';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Process Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Amount (₱)',
                hintText: '500.00',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedMethod,
              decoration: const InputDecoration(
                labelText: 'Payment Method',
              ),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Cash')),
                DropdownMenuItem(value: 'card', child: Text('Card')),
                DropdownMenuItem(value: 'gcash', child: Text('GCash')),
              ],
              onChanged: (value) {
                selectedMethod = value!;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                Get.snackbar('Error', 'Please enter a valid amount');
                return;
              }

              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close modal

              controller.processPayment(appointment, amount, selectedMethod);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Process Payment',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _viewMedicalRecord(
      BuildContext context, EnhancedClinicAppointmentController controller) {
    Navigator.pop(context);
    Get.snackbar(
      'Info',
      'Navigation to medical records will be implemented',
      backgroundColor: Colors.teal,
      colorText: Colors.white,
    );
  }

  void _printMedicalRecord(BuildContext context) {
    Navigator.pop(context);
    Get.snackbar('Info', 'Medical record printing feature will be implemented');
  }

  // Helper methods
  List<Color> _getStatusGradient(String status) {
    switch (status) {
      case 'pending':
        return [Colors.orange, Colors.orange.shade300];
      case 'accepted':
        return [Colors.blue, Colors.blue.shade300];
      case 'in_progress':
        return [Colors.purple, Colors.purple.shade300];
      case 'completed':
        return [Colors.green, Colors.green.shade300];
      default:
        return [Colors.grey, Colors.grey.shade300];
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
      case 'no_show':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusDisplayText(String status) {
    switch (status) {
      case 'pending':
        return 'PENDING REVIEW';
      case 'accepted':
        return 'SCHEDULED';
      case 'in_progress':
        return 'IN PROGRESS';
      case 'completed':
        return 'COMPLETED';
      case 'no_show':
        return 'NO SHOW';
      default:
        return status.toUpperCase();
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }
}
