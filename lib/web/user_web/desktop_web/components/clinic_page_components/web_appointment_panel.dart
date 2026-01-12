import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:capstone_app/web/user_web/controllers/user_web_appointment_controller.dart';

class EnhancedWebAppointmentPanel extends StatefulWidget {
  final Clinic clinic;
  final double? maxHeight;
  final bool compact;

  const EnhancedWebAppointmentPanel({
    super.key,
    required this.clinic,
    this.maxHeight,
    this.compact = false,
  });

  @override
  State<EnhancedWebAppointmentPanel> createState() =>
      _EnhancedWebAppointmentPanelState();
}

class _EnhancedWebAppointmentPanelState
    extends State<EnhancedWebAppointmentPanel> {
  late WebAppointmentController controller;

  String? _clinicProfilePictureUrl;
  bool _isLoadingClinicImage = true;

  @override
  void initState() {
    super.initState();
    _fetchClinicImage(); // ADD THIS LINE
    if (!Get.isRegistered<WebAppointmentController>(
        tag: widget.clinic.documentId)) {
      controller = Get.put(
        WebAppointmentController(
          authRepository: Get.find<AuthRepository>(),
          session: Get.find<UserSessionService>(),
          clinic: widget.clinic,
        ),
        tag: widget.clinic.documentId,
      );
    } else {
      controller =
          Get.find<WebAppointmentController>(tag: widget.clinic.documentId);
    }

    // Auto-select today's date after the controller is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoSelectTodayIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCalendarSection(),
        const SizedBox(height: 32),
        _buildDetailsSection(),
        const SizedBox(height: 32),
        _buildPetSection(),
        const SizedBox(height: 32),
        _buildBookButton(),
      ],
    );
  }

  Widget _buildCalendarSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Date',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        Obx(() {
          // Get closed dates from controller
          final closedDates = controller.closedDates.toSet();

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[200]!),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TableCalendar(
                  focusedDay:
                      controller.selectedDateTime.value ?? DateTime.now(),
                  firstDay: DateTime.now(),
                  lastDay: DateTime.now().add(Duration(
                    days: controller.clinicSettings.value?.maxAdvanceBooking ??
                        30,
                  )),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.grey[800],
                    ),
                    leftChevronIcon: Icon(Icons.chevron_left,
                        color: Colors.grey[600], size: 24),
                    rightChevronIcon: Icon(Icons.chevron_right,
                        color: Colors.grey[600], size: 24),
                  ),
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: const Color(0xFF5173B8).withOpacity(0.6),
                      border: Border.all(color: Color(0xFF5173B8)),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: Color(0xFF5173B8),
                      shape: BoxShape.circle,
                    ),
                    weekendTextStyle: TextStyle(color: Colors.grey[600]),
                    outsideDaysVisible: false,
                    cellMargin: const EdgeInsets.all(4),
                    disabledTextStyle: TextStyle(color: Colors.grey[400]),
                    defaultTextStyle: const TextStyle(fontSize: 14),
                  ),
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) {
                      final dateStr =
                          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

                      if (closedDates.contains(dateStr)) {
                        // Show closed dates with red background
                        return Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            border: Border.all(color: Colors.red[200]!),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              color: Colors.red[400],
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        );
                      }
                      return null;
                    },
                    disabledBuilder: (context, day, focusedDay) {
                      final dateStr =
                          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

                      if (closedDates.contains(dateStr)) {
                        // Show closed dates with red background even if disabled
                        return Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            border: Border.all(color: Colors.red[200]!),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              color: Colors.red[300],
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        );
                      }
                      return null;
                    },
                  ),
                  daysOfWeekStyle: const DaysOfWeekStyle(
                    weekdayStyle:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    weekendStyle:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  enabledDayPredicate: controller.isDateSelectable,
                  onDaySelected: (selectedDay, focusedDay) {
                    if (controller.isDateSelectable(selectedDay)) {
                      controller.onDateSelected(selectedDay);
                    } else {
                      // Check if it's a closed date
                      final dateStr =
                          '${selectedDay.year}-${selectedDay.month.toString().padLeft(2, '0')}-${selectedDay.day.toString().padLeft(2, '0')}';
                      if (closedDates.contains(dateStr)) {
                        _showClosedDateMessage();
                      }
                    }
                  },
                  selectedDayPredicate: (day) =>
                      isSameDay(day, controller.selectedDateTime.value),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Appointment Details',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTimeSelector()),
            const SizedBox(width: 16),
            Expanded(child: _buildServiceSelector()),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Obx(() => Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: controller.selectedTime.value,
                  hint: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, size: 20),
                        SizedBox(width: 8),
                        Text('Select time', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                  isExpanded: true,
                  items: controller.availableTimes.map((time) {
                    return DropdownMenuItem<String>(
                      value: time,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            const SizedBox(width: 8),
                            Text(time, style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: controller.availableTimes.isEmpty
                      ? null
                      : controller.onTimeSelected,
                ),
              ),
            )),
        Obx(() {
          if (controller.selectedDateTime.value != null &&
              controller.availableTimes.isEmpty &&
              controller.clinicSettings.value != null) {
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'No available times for this date',
                style: TextStyle(fontSize: 12, color: Colors.red[600]),
              ),
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  Widget _buildServiceSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Service',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Obx(() => Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: controller.selectedService.value,
                  hint: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child:
                        Text('Choose service', style: TextStyle(fontSize: 14)),
                  ),
                  isExpanded: true,
                  items: controller.services.map((service) {
                    return DropdownMenuItem<String>(
                      value: service,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          service,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: controller.onServiceSelected,
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildPetSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Pet',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        Obx(() {
          if (controller.isLoading.value) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Loading pets...', style: TextStyle(fontSize: 14)),
                ],
              ),
            );
          }

          if (controller.pets.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.orange[300]!),
                borderRadius: BorderRadius.circular(8),
                color: Colors.orange[50],
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[600], size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'No pets found. Please add a pet to your profile first.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            );
          }

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Pet>(
                value: controller.selectedPet.value,
                hint: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.pets, size: 20),
                      SizedBox(width: 12),
                      Text('Choose your pet', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
                isExpanded: true,
                items: controller.pets.map((pet) {
                  return DropdownMenuItem<Pet>(
                    value: pet,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.grey[200],
                            backgroundImage:
                                pet.image != null && pet.image!.isNotEmpty
                                    ? NetworkImage(pet.image!)
                                    : null,
                            child: pet.image == null || pet.image!.isEmpty
                                ? const Icon(Icons.pets, size: 16)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  pet.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${pet.type} • ${pet.breed}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                onChanged: controller.onPetSelected,
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBookButton() {
    return Obx(() {
      final validationMessage = controller.bookingValidationMessage;
      final isEnabled = controller.canBookAppointment;

      return Column(
        children: [
          if (validationMessage != null && !controller.isBooking.value)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      validationMessage,
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isEnabled ? _showBookingConfirmation : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isEnabled ? const Color(0xFF5173B8) : Colors.grey[300],
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: isEnabled ? 2 : 0,
              ),
              child: controller.isBooking.value
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
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
                        color: isEnabled ? Colors.white : Colors.grey[600],
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      );
    });
  }

  void _showClosedDateMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.event_busy, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'This clinic is closed on the selected date. Please choose another day.',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showBookingConfirmation() {
    final selectedDate = controller.selectedDateTime.value;
    final selectedTime = controller.selectedTime.value;
    final selectedService = controller.selectedService.value;
    final selectedPet = controller.selectedPet.value;

    if (selectedDate == null ||
        selectedTime == null ||
        selectedService == null ||
        selectedPet == null) {
      return;
    }

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
        '${months[selectedDate.month - 1]} ${selectedDate.day}, ${selectedDate.year}';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // Get screen dimensions
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;

        // Calculate responsive dimensions
        final dialogWidth = screenWidth > 500 ? 480.0 : screenWidth * 0.9;
        final isCompact = screenHeight < 700 || screenWidth < 400;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: dialogWidth,
            constraints: BoxConstraints(
              maxWidth: 500,
              maxHeight: screenHeight * 0.85, // Limit to 85% of screen height
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient background
                Container(
                  padding: EdgeInsets.all(isCompact ? 16 : 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF5173B8),
                        const Color(0xFF5173B8).withOpacity(0.8),
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
                        padding: EdgeInsets.all(isCompact ? 8 : 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.calendar_month,
                          color: Colors.white,
                          size: isCompact ? 22 : 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Confirm Appointment',
                              style: GoogleFonts.inter(
                                fontSize: isCompact ? 18 : 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: isCompact ? 2 : 4),
                            Text(
                              'Review your booking details',
                              style: GoogleFonts.inter(
                                fontSize: isCompact ? 12 : 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content - Make scrollable
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isCompact ? 16 : 24),
                    child: Column(
                      children: [
                        // Clinic Section with Image
                        _buildClinicSection(),

                        SizedBox(height: isCompact ? 12 : 20),

                        // Divider
                        Divider(color: Colors.grey[300], height: 1),

                        SizedBox(height: isCompact ? 12 : 20),

                        // Pet Section with Image
                        _buildDisplayPetSection(selectedPet),

                        SizedBox(height: isCompact ? 12 : 20),

                        // Service, Date, and Time in Cards
                        _buildInfoCard(
                          icon: Icons.medical_services,
                          iconColor: const Color(0xFF5173B8),
                          label: 'Service',
                          value: selectedService,
                        ),

                        SizedBox(height: isCompact ? 8 : 12),

                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoCard(
                                icon: Icons.calendar_today,
                                iconColor: Colors.orange,
                                label: 'Date',
                                value: formattedDate,
                              ),
                            ),
                            SizedBox(width: isCompact ? 8 : 12),
                            Expanded(
                              child: _buildInfoCard(
                                icon: Icons.access_time,
                                iconColor: Colors.green,
                                label: 'Time',
                                value: selectedTime,
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
                  padding: EdgeInsets.all(isCompact ? 12 : 20),
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
                                vertical: isCompact ? 12 : 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              fontSize: isCompact ? 14 : 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: isCompact ? 8 : 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            await controller.bookAppointment();
                            _resetFormAfterBooking();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5173B8),
                            padding: EdgeInsets.symmetric(
                                vertical: isCompact ? 12 : 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle,
                                  size: isCompact ? 16 : 20),
                              SizedBox(width: isCompact ? 6 : 8),
                              Text(
                                'Confirm Booking',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: isCompact ? 14 : 16,
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
            width: 360,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange[700],
                    size: 48,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Cancel Booking?',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to cancel this appointment booking? This action cannot be undone.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: Text(
                          'Go Back',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(parentContext).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Yes, Cancel',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 15,
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

  Widget _buildClinicSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Clinic image with proper error handling
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildClinicImage(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Veterinary Clinic',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.clinic.clinicName,
                  style: GoogleFonts.inter(
                    fontSize: 16,
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

  Widget _buildDisplayPetSection(Pet pet) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Row(
        children: [
          // Pet image
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blue[200]!, width: 2),
              image: pet.image != null && pet.image!.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(pet.image!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: pet.image == null || pet.image!.isEmpty
                ? Icon(Icons.pets, color: Colors.blue[300], size: 28)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Pet',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pet.name,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.grey[900],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${pet.type} • ${pet.breed}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
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

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
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

  void _autoSelectTodayIfNeeded() {
    // Only auto-select if no date is currently selected
    if (controller.selectedDateTime.value == null) {
      final today = DateTime.now();

      // Check if today is selectable (not closed, within business hours, etc.)
      if (controller.isDateSelectable(today)) {
        controller.onDateSelected(today);
      }
    }
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

  Widget _buildClinicImage() {
    if (_isLoadingClinicImage) {
      return Center(
        child: SizedBox(
          width: 24,
          height: 24,
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
          return _buildDefaultClinicIcon();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return Center(
            child: SizedBox(
              width: 20,
              height: 20,
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

    return _buildDefaultClinicIcon();
  }

  Widget _buildDefaultClinicIcon() {
    return Icon(
      Icons.local_hospital,
      color: Colors.grey[400],
      size: 28,
    );
  }

  void _resetFormAfterBooking() {
    // Clear selections
    controller.selectedTime.value = null;
    controller.selectedService.value = null;
    controller.selectedPet.value = null;

    // Re-select today's date if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoSelectTodayIfNeeded();
    });
  }
}
