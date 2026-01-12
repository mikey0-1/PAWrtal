import 'package:capstone_app/data/models/appointment_model.dart';
import 'package:capstone_app/data/models/medical_record_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/mobile/admin/controllers/enhanced_clinic_appointment_controller.dart';
import 'package:capstone_app/mobile/admin/pages/modals/appointment_workflow_modal.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class PatientWorkflowTile extends StatelessWidget {
  final Appointment appointment;
  final String
      workflowStage; // 'pending', 'scheduled', 'in_progress', 'completed'

  const PatientWorkflowTile({
    super.key,
    required this.appointment,
    required this.workflowStage,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<EnhancedClinicAppointmentController>();

    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 16, right: 16),
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => AppointmentWorkflowModal(
              appointment: appointment,
              workflowStage: workflowStage,
            ),
          );
        },
        child: Container(
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _getStatusBorderColor(appointment.status),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Main Info Row
                Row(
                  children: [
                    // Status Indicator & Avatar
                    Stack(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: LinearGradient(
                              colors: _getStatusGradient(appointment.status),
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(
                            Icons.pets,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        // Status dot
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: _getStatusColor(appointment.status),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),

                    // Appointment Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Pet Name & Owner
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  controller.getPetName(appointment.petId),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 81, 115, 153),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(appointment.status)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getStatusDisplayText(appointment.status),
                                  style: TextStyle(
                                    color: _getStatusColor(appointment.status),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Owner name
                          Text(
                            'Owner: ${controller.getOwnerName(appointment.userId)}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 2),

                          // Time & Service
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('MMM dd • hh:mm a')
                                    .format(appointment.dateTime),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.medical_services,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  appointment.service,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Progress Indicators
                          _buildProgressIndicators(appointment),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Action Buttons Based on Status
                _buildActionButtons(context, controller, appointment),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicators(Appointment appointment) {
    return Row(
      children: [
        _buildProgressDot(
            'Scheduled', appointment.status != 'pending', Colors.blue),
        _buildProgressLine(appointment.hasArrived),
        _buildProgressDot('Arrived', appointment.hasArrived, Colors.orange),
        _buildProgressLine(appointment.hasServiceStarted),
        _buildProgressDot(
            'Treatment', appointment.hasServiceStarted, Colors.purple),
        _buildProgressLine(appointment.hasServiceCompleted),
        _buildProgressDot(
            'Complete', appointment.hasServiceCompleted, Colors.green),
      ],
    );
  }

  Widget _buildProgressDot(String label, bool isActive, Color color) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isActive ? color : Colors.grey[300],
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            color: isActive ? color : Colors.grey[400],
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 16),
        color: isActive ? Colors.green : Colors.grey[300],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context,
      EnhancedClinicAppointmentController controller, Appointment appointment) {
    switch (appointment.status) {
      case 'pending':
        return Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Decline',
                Icons.close,
                Colors.red,
                () => _showConfirmDialog(
                  context,
                  'Decline Appointment',
                  'Are you sure you want to decline this appointment?',
                  () => controller.declineAppointment(appointment),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: _buildActionButton(
                'Accept',
                Icons.check,
                Colors.green,
                () => _showConfirmDialog(
                  context,
                  'Accept Appointment',
                  'Accept this appointment for ${controller.getPetName(appointment.petId)}?',
                  () => controller.acceptAppointment(appointment),
                ),
              ),
            ),
          ],
        );

      case 'accepted':
        return Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'No Show',
                Icons.person_off,
                Colors.orange,
                () => controller.markNoShow(appointment),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: _buildActionButton(
                'Check In Patient',
                Icons.login,
                Colors.blue,
                () => controller.checkInPatient(appointment),
              ),
            ),
          ],
        );

      case 'in_progress':
        return Row(
          children: [
            if (!appointment.hasServiceStarted)
              Expanded(
                child: _buildActionButton(
                  'Start Service',
                  Icons.play_arrow,
                  Colors.purple,
                  () => controller.startService(appointment),
                ),
              ),
            if (appointment.hasServiceStarted) ...[
              Expanded(
                child: _buildActionButton(
                  'Add Vitals',
                  Icons.favorite,
                  Colors.red,
                  () => _showVitalsDialog(context, controller, appointment),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _buildActionButton(
                  'Complete Service',
                  Icons.check_circle,
                  Colors.green,
                  () => _showCompleteServiceDialog(
                      context, controller, appointment),
                ),
              ),
            ],
          ],
        );

      case 'completed':
        return Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'View Record',
                Icons.medical_information,
                Colors.teal,
                () => _showMedicalRecordDialog(context, appointment),
              ),
            ),
            const SizedBox(width: 8),
            if (!appointment.isPaid)
              Expanded(
                child: _buildActionButton(
                  'Process Payment',
                  Icons.payment,
                  Colors.green,
                  () => _showPaymentDialog(context, controller, appointment),
                ),
              ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildActionButton(
      String text, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Dialog Methods
  void _showConfirmDialog(BuildContext context, String title, String content,
      VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _showVitalsDialog(BuildContext context,
      EnhancedClinicAppointmentController controller, Appointment appointment) {
    final tempController = TextEditingController();
    final weightController = TextEditingController();
    final bpController = TextEditingController();
    final hrController = TextEditingController();
    final notesController = TextEditingController();

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
                decoration:
                    const InputDecoration(labelText: 'Temperature (°C)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: weightController,
                decoration: const InputDecoration(labelText: 'Weight (kg)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: bpController,
                decoration: const InputDecoration(labelText: 'Blood Pressure'),
              ),
              TextField(
                controller: hrController,
                decoration:
                    const InputDecoration(labelText: 'Heart Rate (bpm)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: notesController,
                decoration:
                    const InputDecoration(labelText: 'Additional Notes'),
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
              if (tempController.text.isNotEmpty &&
                  weightController.text.isNotEmpty) {
                // Store vitals temporarily or update appointment with vitals note
                // You'll need to add this method to your controller
                Navigator.pop(context);
                Get.snackbar(
                  'Vitals Recorded',
                  'Vital signs have been recorded',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showCompleteServiceDialog(BuildContext context,
      EnhancedClinicAppointmentController controller, Appointment appointment) {
    final diagnosisController = TextEditingController();
    final treatmentController = TextEditingController();
    final prescriptionController = TextEditingController();
    final notesController = TextEditingController();
    final costController = TextEditingController();
    final followUpController = TextEditingController();

    // Vitals controllers
    final tempController = TextEditingController();
    final weightController = TextEditingController();
    final bpController = TextEditingController();
    final hrController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Service'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Medical Record Fields
                const Text(
                  'Medical Information',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: diagnosisController,
                  decoration: const InputDecoration(
                    labelText: 'Diagnosis *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: treatmentController,
                  decoration: const InputDecoration(
                    labelText: 'Treatment *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: prescriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Prescription',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Medical Notes',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),

                const SizedBox(height: 16),
                const Divider(),

                // Vitals Section
                const Text(
                  'Vital Signs (Optional)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: tempController,
                        decoration: const InputDecoration(
                          labelText: 'Temperature (°C)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: weightController,
                        decoration: const InputDecoration(
                          labelText: 'Weight (kg)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: bpController,
                        decoration: const InputDecoration(
                          labelText: 'Blood Pressure',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: hrController,
                        decoration: const InputDecoration(
                          labelText: 'Heart Rate (bpm)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(),

                // Appointment Details Section
                const Text(
                  'Appointment Details',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: costController,
                  decoration: const InputDecoration(
                    labelText: 'Total Cost (₱)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: followUpController,
                  decoration: const InputDecoration(
                    labelText: 'Follow-up Instructions',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
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
                  'Required Fields',
                  'Please fill in diagnosis and treatment',
                  backgroundColor: Colors.orange,
                  colorText: Colors.white,
                );
                return;
              }

              // Parse vitals
              final temperature = tempController.text.isNotEmpty
                  ? double.tryParse(tempController.text)
                  : null;
              final weight = weightController.text.isNotEmpty
                  ? double.tryParse(weightController.text)
                  : null;
              final bloodPressure =
                  bpController.text.isNotEmpty ? bpController.text : null;
              final heartRate = hrController.text.isNotEmpty
                  ? int.tryParse(hrController.text)
                  : null;

              // Parse cost
              final totalCost = costController.text.isNotEmpty
                  ? double.tryParse(costController.text)
                  : null;

              // Build vitals map for completeServiceWithRecord
              final Map<String, dynamic>? vitals = (temperature != null ||
                      weight != null ||
                      bloodPressure != null ||
                      heartRate != null)
                  ? {
                      if (temperature != null) 'temperature': temperature,
                      if (weight != null) 'weight': weight,
                      if (bloodPressure != null) 'bloodPressure': bloodPressure,
                      if (heartRate != null) 'heartRate': heartRate,
                    }
                  : null;

              controller.completeServiceWithRecord(
                appointment: appointment,
                diagnosis: diagnosisController.text,
                treatment: treatmentController.text,
                prescription: prescriptionController.text.isNotEmpty
                    ? prescriptionController.text
                    : null,
                vetNotes: notesController.text.isNotEmpty
                    ? notesController.text
                    : null,
                vitals: vitals,
                totalCost: totalCost,
                followUpInstructions: followUpController.text.isNotEmpty
                    ? followUpController.text
                    : null,
              );

              Navigator.pop(context);
            },
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  void _showMedicalRecordDialog(BuildContext context, Appointment appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Medical Record'),
        content: FutureBuilder(
          // Fetch from repository instead of controller
          future: Get.find<AuthRepository>()
              .getPetMedicalRecords(appointment.petId),
          builder: (context, AsyncSnapshot<List<MedicalRecord>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (!snapshot.hasData ||
                snapshot.data == null ||
                snapshot.data!.isEmpty) {
              return const Text(
                  'No medical record found for this appointment.');
            }

            // Find the record for this specific appointment
            final record = snapshot.data!.firstWhere(
              (r) => r.appointmentId == appointment.documentId,
              orElse: () => snapshot.data!.first, // Fallback to first record
            );

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildRecordField('Service', record.service),
                  const SizedBox(height: 8),
                  _buildRecordField('Date',
                      DateFormat('MMM dd, yyyy').format(record.visitDate)),
                  const SizedBox(height: 8),
                  _buildRecordField('Diagnosis', record.diagnosis),
                  const SizedBox(height: 8),
                  _buildRecordField('Treatment', record.treatment),
                  const SizedBox(height: 8),

                  if (record.prescription != null &&
                      record.prescription!.isNotEmpty) ...[
                    _buildRecordField('Prescription', record.prescription!),
                    const SizedBox(height: 8),
                  ],

                  if (record.notes != null && record.notes!.isNotEmpty) ...[
                    _buildRecordField('Medical Notes', record.notes!),
                    const SizedBox(height: 8),
                  ],

                  // Display individual vitals
                  if (record.hasVitals) ...[
                    const Text(
                      'Vital Signs:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    if (record.temperature != null)
                      Text(
                          'Temperature: ${record.temperature!.toStringAsFixed(1)}°C'),
                    if (record.weight != null)
                      Text('Weight: ${record.weight!.toStringAsFixed(2)} kg'),
                    if (record.bloodPressure != null)
                      Text('Blood Pressure: ${record.bloodPressure}'),
                    if (record.heartRate != null)
                      Text('Heart Rate: ${record.heartRate} bpm'),
                    const SizedBox(height: 8),
                  ],

                  const Divider(),
                  const SizedBox(height: 8),

                  // Display appointment details
                  const Text(
                    'Appointment Details:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                      'Date: ${DateFormat('MMM dd, yyyy • h:mm a').format(appointment.dateTime)}'),

                  if (appointment.totalCost != null)
                    Text('Cost: ₱${appointment.totalCost!.toStringAsFixed(2)}'),

                  Text(
                      'Payment Status: ${appointment.isPaid ? "Paid" : "Unpaid"}'),

                  if (appointment.paymentMethod != null)
                    Text('Payment Method: ${appointment.paymentMethod}'),

                  if (appointment.followUpInstructions != null &&
                      appointment.followUpInstructions!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildRecordField('Follow-up Instructions',
                        appointment.followUpInstructions!),
                  ],
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Helper widget for record fields
  Widget _buildRecordField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  void _showPaymentDialog(BuildContext context,
      EnhancedClinicAppointmentController controller, Appointment appointment) {
    final amountController =
        TextEditingController(text: appointment.totalCost?.toString() ?? '');
    String paymentMethod = 'cash';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Process Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Amount (₱)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: paymentMethod,
              decoration: const InputDecoration(labelText: 'Payment Method'),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Cash')),
                DropdownMenuItem(value: 'card', child: Text('Card')),
                DropdownMenuItem(value: 'gcash', child: Text('GCash')),
              ],
              onChanged: (value) => paymentMethod = value!,
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
              if (amountController.text.isNotEmpty) {
                controller.processPayment(
                  appointment,
                  double.parse(amountController.text),
                  paymentMethod,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Process'),
          ),
        ],
      ),
    );
  }

  // Helper Methods
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

  Color _getStatusBorderColor(String status) {
    return _getStatusColor(status).withOpacity(0.3);
  }

  String _getStatusDisplayText(String status) {
    switch (status) {
      case 'pending':
        return 'PENDING';
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
}
