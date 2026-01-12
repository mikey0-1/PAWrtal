import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/clinic_settings_model.dart';
import 'package:capstone_app/data/models/notification_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:capstone_app/mobile/user/components/pets_components/pets_controller.dart';
import 'package:capstone_app/mobile/user/components/appointment_tabs/components/user_appointment_controller.dart';
import 'dart:async';
import 'package:appwrite/appwrite.dart';
import 'package:capstone_app/data/provider/appwrite_provider.dart';
import '../../../data/models/appointment_model.dart';

class ScheduleAppointment extends StatefulWidget {
  final Clinic clinic;
  final ClinicSettings? clinicSettings;

  const ScheduleAppointment({
    super.key,
    required this.clinic,
    this.clinicSettings,
  });

  @override
  State<ScheduleAppointment> createState() => _ScheduleAppointmentState();
}

class _ScheduleAppointmentState extends State<ScheduleAppointment> {
  DateTime today = DateTime.now();
  String? selectedTime;
  String? selectedService;
  String? selectedPet;
  bool isBooking = false;
  List<String> availableTimeSlots = [];
  List<String> occupiedTimeSlots = [];
  StreamSubscription<RealtimeMessage>? _appointmentSubscription;
  String? _clinicProfilePictureUrl;
  bool _isLoadingClinicImage = true;

  PetsController? petsController;

  @override
  void initState() {
    super.initState();
    _fetchClinicImage(); // ADD THIS LINE
    _initializePetsController();
    _setupRealtimeSubscription();
    _fetchOccupiedSlots();

    // Auto-select today's date after initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoSelectTodayIfNeeded();
    });

    // Add focus listener to refresh pets when page regains focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final focusNode = FocusNode();
      focusNode.addListener(() {
        if (focusNode.hasFocus) {
          petsController?.fetchUserPets();
        }
      });
      FocusScope.of(context).requestFocus(focusNode);
    });
  }

  @override
  void dispose() {
    _appointmentSubscription?.cancel();
    super.dispose();
  }

  void _setupRealtimeSubscription() {
    try {
      final clinicId = widget.clinic.documentId ?? '';
      if (clinicId.isEmpty) return;

      _appointmentSubscription = Get.find<AuthRepository>()
          .subscribeToClinicAppointments(clinicId)
          .listen((message) {
        // When an appointment is created, updated, or deleted, refresh time slots
        _fetchOccupiedSlots();
      });
    } catch (e) {}
  }

  void _autoSelectTodayIfNeeded() {
    final todayDate = DateTime.now();

    // Check if today is selectable
    if (_isDateSelectable(todayDate)) {
      setState(() {
        today = todayDate;
      });
      _updateAvailableTimeSlots();
    }
  }

  Future<void> _fetchOccupiedSlots() async {
    try {
      final clinicId = widget.clinic.documentId ?? '';
      if (clinicId.isEmpty) return;

      final slots = await Get.find<AuthRepository>()
          .getOccupiedTimeSlots(clinicId, today);

      setState(() {
        occupiedTimeSlots = slots;
      });
      _updateAvailableTimeSlots();
    } catch (e) {}
  }

  void _onDaySelected(DateTime day, DateTime focusedDay) {
    if (_isDateSelectable(day)) {
      setState(() {
        today = day;
        selectedTime = null;
      });
      _fetchOccupiedSlots(); // Fetch occupied slots for new date
    }
  }

  void _updateAvailableTimeSlots() {
    List<String> slots = [];

    if (widget.clinicSettings != null) {
      // Get slots from clinic settings (these should already be in 12-hour format)
      slots = widget.clinicSettings!.getAvailableTimeSlots(today);
    } else {
      // Fallback slots in 12-hour format
      slots = [
        '09:00 AM',
        '10:00 AM',
        '11:00 AM',
        '01:00 PM',
        '02:00 PM',
        '03:00 PM',
        '04:00 PM',
      ];
    }

    // Filter out past time slots if today
    if (_isToday(today)) {
      slots = _filterPastTimeSlots(slots);
    }

    // Filter out occupied time slots
    final filteredSlots = slots.where((slot) {
      final isOccupied = occupiedTimeSlots.contains(slot);
      if (isOccupied) {}
      return !isOccupied;
    }).toList();

    setState(() {
      availableTimeSlots = filteredSlots;
      if (selectedTime != null && !filteredSlots.contains(selectedTime)) {
        selectedTime = null;
      }
    });
  }

  void _initializePetsController() {
    if (!Get.isRegistered<PetsController>()) {
      petsController = Get.put(
        PetsController(
          authRepository: Get.find(),
          session: Get.find(),
        ),
      );
    } else {
      petsController = Get.find();
    }

    // Always refresh pets when page is initialized
    petsController?.fetchUserPets();
  }

  List<String> get services {
    // Use services from clinic settings first, then fallback to clinic.services
    if (widget.clinicSettings != null &&
        widget.clinicSettings!.services.isNotEmpty) {
      return widget.clinicSettings!.services;
    }

    if (widget.clinic.services.isEmpty) {
      return ['General Consultation', 'Vaccination', 'Check-up', 'Grooming'];
    }
    return widget.clinic.services.split(',').map((s) => s.trim()).toList();
  }

  bool _isDateSelectable(DateTime day) {
    // Check if date is in the past
    if (day.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      return false;
    }

    // Check if clinic settings allow this date
    if (widget.clinicSettings != null) {
      // Check if clinic is open
      if (!widget.clinicSettings!.isOpen) {
        return false;
      }

      // Check max advance booking
      final maxAdvanceDate = DateTime.now()
          .add(Duration(days: widget.clinicSettings!.maxAdvanceBooking));
      if (day.isAfter(maxAdvanceDate)) {
        return false;
      }

      // Check if clinic is open on this day
      final dayName = _getDayName(day.weekday);
      final daySchedule = widget.clinicSettings!.operatingHours[dayName];
      if (daySchedule?['isOpen'] != true) {
        return false;
      }
    }

    return true;
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'monday';
      case 2:
        return 'tuesday';
      case 3:
        return 'wednesday';
      case 4:
        return 'thursday';
      case 5:
        return 'friday';
      case 6:
        return 'saturday';
      case 7:
        return 'sunday';
      default:
        return 'monday';
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  List<String> _filterPastTimeSlots(List<String> timeSlots) {
    final now = DateTime.now();

    return timeSlots.where((timeSlot) {
      try {
        final slotDateTime = parseTimeStringToDateTime(today, timeSlot);
        // Add a 30-minute buffer - don't allow booking slots that start within 30 minutes
        return slotDateTime.isAfter(now.add(const Duration(minutes: 30)));
      } catch (e) {
        // If parsing fails, include the slot (better to be permissive)
        return true;
      }
    }).toList();
  }

  DateTime parseTimeStringToDateTime(DateTime date, String timeString) {
    try {
      // Handle 12-hour format (e.g., "09:00 AM" or "02:30 PM")
      if (timeString.contains('AM') || timeString.contains('PM')) {
        final parts = timeString.trim().split(' ');
        final timeParts = parts[0].split(':');
        int hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        final period = parts[1].toUpperCase();

        if (period == 'PM' && hour != 12) {
          hour += 12;
        } else if (period == 'AM' && hour == 12) {
          hour = 0;
        }

        return DateTime(date.year, date.month, date.day, hour, minute);
      }
      // Handle 24-hour format (e.g., "09:00" or "14:30")
      else {
        final timeParts = timeString.split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        return DateTime(date.year, date.month, date.day, hour, minute);
      }
    } catch (e) {
      // Fallback: return current date with 9 AM
      return DateTime(date.year, date.month, date.day, 9, 0);
    }
  }

  Future<void> _bookAppointment() async {
    if (selectedPet == null ||
        selectedService == null ||
        selectedTime == null) {
      _showSnackBar("Please complete all fields", isError: true);
      return;
    }

    final userId = Get.find<UserSessionService>().userId;
    if (userId.isEmpty) {
      _showSnackBar("User not logged in", isError: true);
      return;
    }

    // Check if clinic is accepting appointments
    if (widget.clinicSettings != null && !widget.clinicSettings!.isOpen) {
      _showSnackBar("This clinic is currently not accepting appointments",
          isError: true);
      return;
    }

    // Show confirmation dialog
    _showBookingConfirmation();
  }

  void _showBookingConfirmation() {
    // Format date
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final formattedDate =
        '${months[today.month - 1]} ${today.day}, ${today.year}';

    // Get selected pet object
    final selectedPetObj = petsController?.pets.firstWhere(
      (pet) => pet.name == selectedPet,
      orElse: () => petsController!.pets.first,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // Get screen dimensions
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;

        // Determine if we're on a small device
        final isCompact = screenHeight < 650 || screenWidth < 360;
        final isVerySmall = screenHeight < 600;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 500,
              maxHeight: screenHeight * 0.9, // Use 90% of screen height
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient background
                Container(
                  padding: EdgeInsets.all(isCompact ? 14 : 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color.fromARGB(255, 81, 115, 153),
                        const Color.fromARGB(255, 81, 115, 153)
                            .withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isCompact ? 8 : 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.calendar_month,
                          color: Colors.white,
                          size: isCompact ? 20 : 24,
                        ),
                      ),
                      SizedBox(width: isCompact ? 10 : 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Confirm Appointment',
                              style: GoogleFonts.inter(
                                fontSize: isCompact ? 16 : 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (!isVerySmall) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Review your booking details',
                                style: GoogleFonts.inter(
                                  fontSize: isCompact ? 11 : 13,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content - Made scrollable
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isCompact ? 12 : 20),
                    child: Column(
                      children: [
                        // Clinic Section with Image
                        _buildMobileClinicSection(),

                        SizedBox(height: isCompact ? 10 : 16),

                        // Divider
                        Divider(color: Colors.grey[300], height: 1),

                        SizedBox(height: isCompact ? 10 : 16),

                        // Pet Section with Image
                        if (selectedPetObj != null)
                          _buildMobilePetSection(selectedPetObj),

                        SizedBox(height: isCompact ? 10 : 16),

                        // Service Card
                        _buildMobileInfoCard(
                          icon: Icons.medical_services,
                          iconColor: const Color.fromARGB(255, 81, 115, 153),
                          label: 'Service',
                          value: selectedService!,
                        ),

                        SizedBox(height: isCompact ? 8 : 10),

                        // Date and Time Cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildMobileInfoCard(
                                icon: Icons.calendar_today,
                                iconColor: Colors.orange,
                                label: 'Date',
                                value: formattedDate,
                              ),
                            ),
                            SizedBox(width: isCompact ? 8 : 10),
                            Expanded(
                              child: _buildMobileInfoCard(
                                icon: Icons.access_time,
                                iconColor: Colors.green,
                                label: 'Time',
                                value: selectedTime!,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Action Buttons
                Container(
                  padding: EdgeInsets.all(isCompact ? 10 : 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => _showCancelConfirmation(context),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                            padding: EdgeInsets.symmetric(
                                vertical: isCompact ? 10 : 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              fontSize: isCompact ? 13 : 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: isCompact ? 8 : 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            await _confirmBookAppointment();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 81, 115, 153),
                            padding: EdgeInsets.symmetric(
                                vertical: isCompact ? 10 : 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle,
                                  size: isCompact ? 16 : 18),
                              SizedBox(width: isCompact ? 4 : 6),
                              Text(
                                'Confirm',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: isCompact ? 13 : 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileClinicSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Clinic image
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _buildMobileClinicImage(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Veterinary Clinic',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.clinic.clinicName,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: Colors.grey[900],
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobilePetSection(dynamic pet) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Row(
        children: [
          // Pet image
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blue[200]!, width: 2),
            ),
            child: ClipOval(
              child: pet.image != null && pet.image!.isNotEmpty
                  ? Image.network(
                      pet.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.pets,
                            color: Colors.blue[300], size: 24);
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                    )
                  : Icon(Icons.pets, color: Colors.blue[300], size: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Pet',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  pet.name,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: Colors.grey[900],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${pet.type} • ${pet.breed}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileInfoCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey[900],
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelConfirmation(BuildContext parentContext) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: EdgeInsets.zero,
          content: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange[700],
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Cancel Booking?',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Are you sure you want to cancel this appointment booking?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: Text(
                          'Go Back',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(parentContext).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Yes, Cancel',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmBookAppointment() async {
    setState(() {
      isBooking = true;
    });

    try {
      final userId = Get.find<UserSessionService>().userId;
      final selectedDateTime = parseTimeStringToDateTime(today, selectedTime!);

      final appointment = Appointment(
        userId: userId,
        clinicId: widget.clinic.documentId ?? '',
        petId: selectedPet!,
        service: selectedService!,
        dateTime: selectedDateTime,
        status: widget.clinicSettings?.autoAcceptAppointments == true
            ? 'accepted'
            : 'pending',
      );

      // Create appointment
      await Get.find<AuthRepository>().createAppointment(appointment);

      // Create notification for admin
      try {
        final clinicDoc = await Get.find<AuthRepository>()
            .getClinicById(widget.clinic.documentId ?? '');

        if (clinicDoc != null) {
          final adminId = clinicDoc.data['adminId'] as String?;

          if (adminId != null && adminId.isNotEmpty) {
            final notification = AppNotification.appointmentBooked(
              adminId: adminId,
              appointmentId: '',
              clinicId: widget.clinic.documentId ?? '',
              petName: selectedPet!,
              ownerName: Get.find<UserSessionService>().userName,
              service: selectedService!,
              appointmentDateTime: appointment.dateTime,
            );

            await Get.find<AuthRepository>().createNotification(notification);
          }
        }
      } catch (e) {
        // Notification failure doesn't stop booking
      }

      // Notify admin of new appointment
      await _notifyAdminOfNewAppointment(appointment);

      // Refresh appointments if controller exists
      if (Get.isRegistered<EnhancedUserAppointmentController>()) {
        Get.find<EnhancedUserAppointmentController>().fetchAppointments();
      }

      // ADDED: Show success dialog (which will handle the reset)
      _showSuccessDialog();
    } catch (e) {
      _showSnackBar("Failed to book appointment: $e", isError: true);
    } finally {
      setState(() {
        isBooking = false;
      });
    }
  }

  Future<void> _notifyAdminOfNewAppointment(Appointment appointment) async {
    try {
      // Get clinic admin ID
      final clinicDoc = await Get.find<AuthRepository>()
          .getClinicById(widget.clinic.documentId ?? '');

      if (clinicDoc == null) {
        return;
      }

      final adminId = clinicDoc.data['adminId'] as String?;
      if (adminId == null || adminId.isEmpty) {
        return;
      }

      // Get user details
      final userName = Get.find<UserSessionService>().userName;
      final petName = selectedPet ?? 'Unknown Pet';

      // Use AppwriteProvider to send notification
      final appwriteProvider = Get.find<AppWriteProvider>();

      await appwriteProvider.notifyAdminNewAppointment(
        adminId: adminId,
        petName: petName,
        ownerName: userName.isEmpty ? 'A user' : userName,
        service: appointment.service,
        appointmentDateTime: appointment.dateTime,
        appointmentId: '', // Will be empty for new appointments
      );
    } catch (e) {
      // Don't fail booking if notification fails
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessDialog() {
    final isAutoAccepted =
        widget.clinicSettings?.autoAcceptAppointments == true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Success!'),
          ],
        ),
        content: Text(isAutoAccepted
            ? 'Your appointment has been automatically confirmed!'
            : 'Your appointment has been booked successfully. You will receive a confirmation once the clinic reviews your request.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close success dialog
              Navigator.of(context).pop(); // Go back to previous screen
              // ADDED: Reset form for better UX when user returns
              _resetFormAfterBooking();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 81, 115, 153),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildTimeSlot(String time) {
    final isSelected = selectedTime == time;
    return GestureDetector(
      onTap: () => setState(() => selectedTime = time),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color.fromARGB(255, 81, 115, 153)
              : Colors.white,
          border: Border.all(
            color: isSelected
                ? const Color.fromARGB(255, 81, 115, 153)
                : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          time,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildClinicStatusBanner() {
    if (widget.clinicSettings == null) return const SizedBox.shrink();

    final settings = widget.clinicSettings!;
    if (settings.isOpen && settings.isOpenToday()) {
      return const SizedBox.shrink();
    }

    Color bannerColor;
    String bannerText;
    IconData bannerIcon;

    if (!settings.isOpen) {
      bannerColor = Colors.red;
      bannerText = 'This clinic is currently closed for appointments';
      bannerIcon = Icons.cancel;
    } else {
      bannerColor = Colors.orange;
      bannerText = 'This clinic is closed today';
      bannerIcon = Icons.schedule;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bannerColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(bannerIcon, color: bannerColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              bannerText,
              style: TextStyle(
                color: bannerColor,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canBookAppointments = widget.clinicSettings?.isOpen ?? true;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 81, 115, 153),
      body: Column(
        children: [
          // Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Book Appointment',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.clinic.clinicName,
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Clinic status banner
                    _buildClinicStatusBanner(),

                    if (canBookAppointments) ...[
                      // Calendar
                      _buildSectionTitle('Select Date'),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[200]!),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TableCalendar(
                          focusedDay: today,
                          firstDay: DateTime.now(),
                          lastDay: DateTime.now().add(Duration(
                            days:
                                widget.clinicSettings?.maxAdvanceBooking ?? 90,
                          )),
                          headerStyle: HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                            titleTextStyle: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          calendarStyle: CalendarStyle(
                            todayDecoration: BoxDecoration(
                              color: const Color.fromARGB(255, 81, 115, 153)
                                  .withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            selectedDecoration: const BoxDecoration(
                              color: Color.fromARGB(255, 81, 115, 153),
                              shape: BoxShape.circle,
                            ),
                            weekendTextStyle:
                                TextStyle(color: Colors.grey[600]),
                            outsideDaysVisible: false,
                            disabledTextStyle:
                                TextStyle(color: Colors.grey[400]),
                          ),
                          enabledDayPredicate: _isDateSelectable,
                          onDaySelected: _onDaySelected,
                          selectedDayPredicate: (day) => isSameDay(day, today),
                        ),
                      ),

                      // Time slots
                      _buildSectionTitle('Available Times'),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: availableTimeSlots.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.orange.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline,
                                        color: Colors.orange[700]),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                          'No available times for this date'),
                                    ),
                                  ],
                                ),
                              )
                            : Wrap(
                                children: availableTimeSlots
                                    .map(_buildTimeSlot)
                                    .toList(),
                              ),
                      ),

                      // Service selection
                      _buildSectionTitle('Select Service'),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: DropdownButtonFormField<String>(
                          value: selectedService,
                          decoration: InputDecoration(
                            hintText: 'Choose a service',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color.fromARGB(255, 81, 115, 153),
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          items: services
                              .map((service) => DropdownMenuItem(
                                    value: service,
                                    child: Text(service),
                                  ))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => selectedService = value),
                        ),
                      ),

                      // Pet selection
                      _buildSectionTitle('Select Pet'),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Obx(() {
                          if (petsController!.isLoading.value) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Loading pets...'),
                                ],
                              ),
                            );
                          }

                          if (petsController!.pets.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                  'No pets found. Please add a pet first.'),
                            );
                          }

                          return DropdownButtonFormField<String>(
                            value: selectedPet,
                            decoration: InputDecoration(
                              hintText: 'Choose your pet',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color.fromARGB(255, 81, 115, 153),
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            items: petsController!.pets
                                .map((pet) => DropdownMenuItem(
                                      value: pet.name,
                                      child: Row(
                                        children: [
                                          Icon(Icons.pets,
                                              size: 20,
                                              color: Colors.grey[600]),
                                          const SizedBox(width: 8),
                                          Text(pet.name),
                                        ],
                                      ),
                                    ))
                                .toList(),
                            onChanged: (value) =>
                                setState(() => selectedPet = value),
                          );
                        }),
                      ),

                      // Book button
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isBooking ? null : _bookAppointment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 81, 115, 153),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: isBooking
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Booking...',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    'Book Appointment',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ] else ...[
                      // Clinic closed message
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.cancel_outlined,
                                size: 64,
                                color: Colors.red[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Appointments Unavailable',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'This clinic is currently not accepting new appointments.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchClinicImage() async {
    if (!mounted) return;

    try {
      setState(() => _isLoadingClinicImage = true);

      if (widget.clinic.documentId == null ||
          widget.clinic.documentId!.isEmpty) {
        if (mounted) setState(() => _isLoadingClinicImage = false);
        return;
      }

      final authRepo = Get.find<AuthRepository>();
      final clinicId = widget.clinic.documentId!;

      // STEP 1: Get ClinicSettings
      final clinicSettings =
          await authRepo.getClinicSettingsByClinicId(clinicId);

      if (clinicSettings != null) {
      } else {}

      // STEP 2: Get Clinic document
      final clinicDoc = await authRepo.getClinicById(clinicId);

      if (clinicDoc != null) {
      } else {}

      if (!mounted) return;

      String? imageUrl;
      String? fileId;

      // PRIORITY 1: dashboardPic from ClinicSettings
      if (clinicSettings != null && clinicSettings.dashboardPic.isNotEmpty) {
        final dashboardPic = clinicSettings.dashboardPic.trim();

        // Extract file ID
        if (dashboardPic.contains('/files/')) {
          final parts = dashboardPic.split('/files/');
          fileId = parts.last.split('/').first.split('?').first;
        } else {
          fileId = dashboardPic;
        }

        imageUrl =
            'https://cloud.appwrite.io/v1/storage/buckets/${AppwriteConstants.imageBucketID}/files/$fileId/view?project=${AppwriteConstants.projectID}';
      }

      // PRIORITY 2: profilePictureId from Clinic
      if ((imageUrl == null || imageUrl.isEmpty) && clinicDoc != null) {
        final profilePictureId = clinicDoc.data['profilePictureId'] as String?;
        if (profilePictureId != null && profilePictureId.trim().isNotEmpty) {
          String cleanId = profilePictureId.trim();
          if (cleanId.contains('/files/')) {
            final parts = cleanId.split('/files/');
            fileId = parts.last.split('/').first.split('?').first;
          } else {
            fileId = cleanId;
          }

          imageUrl =
              'https://cloud.appwrite.io/v1/storage/buckets/${AppwriteConstants.imageBucketID}/files/$fileId/view?project=${AppwriteConstants.projectID}';
        }
      }

      // PRIORITY 3: image field from Clinic
      if ((imageUrl == null || imageUrl.isEmpty) && clinicDoc != null) {
        final image = clinicDoc.data['image'] as String?;
        if (image != null && image.trim().isNotEmpty) {
          String cleanId = image.trim();
          if (cleanId.contains('/files/')) {
            final parts = cleanId.split('/files/');
            fileId = parts.last.split('/').first.split('?').first;
          } else {
            fileId = cleanId;
          }

          imageUrl =
              'https://cloud.appwrite.io/v1/storage/buckets/${AppwriteConstants.imageBucketID}/files/$fileId/view?project=${AppwriteConstants.projectID}';
        }
      }

      // FINAL RESULT
      if (imageUrl == null || imageUrl.isEmpty) {
      } else {}

      if (mounted) {
        setState(() {
          _clinicProfilePictureUrl = imageUrl;
          _isLoadingClinicImage = false;
        });
      }
    } catch (e, stackTrace) {
      if (mounted) setState(() => _isLoadingClinicImage = false);
    }
  }

  Widget _buildMobileClinicImage() {
    if (_isLoadingClinicImage) {
      return Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.grey[400],
          ),
        ),
      );
    }

    if (_clinicProfilePictureUrl != null &&
        _clinicProfilePictureUrl!.isNotEmpty) {
      return Image.network(
        _clinicProfilePictureUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildMobileDefaultIcon();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      );
    }

    return _buildMobileDefaultIcon();
  }

  Widget _buildMobileDefaultIcon() {
    return Icon(
      Icons.local_hospital,
      color: Colors.grey[400],
      size: 24,
    );
  }

  void _resetFormAfterBooking() {
    setState(() {
      selectedTime = null;
      selectedService = null;
      selectedPet = null;
    });

    // Re-select today's date if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoSelectTodayIfNeeded();
    });
  }
}
