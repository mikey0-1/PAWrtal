import 'package:capstone_app/data/models/appointment_model.dart';
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/mobile/user/components/appointment_tabs/components/mobile_rating_dialog.dart';
import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/mobile/user/components/appointment_tabs/components/user_appointment_controller.dart';
import 'package:capstone_app/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class EnhancedAppointmentDetailsPage extends StatefulWidget {
  final Appointment appointment;
  final Clinic? clinic;
  final Pet? pet;

  const EnhancedAppointmentDetailsPage({
    super.key,
    required this.appointment,
    this.clinic,
    this.pet,
  });

  @override
  State<EnhancedAppointmentDetailsPage> createState() =>
      _EnhancedAppointmentDetailsPageState();
}

class _EnhancedAppointmentDetailsPageState
    extends State<EnhancedAppointmentDetailsPage> {
  bool _hasReviewed = false;
  bool _isLoadingReview = true;

  @override
  void initState() {
    super.initState();
    _checkIfReviewed();
  }

  Future<void> _checkIfReviewed() async {
    if (widget.appointment.documentId != null &&
        widget.appointment.status == 'completed') {
      final hasReview = await Get.find<AuthRepository>()
          .hasUserReviewedAppointment(widget.appointment.documentId!);
      setState(() {
        _hasReviewed = hasReview;
        _isLoadingReview = false;
      });
    } else {
      setState(() {
        _isLoadingReview = false;
      });
    }
  }

  Color _getStatusColor() {
    switch (widget.appointment.status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'declined':
      case 'no_show':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (widget.appointment.status.toLowerCase()) {
      case 'pending':
        return Icons.pending_actions;
      case 'accepted':
        return Icons.event_available;
      case 'in_progress':
        return Icons.medical_services;
      case 'completed':
        return Icons.check_circle;
      case 'declined':
        return Icons.cancel;
      case 'no_show':
        return Icons.person_off;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<EnhancedUserAppointmentController>();
    final statusColor = _getStatusColor();

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Header with gradient
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  statusColor.withOpacity(0.1),
                  statusColor.withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Title and close button
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.5),
                      ),
                    ),
                    const Text(
                      'Appointment Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(),
                            size: 16,
                            color: statusColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            controller
                                .getUserFriendlyStatus(widget.appointment),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Appointment Information
                  _buildSection("Appointment Information", [
                    _buildDetailRow(Icons.local_hospital, "Clinic",
                        widget.clinic?.clinicName ?? 'Unknown Clinic'),
                    _buildDetailRow(Icons.location_on, "Address",
                        widget.clinic?.address ?? 'Address not available'),
                    _buildDetailRow(Icons.medical_services, "Service",
                        widget.appointment.service),
                    _buildDetailRow(Icons.pets, "Pet",
                        widget.pet?.name ?? widget.appointment.petId),
                    if (widget.pet != null)
                      _buildDetailRow(Icons.category, "Pet Details",
                          '${widget.pet!.type} • ${widget.pet!.breed}'),
                    _buildDetailRow(
                        Icons.calendar_today,
                        "Date",
                        DateFormat('EEEE, MMMM dd, yyyy')
                            .format(widget.appointment.dateTime)),
                    _buildDetailRow(
                        Icons.access_time,
                        "Time",
                        DateFormat('hh:mm a')
                            .format(widget.appointment.dateTime)),
                  ]),

                  const SizedBox(height: 20),

                  // Booking Information
                  _buildSection("Booking Information", [
                    _buildDetailRow(
                        Icons.event,
                        "Booked on",
                        DateFormat('MMM dd, yyyy • h:mm a')
                            .format(widget.appointment.createdAt.toLocal())),
                    if (widget.appointment.updatedAt !=
                        widget.appointment.createdAt)
                      _buildDetailRow(
                          Icons.update,
                          "Last updated",
                          DateFormat('MMM dd, yyyy • h:mm a')
                              .format(widget.appointment.updatedAt.toLocal())),
                  ]),

                  // Service Progress
                  if (widget.appointment.hasArrived ||
                      widget.appointment.hasServiceStarted ||
                      widget.appointment.hasServiceCompleted) ...[
                    const SizedBox(height: 20),
                    _buildSection("Service Progress", [
                      if (widget.appointment.checkedInAt != null)
                        _buildDetailRow(
                            Icons.login,
                            "Checked In",
                            DateFormat('MMM dd, yyyy • h:mm a')
                                .format(widget.appointment.checkedInAt!)),
                      if (widget.appointment.serviceStartedAt != null)
                        _buildDetailRow(
                            Icons.play_arrow,
                            "Service Started",
                            DateFormat('MMM dd, yyyy • h:mm a')
                                .format(widget.appointment.serviceStartedAt!)),
                      if (widget.appointment.serviceCompletedAt != null)
                        _buildDetailRow(
                            Icons.check_circle,
                            "Service Completed",
                            DateFormat('MMM dd, yyyy • h:mm a').format(
                                widget.appointment.serviceCompletedAt!)),
                      if (widget.appointment.serviceDuration != null)
                        _buildDetailRow(Icons.timer, "Service Duration",
                            '${widget.appointment.serviceDuration!.inMinutes} minutes'),
                    ]),
                  ],

                  // Payment Information
                  if (widget.appointment.totalCost != null ||
                      widget.appointment.isPaid) ...[
                    const SizedBox(height: 20),
                    _buildSection("Payment Information", [
                      if (widget.appointment.totalCost != null)
                        _buildDetailRow(Icons.attach_money, "Total Cost",
                            '₱${widget.appointment.totalCost!.toStringAsFixed(2)}'),
                      _buildDetailRow(Icons.payment, "Payment Status",
                          widget.appointment.isPaid ? 'Paid' : 'Unpaid'),
                      if (widget.appointment.paymentMethod != null)
                        _buildDetailRow(Icons.credit_card, "Payment Method",
                            widget.appointment.paymentMethod!),
                    ]),
                  ],

                  // Follow-up
                  if (widget.appointment.followUpInstructions != null ||
                      widget.appointment.nextAppointmentDate != null) ...[
                    const SizedBox(height: 20),
                    _buildSection("Follow-up", [
                      if (widget.appointment.followUpInstructions != null)
                        _buildDetailRow(Icons.note, "Instructions",
                            widget.appointment.followUpInstructions!),
                      if (widget.appointment.nextAppointmentDate != null)
                        _buildDetailRow(
                            Icons.event_note,
                            "Next Appointment",
                            DateFormat('MMM dd, yyyy • h:mm a').format(
                                widget.appointment.nextAppointmentDate!)),
                    ]),
                  ],

                  // Notes
                  if (widget.appointment.notes != null &&
                      widget.appointment.notes!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildSection("Notes", [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          widget.appointment.notes!,
                          style: const TextStyle(fontSize: 14, height: 1.5),
                        ),
                      ),
                    ]),
                  ],

                  // Cancellation Details
                  if (widget.appointment.isCancelled ||
                      widget.appointment.isDeclined) ...[
                    const SizedBox(height: 20),
                    _buildSection("Cancellation Details", [
                      _buildDetailRow(
                          Icons.cancel,
                          "Cancelled By",
                          widget.appointment.isCancelledByUser
                              ? 'You'
                              : 'Clinic'),
                      if (widget.appointment.cancelledAt != null)
                        _buildDetailRow(
                            Icons.event,
                            "Cancelled On",
                            DateFormat('MMM dd, yyyy • h:mm a')
                                .format(widget.appointment.cancelledAt!)),
                      if (widget.appointment.cancellationReason != null)
                        _buildDetailRow(Icons.info, "Reason",
                            widget.appointment.cancellationReason!),
                    ]),
                  ],

                  const SizedBox(height: 30),

                  // Action Buttons
                  _buildActionButtons(controller),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 81, 115, 153).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: const Color.fromARGB(255, 81, 115, 153),
              size: 16,
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
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(EnhancedUserAppointmentController controller) {
    if (_isLoadingReview) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Rating & Review button
        if (widget.appointment.status == 'completed')
          SizedBox(
            width: double.infinity,
            child: _hasReviewed
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Rating & Review Submitted',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: () => _showRatingDialog(context),
                    icon: const Icon(Icons.rate_review),
                    label: const Text('Rate & Review'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade50,
                      foregroundColor: Colors.amber.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.amber.shade200),
                      ),
                    ),
                  ),
          ),

        if (widget.appointment.status == 'completed')
          const SizedBox(height: 12),

        // Cancel button
        if (controller.canCancelAppointment(widget.appointment))
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showCancelDialog(context, controller),
              icon: const Icon(Icons.cancel_outlined),
              label: Text(widget.appointment.status == 'pending'
                  ? 'Cancel Request'
                  : 'Cancel Appointment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.appointment.status == 'pending'
                    ? Colors.orange.shade50
                    : Colors.red.shade50,
                foregroundColor: widget.appointment.status == 'pending'
                    ? Colors.orange.shade700
                    : Colors.red.shade700,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: widget.appointment.status == 'pending'
                        ? Colors.orange.shade200
                        : Colors.red.shade200,
                  ),
                ),
              ),
            ),
          ),

        if (controller.canCancelAppointment(widget.appointment))
          const SizedBox(height: 12),
      ],
    );
  }

  void _showRatingDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => MobileRatingDialog(
        appointment: widget.appointment,
        clinic: widget.clinic,
        pet: widget.pet,
      ),
    );

    if (result == true) {
      setState(() {
        _hasReviewed = true;
      });
      Navigator.pop(context);
      Get.find<EnhancedUserAppointmentController>().fetchAppointments();
    }
  }

  void _showCancelDialog(
      BuildContext context, EnhancedUserAppointmentController controller) {
    if (!controller.canCancelAppointment(widget.appointment)) {
      SnackbarHelper.showError(
        context: Get.context!,
        title: "Cannot Cancel",
        message:
            "This appointment is less than 1 hour away and cannot be cancelled. Please contact the clinic directly.",
      );
      // Get.snackbar(
      //   "Cannot Cancel",
      //   "This appointment is less than 1 hour away and cannot be cancelled. Please contact the clinic directly.",
      //   snackPosition: SnackPosition.BOTTOM,
      //   backgroundColor: Colors.red.shade50,
      //   colorText: Colors.red.shade700,
      //   icon: const Icon(Icons.block, color: Colors.red),
      //   duration: const Duration(seconds: 4),
      // );
      return;
    }
    if (widget.appointment.status == 'pending') {
      _showPendingCancelDialog(context, controller);
      return;
    }

    _showAcceptedCancelDialog(context, controller);
  }

  void _showPendingCancelDialog(
      BuildContext context, EnhancedUserAppointmentController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.cancel_outlined,
                  color: Colors.orange, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Cancel Request',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to cancel this appointment request?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This appointment hasn\'t been confirmed yet. You can cancel it without any reason.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Request'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              controller
                  .cancelPendingAppointment(widget.appointment.documentId!);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text(
              'Cancel Request',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showAcceptedCancelDialog(
      BuildContext context, EnhancedUserAppointmentController controller) {
    if (!controller.canCancelAppointment(widget.appointment)) {
      SnackbarHelper.showError(
        context: Get.context!,
        title: "Cannot Cancel",
        message:
            "This appointment is less than 1 hour away and cannot be cancelled. Please contact the clinic directly.",
      );
      // Get.snackbar(
      //   "Cannot Cancel",
      //   "This appointment is less than 1 hour away and cannot be cancelled. Please contact the clinic directly.",
      //   snackPosition: SnackPosition.BOTTOM,
      //   backgroundColor: Colors.red.shade50,
      //   colorText: Colors.red.shade700,
      //   icon: const Icon(Icons.block, color: Colors.red),
      //   duration: const Duration(seconds: 4),
      // );
      return;
    }

    String selectedReason = '';
    final customReasonController = TextEditingController();

    final predefinedReasons = [
      'Schedule conflict',
      'Pet condition improved',
      'Found another clinic closer',
      'Financial constraints',
      'Transportation issues',
      'Emergency situation changed plans',
      'Other (specify below)',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.cancel,
                              color: Colors.red, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cancel Appointment',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'This appointment has been confirmed',
                                style:
                                    TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber,
                              color: Colors.orange.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'The clinic has already confirmed this appointment. Please provide a reason for cancellation.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.local_hospital,
                                  color: Colors.blue.shade600, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  controller.getClinicNameForAppointment(
                                      widget.appointment),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${widget.appointment.service} • ${controller.getPetNameForAppointment(widget.appointment)}',
                            style: TextStyle(
                                color: Colors.grey.shade700, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('EEEE, MMM dd, yyyy • h:mm a')
                                .format(widget.appointment.dateTime),
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Please select a reason for cancellation:',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...predefinedReasons.map((reason) {
                      return RadioListTile<String>(
                        title:
                            Text(reason, style: const TextStyle(fontSize: 13)),
                        value: reason,
                        groupValue: selectedReason,
                        onChanged: (value) {
                          setState(() {
                            selectedReason = value!;
                          });
                        },
                        activeColor: const Color.fromARGB(255, 81, 115, 153),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      );
                    }),
                    const SizedBox(height: 12),
                    TextField(
                      controller: customReasonController,
                      decoration: InputDecoration(
                        labelText: selectedReason == 'Other (specify below)'
                            ? 'Please specify your reason *'
                            : 'Additional details (optional)',
                        hintText: 'Enter additional information...',
                        border: const OutlineInputBorder(),
                        enabled: selectedReason.isNotEmpty,
                      ),
                      maxLines: 3,
                      maxLength: 200,
                    ),
                    const SizedBox(height: 8),
                    // Container(
                    //   padding: const EdgeInsets.all(10),
                    //   decoration: BoxDecoration(
                    //     color: Colors.blue.shade50,
                    //     borderRadius: BorderRadius.circular(8),
                    //   ),
                    //   child: Row(
                    //     children: [
                    //       Icon(Icons.info_outline,
                    //           color: Colors.blue.shade700, size: 14),
                    //       const SizedBox(width: 8),
                    //       Expanded(
                    //         child: Text(
                    //           'You can cancel up to 1 hour before your appointment time.',
                    //           style: TextStyle(
                    //             fontSize: 10,
                    //             color: Colors.blue.shade700,
                    //           ),
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Keep Appointment'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            if (selectedReason.isEmpty) {
                              Get.snackbar(
                                'Required Field',
                                'Please select a reason for cancellation',
                                backgroundColor: Colors.orange,
                                colorText: Colors.white,
                                snackPosition: SnackPosition.BOTTOM,
                              );
                              return;
                            }

                            if (selectedReason == 'Other (specify below)' &&
                                customReasonController.text.trim().isEmpty) {
                              Get.snackbar(
                                'Required Field',
                                'Please specify your reason for cancellation',
                                backgroundColor: Colors.orange,
                                colorText: Colors.white,
                                snackPosition: SnackPosition.BOTTOM,
                              );
                              return;
                            }

                            String finalReason = selectedReason;
                            if (customReasonController.text.trim().isNotEmpty) {
                              finalReason = selectedReason ==
                                      'Other (specify below)'
                                  ? customReasonController.text.trim()
                                  : '$selectedReason - ${customReasonController.text.trim()}';
                            }

                            Navigator.pop(context);
                            Navigator.pop(context);
                            controller.cancelAcceptedAppointment(
                              widget.appointment.documentId!,
                              finalReason,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
