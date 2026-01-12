import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/data/models/medical_record_model.dart';
import 'package:capstone_app/data/models/vaccination_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/mobile/user/controllers/mobile_pets_controller.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

enum MedicalHistoryType { appointments, vaccinations }

class PetMedicalHistory extends StatefulWidget {
  final Pet pet;
  final MedicalHistoryType initialType;

  const PetMedicalHistory({
    super.key,
    required this.pet,
    required this.initialType,
  });

  @override
  State<PetMedicalHistory> createState() => _PetMedicalHistoryState();
}

class _PetMedicalHistoryState extends State<PetMedicalHistory>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _selectedAppointment;
  Vaccination? _selectedVaccination;

  // ✅ FIX: Use dedicated controller like admin version
  late MobilePetsController _controller;
  bool _controllerInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex:
          widget.initialType == MedicalHistoryType.appointments ? 0 : 1,
    );

    // ✅ FIX: Initialize controller immediately after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAndLoadData();
    });
  }

  // ✅ NEW: Initialize controller and fetch data immediately
  Future<void> _initializeAndLoadData() async {
    try {

      // Try to find existing controller first
      if (Get.isRegistered<MobilePetsController>()) {
        _controller = Get.find<MobilePetsController>();
      } else {
        // Create new controller if not exists
        _controller = Get.put(MobilePetsController(
          authRepository: Get.find(),
          session: Get.find(),
        ));
      }

      setState(() {
        _controllerInitialized = true;
      });

      // ✅ CRITICAL: Fetch data immediately like admin version

      await Future.wait([
        _controller.fetchPetMedicalAppointmentsAllClinics(widget.pet.petId),
        _controller.fetchPetMedicalRecordsForAppointments(widget.pet.petId),
        _controller.fetchPetVaccinationHistory(widget.pet.petId),
      ]);

    } catch (e, stackTrace) {

      setState(() {
        _controllerInitialized = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: Show loading while initializing
    if (!_controllerInitialized) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(
            'Medical History',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF667eea),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: const Color(0xFF667eea),
              ),
              const SizedBox(height: 24),
              Text(
                'Loading Medical History...',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: const Color(0xFF667eea),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    size: 18, color: Colors.white),
              ),
              onPressed: () {
                if (_selectedAppointment != null ||
                    _selectedVaccination != null) {
                  setState(() {
                    _selectedAppointment = null;
                    _selectedVaccination = null;
                  });
                } else {
                  Navigator.pop(context);
                }
              },
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: EdgeInsets.zero,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.medical_information,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedAppointment != null ||
                                  _selectedVaccination != null
                              ? 'Record Details'
                              : 'Medical History',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(
                            height: 20), // Extra padding to balance spacing
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: _selectedAppointment == null && _selectedVaccination == null
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(48),
                    child: Container(
                      color: const Color(0xFF667eea),
                      child: TabBar(
                        controller: _tabController,
                        indicatorColor: Colors.white,
                        indicatorWeight: 3,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white.withOpacity(0.6),
                        labelStyle: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        unselectedLabelStyle: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                        ),
                        tabs: [
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.local_hospital, size: 18),
                                const SizedBox(width: 8),
                                const Text('Appointments'),
                                const SizedBox(width: 8),
                                Obx(() => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${_controller.medicalAppointments.length}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )),
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.vaccines, size: 18),
                                const SizedBox(width: 8),
                                const Text('Vaccinations'),
                                const SizedBox(width: 8),
                                Obx(() => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${_controller.vaccinations.length}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : null,
          ),

          // Content
          SliverFillRemaining(
            child: _selectedAppointment != null
                ? _buildAppointmentDetails(_selectedAppointment!)
                : _selectedVaccination != null
                    ? _buildVaccinationDetails(_selectedVaccination!)
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildMedicalAppointmentsTab(_controller),
                          _buildVaccinationsTab(_controller),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalAppointmentsTab(MobilePetsController controller) {
    return Obx(() {
      if (controller.isLoadingMedicalAppointments.value) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF667eea)),
        );
      }

      if (controller.medicalAppointments.isEmpty) {
        return _buildEmptyState(
          'No Medical Appointments',
          'No completed medical appointments found yet.',
          Icons.local_hospital_outlined,
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: controller.medicalAppointments.length,
        itemBuilder: (context, index) {
          final appointment = controller.medicalAppointments[index];
          return _buildMedicalAppointmentCard(appointment, controller);
        },
      );
    });
  }

  Widget _buildVaccinationsTab(MobilePetsController controller) {
    return Obx(() {
      if (controller.isLoadingVaccinations.value) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF9B59B6)),
        );
      }

      if (controller.vaccinations.isEmpty) {
        return _buildEmptyState(
          'No Vaccination Records',
          'No vaccination history available yet.',
          Icons.vaccines_outlined,
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: controller.vaccinations.length,
        itemBuilder: (context, index) {
          final vaccination = controller.vaccinations[index];
          return _buildVaccinationCard(vaccination);
        },
      );
    });
  }

  Widget _buildMedicalAppointmentCard(
      Map<String, dynamic> appointment, MobilePetsController controller) {
    final dateTime = DateTime.parse(appointment['dateTime']);
    final clinicName = appointment['clinicName'] ?? 'Unknown Clinic';
    final service = appointment['service'] ?? 'Medical Service';
    final clinicId = appointment['clinicId'];

    final appointmentId = appointment['\$id'];
    final petId = appointment['petId'];

    // Check for medical records
    bool hasMedicalRecord = false;
    for (var record in controller.medicalRecords) {
      if (record.appointmentId == appointmentId) {
        hasMedicalRecord = true;
        break;
      }
    }

    // Fuzzy match if not found
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
          break;
        }
      }
    }

    // Check vaccination records
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
        borderRadius: BorderRadius.circular(16),
        side: hasAnyRecord
            ? BorderSide.none
            : BorderSide(color: Colors.orange[300]!, width: 2),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedAppointment = appointment;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Clinic Icon/Image
              FutureBuilder<String?>(
                future: _getClinicProfilePictureId(clinicId),
                builder: (context, snapshot) {
                  final profilePictureId = snapshot.data;

                  if (profilePictureId != null && profilePictureId.isNotEmpty) {
                    return Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF667eea).withOpacity(0.3),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          _getClinicProfilePictureUrl(profilePictureId),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
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
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2C3E50),
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
                                Icon(
                                  Icons.vaccines,
                                  size: 12,
                                  color: Colors.purple[700],
                                ),
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
                                Icon(
                                  Icons.check_circle,
                                  size: 12,
                                  color: Colors.green[700],
                                ),
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
                                Icon(
                                  Icons.warning_outlined,
                                  size: 12,
                                  color: Colors.orange[700],
                                ),
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
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.medical_services,
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            service,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey[700],
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
                          DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime),
                          style: GoogleFonts.inter(
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
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedVaccination = vaccination;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [statusColor, statusColor.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child:
                    const Icon(Icons.vaccines, color: Colors.white, size: 24),
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
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2C3E50),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            vaccination.statusText,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Given: ${DateFormat('MMM dd, yyyy').format(vaccination.dateGiven)}',
                      style: GoogleFonts.inter(
                          fontSize: 14, color: Colors.grey[600]),
                    ),
                    if (vaccination.nextDueDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Next: ${DateFormat('MMM dd, yyyy').format(vaccination.nextDueDate!)}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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

  Widget _buildAppointmentDetails(Map<String, dynamic> appointment) {
    final dateTime = DateTime.parse(appointment['dateTime']);
    final service = appointment['service'] ?? '';
    final appointmentId = appointment['\$id'];
    final petId = appointment['petId'];
    final completedAt = appointment['serviceCompletedAt'] != null
        ? DateTime.parse(appointment['serviceCompletedAt'])
        : null;

    // Find medical record
    MedicalRecord? medicalRecord;
    try {
      medicalRecord = _controller.medicalRecords.firstWhere(
        (record) => record.appointmentId == appointmentId,
      );
    } catch (e) {
      // Try fuzzy match
      try {
        medicalRecord = _controller.medicalRecords.firstWhere((record) {
          final petMatches = record.petId == petId;
          final dateMatches = record.visitDate.year == dateTime.year &&
              record.visitDate.month == dateTime.month &&
              record.visitDate.day == dateTime.day;
          final serviceMatches =
              record.service.toLowerCase() == service.toLowerCase() ||
                  service.toLowerCase().contains(record.service.toLowerCase());
          return petMatches && dateMatches && serviceMatches;
        });
      } catch (e) {
        medicalRecord = null;
      }
    }

    // Find vaccination record
    Vaccination? vaccinationRecord;
    try {
      final isVaccineService = service.toLowerCase().contains('vaccin') ||
          service.toLowerCase().contains('immuniz');
      if (isVaccineService) {
        vaccinationRecord = _controller.vaccinations.firstWhere((vaccination) {
          final isSameDay = vaccination.dateGiven.year == dateTime.year &&
              vaccination.dateGiven.month == dateTime.month &&
              vaccination.dateGiven.day == dateTime.day;
          return isSameDay;
        });
      }
    } catch (e) {
      vaccinationRecord = null;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

          _buildDetailCard(
            'Appointment Information',
            [
              _buildDetailRow('Service', service),
              _buildDetailRow(
                  'Date', DateFormat('MMMM dd, yyyy').format(dateTime)),
              _buildDetailRow('Time', DateFormat('hh:mm a').format(dateTime)),
              _buildDetailRow('Status', 'Completed'),
              if (completedAt != null)
                _buildDetailRow(
                  'Completed At',
                  DateFormat('MMM dd, yyyy • hh:mm a').format(completedAt),
                ),
            ],
            icon: Icons.event_note,
            iconColor: const Color(0xFF3498DB),
          ),

          // ✅ VACCINATION RECORD SECTION (PRIORITY)
          if (vaccinationRecord != null) ...[
            const SizedBox(height: 16),
            _buildDetailCard(
              'Vaccine Information',
              [
                _buildDetailRow('Vaccine Name', vaccinationRecord.vaccineName),
                _buildDetailRow('Type', vaccinationRecord.vaccineType),
                _buildDetailRow(
                    'Booster', vaccinationRecord.isBooster ? 'Yes' : 'No'),
                if (vaccinationRecord.manufacturer != null)
                  _buildDetailRow(
                      'Manufacturer', vaccinationRecord.manufacturer!),
                if (vaccinationRecord.batchNumber != null)
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
            // ✅ NEW: Show who administered the vaccination
            if (medicalRecord != null) ...[
              const SizedBox(height: 16),
              FutureBuilder<String>(
                future: _controller.getVeterinarianName(medicalRecord.vetId),
                builder: (context, snapshot) {
                  final vetName = snapshot.data ?? 'Loading...';

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
                    [_buildDetailRow('Name', vetName)],
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
          // ✅ MEDICAL RECORD SECTION
          else if (medicalRecord != null) ...[
            const SizedBox(height: 16),
            _buildDetailCard(
              'Diagnosis & Treatment',
              [
                _buildDetailRow('Diagnosis', medicalRecord.diagnosis),
                _buildDetailRow('Treatment', medicalRecord.treatment),
                if (medicalRecord.prescription != null)
                  _buildDetailRow('Prescription', medicalRecord.prescription!),
              ],
              icon: Icons.medical_services,
              iconColor: const Color(0xFFE74C3C),
            ),
            // ✅ NEW: Show doctor/admin/staff who treated
            const SizedBox(height: 16),
            FutureBuilder<String>(
              future: _controller.getVeterinarianName(medicalRecord.vetId),
              builder: (context, snapshot) {
                final vetName = snapshot.data ?? 'Loading...';

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
                  [_buildDetailRow('Name', vetName)],
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
                [_buildDetailRow('Notes', medicalRecord.notes!)],
                icon: Icons.note,
                iconColor: const Color(0xFF9B59B6),
              ),
            ],
          ] else ...[
            const SizedBox(height: 16),
            _buildNoRecordWarning(),
          ],
        ],
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: statusColor),
                const SizedBox(width: 12),
                Text(
                  vaccination.statusText,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
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
              if (vaccination.manufacturer != null)
                _buildDetailRow('Manufacturer', vaccination.manufacturer!),
              if (vaccination.batchNumber != null)
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

          const SizedBox(height: 16),

          _buildDetailCard(
            'Administered By',
            [_buildDetailRow('Veterinarian', vaccination.veterinarianName)],
            icon: Icons.person,
            iconColor: const Color(0xFF2ECC71),
          ),

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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon,
                    size: 20, color: iconColor ?? const Color(0xFF2C3E50)),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2C3E50),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF2C3E50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoRecordWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange[700], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No detailed medical record available for this appointment.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClinicIconFallback(
      bool hasAnyRecord, bool hasVaccinationRecord) {
    final color = hasAnyRecord ? const Color(0xFF667eea) : Colors.orange[400]!;
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
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
        size: 28,
      ),
    );
  }

  Widget _buildEmptyState(String title, String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: Colors.grey[400]),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
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
}
