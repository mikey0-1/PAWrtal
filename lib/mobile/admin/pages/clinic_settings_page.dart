import 'package:capstone_app/mobile/admin/controllers/clinic_settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class ClinicSettingsPage extends StatefulWidget {
  const ClinicSettingsPage({super.key});

  @override
  State<ClinicSettingsPage> createState() => _ClinicSettingsPageState();
}

class _ClinicSettingsPageState extends State<ClinicSettingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final controller = Get.put(ClinicSettingsController());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Clinic Settings',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF608BC1),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF608BC1)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF608BC1),
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: const Color(0xFF608BC1),
          labelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          tabs: const [
            Tab(text: 'General'),
            Tab(text: 'Hours'),
            Tab(text: 'Gallery'),
            Tab(text: 'Location'),
          ],
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF608BC1)),
          );
        }

        return TabBarView(
          controller: _tabController,
          children: [
            _buildGeneralTab(),
            _buildHoursTab(),
            _buildGalleryTab(),
            _buildLocationTab(),
          ],
        );
      }),
      floatingActionButton: Obx(
        () => controller.hasUnsavedChanges.value
            ? FloatingActionButton.extended(
                onPressed: () => controller.saveSettings(),
                backgroundColor: const Color(0xFF608BC1),
                icon: const Icon(Icons.save, color: Colors.white),
                label: Text(
                  'Save Changes',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildGeneralTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Clinic Status Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 0,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.business,
                      color: Color(0xFF608BC1),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Clinic Status',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Obx(() {
                  final isOpen = controller.isOpen.value;
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isOpen
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isOpen
                            ? Colors.green.withOpacity(0.3)
                            : Colors.red.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isOpen ? Icons.check_circle : Icons.cancel,
                          color: isOpen ? Colors.green : Colors.red,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isOpen ? 'Clinic is Open' : 'Clinic is Closed',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isOpen
                                      ? Colors.green[700]
                                      : Colors.red[700],
                                ),
                              ),
                              Text(
                                isOpen
                                    ? 'Accepting new appointments'
                                    : 'Not accepting appointments',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: isOpen,
                          onChanged: (value) =>
                              controller.toggleClinicStatus(value),
                          activeColor: Colors.green,
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Appointment Settings
          _buildSettingsSection(
            title: 'Appointment Settings',
            icon: Icons.schedule,
            children: [
              _buildNumberSetting(
                label: 'Appointment Duration (minutes)',
                value: controller.appointmentDuration,
                min: 15,
                max: 120,
                step: 15,
              ),
              const SizedBox(height: 16),
              _buildNumberSetting(
                label: 'Max Advance Booking (days)',
                value: controller.maxAdvanceBooking,
                min: 1,
                max: 365,
                step: 1,
              ),
              const SizedBox(height: 16),
              // Obx(() => SwitchListTile(
              //       title: Text(
              //         'Auto-accept Appointments',
              //         style: GoogleFonts.inter(
              //           fontWeight: FontWeight.w500,
              //           color: Colors.grey[800],
              //         ),
              //       ),
              //       subtitle: Text(
              //         'Automatically approve new appointments',
              //         style: GoogleFonts.inter(
              //           fontSize: 12,
              //           color: Colors.grey[600],
              //         ),
              //       ),
              //       value: controller.autoAccept.value,
              //       onChanged: (value) => controller.autoAccept.value = value,
              //       activeColor: const Color(0xFF608BC1),
              //       contentPadding: EdgeInsets.zero,
              //     )),
            ],
          ),

          const SizedBox(height: 20),

          // Services
          _buildSettingsSection(
            title: 'Services Offered',
            icon: Icons.medical_services,
            children: [
              _buildTextAreaField(
                label: 'Services',
                controller: controller.servicesController,
                hintText: 'List the services your clinic offers...',
                maxLines: 4,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Contact Information
          _buildSettingsSection(
            title: 'Contact Information',
            icon: Icons.contact_phone,
            children: [
              _buildTextField(
                label: 'Emergency Contact',
                controller: controller.emergencyContactController,
                hintText: 'Emergency phone number',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              _buildTextAreaField(
                label: 'Special Instructions',
                controller: controller.specialInstructionsController,
                hintText: 'Any special instructions for patients...',
                maxLines: 3,
              ),
            ],
          ),

          const SizedBox(height: 100), // Bottom padding for FAB
        ],
      ),
    );
  }

  Widget _buildHoursTab() {
    final days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Operating Hours',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set your clinic\'s operating hours for each day',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),

          ...days.map((day) => _buildDaySchedule(day)),

          const SizedBox(height: 100), // Bottom padding for FAB
        ],
      ),
    );
  }

  Widget _buildDaySchedule(String day) {
    final dayName = day[0].toUpperCase() + day.substring(1);

    return Obx(() {
      final dayData = controller.operatingHours[day];
      final isOpen = dayData?['isOpen'] ?? false;

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    dayName,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                Switch(
                  value: isOpen,
                  onChanged: (value) => controller.toggleDayStatus(day, value),
                  activeColor: const Color(0xFF608BC1),
                ),
              ],
            ),
            if (isOpen) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTimeField(
                      label: 'Open Time',
                      value: dayData?['openTime'] ?? '09:00',
                      onChanged: (time) =>
                          controller.updateDayTime(day, 'openTime', time),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTimeField(
                      label: 'Close Time',
                      value: dayData?['closeTime'] ?? '17:00',
                      onChanged: (time) =>
                          controller.updateDayTime(day, 'closeTime', time),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildGalleryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
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
                    'Clinic Gallery',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  Text(
                    'Upload photos of your clinic',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => controller.pickImages(),
                icon: const Icon(Icons.add_photo_alternate, size: 20),
                label: const Text('Add Photos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF608BC1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Obx(() {
            if (controller.gallery.isEmpty) {
              return _buildEmptyGallery();
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: controller.gallery.length,
              itemBuilder: (context, index) {
                final imageId = controller.gallery[index];
                return _buildGalleryItem(imageId, index);
              },
            );
          }),

          const SizedBox(height: 100), // Bottom padding for FAB
        ],
      ),
    );
  }

  Widget _buildLocationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Clinic Location',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set your clinic\'s location on the map',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),

          // Location input fields
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: 'Latitude',
                  controller: controller.latController,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  label: 'Longitude',
                  controller: controller.lngController,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Map placeholder
          Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Interactive Map',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Coming Soon',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement location picker
              Get.snackbar(
                'Coming Soon',
                'Map location picker will be available soon',
                backgroundColor: Colors.blue,
                colorText: Colors.white,
              );
            },
            icon: const Icon(Icons.my_location),
            label: const Text('Use Current Location'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF608BC1),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 100), // Bottom padding for FAB
        ],
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF608BC1), size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF608BC1)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextAreaField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    int maxLines = 3,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF608BC1)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberSetting({
    required String label,
    required RxInt value,
    required int min,
    required int max,
    required int step,
  }) {
    return Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  '${value.value}',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF608BC1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: value.value > min
                      ? () => value.value = (value.value - step).clamp(min, max)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: const Color(0xFF608BC1),
                ),
                Expanded(
                  child: Slider(
                    value: value.value.toDouble(),
                    min: min.toDouble(),
                    max: max.toDouble(),
                    divisions: ((max - min) / step).round(),
                    activeColor: const Color(0xFF608BC1),
                    onChanged: (newValue) {
                      value.value =
                          ((newValue / step).round() * step).clamp(min, max);
                    },
                  ),
                ),
                IconButton(
                  onPressed: value.value < max
                      ? () => value.value = (value.value + step).clamp(min, max)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                  color: const Color(0xFF608BC1),
                ),
              ],
            ),
          ],
        ));
  }

  Widget _buildTimeField({
    required String label,
    required String value,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () async {
            final TimeOfDay? picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay(
                hour: int.parse(value.split(':')[0]),
                minute: int.parse(value.split(':')[1]),
              ),
            );
            if (picked != null) {
              final formattedTime =
                  '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
              onChanged(formattedTime);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                Icon(
                  Icons.access_time,
                  color: Colors.grey[500],
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyGallery() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[300]!,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'No photos added yet',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add photos to showcase your clinic',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryItem(String imageId, int index) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 0,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Image with better error handling
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.grey[200],
              child: _buildDebugImage(imageId),
            ),
            // Delete button
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => controller.removeImage(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
            // Debug info overlay (temporary)
            // Positioned(
            //   bottom: 0,
            //   left: 0,
            //   right: 0,
            //   child: Container(
            //     padding: const EdgeInsets.all(4),
            //     decoration: BoxDecoration(
            //       color: Colors.black.withOpacity(0.7),
            //       borderRadius: const BorderRadius.only(
            //         bottomLeft: Radius.circular(12),
            //         bottomRight: Radius.circular(12),
            //       ),
            //     ),
            //     child: Text(
            //       imageId,
            //       style: const TextStyle(
            //         color: Colors.white,
            //         fontSize: 8,
            //       ),
            //       maxLines: 1,
            //       overflow: TextOverflow.ellipsis,
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugImage(String imageId) {
    final url = controller.getImageUrl(imageId);

    return Column(
      children: [
        Expanded(
          child: Image.network(
            url,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  color: const Color(0xFF608BC1),
                ),
              );
            },
            // errorBuilder: (context, error, stackTrace) {
            //   print('Image loading error for $imageId: $error');
            //   print('URL: $url');
            //   print('Stack trace: $stackTrace');

            //   return Container(
            //     color: Colors.grey[300],
            //     child: Column(
            //       mainAxisAlignment: MainAxisAlignment.center,
            //       children: [
            //         Icon(
            //           Icons.broken_image,
            //           color: Colors.grey[500],
            //           size: 32,
            //         ),
            //         const SizedBox(height: 4),
            //         Text(
            //           'Failed to load',
            //           style: GoogleFonts.inter(
            //             fontSize: 10,
            //             color: Colors.grey[600],
            //           ),
            //         ),
            //         // Show error details (remove this in production)
            //         Padding(
            //           padding: const EdgeInsets.all(4),
            //           child: Text(
            //             error.toString(),
            //             style: GoogleFonts.inter(
            //               fontSize: 6,
            //               color: Colors.red[600],
            //             ),
            //             textAlign: TextAlign.center,
            //             maxLines: 2,
            //             overflow: TextOverflow.ellipsis,
            //           ),
            //         ),
            //       ],
            //     ),
            //   );
            // },
          ),
        ),
      ],
    );
  }
}
