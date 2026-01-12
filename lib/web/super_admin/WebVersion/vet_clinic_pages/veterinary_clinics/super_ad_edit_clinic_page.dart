import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/clinic_settings_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';

class SuperAdminEditClinicPage extends StatefulWidget {
  final Clinic clinic;
  final ClinicSettings? settings;

  const SuperAdminEditClinicPage({
    super.key,
    required this.clinic,
    this.settings,
  });

  @override
  State<SuperAdminEditClinicPage> createState() =>
      _SuperAdminEditClinicPageState();
}

class _SuperAdminEditClinicPageState extends State<SuperAdminEditClinicPage>
    with TickerProviderStateMixin {
  final AuthRepository authRepository = Get.find<AuthRepository>();
  late TabController _tabController;

  // Controllers for basic info
  late TextEditingController clinicNameController;
  late TextEditingController addressController;
  late TextEditingController contactController;
  late TextEditingController emailController;
  late TextEditingController descriptionController;

  // Settings controllers
  late TextEditingController emergencyContactController;
  late TextEditingController specialInstructionsController;

  bool isSaving = false;
  bool isLoadingImage = false;
  String? newMainImageId;
  List<String> galleryImages = [];
  List<String> removedGalleryImages = [];
  List<String> clinicServices = [];
  Map<String, bool> medicalServices = {};

  // Services
  List<String> selectedServices = [];
  final List<String> availableServices = [
    'General Checkup',
    'Vaccination',
    'Surgery',
    'Dental Care',
    'Emergency Care',
    'Laboratory Tests',
    'Microchipping',
    'Spay/Neuter',
    'X-Ray Imaging',
    'Ultrasound',
    'Blood Work',
    'Behavioral Consultation',
    'Nutritional Counseling',
    'Parasite Treatment',
    'Wound Care',
    'Prescription Medications',
    'Health Certificates',
  ];

  bool _isServiceMedicalByDefault(String service) {
    // Define which services are medical by default
    final List<String> medicalServicesList = [
      'General Checkup',
      'Vaccination',
      'Surgery',
      'Dental Care',
      'Emergency Care',
      'Laboratory Tests',
      'Microchipping',
      'Spay/Neuter',
      'X-Ray Imaging',
      'Ultrasound',
      'Blood Work',
      'Behavioral Consultation',
      'Nutritional Counseling',
      'Parasite Treatment',
      'Wound Care',
      'Prescription Medications',
      'Health Certificates',
    ];

    return medicalServicesList.contains(service);
  }

  // Operating hours
  Map<String, Map<String, dynamic>> operatingHours = {};

  // Settings
  int appointmentDuration = 30;
  int maxAdvanceBooking = 30;

  bool isOpen = true;
  String? newDashboardImageId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeControllers();
    _initializeData();
  }

  void _initializeControllers() {
    clinicNameController =
        TextEditingController(text: widget.clinic.clinicName);
    addressController = TextEditingController(text: widget.clinic.address);
    contactController = TextEditingController(text: widget.clinic.contact);
    emailController = TextEditingController(text: widget.clinic.email);
    descriptionController =
        TextEditingController(text: widget.clinic.description);
    emergencyContactController = TextEditingController(
      text: widget.settings?.emergencyContact ?? '',
    );
    specialInstructionsController = TextEditingController(
      text: widget.settings?.specialInstructions ?? '',
    );
  }

  void _initializeData() {

    // Parse services from clinic's services string
    if (widget.clinic.services.isNotEmpty) {
      clinicServices = widget.clinic.services
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      selectedServices = List<String>.from(clinicServices);
    }

    // Initialize settings data if available
    if (widget.settings != null) {
      // CRITICAL FIX: Load gallery images as URLs directly (not file IDs)
      galleryImages = List<String>.from(widget.settings!.gallery);
      if (galleryImages.isNotEmpty) {
      }

      // Load operating hours
      operatingHours = Map.from(widget.settings!.operatingHours);

      // Appointment settings
      appointmentDuration = widget.settings!.appointmentDuration;
      maxAdvanceBooking = widget.settings!.maxAdvanceBooking;
      isOpen = widget.settings!.isOpen;

      // CRITICAL: Load medical services map from settings
      medicalServices =
          Map<String, bool>.from(widget.settings!.medicalServices);

      // Ensure all selected services have medical status
      for (var service in selectedServices) {
        if (!medicalServices.containsKey(service)) {
          medicalServices[service] = _isServiceMedicalByDefault(service);
        }
      }

      // CRITICAL FIX: Load dashboard pic as URL directly (not file ID)
      if (widget.settings!.dashboardPic.isNotEmpty) {
        newDashboardImageId = widget.settings!.dashboardPic;
      }
    } else {
      operatingHours = _getDefaultOperatingHours();

      // Set default medical status for pre-selected services
      for (var service in selectedServices) {
        medicalServices[service] = _isServiceMedicalByDefault(service);
      }
    }

  }

  Map<String, Map<String, dynamic>> _getDefaultOperatingHours() {
    return {
      'monday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '17:00'},
      'tuesday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '17:00'},
      'wednesday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '17:00'},
      'thursday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '17:00'},
      'friday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '17:00'},
      'saturday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '15:00'},
      'sunday': {'isOpen': false, 'openTime': '09:00', 'closeTime': '17:00'},
    };
  }

  @override
  void dispose() {
    _tabController.dispose();
    clinicNameController.dispose();
    addressController.dispose();
    contactController.dispose();
    emailController.dispose();
    descriptionController.dispose();
    emergencyContactController.dispose();
    specialInstructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 248, 253, 255),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 248, 253, 255),
        elevation: 2,
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color.fromRGBO(81, 115, 153, 0.1),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color.fromRGBO(81, 115, 153, 1)),
          onPressed: () => _handleBackPress(),
        ),
        title: const Text(
          'Edit Clinic',
          style: TextStyle(
            color: Color.fromRGBO(81, 115, 153, 1),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: isSaving ? null : _saveAllChanges,
            icon: isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(isSaving ? 'Saving...' : 'Save All'),
            style: TextButton.styleFrom(
              foregroundColor: const Color.fromRGBO(81, 115, 153, 1),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color.fromRGBO(81, 115, 153, 1),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color.fromRGBO(81, 115, 153, 1),
          tabs: const [
            Tab(text: "Basic Info"),
            Tab(text: "Services & Hours"),
            Tab(text: "Settings"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBasicInfoTab(),
          _buildServicesAndHoursTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }

  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // CHANGED: Clinic Gallery instead of single image
          _buildSectionCard(
            title: "Clinic Gallery",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "Upload images of your clinic (${galleryImages.length})",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: isLoadingImage ? null : _pickGalleryImages,
                      icon: isLoadingImage
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_photo_alternate),
                      label:
                          Text(isLoadingImage ? 'Uploading...' : 'Add Images'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(81, 115, 153, 1),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Info message
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.blue[700], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Upload multiple images to showcase your clinic. These will be displayed in your clinic profile.',
                          style: TextStyle(
                            color: Colors.blue[900],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Gallery display
                if (galleryImages.isEmpty)
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[50],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_library,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "No images uploaded yet",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Click 'Add Images' to get started",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1,
                    ),
                    itemCount: galleryImages.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          // Image container
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                getDashImageUrl(galleryImages[index]),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: Colors.grey[200],
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          color: Colors.red[700],
                                          size: 32,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Failed to load",
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.red[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                          // Delete button
                          Positioned(
                            top: 6,
                            right: 6,
                            child: InkWell(
                              onTap: () => _confirmRemoveGalleryImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.red[700],
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),

                          // Image number badge
                          Positioned(
                            bottom: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildDashboardImageSection(),
          const SizedBox(height: 24),
          _buildSectionCard(
            title: "Basic Information",
            child: Column(
              children: [
                _buildTextField(
                  controller: clinicNameController,
                  label: "Clinic Name",
                  icon: Icons.business,
                  required: true,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: emailController,
                  label: "Email",
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  required: true,
                  enabled: false,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: addressController,
                  label: "Address",
                  icon: Icons.location_on,
                  required: true,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: contactController,
                  label: "Contact Number",
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  required: true,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: descriptionController,
                  label: "Description",
                  icon: Icons.description,
                  maxLines: 4,
                  hint: "Tell customers about your clinic...",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveGalleryImage(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 248, 253, 255),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Image?'),
        content: const Text(
          'Are you sure you want to remove this image from the gallery?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _removeGalleryImage(index);
              _showSuccessSnackbar('Image removed from gallery');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardImageSection() {
    return _buildSectionCard(
      title: "Dashboard Image (Optional)",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Dashboard image will be shown in the main dashboard. If not set, the main clinic image will be used.',
                    style: TextStyle(
                      color: Colors.blue[900],
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              width: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
                color: Colors.grey[100],
              ),
              child: AspectRatio(
                aspectRatio: 1.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildDashboardImagePreview(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isLoadingImage ? null : _pickDashboardImage,
                  icon: isLoadingImage
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload),
                  label: Text(isLoadingImage
                      ? 'Uploading...'
                      : 'Change Dashboard Image'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(81, 115, 153, 1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              if (newDashboardImageId != null ||
                  (widget.clinic.dashboardPic != null &&
                      widget.clinic.dashboardPic!.isNotEmpty)) ...[
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _removeDashboardImage,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 20,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServicesAndHoursTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildSectionCard(
            title: "Services Offered",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Info box showing current status
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selectedServices.isEmpty
                        ? Colors.orange[50]
                        : Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selectedServices.isEmpty
                          ? Colors.orange[200]!
                          : Colors.blue[200]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selectedServices.isEmpty
                            ? Icons.info_outline
                            : Icons.check_circle_outline,
                        color: selectedServices.isEmpty
                            ? Colors.orange[700]
                            : Colors.blue[700],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          selectedServices.isEmpty
                              ? "No services selected. You can add services or leave empty."
                              : "${selectedServices.length} service(s) selected",
                          style: TextStyle(
                            fontSize: 13,
                            color: selectedServices.isEmpty
                                ? Colors.orange[700]
                                : Colors.blue[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ✅ Services chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableServices.map((service) {
                    final isSelected = selectedServices.contains(service);
                    final isMedical = medicalServices[service] ??
                        _isServiceMedicalByDefault(service);
                    return FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(service),
                          if (isSelected && isMedical) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green[700],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Medical',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedServices.add(service);
                            medicalServices[service] =
                                _isServiceMedicalByDefault(service);
                          } else {
                            selectedServices.remove(service);
                            medicalServices.remove(service);
                          }
                        });
                      },
                      selectedColor: const Color.fromRGBO(81, 115, 153, 0.2),
                      checkmarkColor: const Color.fromRGBO(81, 115, 153, 1),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionCard(
            title: "Operating Hours",
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text(
                    "Clinic Open for Appointments",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text("Toggle to accept/reject appointments"),
                  value: isOpen,
                  onChanged: (value) {
                    setState(() {
                      isOpen = value;
                    });
                  },
                  activeColor: const Color.fromRGBO(81, 115, 153, 1),
                ),
                const Divider(height: 24),
                ...operatingHours.entries.map((entry) {
                  final day = entry.key;
                  final hours = entry.value;
                  final dayIsOpen = hours['isOpen'] as bool;
                  final openTime = hours['openTime'] as String;
                  final closeTime = hours['closeTime'] as String;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                day.substring(0, 1).toUpperCase() +
                                    day.substring(1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Switch(
                              value: dayIsOpen,
                              onChanged: (value) {
                                setState(() {
                                  operatingHours[day]!['isOpen'] = value;
                                });
                              },
                              activeColor:
                                  const Color.fromRGBO(81, 115, 153, 1),
                            ),
                          ],
                        ),
                        if (dayIsOpen) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTimeField(
                                  value: openTime,
                                  label: "Open",
                                  onChanged: (time) {
                                    setState(() {
                                      operatingHours[day]!['openTime'] = time;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTimeField(
                                  value: closeTime,
                                  label: "Close",
                                  onChanged: (time) {
                                    setState(() {
                                      operatingHours[day]!['closeTime'] = time;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionCard(
            title: "Clinic Gallery",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "Current Images (${galleryImages.length})",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _pickGalleryImages,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text("Add Images"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(81, 115, 153, 1),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (galleryImages.isEmpty)
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo_library,
                              size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text("No images uploaded"),
                        ],
                      ),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: galleryImages.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: Image.network(
                                getDashImageUrl(galleryImages[index]),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: InkWell(
                              onTap: () => _removeGalleryImage(index),
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
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildSectionCard(
            title: "Appointment Settings",
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Default Duration",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            value: appointmentDuration,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              suffixText: "minutes",
                            ),
                            items: [15, 30, 45, 60, 90].map((duration) {
                              return DropdownMenuItem(
                                value: duration,
                                child: Text("$duration minutes"),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  appointmentDuration = value;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Max Advance Booking",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            value: maxAdvanceBooking,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              suffixText: "days",
                            ),
                            items: [7, 14, 30, 60, 90].map((days) {
                              return DropdownMenuItem(
                                value: days,
                                child: Text("$days days"),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  maxAdvanceBooking = value;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: emergencyContactController,
                  label: "Emergency Contact",
                  icon: Icons.emergency,
                  keyboardType: TextInputType.phone,
                  enabled: true,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: specialInstructionsController,
                  label: "Special Instructions",
                  icon: Icons.info,
                  maxLines: 3,
                  hint: "Any special instructions for customers...",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(81, 115, 153, 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color.fromRGBO(81, 115, 153, 1),
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    String? hint,
    bool required = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: required ? "$label *" : label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color.fromRGBO(81, 115, 153, 1)),
        ),
      ),
    );
  }

  String getDashImageUrl(String imageReference) {
    // Since we're storing full URLs, just return them directly
    if (imageReference.isEmpty) {
      return '';
    }

    // If it's already a URL, return it
    if (imageReference.startsWith('http')) {
      return imageReference;
    }

    // If somehow it's still a file ID, construct the URL
    return '${AppwriteConstants.endPoint}/storage/buckets/${AppwriteConstants.imageBucketID}/files/$imageReference/view?project=${AppwriteConstants.projectID}';
  }

  Widget _buildDashboardImagePreview() {

    // Priority 1: New dashboard image (just uploaded)
    if (newDashboardImageId != null && newDashboardImageId!.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            newDashboardImageId!, // Already a URL
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.grey[200],
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.error, color: Colors.red, size: 48),
                ),
              );
            },
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green[700],
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.new_releases, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'NEW',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Priority 2: Marked for removal
    if (newDashboardImageId == '' &&
        widget.settings?.dashboardPic != null &&
        widget.settings!.dashboardPic.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            widget.settings!.dashboardPic, // Already a URL
            fit: BoxFit.cover,
            color: Colors.red.withOpacity(0.3),
            colorBlendMode: BlendMode.color,
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red[700],
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete_outline, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Will be removed on save',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Priority 3: Existing dashboard pic from settings
    if (widget.settings?.dashboardPic != null &&
        widget.settings!.dashboardPic.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            widget.settings!.dashboardPic, // Already a URL
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.grey[200],
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.error, color: Colors.red, size: 48),
                ),
              );
            },
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(81, 115, 153, 1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.dashboard, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'CURRENT',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Priority 4: First gallery image as fallback
    if (galleryImages.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            galleryImages.first, // Already a URL
            fit: BoxFit.cover,
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue[700],
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_library, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'GALLERY',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Priority 5: No image available
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'No image available',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  String _extractFileIdFromUrl(String url) {
    if (!url.contains('/files/')) {
      return url; // Already a file ID or invalid
    }

    final regex = RegExp(r'/files/([^/]+)/');
    final match = regex.firstMatch(url);
    return match?.group(1) ?? url;
  }

  Widget _buildTimeField({
    required String value,
    required String label,
    required Function(String) onChanged,
  }) {
    return TextField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.access_time),
      ),
      controller: TextEditingController(text: value),
      onTap: () async {
        final TimeOfDay? time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(
            hour: int.parse(value.split(':')[0]),
            minute: int.parse(value.split(':')[1]),
          ),
        );
        if (time != null) {
          final formattedTime =
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
          onChanged(formattedTime);
        }
      },
    );
  }

  Future<void> _pickDashboardImage() async {
    try {
      setState(() {
        isLoadingImage = true;
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;


        // Upload dashboard image to storage
        final uploadedFile = await authRepository.uploadImage(
          file.bytes != null
              ? InputFile.fromBytes(bytes: file.bytes!, filename: file.name)
              : InputFile.fromPath(path: file.path!, filename: file.name),
        );

        setState(() {
          // CRITICAL FIX: Store full URL, not file ID
          final imageUrl =
              '${AppwriteConstants.endPoint}/storage/buckets/${AppwriteConstants.imageBucketID}/files/${uploadedFile.$id}/view?project=${AppwriteConstants.projectID}';
          newDashboardImageId = imageUrl;
        });

        _showSuccessSnackbar('Dashboard image uploaded successfully');
      }
    } catch (e) {
      _showErrorSnackbar('Error uploading dashboard image: ${e.toString()}');
    } finally {
      setState(() {
        isLoadingImage = false;
      });
    }
  }

  Future<void> _removeDashboardImage() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 248, 253, 255),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Dashboard Image?'),
        content: const Text(
          'Are you sure you want to remove the dashboard image? The main clinic image will be used instead.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        // Empty string signals deletion on save
        newDashboardImageId = '';
      });
      _showSuccessSnackbar('Dashboard image will be removed on save');
    }
  }

  Future<void> _pickGalleryImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          isLoadingImage = true;
        });


        // Upload images to storage
        final uploadedFiles = await authRepository.uploadClinicGalleryImages(
          result.files,
        );

        setState(() {
          // CRITICAL FIX: Store full URLs, not file IDs
          for (var file in uploadedFiles) {
            final imageUrl =
                '${AppwriteConstants.endPoint}/storage/buckets/${AppwriteConstants.imageBucketID}/files/${file.$id}/view?project=${AppwriteConstants.projectID}';
            galleryImages.add(imageUrl);
          }
          isLoadingImage = false;
        });

        _showSuccessSnackbar('${uploadedFiles.length} images uploaded');
      }
    } catch (e) {
      setState(() {
        isLoadingImage = false;
      });
      _showErrorSnackbar('Error uploading images: ${e.toString()}');
    }
  }

  void _removeGalleryImage(int index) {
    final imageUrl = galleryImages[index];

    setState(() {
      // CRITICAL FIX: Store URL in removed list (will be converted to ID during deletion)
      removedGalleryImages.add(imageUrl);

      // Remove from current gallery list
      galleryImages.removeAt(index);
    });

  }

  Future<void> _saveAllChanges() async {
    if (clinicNameController.text.trim().isEmpty) {
      _showErrorSnackbar('Clinic name is required');
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {

      // STEP 1: Handle dashboard image changes
      String finalDashboardImageId = '';

      if (newDashboardImageId == '') {
        // User wants to remove dashboard image
        if (widget.settings?.dashboardPic != null &&
            widget.settings!.dashboardPic.isNotEmpty) {
          final oldImageId =
              _extractFileIdFromUrl(widget.settings!.dashboardPic);
          try {
            await authRepository.deleteImage(oldImageId);
          } catch (e) {
          }
        }
        finalDashboardImageId = '';
      } else if (newDashboardImageId != null &&
          newDashboardImageId!.isNotEmpty) {
        // User uploaded new dashboard image
        finalDashboardImageId = newDashboardImageId!;

        // Delete old dashboard image if different
        if (widget.settings?.dashboardPic != null &&
            widget.settings!.dashboardPic.isNotEmpty &&
            widget.settings!.dashboardPic != newDashboardImageId) {
          final oldImageId =
              _extractFileIdFromUrl(widget.settings!.dashboardPic);
          try {
            await authRepository.deleteImage(oldImageId);
          } catch (e) {
          }
        }
      } else {
        // No change to dashboard image - keep existing
        finalDashboardImageId = widget.settings?.dashboardPic ?? '';
      }


      // STEP 2: Sanitize medical services map
      final sanitizedMedicalServices = <String, bool>{};
      for (var service in selectedServices) {
        sanitizedMedicalServices[service] =
            medicalServices[service] ?? _isServiceMedicalByDefault(service);
      }


      // STEP 3: Update clinic basic info
      final clinicData = {
        'clinicName': clinicNameController.text.trim(),
        'address': addressController.text.trim(),
        'contact': contactController.text.trim(),
        'email': emailController.text.trim(),
        'description': descriptionController.text.trim(),
        'services': selectedServices.join(', '),
        'image': newMainImageId ?? widget.clinic.image,
        'dashboardPic': finalDashboardImageId, // Store as URL
      };

      await authRepository.updateClinic(
        widget.clinic.documentId!,
        clinicData,
      );

      // STEP 4: Update or create clinic settings
      if (widget.settings != null) {

        final updatedSettings = widget.settings!.copyWith(
          isOpen: isOpen,
          operatingHours: operatingHours,
          gallery: galleryImages, // Store as URLs
          services: selectedServices,
          medicalServices: sanitizedMedicalServices,
          appointmentDuration: appointmentDuration,
          maxAdvanceBooking: maxAdvanceBooking,
          emergencyContact: emergencyContactController.text.trim(),
          specialInstructions: specialInstructionsController.text.trim(),
          dashboardPic: finalDashboardImageId, // Store as URL
        );

        await authRepository.updateClinicSettings(updatedSettings);
      } else {

        final newSettings = ClinicSettings(
          clinicId: widget.clinic.documentId!,
          isOpen: isOpen,
          operatingHours: operatingHours,
          gallery: galleryImages, // Store as URLs
          services: selectedServices,
          medicalServices: sanitizedMedicalServices,
          appointmentDuration: appointmentDuration,
          maxAdvanceBooking: maxAdvanceBooking,
          emergencyContact: emergencyContactController.text.trim(),
          specialInstructions: specialInstructionsController.text.trim(),
          dashboardPic: finalDashboardImageId, // Store as URL
        );

        await authRepository.createClinicSettings(newSettings);
      }

      // STEP 5: Delete removed gallery images from storage
      if (removedGalleryImages.isNotEmpty) {

        // Extract file IDs from URLs
        final fileIdsToDelete = removedGalleryImages
            .map((url) => _extractFileIdFromUrl(url))
            .toList();

        await authRepository.deleteClinicGalleryImages(fileIdsToDelete);
      }


      // _showSuccessSnackbar('Clinic updated successfully');

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e, stackTrace) {
      _showErrorSnackbar('Error saving changes: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  void _handleBackPress() {
    if (isSaving) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 248, 253, 255),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Discard Changes?'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle,
                color: Color.fromARGB(255, 255, 255, 255)),
            const SizedBox(width: 12),
            Text(message, style: const TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 5),
      ),
    );
  }
}
