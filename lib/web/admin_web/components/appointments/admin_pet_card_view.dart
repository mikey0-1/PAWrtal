// admin_pet_card_view.dart
import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/data/models/medical_record_model.dart';
import 'package:capstone_app/data/models/vaccination_model.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:capstone_app/web/admin_web/components/appointments/admin_pet_card_view_controller.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

enum CardView { front, back, vaccinationHistory, medicalAppointmentsHistory }

class AdminPetCardView extends StatefulWidget {
  final Pet pet;
  final String clinicId; // NEW: Required clinic ID

  const AdminPetCardView({
    super.key,
    required this.pet,
    required this.clinicId, // NEW
  });

  @override
  State<AdminPetCardView> createState() => _AdminPetCardViewState();
}

class _AdminPetCardViewState extends State<AdminPetCardView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  CardView _currentView = CardView.front;
  CardView _previousView = CardView.front;
  bool _isGoingForward = true;

  Vaccination? _selectedVaccination;
  Map<String, dynamic>? _selectedMedicalAppointment;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // ✅ CRITICAL: Initialize controller IMMEDIATELY in initState
    _initializeController();
  }

  /// NEW: Initialize controller synchronously in initState
  void _initializeController() {
    // Register controller with unique tag
    final adminController = Get.put(
      AdminPetCardViewController(
        authRepository: Get.find(),
      ),
      tag: widget.pet.petId,
    );

    // Fetch data AFTER first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPetData(adminController);
    });
  }

  /// NEW: Load pet data after controller is initialized
  Future<void> _loadPetData(AdminPetCardViewController controller) async {
    try {
      // Load all data
      await controller.loadPetData(widget.pet, widget.clinicId);
    } catch (e, stackTrace) {}
  }

  /// NEW: Initialize controller and fetch all data immediately
  Future<void> _initializeAndLoadData() async {
    try {
      final adminController = Get.put(
        AdminPetCardViewController(
          authRepository: Get.find(),
        ),
        tag: widget.pet.petId,
      );

      // âœ… CRITICAL: Pass clinic ID and fetch data immediately
      await adminController.loadPetData(widget.pet, widget.clinicId);
    } catch (e, stackTrace) {}
  }

  @override
  void dispose() {
    _controller.dispose();
    // Clean up controller
    Get.delete<AdminPetCardViewController>(tag: widget.pet.petId);
    super.dispose();
  }

  int _getViewLevel(CardView view) {
    switch (view) {
      case CardView.front:
        return 0;
      case CardView.back:
        return 1;
      case CardView.vaccinationHistory:
        return 2;
      case CardView.medicalAppointmentsHistory:
        return 2;
    }
  }

  void _flipToView(CardView newView) {
    setState(() {
      _previousView = _currentView;
      _isGoingForward = _getViewLevel(newView) > _getViewLevel(_currentView);
      _currentView = newView;
      _selectedVaccination = null;
      _selectedMedicalAppointment = null;
    });
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    // ✅ SAFE: Check if controller exists before accessing
    final controllerTag = widget.pet.petId;

    if (!Get.isRegistered<AdminPetCardViewController>(tag: controllerTag)) {
      // Controller not ready yet - show loading
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 800,
          height: 600,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: const Color(0xFF3498DB),
                ),
                const SizedBox(height: 16),
                Text(
                  'Initializing pet card...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ✅ Controller exists - get it safely
    final controller = Get.find<AdminPetCardViewController>(tag: controllerTag);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 800,
          maxHeight: 600,
        ),
        child: Obx(() {
          // Show loading while data is being fetched
          final isLoading = controller.isLoadingMedicalRecords.value ||
              controller.isLoadingVaccinations.value ||
              controller.isLoadingMedicalAppointments.value;

          if (isLoading) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: const Color(0xFF3498DB),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading ${widget.pet.name}\'s medical history...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // ✅ Data loaded - show the card with animation
          return AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final angle =
                  _animation.value * math.pi * (_isGoingForward ? 1 : -1);
              final transform = Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle);

              return Transform(
                transform: transform,
                alignment: Alignment.center,
                child: angle.abs() >= math.pi / 2
                    ? Transform(
                        transform: Matrix4.identity()
                          ..rotateY(_isGoingForward ? math.pi : -math.pi),
                        alignment: Alignment.center,
                        child: _buildCurrentView(),
                      )
                    : _buildPreviousView(),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildPreviousView() {
    switch (_previousView) {
      case CardView.front:
        return _buildFrontSide();
      case CardView.back:
        return _buildBackSide();
      case CardView.vaccinationHistory:
        return _buildVaccinationHistoryView();
      case CardView.medicalAppointmentsHistory:
        return _buildMedicalAppointmentsHistoryView();
    }
  }

  Widget _buildCurrentView() {
    switch (_currentView) {
      case CardView.front:
        return _buildFrontSide();
      case CardView.back:
        return _buildBackSide();
      case CardView.vaccinationHistory:
        return _buildVaccinationHistoryView();
      case CardView.medicalAppointmentsHistory:
        return _buildMedicalAppointmentsHistoryView();
    }
  }

  Widget _buildFrontSide() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section with small image on top left
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF3498DB),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Small circular pet image
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.network(
                        widget.pet.image ??
                            'https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=300&h=300&fit=crop',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.pets,
                            size: 50,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Pet info next to image
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.pet.name,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.pet.type,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Action buttons
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.more_horiz_rounded,
                            color: Colors.white),
                        onPressed: () => _flipToView(CardView.back),
                        tooltip: "More",
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: "Close",
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Body section with pet details
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ID-style information grid
                  _buildIDRow('Breed', widget.pet.breed),
                  const Divider(height: 24),
                  _buildIDRow('Color', widget.pet.color ?? 'Not specified'),
                  const Divider(height: 24),
                  _buildIDRow(
                      'Weight',
                      widget.pet.weight != null
                          ? '${widget.pet.weight} kg'
                          : 'Not specified'),
                  const Divider(height: 24),
                  _buildIDRow('Gender', widget.pet.gender ?? 'Not specified'),
                  // NEW: Add birthdate and age
                  if (widget.pet.hasBirthdate) ...[
                    const Divider(height: 24),
                    _buildIDRow(
                      'Birthdate',
                      DateFormat('MMMM dd, yyyy').format(widget.pet.birthdate!),
                    ),
                    const Divider(height: 24),
                    _buildIDRow('Age', widget.pet.ageString),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackSide() {
    final controller =
        Get.find<AdminPetCardViewController>(tag: widget.pet.petId);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header for back side
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF2C3E50),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => _flipToView(CardView.front),
                    tooltip: "Back",
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Health Records',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Back side content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Medical Appointments History section (CLINIC-SPECIFIC)
                  _buildHistoryButton(
                    'Medical Appointments History',
                    'View medical appointments from your clinic', // UPDATED MESSAGE
                    Icons.local_hospital_outlined,
                    () => _flipToView(CardView.medicalAppointmentsHistory),
                    controller.medicalAppointmentsCount,
                    isPrimary: true,
                  ),

                  const SizedBox(height: 16),

                  // Vaccination History section (ALL CLINICS)
                  _buildHistoryButton(
                    'Vaccination History',
                    'View vaccination records (all clinics)', // UPDATED MESSAGE
                    Icons.vaccines_outlined,
                    () => _flipToView(CardView.vaccinationHistory),
                    controller.vaccinationCount,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalAppointmentsHistoryView() {
    final controller =
        Get.find<AdminPetCardViewController>(tag: widget.pet.petId);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _selectedMedicalAppointment = null;
                    });
                    _flipToView(CardView.back);
                  },
                  tooltip: "Back",
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedMedicalAppointment != null
                            ? 'Appointment Details'
                            : 'Medical Appointments History',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (_selectedMedicalAppointment == null)
                        const SizedBox(height: 4),
                      if (_selectedMedicalAppointment == null)
                        const Text(
                          'Medical visits from your clinic', // UPDATED MESSAGE
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                    ],
                  ),
                ),
                if (_selectedMedicalAppointment != null)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _selectedMedicalAppointment = null;
                      });
                    },
                    tooltip: "Close Details",
                  ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Obx(() {
              if (controller.isLoadingMedicalAppointments.value) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Loading medical appointments...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              if (controller.medicalAppointments.isEmpty) {
                return _buildEmptyState(
                  'No Medical Appointments',
                  'No completed medical appointments from your clinic found for ${widget.pet.name} yet.', // UPDATED MESSAGE
                  Icons.local_hospital_outlined,
                );
              }

              if (_selectedMedicalAppointment != null) {
                return _buildMedicalAppointmentDetails(
                    _selectedMedicalAppointment!, controller);
              }

              return _buildMedicalAppointmentsList(
                  controller.medicalAppointments, controller);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildVaccinationHistoryView() {
    final controller =
        Get.find<AdminPetCardViewController>(tag: widget.pet.petId);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF2C3E50),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _selectedVaccination = null;
                    });
                    _flipToView(CardView.back);
                  },
                  tooltip: "Back",
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedVaccination != null
                            ? 'Vaccination Details'
                            : 'Vaccination History',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (_selectedVaccination == null)
                        const SizedBox(height: 4),
                      if (_selectedVaccination == null)
                        const Text(
                          'All vaccinations (across all clinics)', // ADDED CLARIFICATION
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                    ],
                  ),
                ),
                if (_selectedVaccination != null)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _selectedVaccination = null;
                      });
                    },
                    tooltip: "Close Details",
                  ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Obx(() {
              if (controller.isLoadingVaccinations.value) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Loading vaccination history...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              if (controller.vaccinations.isEmpty) {
                return _buildEmptyState(
                  'No Vaccination Records',
                  'No vaccination history available for this pet yet.',
                  Icons.vaccines_outlined,
                );
              }

              if (_selectedVaccination != null) {
                return _buildVaccinationDetails(_selectedVaccination!);
              }

              return _buildVaccinationsList(controller.vaccinations);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalAppointmentsList(List<Map<String, dynamic>> appointments,
      AdminPetCardViewController controller) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return _buildMedicalAppointmentCard(appointment, controller);
      },
    );
  }

  Widget _buildMedicalAppointmentCard(
      Map<String, dynamic> appointment, AdminPetCardViewController controller) {
    final dateTime = DateTime.parse(appointment['dateTime']);
    final clinicName = appointment['clinicName'] ?? 'Unknown Clinic';
    final service = appointment['service'] ?? 'Medical Service';
    final clinicId = appointment['clinicId'];
    final appointmentId = appointment['\$id'];
    final petId = appointment['petId'];

    // Check for medical record
    bool hasMedicalRecord = false;
    MedicalRecord? matchedRecord;

    for (var record in controller.medicalRecords) {
      if (record.appointmentId == appointmentId) {
        hasMedicalRecord = true;
        matchedRecord = record;
        break;
      }
    }

    if (!hasMedicalRecord) {
      for (var record in controller.medicalRecords) {
        final petMatches = record.petId == petId;
        final dateMatches = record.visitDate.year == dateTime.year &&
            record.visitDate.month == dateTime.month &&
            record.visitDate.day == dateTime.day;
        final serviceMatches =
            record.service.toLowerCase().contains(service.toLowerCase()) ||
                service.toLowerCase().contains(record.service.toLowerCase());

        if (petMatches && dateMatches && serviceMatches) {
          hasMedicalRecord = true;
          matchedRecord = record;
          break;
        }
      }
    }

    // Check for vaccination record
    final hasVaccinationRecord = controller.vaccinations.any((vaccination) {
      final isSameDay = vaccination.dateGiven.year == dateTime.year &&
          vaccination.dateGiven.month == dateTime.month &&
          vaccination.dateGiven.day == dateTime.day;
      final isVaccineService = service.toLowerCase().contains('vaccin') ||
          service.toLowerCase().contains('immuniz');
      return isSameDay && isVaccineService;
    });

    final hasAnyRecord = hasMedicalRecord || hasVaccinationRecord;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: hasAnyRecord
            ? BorderSide.none
            : BorderSide(color: Colors.orange[300]!, width: 2),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedMedicalAppointment = appointment;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Clinic profile picture or icon
              FutureBuilder<String?>(
                future: _getClinicProfilePictureId(clinicId),
                builder: (context, snapshot) {
                  final profilePictureId = snapshot.data;

                  if (profilePictureId != null && profilePictureId.isNotEmpty) {
                    return Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: (hasAnyRecord
                                    ? const Color(0xFF667eea)
                                    : Colors.orange[400]!)
                                .withOpacity(0.3),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _getClinicProfilePictureUrl(profilePictureId),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildClinicIconFallback(
                                hasAnyRecord, hasVaccinationRecord);
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return _buildClinicIconFallback(
                                hasAnyRecord, hasVaccinationRecord);
                          },
                        ),
                      ),
                    );
                  }

                  return _buildClinicIconFallback(
                      hasAnyRecord, hasVaccinationRecord);
                },
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            clinicName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                        ),
                        // Record badge
                        if (hasVaccinationRecord)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purple[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.vaccines,
                                    size: 12, color: Colors.purple[700]),
                                const SizedBox(width: 4),
                                Text(
                                  'Vaccine',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple[700],
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (hasMedicalRecord)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle,
                                    size: 12, color: Colors.green[700]),
                                const SizedBox(width: 4),
                                Text(
                                  'Record',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.warning_outlined,
                                    size: 12, color: Colors.orange[700]),
                                const SizedBox(width: 4),
                                Text(
                                  'No Record',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.medical_services,
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            service,
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
                        Icon(Icons.calendar_today,
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMMM dd, yyyy • hh:mm a')
                              .format(dateTime),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClinicIconFallback(
      bool hasAnyRecord, bool hasVaccinationRecord) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasAnyRecord
              ? [const Color(0xFF667eea), const Color(0xFF764ba2)]
              : [Colors.orange[400]!, Colors.orange[300]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:
                (hasAnyRecord ? const Color(0xFF667eea) : Colors.orange[400]!)
                    .withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        hasAnyRecord
            ? (hasVaccinationRecord ? Icons.vaccines : Icons.local_hospital)
            : Icons.local_hospital_outlined,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Future<String?> _getClinicProfilePictureId(String clinicId) async {
    try {
      final authRepository = Get.find<AuthRepository>();
      final clinicDoc = await authRepository.getClinicById(clinicId);

      if (clinicDoc != null) {
        return clinicDoc.data['profilePictureId'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  String _getClinicProfilePictureUrl(String profilePictureId) {
    return '${AppwriteConstants.endPoint}/storage/buckets/${AppwriteConstants.imageBucketID}/files/$profilePictureId/view?project=${AppwriteConstants.projectID}';
  }

  // admin_pet_card_view.dart - MODIFIED METHODS ONLY

// Replace the existing _buildMedicalAppointmentDetails method with this:

  Widget _buildMedicalAppointmentDetails(
      Map<String, dynamic> appointment, AdminPetCardViewController controller) {
    final dateTime = DateTime.parse(appointment['dateTime']);
    final completedAt = appointment['serviceCompletedAt'] != null
        ? DateTime.parse(appointment['serviceCompletedAt'])
        : null;

    final appointmentId = appointment['\$id'];
    final service = appointment['service'] ?? '';
    final petId = appointment['petId'];

    // Find medical record
    MedicalRecord? medicalRecord;

    try {
      medicalRecord = controller.medicalRecords.firstWhere(
        (record) => record.appointmentId == appointmentId,
        orElse: () => throw Exception('Not found'),
      );
      if (medicalRecord != null) {
        controller.debugVetIdIssue(
            medicalRecord.vetId, medicalRecord.appointmentId);
      }
    } catch (e) {
      // Try fuzzy match
      try {
        medicalRecord = controller.medicalRecords.firstWhere(
          (record) {
            final petMatches = record.petId == petId;
            final dateMatches = record.visitDate.year == dateTime.year &&
                record.visitDate.month == dateTime.month &&
                record.visitDate.day == dateTime.day;
            final serviceMatches = record.service
                    .toLowerCase()
                    .contains(service.toLowerCase()) ||
                service.toLowerCase().contains(record.service.toLowerCase());
            return petMatches && dateMatches && serviceMatches;
          },
          orElse: () => throw Exception('Not found'),
        );
      } catch (e) {
        // No medical record found
      }
    }

    if (medicalRecord != null) {
      controller.debugVetIdIssue(
          medicalRecord.vetId, medicalRecord.appointmentId);
    }

    // Find vaccination record
    Vaccination? vaccinationRecord;
    try {
      final isVaccineService = service.toLowerCase().contains('vaccin') ||
          service.toLowerCase().contains('immuniz');
      if (isVaccineService) {
        vaccinationRecord = controller.vaccinations.firstWhere(
          (vaccination) {
            final isSameDay = vaccination.dateGiven.year == dateTime.year &&
                vaccination.dateGiven.month == dateTime.month &&
                vaccination.dateGiven.day == dateTime.day;
            return isSameDay;
          },
          orElse: () => throw Exception('Not found'),
        );
      }
    } catch (e) {
      // No vaccination record found
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Clinic Information
          _buildDetailCard(
            'Veterinary Clinic',
            [
              _buildDetailRow(
                  'Clinic Name', appointment['clinicName'] ?? 'N/A'),
              _buildDetailRow('Address', appointment['clinicAddress'] ?? 'N/A'),
              _buildDetailRow('Contact', appointment['clinicContact'] ?? 'N/A'),
            ],
            icon: Icons.local_hospital,
            iconColor: const Color(0xFF667eea),
          ),
          const SizedBox(height: 16),
          // Appointment Information
          _buildDetailCard(
            'Appointment Information',
            [
              _buildDetailRow('Service', appointment['service'] ?? 'N/A'),
              _buildDetailRow(
                'Date & Time',
                DateFormat('MMMM dd, yyyy').format(dateTime),
              ),
              _buildDetailRow(
                'Time',
                DateFormat('hh:mm a').format(dateTime),
              ),
              _buildDetailRow('Status', 'Completed'),
              if (completedAt != null)
                _buildDetailRow(
                  'Completed At',
                  DateFormat('MMMM dd, yyyy • hh:mm a').format(completedAt),
                ),
            ],
            icon: Icons.event_note,
            iconColor: const Color(0xFF3498DB),
          ),

          // Vaccination Record Section (Priority)
          if (vaccinationRecord != null) ...[
            const SizedBox(height: 16),
            _buildDetailCard(
              'Vaccine Information',
              [
                _buildDetailRow('Vaccine Name', vaccinationRecord.vaccineName),
                _buildDetailRow('Type', vaccinationRecord.vaccineType),
                _buildDetailRow(
                    'Booster', vaccinationRecord.isBooster ? 'Yes' : 'No'),
                if (vaccinationRecord.manufacturer != null &&
                    vaccinationRecord.manufacturer!.isNotEmpty)
                  _buildDetailRow(
                      'Manufacturer', vaccinationRecord.manufacturer!),
                if (vaccinationRecord.batchNumber != null &&
                    vaccinationRecord.batchNumber!.isNotEmpty)
                  _buildDetailRow(
                      'Batch Number', vaccinationRecord.batchNumber!),
              ],
              icon: Icons.vaccines,
              iconColor: const Color(0xFF9B59B6),
            ),
            const SizedBox(height: 16),
            _buildDetailCard(
              'Vaccination Dates',
              [
                _buildDetailRow(
                  'Date Given',
                  DateFormat('MMMM dd, yyyy')
                      .format(vaccinationRecord.dateGiven),
                ),
                if (vaccinationRecord.nextDueDate != null)
                  _buildDetailRow(
                    'Next Due Date',
                    DateFormat('MMMM dd, yyyy')
                        .format(vaccinationRecord.nextDueDate!),
                  ),
              ],
              icon: Icons.event,
              iconColor: const Color(0xFF3498DB),
            ),
            // MODIFIED: Show who administered the vaccination
            if (medicalRecord != null) ...[
              const SizedBox(height: 16),
              FutureBuilder<String>(
                future: controller.getVeterinarianName(medicalRecord.vetId),
                builder: (context, snapshot) {
                  final vetName = snapshot.data ?? 'Loading...';

                  // Determine the title based on the name
                  String title;
                  IconData icon;
                  Color iconColor;

                  if (vetName == 'Admin') {
                    title = 'Administered By (Admin)';
                    icon = Icons.admin_panel_settings;
                    iconColor = const Color(0xFF667eea);
                  } else if (vetName.startsWith('Dr.')) {
                    title = 'Administered By (Doctor)';
                    icon = Icons.medical_services;
                    iconColor = const Color(0xFF2ECC71);
                  } else {
                    title = 'Administered By (Staff)';
                    icon = Icons.person;
                    iconColor = const Color(0xFF95A5A6);
                  }

                  return _buildDetailCard(
                    title,
                    [
                      _buildDetailRow('Name', vetName),
                    ],
                    icon: icon,
                    iconColor: iconColor,
                  );
                },
              ),
            ],
            if (vaccinationRecord.notes != null &&
                vaccinationRecord.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildDetailCard(
                'Additional Notes',
                [_buildDetailRow('Notes', vaccinationRecord.notes!)],
                icon: Icons.note,
                iconColor: const Color(0xFF95A5A6),
              ),
            ],
          ]
          // Medical Record Section
          else if (medicalRecord != null) ...[
            const SizedBox(height: 16),
            _buildDetailCard(
              'Diagnosis & Treatment',
              [
                _buildDetailRow('Diagnosis', medicalRecord.diagnosis),
                _buildDetailRow('Treatment', medicalRecord.treatment),
                if (medicalRecord.prescription != null &&
                    medicalRecord.prescription!.isNotEmpty)
                  _buildDetailRow('Prescription', medicalRecord.prescription!),
              ],
              icon: Icons.medical_services,
              iconColor: const Color(0xFFE74C3C),
            ),
            // MODIFIED: Show doctor/admin/staff who treated
            const SizedBox(height: 16),
            FutureBuilder<String>(
              future: controller.getVeterinarianName(medicalRecord.vetId),
              builder: (context, snapshot) {
                final vetName = snapshot.data ?? 'Loading...';

                // Determine the title and styling based on the name
                String title;
                IconData icon;
                Color iconColor;

                if (vetName == 'Admin') {
                  title = 'Treated By (Admin)';
                  icon = Icons.admin_panel_settings;
                  iconColor = const Color(0xFF667eea);
                } else if (vetName.startsWith('Dr.')) {
                  title = 'Attending Veterinarian';
                  icon = Icons.medical_services;
                  iconColor = const Color(0xFF2ECC71);
                } else {
                  title = 'Treated By (Staff)';
                  icon = Icons.person;
                  iconColor = const Color(0xFF95A5A6);
                }

                return _buildDetailCard(
                  title,
                  [
                    _buildDetailRow('Name', vetName),
                  ],
                  icon: icon,
                  iconColor: iconColor,
                );
              },
            ),
            if (medicalRecord.hasVitals) ...[
              const SizedBox(height: 16),
              _buildDetailCard(
                'Vital Signs',
                [
                  if (medicalRecord.temperature != null)
                    _buildDetailRow('Temperature',
                        '${medicalRecord.temperature!.toStringAsFixed(1)}°C'),
                  if (medicalRecord.weight != null)
                    _buildDetailRow('Weight',
                        '${medicalRecord.weight!.toStringAsFixed(2)} kg'),
                  if (medicalRecord.bloodPressure != null)
                    _buildDetailRow(
                        'Blood Pressure', medicalRecord.bloodPressure!),
                  if (medicalRecord.heartRate != null)
                    _buildDetailRow(
                        'Heart Rate', '${medicalRecord.heartRate} bpm'),
                ],
                icon: Icons.favorite,
                iconColor: const Color(0xFFE74C3C),
              ),
            ],
            if (medicalRecord.notes != null &&
                medicalRecord.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildDetailCard(
                'Veterinary Notes',
                [
                  _buildDetailRow('Notes', medicalRecord.notes!),
                ],
                icon: Icons.note,
                iconColor: const Color(0xFF9B59B6),
              ),
            ],
          ] else ...[
            // No records found
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.orange[700], size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No medical record available',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This appointment was completed, but no detailed medical record or vaccination record was created at the time.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          if (appointment['followUpInstructions'] != null ||
              appointment['nextAppointmentDate'] != null)
            _buildDetailCard(
              'Follow-up Information',
              [
                if (appointment['followUpInstructions'] != null &&
                    appointment['followUpInstructions'].toString().isNotEmpty)
                  _buildDetailRow(
                    'Instructions',
                    appointment['followUpInstructions'],
                  ),
                if (appointment['nextAppointmentDate'] != null)
                  _buildDetailRow(
                    'Next Appointment',
                    DateFormat('MMMM dd, yyyy').format(
                      DateTime.parse(appointment['nextAppointmentDate']),
                    ),
                  ),
              ],
              icon: Icons.event_available,
              iconColor: const Color(0xFFE67E22),
            ),

          const SizedBox(height: 16),

          if (appointment['notes'] != null &&
              appointment['notes'].toString().isNotEmpty)
            _buildDetailCard(
              'Additional Appointment Notes',
              [
                _buildDetailRow('Notes', appointment['notes']),
              ],
              icon: Icons.note_outlined,
              iconColor: const Color(0xFF95A5A6),
            ),
        ],
      ),
    );
  }

  Widget _buildVaccinationsList(List<Vaccination> vaccinations) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: vaccinations.length,
      itemBuilder: (context, index) {
        final vaccination = vaccinations[index];
        return _buildVaccinationCard(vaccination);
      },
    );
  }

  Widget _buildVaccinationCard(Vaccination vaccination) {
    Color statusColor;
    if (vaccination.isOverdue) {
      statusColor = Colors.red;
    } else if (vaccination.isDueSoon) {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.green;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedVaccination = vaccination;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.vaccines,
                  color: statusColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            vaccination.vaccineName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            vaccination.statusText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Given: ${DateFormat('MMM dd, yyyy').format(vaccination.dateGiven)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (vaccination.nextDueDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Next Due: ${DateFormat('MMM dd, yyyy').format(vaccination.nextDueDate!)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVaccinationDetails(Vaccination vaccination) {
    Color statusColor;
    if (vaccination.isOverdue) {
      statusColor = Colors.red;
    } else if (vaccination.isDueSoon) {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.green;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: statusColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    vaccination.statusText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailCard(
            'Vaccine Information',
            [
              _buildDetailRow('Vaccine Name', vaccination.vaccineName),
              _buildDetailRow('Type', vaccination.vaccineType),
              _buildDetailRow('Booster', vaccination.isBooster ? 'Yes' : 'No'),
              if (vaccination.manufacturer != null &&
                  vaccination.manufacturer!.isNotEmpty)
                _buildDetailRow('Manufacturer', vaccination.manufacturer!),
              if (vaccination.batchNumber != null &&
                  vaccination.batchNumber!.isNotEmpty)
                _buildDetailRow('Batch Number', vaccination.batchNumber!),
            ],
            icon: Icons.vaccines,
            iconColor: const Color(0xFF9B59B6),
          ),
          const SizedBox(height: 16),
          _buildDetailCard(
            'Vaccination Dates',
            [
              _buildDetailRow(
                'Date Given',
                DateFormat('MMMM dd, yyyy').format(vaccination.dateGiven),
              ),
              if (vaccination.nextDueDate != null)
                _buildDetailRow(
                  'Next Due Date',
                  DateFormat('MMMM dd, yyyy').format(vaccination.nextDueDate!),
                ),
            ],
            icon: Icons.event,
            iconColor: const Color(0xFF3498DB),
          ),
          // REMOVED: "Administered By" section completely
          if (vaccination.notes != null && vaccination.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildDetailCard(
              'Additional Notes',
              [_buildDetailRow('Notes', vaccination.notes!)],
              icon: Icons.note,
              iconColor: const Color(0xFF95A5A6),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailCard(
    String title,
    List<Widget> children, {
    IconData? icon,
    Color? iconColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 20,
                  color: iconColor ?? const Color(0xFF2C3E50),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2C3E50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIDRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2C3E50),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryButton(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onPressed,
    int count, {
    bool isPrimary = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isPrimary ? const Color(0xFF667eea) : Colors.white,
              foregroundColor:
                  isPrimary ? Colors.white : const Color(0xFF2C3E50),
              padding: const EdgeInsets.all(20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color:
                      isPrimary ? const Color(0xFF667eea) : Colors.grey[300]!,
                  width: isPrimary ? 2 : 1,
                ),
              ),
              elevation: isPrimary ? 4 : 0,
            ),
            onPressed: onPressed,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isPrimary
                        ? Colors.white.withOpacity(0.2)
                        : const Color(0xFF3498DB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isPrimary ? Colors.white : const Color(0xFF3498DB),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isPrimary
                              ? Colors.white
                              : const Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: isPrimary ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isPrimary
                            ? Colors.white.withOpacity(0.2)
                            : const Color(0xFF3498DB).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isPrimary
                              ? Colors.white
                              : const Color(0xFF3498DB),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'records',
                      style: TextStyle(
                        fontSize: 11,
                        color: isPrimary ? Colors.white60 : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: isPrimary ? Colors.white : Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
