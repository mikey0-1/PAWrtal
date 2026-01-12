import 'package:capstone_app/data/models/appointment_model.dart';
import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/web/admin_web/components/appointments/admin_pet_card_view.dart';
import 'package:capstone_app/web/admin_web/components/appointments/admin_web_appointment_controller.dart';
import 'package:capstone_app/web/admin_web/components/appointments/web_appointment_modal.dart';
import 'package:capstone_app/web/admin_web/components/appointments/web_non_medical_appointment_modal.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:capstone_app/web/admin_web/components/appointments/dialogs/vaccination_completion_dialog.dart';

class WebAppointmentTile extends StatelessWidget {
  final Appointment appointment;
  final bool isSelected;

  const WebAppointmentTile({
    super.key,
    required this.appointment,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WebAppointmentController>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      margin: EdgeInsets.only(
        bottom: isMobile ? 8 : 12,
        left: isMobile ? 8 : 16,
        right: isMobile ? 8 : 16,
      ),
      child: InkWell(
        onTap: () => _showAppointmentDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color.fromARGB(255, 81, 115, 153)
                  : _getStatusBorderColor(appointment.status),
              width: isSelected ? 2 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: isMobile
              ? _buildMobileLayout(controller)
              : _buildDesktopLayout(controller),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(WebAppointmentController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildPetAvatar(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pet name with View Card button
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          controller.getPetName(appointment.petId),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 81, 115, 153),
                          ),
                        ),
                      ),
                      // View Pet Card button
                      IconButton(
                        onPressed: () => _showPetCardView(controller),
                        icon: const Icon(Icons.credit_card),
                        iconSize: 18,
                        color: const Color(0xFF3498DB),
                        tooltip: 'View Pet Card',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    controller.getOwnerName(appointment.userId),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            _buildStatusBadge(),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              DateFormat('MMM dd • hh:mm a').format(appointment.dateTime),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(width: 12),
            Icon(Icons.medical_services, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                appointment.service,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildProgressIndicator(),
        const SizedBox(height: 12),
        _buildActionButtons(controller, isMobile: true),
      ],
    );
  }

  Widget _buildDesktopLayout(WebAppointmentController controller) {
    return Row(
      children: [
        _buildPetAvatar(),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
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
                        const SizedBox(width: 8),
                        // View Pet Card button
                        Tooltip(
                          message: 'View Pet Card',
                          child: InkWell(
                            onTap: () => _showPetCardView(controller),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3498DB).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.credit_card,
                                size: 18,
                                color: Color(0xFF3498DB),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Owner: ${controller.getOwnerName(appointment.userId)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${controller.getPetType(appointment.petId)} • ${controller.getPetBreed(appointment.petId)}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      DateFormat('MMM dd, yyyy').format(appointment.dateTime),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('hh:mm a').format(appointment.dateTime),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.medical_services,
                      size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      appointment.service,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _buildProgressIndicator(),
              const SizedBox(height: 12),
              _buildActionButtons(controller),
            ],
          ),
        ),
        _buildServiceTypeIndicator(), // NEW: Add this
        const SizedBox(width: 8),
        _buildStatusBadge(),
      ],
    );
  }

  // NEW METHOD: Show Pet Card View Dialog
  void _showPetCardView(WebAppointmentController controller) async {
    // Show loading indicator
    Get.dialog(
      const Center(
        child: CircularProgressIndicator(),
      ),
      barrierDismissible: false,
    );

    try {
      Pet? pet;
      String? clinicId;

      // NEW

      // Get clinic ID from appointment
      clinicId = appointment.clinicId;

      // Try fetching by userId to get all user's pets
      final userPets =
          await controller.authRepository.getUserPets(appointment.userId);


      // Find the pet by matching petId, name, or document ID
      final petDoc = userPets.firstWhereOrNull(
        (doc) =>
            doc.data['petId'] == appointment.petId ||
            doc.data['name'] == appointment.petId ||
            doc.$id == appointment.petId,
      );

      if (petDoc != null) {
        pet = Pet.fromMap(petDoc.data);
        pet.documentId = petDoc.$id;
      }

      // Close loading indicator
      Get.back();

      if (pet == null) {
        Get.snackbar(
          'Error',
          'Could not load pet information. Pet ID: ${appointment.petId}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        return;
      }

      if (clinicId == null || clinicId.isEmpty) {
        Get.snackbar(
          'Error',
          'Clinic information not available for this appointment',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        return;
      }

      // Show the AdminPetCardView dialog with clinicId
      showDialog(
        context: Get.context!,
        builder: (context) => AdminPetCardView(
          pet: pet!,
          clinicId: clinicId!, // PASS CLINIC ID
        ),
      );
    } catch (e) {
      // Close loading indicator if still open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      Get.snackbar(
        'Error',
        'Failed to load pet information: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Widget _buildPetAvatar() {
    final controller = Get.find<WebAppointmentController>();

    // CRITICAL: Use composite key (userId + petId) to avoid conflicts
    final cacheKey = '${appointment.userId}_${appointment.petId}';

    // Check cache FIRST before building FutureBuilder
    if (controller.petProfilePictures.containsKey(cacheKey)) {
      final cachedImageUrl = controller.petProfilePictures[cacheKey];

      if (cachedImageUrl != null && cachedImageUrl.isNotEmpty) {
        // Show cached image
        return Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: _getStatusBorderColor(appointment.status),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Image.network(
              cachedImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildPetAvatarFallback();
              },
            ),
          ),
        );
      } else {
        // Cached as null - show fallback immediately
        return _buildPetAvatarFallback();
      }
    }

    // Not cached yet - fetch once
    return FutureBuilder<String?>(
      future: controller.getPetImageByUserId(
        appointment.petId,
        appointment.userId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              color: Colors.grey[200],
            ),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getStatusBorderColor(appointment.status),
                  ),
                ),
              ),
            ),
          );
        }

        final profilePictureUrl = snapshot.data;

        if (profilePictureUrl != null && profilePictureUrl.isNotEmpty) {
          return Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: _getStatusBorderColor(appointment.status),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Image.network(
                profilePictureUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPetAvatarFallback();
                },
              ),
            ),
          );
        }

        return _buildPetAvatarFallback();
      },
    );
  }

  // 🆕 Helper method for fallback avatar
  Widget _buildPetAvatarFallback() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: LinearGradient(
          colors: _getStatusGradient(appointment.status),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(Icons.pets, color: Colors.white, size: 24),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(appointment.status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(appointment.status).withOpacity(0.3),
        ),
      ),
      child: Text(
        _getStatusDisplayText(appointment.status),
        style: TextStyle(
          color: _getStatusColor(appointment.status),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildProgressDot(appointment.status != 'pending', Colors.blue),
        _buildProgressLine(appointment.hasArrived),
        _buildProgressDot(appointment.hasArrived, Colors.orange),
        _buildProgressLine(appointment.hasServiceStarted),
        _buildProgressDot(appointment.hasServiceStarted, Colors.purple),
        _buildProgressLine(appointment.hasServiceCompleted),
        _buildProgressDot(appointment.hasServiceCompleted, Colors.green),
      ],
    );
  }

  Widget _buildProgressDot(bool isActive, Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? color : Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildProgressLine(bool isActive) {
    return Container(
      width: 16,
      height: 2,
      color: isActive ? Colors.green : Colors.grey[300],
    );
  }

  Widget _buildActionButtons(WebAppointmentController controller,
      {bool isMobile = false}) {
    final buttonHeight = isMobile ? 32.0 : 36.0;
    final fontSize = isMobile ? 11.0 : 12.0;

    final isPastAccepted =
        appointment.isPast && appointment.status == 'accepted';

    if (isPastAccepted) {
      return FutureBuilder<bool>(
        future: controller.isCurrentStaffDoctor(),
        builder: (context, snapshot) {
          final isDoctor = snapshot.data ?? true; // Default to true for admins
          final canCompleteMedical = isDoctor || !appointment.isMedicalService;

          return Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: buttonHeight,
                  child: OutlinedButton(
                    onPressed: () => controller.confirmMarkNoShow(appointment),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Text('Mark No Show',
                        style: TextStyle(fontSize: fontSize)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: buttonHeight,
                  child: ElevatedButton(
                    onPressed: canCompleteMedical
                        ? () => _showCompleteServiceDialog(controller)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          canCompleteMedical ? Colors.green : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child:
                        Text('Complete', style: TextStyle(fontSize: fontSize)),
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

    switch (appointment.status) {
      case 'pending':
        return Row(
          children: [
            Expanded(
              child: SizedBox(
                height: buttonHeight,
                child: OutlinedButton(
                  onPressed: () => _showDeclineDialog(controller),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text('Decline', style: TextStyle(fontSize: fontSize)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: buttonHeight,
                child: ElevatedButton(
                  onPressed: () =>
                      controller.confirmAcceptAppointment(appointment),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text('Accept', style: TextStyle(fontSize: fontSize)),
                ),
              ),
            ),
          ],
        );

      case 'accepted':
        if (!appointment.isToday) {
          return SizedBox(
            height: buttonHeight,
            child: OutlinedButton(
              onPressed: () => _showAppointmentDetails(Get.context!),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                side: const BorderSide(color: Colors.blue),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text('View Details', style: TextStyle(fontSize: fontSize)),
            ),
          );
        }

        return Row(
          children: [
            Expanded(
              child: SizedBox(
                height: buttonHeight,
                child: OutlinedButton(
                  onPressed: () => controller.confirmMarkNoShow(appointment),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text('No Show', style: TextStyle(fontSize: fontSize)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: buttonHeight,
                child: ElevatedButton(
                  onPressed: () =>
                      controller.confirmCheckInPatient(appointment),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text('Check In', style: TextStyle(fontSize: fontSize)),
                ),
              ),
            ),
          ],
        );

      case 'in_progress':
        return FutureBuilder<bool>(
          future: controller.isCurrentStaffDoctor(),
          builder: (context, snapshot) {
            final isDoctor = snapshot.data ?? true;
            final canCompleteMedical =
                isDoctor || !appointment.isMedicalService;
            final isVaccination =
                controller.isVaccinationService(appointment.service);

            return Row(
              children: [
                if (!appointment.hasServiceStarted)
                  Expanded(
                    child: SizedBox(
                      height: buttonHeight,
                      child: ElevatedButton(
                        onPressed: () =>
                            controller.confirmStartService(appointment),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child:
                            Text('Start', style: TextStyle(fontSize: fontSize)),
                      ),
                    ),
                  ),
                if (appointment.hasServiceStarted) ...[
                  // Only show Vitals button for medical services AND doctors
                  if (!isVaccination &&
                      appointment.isMedicalService &&
                      canCompleteMedical) ...[
                    Expanded(
                      child: SizedBox(
                        height: buttonHeight,
                        child: OutlinedButton(
                          onPressed: () => _showVitalsDialog(controller),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: Text('Vitals',
                              style: TextStyle(fontSize: fontSize)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    flex: (isVaccination || !appointment.isMedicalService)
                        ? 1
                        : 2,
                    child: SizedBox(
                      height: buttonHeight,
                      child: ElevatedButton(
                        onPressed: canCompleteMedical
                            ? () => _showCompleteServiceDialog(controller)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              canCompleteMedical ? Colors.green : Colors.grey,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: Text('Complete',
                            style: TextStyle(fontSize: fontSize)),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        );

      default:
        return SizedBox(
          height: buttonHeight,
          child: OutlinedButton(
            onPressed: () => _showAppointmentDetails(Get.context!),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey,
              side: const BorderSide(color: Colors.grey),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text('View', style: TextStyle(fontSize: fontSize)),
          ),
        );
    }
  }

  void _showAppointmentDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => WebAppointmentModal(appointment: appointment),
    );
  }

  void _showDeclineDialog(WebAppointmentController controller) {
    String selectedReason = '';
    final customReasonController = TextEditingController();
    bool hasChanges = false; // Track if user made changes

    final predefinedReasons = [
      'Time slot already booked',
      'Clinic at full capacity',
      'Service not available',
      'Emergency override needed',
      'Insufficient information provided',
      'Other (specify below)',
    ];

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: StatefulBuilder(
            builder: (context, setState) {
              return WillPopScope(
                onWillPop: () async {
                  if (hasChanges) {
                    return await _showDiscardChangesDialog(context);
                  }
                  return true;
                },
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
                          child: Text(
                            'Decline Appointment',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Please select or provide a reason for declining:',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 16),
                    ...predefinedReasons.map((reason) {
                      return RadioListTile<String>(
                        title:
                            Text(reason, style: const TextStyle(fontSize: 14)),
                        value: reason,
                        groupValue: selectedReason,
                        onChanged: (value) {
                          setState(() {
                            selectedReason = value!;
                            hasChanges = true;
                          });
                        },
                        activeColor: const Color.fromARGB(255, 81, 115, 153),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      );
                    }),
                    const SizedBox(height: 16),
                    TextField(
                      controller: customReasonController,
                      decoration: InputDecoration(
                        labelText: 'Custom reason (optional)',
                        hintText: 'Enter additional details...',
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      maxLength: 200,
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          hasChanges = true;
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            if (hasChanges) {
                              _showDiscardChangesDialog(context)
                                  .then((discard) {
                                if (discard == true) {
                                  customReasonController.dispose();
                                  Get.back();
                                }
                              });
                            } else {
                              customReasonController.dispose();
                              Get.back();
                            }
                          },
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: selectedReason.isEmpty
                              ? null
                              : () {
                                  String finalReason = selectedReason;
                                  if (customReasonController.text.isNotEmpty) {
                                    finalReason = selectedReason ==
                                            'Other (specify below)'
                                        ? customReasonController.text
                                        : '$selectedReason - ${customReasonController.text}';
                                  }

                                  customReasonController.dispose();
                                  Get.back();
                                  controller.declineAppointment(
                                      appointment, finalReason);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Decline Appointment',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showVitalsDialog(WebAppointmentController controller) {
    // Create a local BuildContext reference
    final currentContext = Get.context;
    if (currentContext == null) {
      return;
    }

    // Controllers - will be disposed in the finally block
    final tempController = TextEditingController();
    final weightController = TextEditingController();
    final bpController = TextEditingController();
    final hrController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    bool isDialogMounted = true;
    bool hasChanges = false; // Track if user made changes

    // Pre-fill with pending vitals if they exist
    try {
      final pendingVitals =
          controller.getPendingVitals(appointment.documentId!);
      if (pendingVitals != null) {
        if (pendingVitals['temperature'] != null) {
          tempController.text = pendingVitals['temperature'].toString();
        }
        if (pendingVitals['weight'] != null) {
          weightController.text = pendingVitals['weight'].toString();
        }
        if (pendingVitals['bloodPressure'] != null) {
          bpController.text = pendingVitals['bloodPressure'].toString();
        }
        if (pendingVitals['heartRate'] != null) {
          hrController.text = pendingVitals['heartRate'].toString();
        }
      }
    } catch (e) {
    }

    // Add listeners to track changes
    tempController.addListener(() {
      hasChanges = true;
    });
    weightController.addListener(() {
      hasChanges = true;
    });
    bpController.addListener(() {
      hasChanges = true;
    });
    hrController.addListener(() {
      hasChanges = true;
    });

    // Validation functions
    String? validateTemperature(String? value) {
      if (value == null || value.isEmpty) return null;
      final temp = double.tryParse(value);
      if (temp == null) return 'Enter a valid number';
      if (temp < 0 || temp > 50) return 'Temperature must be 0-50°C';
      return null;
    }

    String? validateWeight(String? value) {
      if (value == null || value.isEmpty) return null;
      final weight = double.tryParse(value);
      if (weight == null) return 'Enter a valid number';
      if (weight < 0 || weight > 500) return 'Weight must be 0-500kg';
      return null;
    }

    String? validateHeartRate(String? value) {
      if (value == null || value.isEmpty) return null;
      final hr = int.tryParse(value);
      if (hr == null) return 'Enter a valid whole number';
      if (hr < 0 || hr > 300) return 'Heart rate must be 0-300 bpm';
      return null;
    }

    String? validateBloodPressure(String? value) {
      if (value == null || value.isEmpty) return null;
      final bpPattern = RegExp(r'^\d{2,3}\/\d{2,3}$');
      if (!bpPattern.hasMatch(value)) return 'Format: 120/80';
      return null;
    }

    bool hasVitalData() {
      return tempController.text.isNotEmpty ||
          weightController.text.isNotEmpty ||
          bpController.text.isNotEmpty ||
          hrController.text.isNotEmpty;
    }

    void safeDispose() {
      try {
        if (!tempController.hasListeners) tempController.dispose();
        if (!weightController.hasListeners) weightController.dispose();
        if (!bpController.hasListeners) bpController.dispose();
        if (!hrController.hasListeners) hrController.dispose();
      } catch (e) {
      }
    }

    // CRITICAL FIX: Use Navigator.of(context).push instead of showDialog
    // This prevents the TextEditingController disposal error
    Navigator.of(currentContext)
        .push(
      DialogRoute(
        context: currentContext,
        builder: (BuildContext dialogContext) {
          return WillPopScope(
            onWillPop: () async {
              // If user has made changes, show confirmation dialog
              if (hasChanges && hasVitalData()) {
                final shouldDiscard =
                    await _showDiscardVitalsDialog(dialogContext);
                if (shouldDiscard == true) {
                  isDialogMounted = false;
                  safeDispose();
                  return true;
                }
                return false; // Don't close if user cancels
              }
              // No changes, close normally
              isDialogMounted = false;
              safeDispose();
              return true;
            },
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: 500,
                constraints: const BoxConstraints(maxHeight: 700),
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.favorite,
                                color: Colors.red,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Record Vital Signs',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 81, 115, 153),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                // Check for unsaved changes before closing
                                if (hasChanges && hasVitalData()) {
                                  final shouldDiscard =
                                      await _showDiscardVitalsDialog(
                                          dialogContext);
                                  if (shouldDiscard == true) {
                                    isDialogMounted = false;
                                    Navigator.of(dialogContext).pop();
                                    safeDispose();
                                  }
                                } else {
                                  isDialogMounted = false;
                                  Navigator.of(dialogContext).pop();
                                  safeDispose();
                                }
                              },
                              icon: const Icon(Icons.close),
                              tooltip: 'Close',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Colors.blue[700], size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Vitals will be saved when you complete the service.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Temperature and Weight
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: tempController,
                                decoration: InputDecoration(
                                  labelText: 'Temperature (°C)',
                                  border: const OutlineInputBorder(),
                                  hintText: '36.0 - 40.0',
                                  helperText: 'Range: 0-50°C',
                                  helperStyle: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                validator: validateTemperature,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: weightController,
                                decoration: InputDecoration(
                                  labelText: 'Weight (kg)',
                                  border: const OutlineInputBorder(),
                                  hintText: '5.0 - 50.0',
                                  helperText: 'Range: 0-500kg',
                                  helperStyle: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                validator: validateWeight,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Blood Pressure and Heart Rate
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: bpController,
                                decoration: InputDecoration(
                                  labelText: 'Blood Pressure',
                                  border: const OutlineInputBorder(),
                                  hintText: '120/80',
                                  helperText: 'Format: 120/80',
                                  helperStyle: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                validator: validateBloodPressure,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: hrController,
                                decoration: InputDecoration(
                                  labelText: 'Heart Rate (bpm)',
                                  border: const OutlineInputBorder(),
                                  hintText: '60 - 100',
                                  helperText: 'Range: 0-300 bpm',
                                  helperStyle: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                validator: validateHeartRate,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () async {
                                // Check for unsaved changes before canceling
                                if (hasChanges && hasVitalData()) {
                                  final shouldDiscard =
                                      await _showDiscardVitalsDialog(
                                          dialogContext);
                                  if (shouldDiscard == true) {
                                    isDialogMounted = false;
                                    Navigator.of(dialogContext).pop();
                                    safeDispose();
                                  }
                                } else {
                                  isDialogMounted = false;
                                  Navigator.of(dialogContext).pop();
                                  safeDispose();
                                }
                              },
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: () {
                                // Validate form
                                if (formKey.currentState?.validate() != true) {
                                  ScaffoldMessenger.of(dialogContext)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please fix the errors before recording vitals',
                                      ),
                                      backgroundColor: Colors.orange,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  return;
                                }

                                // Check that at least one field is filled
                                if (!hasVitalData()) {
                                  ScaffoldMessenger.of(dialogContext)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please enter at least one vital sign',
                                      ),
                                      backgroundColor: Colors.orange,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  return;
                                }

                                // Build vitals map
                                final vitals = <String, dynamic>{};

                                if (tempController.text.isNotEmpty) {
                                  vitals['temperature'] =
                                      double.parse(tempController.text);
                                }
                                if (weightController.text.isNotEmpty) {
                                  vitals['weight'] =
                                      double.parse(weightController.text);
                                }
                                if (bpController.text.isNotEmpty) {
                                  vitals['bloodPressure'] = bpController.text;
                                }
                                if (hrController.text.isNotEmpty) {
                                  vitals['heartRate'] =
                                      int.parse(hrController.text);
                                }
                                vitals['recordedAt'] =
                                    DateTime.now().toIso8601String();

                                // CRITICAL: Close dialog FIRST
                                isDialogMounted = false;
                                Navigator.of(dialogContext).pop();

                                // Dispose controllers immediately after closing
                                safeDispose();

                                // Store vitals AFTER dialog is closed and controllers disposed
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  try {
                                    if (Get.isRegistered<
                                        WebAppointmentController>()) {
                                      controller.recordVitalsLocally(
                                        appointment,
                                        vitals,
                                      );
                                    }
                                  } catch (e) {
                                  }
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 81, 115, 153),
                              ),
                              child: const Text(
                                'Record Vitals',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    )
        .then((_) {
      // Ensure controllers are disposed when dialog is dismissed
      if (isDialogMounted) {
        isDialogMounted = false;
        safeDispose();
      }
    });
  }

  Future<bool?> _showDiscardVitalsDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Colors.orange[700], size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Discard Vitals?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'You have unsaved vital signs data. If you close now, this information will be lost.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.orange[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Vitals will only be saved when you complete the service.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
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
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(
                'Keep Editing',
                style: TextStyle(
                  color: Color.fromARGB(255, 81, 115, 153),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text(
                'Discard Changes',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

// Helper widget to build vital info rows in the discard dialog
  // Widget _buildVitalInfoRow(String label, String value) {
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 6),
  //     child: Row(
  //       children: [
  //         Icon(Icons.check_circle, size: 14, color: Colors.orange[700]),
  //         const SizedBox(width: 8),
  //         Text(
  //           '$label: ',
  //           style: const TextStyle(
  //             fontSize: 13,
  //             fontWeight: FontWeight.w600,
  //           ),
  //         ),
  //         Text(
  //           value,
  //           style: const TextStyle(
  //             fontSize: 13,
  //             fontWeight: FontWeight.normal,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  void _showCompleteServiceDialog(WebAppointmentController controller) async {
    // Check if vaccination service FIRST
    if (controller.isVaccinationService(appointment.service)) {
      Get.dialog(
        VaccinationCompletionDialog(appointment: appointment),
        barrierDismissible: false,
      );
      return;
    }

    // Check if non-medical service
    if (!appointment.isMedicalService) {
      showDialog(
        context: Get.context!,
        builder: (context) =>
            WebNonMedicalAppointmentModal(appointment: appointment),
      );
      return;
    }

    // Check if user is a doctor for medical services
    final isDoctor = await controller.isCurrentStaffDoctor();
    if (!isDoctor) {
      Get.snackbar(
        'Access Restricted',
        'Only doctors can complete medical appointments with diagnosis.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.lock, color: Colors.white),
        duration: const Duration(seconds: 4),
      );
      return;
    }

    // Show regular medical service completion dialog
    final diagnosisController = TextEditingController();
    final treatmentController = TextEditingController();
    final prescriptionController = TextEditingController();
    final notesController = TextEditingController();
    final followUpController = TextEditingController();
    DateTime? nextAppointmentDate;
    bool hasChanges = false;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 600,
          constraints: const BoxConstraints(maxHeight: 700),
          padding: const EdgeInsets.all(24),
          child: StatefulBuilder(
            builder: (context, setState) {
              return WillPopScope(
                onWillPop: () async {
                  if (hasChanges) {
                    return await _showDiscardChangesDialog(context);
                  }
                  return true;
                },
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.check_circle,
                                color: Colors.green, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Complete Service',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 81, 115, 153),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Fill in the medical information for ${controller.getPetName(appointment.petId)}',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Info banner
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.orange[700], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Diagnosis and Treatment are required',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Diagnosis field (required)
                      TextField(
                        controller: diagnosisController,
                        decoration: const InputDecoration(
                          labelText: 'Diagnosis *',
                          border: OutlineInputBorder(),
                          hintText: 'Enter diagnosis',
                        ),
                        maxLines: 2,
                        onChanged: (value) {
                          if (value.isNotEmpty) hasChanges = true;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Treatment field (required)
                      TextField(
                        controller: treatmentController,
                        decoration: const InputDecoration(
                          labelText: 'Treatment *',
                          border: OutlineInputBorder(),
                          hintText: 'Enter treatment provided',
                        ),
                        maxLines: 2,
                        onChanged: (value) {
                          if (value.isNotEmpty) hasChanges = true;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Prescription field (optional)
                      TextField(
                        controller: prescriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Prescription (Optional)',
                          border: OutlineInputBorder(),
                          hintText: 'Enter prescribed medications',
                        ),
                        maxLines: 2,
                        onChanged: (value) {
                          if (value.isNotEmpty) hasChanges = true;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Follow-up instructions (optional)
                      TextField(
                        controller: followUpController,
                        decoration: const InputDecoration(
                          labelText: 'Follow-up Instructions (Optional)',
                          border: OutlineInputBorder(),
                          hintText: 'Enter any follow-up care instructions',
                        ),
                        maxLines: 3,
                        onChanged: (value) {
                          if (value.isNotEmpty) hasChanges = true;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Next appointment date (optional)
                      InkWell(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate:
                                DateTime.now().add(const Duration(days: 7)),
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() {
                              nextAppointmentDate = picked;
                              hasChanges = true;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Next Appointment Date (Optional)',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            nextAppointmentDate != null
                                ? DateFormat('MMMM dd, yyyy')
                                    .format(nextAppointmentDate!)
                                : 'Select date (Optional)',
                            style: TextStyle(
                              color: nextAppointmentDate != null
                                  ? Colors.black87
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Veterinary notes (optional)
                      TextField(
                        controller: notesController,
                        decoration: const InputDecoration(
                          labelText: 'Veterinary Notes (Optional)',
                          border: OutlineInputBorder(),
                          hintText: 'Additional notes for the medical record',
                        ),
                        maxLines: 3,
                        onChanged: (value) {
                          if (value.isNotEmpty) hasChanges = true;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () async {
                              if (hasChanges) {
                                final shouldDiscard =
                                    await _showDiscardChangesDialog(context);
                                if (shouldDiscard == true) {
                                  diagnosisController.dispose();
                                  treatmentController.dispose();
                                  prescriptionController.dispose();
                                  notesController.dispose();
                                  followUpController.dispose();
                                  Get.back();
                                }
                              } else {
                                diagnosisController.dispose();
                                treatmentController.dispose();
                                prescriptionController.dispose();
                                notesController.dispose();
                                followUpController.dispose();
                                Get.back();
                              }
                            },
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () async {
                              // Validate required fields
                              if (diagnosisController.text.trim().isEmpty) {
                                Get.snackbar(
                                  'Required Field',
                                  'Please enter a diagnosis',
                                  backgroundColor: Colors.orange,
                                  colorText: Colors.white,
                                );
                                return;
                              }
                              if (treatmentController.text.trim().isEmpty) {
                                Get.snackbar(
                                  'Required Field',
                                  'Please enter the treatment provided',
                                  backgroundColor: Colors.orange,
                                  colorText: Colors.white,
                                );
                                return;
                              }

                              // Close dialog FIRST
                              Get.back();

                              // Then call the completion method
                              try {
                                await controller.completeServiceWithRecord(
                                  appointment: appointment,
                                  diagnosis: diagnosisController.text.trim(),
                                  treatment: treatmentController.text.trim(),
                                  prescription: prescriptionController.text
                                          .trim()
                                          .isNotEmpty
                                      ? prescriptionController.text.trim()
                                      : null,
                                  vetNotes:
                                      notesController.text.trim().isNotEmpty
                                          ? notesController.text.trim()
                                          : null,
                                  followUpInstructions:
                                      followUpController.text.trim().isNotEmpty
                                          ? followUpController.text.trim()
                                          : null,
                                  nextAppointmentDate: nextAppointmentDate,
                                );
                              } finally {
                                // Dispose controllers after completion
                                diagnosisController.dispose();
                                treatmentController.dispose();
                                prescriptionController.dispose();
                                notesController.dispose();
                                followUpController.dispose();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: const Text(
                              'Complete Service',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  // NEW HELPER METHOD - Add to WebAppointmentTile class
  Future<bool> _showDiscardChangesDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text(
            'Discard Changes?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          content: const Text(
            'You have unsaved changes. Are you sure you want to discard them? This action cannot be undone.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(
                'Continue Editing',
                style: TextStyle(color: Color.fromARGB(255, 81, 115, 153)),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text(
                'Discard Changes',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

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
      case 'cancelled':
        return [Colors.grey, Colors.grey.shade300];
      case 'declined':
        return [Colors.red, Colors.red.shade300];
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
      case 'cancelled':
        return Colors.grey;
      case 'declined':
        return Colors.red;
      case 'no_show':
        return Colors.red.shade700;
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
      case 'cancelled':
        return 'CANCELLED';
      case 'declined':
        return 'DECLINED';
      case 'no_show':
        return 'NO SHOW';
      default:
        return status.toUpperCase();
    }
  }

  Widget _buildServiceTypeIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: appointment.isMedicalService
            ? Colors.red.withOpacity(0.1)
            : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: appointment.isMedicalService
              ? Colors.red.withOpacity(0.3)
              : Colors.blue.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            appointment.isMedicalService
                ? Icons.medical_services
                : Icons.content_cut,
            size: 14,
            color: appointment.isMedicalService ? Colors.red : Colors.blue,
          ),
          const SizedBox(width: 6),
          Text(
            appointment.isMedicalService ? 'MEDICAL' : 'BASIC',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: appointment.isMedicalService ? Colors.red : Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}
