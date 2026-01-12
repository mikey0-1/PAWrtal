import 'package:capstone_app/web/admin_web/components/clinic/admin_ratings_and_reviews.dart';
import 'package:capstone_app/web/admin_web/components/clinic/clinic_settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get_storage/get_storage.dart';
import 'package:latlong2/latlong.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminClinicPreview extends StatefulWidget {
  final ClinicSettingsController controller;
  final VoidCallback? onNavigateToSettings; // NEW: Optional callback

  const AdminClinicPreview({
    super.key,
    required this.controller,
    this.onNavigateToSettings, // NEW
  });

  @override
  State<AdminClinicPreview> createState() => _AdminClinicPreviewState();
}

class _AdminClinicPreviewState extends State<AdminClinicPreview> {
  final ScrollController _scrollController = ScrollController();
  final MapController _mapController = MapController();

  bool _showAppointmentPanel = false;

  bool _isValidEmail(String email) {
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  void _toggleAppointmentPanel() {
    setState(() {
      _showAppointmentPanel = !_showAppointmentPanel;
    });
  }

  IconData _getServiceIcon(String service) {
    String serviceLower = service.toLowerCase();

    if (serviceLower.contains('vaccination') ||
        serviceLower.contains('vaccine') ||
        serviceLower.contains('immunization')) {
      return Icons.vaccines_outlined;
    } else if (serviceLower.contains('surgery') ||
        serviceLower.contains('operation') ||
        serviceLower.contains('surgical')) {
      return Icons.local_hospital_outlined;
    } else if (serviceLower.contains('checkup') ||
        serviceLower.contains('examination') ||
        serviceLower.contains('consultation')) {
      return Icons.health_and_safety_outlined;
    } else if (serviceLower.contains('grooming') ||
        serviceLower.contains('bath') ||
        serviceLower.contains('cleaning')) {
      return Icons.pets_outlined;
    } else if (serviceLower.contains('dental') ||
        serviceLower.contains('teeth') ||
        serviceLower.contains('oral')) {
      return Icons.medication_liquid_outlined;
    } else if (serviceLower.contains('emergency') ||
        serviceLower.contains('urgent') ||
        serviceLower.contains('critical')) {
      return Icons.emergency_outlined;
    } else if (serviceLower.contains('laboratory') ||
        serviceLower.contains('lab') ||
        serviceLower.contains('test') ||
        serviceLower.contains('diagnostic')) {
      return Icons.science_outlined;
    } else if (serviceLower.contains('microchip') ||
        serviceLower.contains('chip') ||
        serviceLower.contains('id')) {
      return Icons.memory_outlined;
    } else if (serviceLower.contains('boarding') ||
        serviceLower.contains('hotel') ||
        serviceLower.contains('stay')) {
      return Icons.hotel_outlined;
    } else if (serviceLower.contains('nutrition') ||
        serviceLower.contains('diet') ||
        serviceLower.contains('feeding')) {
      return Icons.restaurant_outlined;
    } else if (serviceLower.contains('x-ray') ||
        serviceLower.contains('imaging') ||
        serviceLower.contains('scan')) {
      return Icons.camera_outlined;
    } else if (serviceLower.contains('spay') ||
        serviceLower.contains('neuter') ||
        serviceLower.contains('sterilization')) {
      return Icons.healing_outlined;
    } else {
      return Icons.medical_services_outlined;
    }
  }

  Color _getServiceColor(String service) {
    String serviceLower = service.toLowerCase();

    if (serviceLower.contains('emergency') || serviceLower.contains('urgent')) {
      return Colors.red.shade600;
    } else if (serviceLower.contains('surgery') ||
        serviceLower.contains('operation')) {
      return Colors.orange.shade600;
    } else if (serviceLower.contains('vaccination') ||
        serviceLower.contains('vaccine')) {
      return Colors.green.shade600;
    } else {
      return Colors.blue.shade600;
    }
  }

  // bool _editingAddress = false;
  bool _editingEmail = false;
  bool _editingContact = false;
  bool _editingDescription = false;

  // late TextEditingController _tempAddressController;
  late TextEditingController _tempEmailController;
  late TextEditingController _tempContactController;
  late TextEditingController _tempDescriptionController;

  // String _originalAddress = '';
  String _originalEmail = '';
  String _originalContact = '';
  String _originalDescription = '';

  DateTime? _selectedDate;
  bool _showFullDescription = false;

  final reviewsEndKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // _tempAddressController = TextEditingController();
    _tempEmailController = TextEditingController();
    _tempContactController = TextEditingController();
    _tempDescriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _mapController.dispose();
    // _tempAddressController.dispose();
    _tempEmailController.dispose();
    _tempContactController.dispose();
    _tempDescriptionController.dispose();
    super.dispose();
  }

  bool _isMobileLayout(double screenWidth) {
    return screenWidth <= 785;
  }

  bool _isTabletLayout(double screenWidth) {
    return screenWidth > 785 && screenWidth < 1100;
  }

  double getResponsivePadding(double screenWidth) {
    if (_isMobileLayout(screenWidth)) return 16;
    if (_isTabletLayout(screenWidth)) return 16;

    const double minScreen = 1100;
    const double maxScreen = 1920;
    const double minPadding = 16;
    const double maxPadding = 380;

    if (screenWidth <= minScreen) return minPadding;
    if (screenWidth >= maxScreen) return maxPadding;

    double t = (screenWidth - minScreen) / (maxScreen - minScreen);
    return minPadding + t * (maxPadding - minPadding);
  }

  String _safeGetControllerText(TextEditingController controller) {
    try {
      return controller.text;
    } catch (e) {
      return '';
    }
  }

  void _startEditing(String field) {
    setState(() {
      switch (field) {
        // Remove 'address' case entirely
        case 'email':
          _originalEmail =
              _safeGetControllerText(widget.controller.emailController);
          _tempEmailController.text = _originalEmail;
          _editingEmail = true;
          break;
        case 'contact':
          _originalContact =
              _safeGetControllerText(widget.controller.contactController);
          String contactValue = _originalContact;
          if (contactValue.startsWith('09') && contactValue.length == 11) {
            _tempContactController.text = contactValue.substring(2);
          } else {
            _tempContactController.text = '';
          }
          _editingContact = true;
          break;
        case 'description':
          _originalDescription =
              _safeGetControllerText(widget.controller.descriptionController);
          _tempDescriptionController.text = _originalDescription;
          _editingDescription = true;
          break;
      }
    });
  }

  bool _hasUnsavedChanges(String field) {
    switch (field) {
      // case 'address':
      //   return _tempAddressController.text != _originalAddress;
      case 'email':
        return _tempEmailController.text != _originalEmail;
      case 'contact':
        return '09${_tempContactController.text}' != _originalContact;
      case 'description':
        return _tempDescriptionController.text != _originalDescription;
      default:
        return false;
    }
  }

  Future<void> _saveEdit(String field) async {
    if (field == 'contact') {
      if (_tempContactController.text.length != 9) {
        _showSnackBar('Contact number must be 11 digits (09 + 9 digits)',
            isError: true);
        return;
      }
      widget.controller.contactController.text =
          '09${_tempContactController.text}';
      setState(() => _editingContact = false);
    } else if (field == 'email') {
      if (_tempEmailController.text.isEmpty) {
        _showSnackBar('Email cannot be empty', isError: true);
        return;
      }

      if (!_isValidEmail(_tempEmailController.text)) {
        _showSnackBar(
          'Please enter a valid email address (e.g., example@gmail.com)',
          isError: true,
        );
        return;
      }

      widget.controller.emailController.text = _tempEmailController.text;
      setState(() => _editingEmail = false);
    } else {
      switch (field) {
        // case 'address':
        //   widget.controller.addressController.text =
        //       _tempAddressController.text;
        //   setState(() => _editingAddress = false);
        //   break;
        case 'description':
          widget.controller.descriptionController.text =
              _tempDescriptionController.text;
          setState(() => _editingDescription = false);
          break;
      }
    }

    await widget.controller.saveClinicBasicInfo();
  }

  Future<void> _cancelEdit(String field) async {
    if (_hasUnsavedChanges(field)) {
      final shouldDiscard = await _showDiscardDialog();
      if (shouldDiscard != true) return;
    }

    setState(() {
      switch (field) {
        // case 'address':
        //   _editingAddress = false;
        //   break;
        case 'email':
          _editingEmail = false;
          break;
        case 'contact':
          _editingContact = false;
          break;
        case 'description':
          _editingDescription = false;
          break;
      }
    });
  }

  Future<bool?> _showDiscardDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text(
              'You have unsaved changes. Do you want to discard them?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child:
                  const Text('Discard', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showServicesEditDialog() {
    final originalServices =
        List<String>.from(widget.controller.selectedServices);
    final originalMedicalServices =
        Map<String, bool>.from(widget.controller.medicalServices);
    final tempSelectedServices = List<String>.from(originalServices);
    final tempMedicalServices = Map<String, bool>.from(originalMedicalServices);

    // Initialize medical status for services that don't have it yet
    for (var service in tempSelectedServices) {
      if (!tempMedicalServices.containsKey(service)) {
        tempMedicalServices[service] = _isServiceMedicalByDefault(service);
      }
    }

    bool customServiceIsMedical = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final TextEditingController customServiceController =
                TextEditingController();

            bool hasChanges() {
              if (tempSelectedServices.length != originalServices.length)
                return true;
              for (var service in tempSelectedServices) {
                if (!originalServices.contains(service)) return true;
                if (tempMedicalServices[service] !=
                    originalMedicalServices[service]) return true;
              }
              for (var service in originalServices) {
                if (!tempSelectedServices.contains(service)) return true;
              }
              return false;
            }

            Future<void> handleClose() async {
              if (hasChanges()) {
                final shouldDiscard = await _showDiscardDialog();
                if (shouldDiscard == true) {
                  widget.controller.selectedServices
                      .assignAll(originalServices);
                  widget.controller.medicalServices
                      .assignAll(originalMedicalServices);
                  if (context.mounted) Navigator.pop(context);
                }
              } else {
                Navigator.pop(context);
              }
            }

            return WillPopScope(
              onWillPop: () async {
                if (hasChanges()) {
                  final shouldDiscard = await _showDiscardDialog();
                  if (shouldDiscard == true) {
                    widget.controller.selectedServices
                        .assignAll(originalServices);
                    widget.controller.medicalServices
                        .assignAll(originalMedicalServices);
                    return true;
                  }
                  return false;
                }
                return true;
              },
              child: Dialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Container(
                  width: MediaQuery.of(context).size.width > 785
                      ? 700
                      : MediaQuery.of(context).size.width * 0.9,
                  constraints: const BoxConstraints(maxHeight: 700),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              "Edit Services",
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                              onPressed: handleClose,
                              icon: const Icon(Icons.close)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Select services your clinic offers:",
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Predefined services
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: widget.controller.availableServices
                                    .map((service) {
                                  final isSelected =
                                      tempSelectedServices.contains(service);
                                  final isMedical =
                                      tempMedicalServices[service] ??
                                          _isServiceMedicalByDefault(service);

                                  return InkWell(
                                    onTap: () {
                                      setDialogState(() {
                                        if (isSelected) {
                                          tempSelectedServices.remove(service);
                                          tempMedicalServices.remove(service);
                                        } else {
                                          tempSelectedServices.add(service);
                                          // Set medical status based on default
                                          tempMedicalServices[service] =
                                              _isServiceMedicalByDefault(
                                                  service);
                                        }
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color.fromARGB(
                                                    255, 81, 115, 153)
                                                .withOpacity(0.2)
                                            : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color.fromARGB(
                                                  255, 81, 115, 153)
                                              : Colors.grey[300]!,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isSelected)
                                            Icon(
                                              Icons.check_circle,
                                              size: 16,
                                              color: const Color.fromARGB(
                                                  255, 81, 115, 153),
                                            ),
                                          if (isSelected)
                                            const SizedBox(width: 4),
                                          Text(
                                            service,
                                            style: TextStyle(
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                              color: isSelected
                                                  ? Colors.black87
                                                  : Colors.grey[700],
                                            ),
                                          ),
                                          // Show medical indicator ONLY in edit dialog
                                          if (isSelected && isMedical) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.green[100],
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                border: Border.all(
                                                    color: Colors.green[300]!),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.medical_services,
                                                      size: 10,
                                                      color: Colors.green[700]),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    'Medical',
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.green[700],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 24),
                              const Divider(),
                              const SizedBox(height: 24),

                              // Add custom service section
                              const Text(
                                "Add custom service:",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue[200]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.info_outline,
                                            size: 16, color: Colors.blue[700]),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            "Medical services will have their appointments recorded in pet medical history.",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.blue[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: customServiceController,
                                      maxLength: 50,
                                      decoration: const InputDecoration(
                                        labelText: "Service name",
                                        hintText: "Enter custom service...",
                                        border: OutlineInputBorder(),
                                        counterText: "",
                                        filled: true,
                                        fillColor: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // Medical service checkbox
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: customServiceIsMedical
                                              ? Colors.green[300]!
                                              : Colors.grey[300]!,
                                        ),
                                      ),
                                      child: CheckboxListTile(
                                        value: customServiceIsMedical,
                                        onChanged: (value) {
                                          setDialogState(() {
                                            customServiceIsMedical =
                                                value ?? true;
                                          });
                                        },
                                        activeColor: Colors.green,
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8),
                                        title: Row(
                                          children: [
                                            Icon(
                                              Icons.medical_services,
                                              size: 16,
                                              color: customServiceIsMedical
                                                  ? Colors.green[700]
                                                  : Colors.grey[600],
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              "This is a medical service",
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                                color: customServiceIsMedical
                                                    ? Colors.green[700]
                                                    : Colors.grey[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                        subtitle: Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4),
                                          child: Text(
                                            "Appointments for this service will be added to pet medical records",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // Add button
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          if (customServiceController.text
                                                  .trim()
                                                  .isNotEmpty &&
                                              !tempSelectedServices.contains(
                                                  customServiceController.text
                                                      .trim())) {
                                            setDialogState(() {
                                              final newService =
                                                  customServiceController.text
                                                      .trim();
                                              tempSelectedServices
                                                  .add(newService);
                                              tempMedicalServices[newService] =
                                                  customServiceIsMedical;
                                              customServiceController.clear();
                                              customServiceIsMedical = true;
                                            });
                                          }
                                        },
                                        icon: const Icon(Icons.add),
                                        label: const Text("Add Service"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color.fromARGB(
                                              255, 81, 115, 153),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Selected services display
                              if (tempSelectedServices.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.orange.withOpacity(0.3)),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.warning, color: Colors.orange),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                            "Please select at least one service"),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Selected Services (${tempSelectedServices.length}):",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children:
                                          tempSelectedServices.map((service) {
                                        final isMedical =
                                            tempMedicalServices[service] ??
                                                false;
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: const Color.fromARGB(
                                                    255, 81, 115, 153)
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: const Color.fromARGB(
                                                      255, 81, 115, 153)
                                                  .withOpacity(0.3),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                service,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w500),
                                              ),
                                              if (isMedical) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green[100],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                    border: Border.all(
                                                        color:
                                                            Colors.green[300]!),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                          Icons
                                                              .medical_services,
                                                          size: 10,
                                                          color: Colors
                                                              .green[700]),
                                                      const SizedBox(width: 2),
                                                      Text(
                                                        'Medical',
                                                        style: TextStyle(
                                                          fontSize: 9,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color:
                                                              Colors.green[700],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                              const SizedBox(width: 8),
                                              InkWell(
                                                onTap: () {
                                                  setDialogState(() {
                                                    tempSelectedServices
                                                        .remove(service);
                                                    tempMedicalServices
                                                        .remove(service);
                                                  });
                                                },
                                                child: const Icon(Icons.close,
                                                    size: 18),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: handleClose,
                            child: const Text("Cancel"),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () async {
                              // Ensure all selected services have medical status
                              for (var service in tempSelectedServices) {
                                if (!tempMedicalServices.containsKey(service)) {
                                  tempMedicalServices[service] =
                                      _isServiceMedicalByDefault(service);
                                }
                              }

                              // CRITICAL: Assign to controller
                              widget.controller.selectedServices
                                  .assignAll(tempSelectedServices);
                              widget.controller.medicalServices
                                  .assignAll(tempMedicalServices);

                              // Save to database
                              await widget.controller.saveClinicSettings();

                              if (context.mounted) Navigator.pop(context);
                            },
                            icon: const Icon(Icons.save),
                            label: const Text("Save Services"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 81, 115, 153),
                              foregroundColor: Colors.white,
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
        );
      },
    );
  }

// NEW: Helper method to determine default medical status
  bool _isServiceMedicalByDefault(String service) {
    final medicalServices = [
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

    return medicalServices.contains(service);
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final horizontalPadding = getResponsivePadding(screenWidth);
    final isMobile = _isMobileLayout(screenWidth);
    final isTablet = _isTabletLayout(screenWidth);

    return Obx(() {
      final clinic = widget.controller.clinic.value;
      final settings = widget.controller.clinicSettings.value;

      if (clinic == null) {
        return const Center(child: CircularProgressIndicator());
      }

      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: Stack(
          children: [
            // Main scrollable content
            SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding, vertical: 16),
                    color: Colors.blue.shade50,
                    child: Row(
                      children: [
                        Icon(Icons.visibility,
                            color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Preview Mode - This is how customers see your clinic. Click edit icons to update basic information.",
                            style: TextStyle(
                                fontSize: isMobile ? 12 : 14,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.controller.clinic.value!.clinicName,
                                style: const TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        _buildGalleryPreview(isMobile),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // MODIFIED: Remove the Row wrapper and just use full width
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: SizedBox(
                      width: double.infinity,
                      child: _buildLeftContent(isMobile),
                    ),
                  ),
                  const SizedBox(height: 64),
                  _buildLocationSection(isMobile),
                  const SizedBox(height: 64),
                ],
              ),
            ),

            // Floating Appointment Panel (Chat-style)
            if (_showAppointmentPanel)
              Positioned(
                right: 24,
                bottom: 24,
                child: Container(
                  width: 420,
                  height: screenHeight * 0.75,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header
                      InkWell(
                        onTap: _toggleAppointmentPanel,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: const BoxDecoration(
                            color: Color(0xFF5173B8),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Book Appointment',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: _toggleAppointmentPanel,
                                icon: const Icon(Icons.close,
                                    color: Colors.white, size: 20),
                                tooltip: 'Close',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Scrollable content
                      Expanded(
                        child: Container(
                          color: Colors.grey.shade50,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: settings != null
                                ? _buildAppointmentPanel(settings, isMobile)
                                : const Center(
                                    child: CircularProgressIndicator()),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        // Floating Action Button
        floatingActionButton: !_showAppointmentPanel
            ? FloatingActionButton.extended(
                onPressed: _toggleAppointmentPanel,
                backgroundColor: const Color(0xFF5173B8),
                icon: const Icon(Icons.calendar_today, color: Colors.white),
                label: const Text(
                  'Book Appointment',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : null,
      );
    });
  }

  Widget _buildLeftContent(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildClinicHeader(isMobile),
        const SizedBox(height: 32),
        _buildAboutSection(widget.controller.clinicSettings.value, isMobile),
        const SizedBox(height: 32),
        _buildServicesSection(isMobile),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: SizedBox(
            width: double.infinity,
            child: Divider(height: 1, thickness: 0.5),
          ),
        ),
        if (widget.controller.clinic.value?.documentId != null)
          AdminRatingsAndReviews(
            reviewsEndKey: reviewsEndKey,
            clinicId: widget.controller.clinic.value!.documentId!,
          ),
      ],
    );
  }

  Widget _buildGalleryPreview(bool isMobile) {
    return Obx(() {
      final images = widget.controller.galleryImages;

      for (var img in images) {}

      if (images.isEmpty) {
        return Container(
          height: isMobile ? 300 : 520,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_library,
                    size: isMobile ? 48 : 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text("No gallery images",
                    style: TextStyle(
                        fontSize: isMobile ? 14 : 18, color: Colors.grey[600])),
              ],
            ),
          ),
        );
      }

      if (isMobile) {
        return Column(
          children: [
            Container(
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  images[0],
                  fit: BoxFit.cover,
                  width: double.infinity,
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
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.error, color: Colors.red, size: 48),
                      ),
                    );
                  },
                ),
              ),
            ),
            if (images.length > 1) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length - 1,
                  itemBuilder: (context, index) {
                    final imageIndex = index + 1;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () =>
                            _showImageDialog(images[imageIndex], imageIndex),
                        child: Container(
                          width: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              images[imageIndex],
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: Icon(Icons.error,
                                        color: Colors.red, size: 24),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (images.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showAllPhotosDialog(),
                      icon: const Icon(Icons.grid_view_rounded),
                      label: Text(
                        "View all ${images.length} photos",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        );
      }

      return SizedBox(
        height: 520,
        child: Row(
          children: [
            Flexible(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
                child: Image.network(
                  images[0],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
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
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.error, color: Colors.red, size: 64),
                      ),
                    );
                  },
                ),
              ),
            ),
            if (images.length > 1) const SizedBox(width: 12),
            if (images.length > 1)
              Flexible(
                flex: 2,
                child: Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: images.length > 2
                            ? BorderRadius.zero
                            : const BorderRadius.only(
                                topRight: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              ),
                        child: Image.network(
                          images[1],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[200],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Icon(Icons.error, color: Colors.red),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    if (images.length > 2) const SizedBox(height: 10),
                    if (images.length > 2)
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomRight: Radius.circular(20),
                          ),
                          child: Image.network(
                            images[2],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                    ),
                                  ));
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: Icon(Icons.error, color: Colors.red),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            if (images.length > 3) const SizedBox(width: 12),
            if (images.length > 3)
              Flexible(
                flex: 2,
                child: Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(20),
                        ),
                        child: Image.network(
                          images[3],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[200],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Icon(Icons.error, color: Colors.red),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              bottomRight: Radius.circular(20),
                            ),
                            child: images.length > 4
                                ? Image.network(
                                    images[4],
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
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey.shade200,
                                        child: const Center(
                                          child: Icon(Icons.error,
                                              color: Colors.red),
                                        ),
                                      );
                                    },
                                  )
                                : Container(color: Colors.grey.shade200),
                          ),
                          if (images.length > 4)
                            Positioned.fill(
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black26,
                                  borderRadius: BorderRadius.only(
                                    bottomRight: Radius.circular(20),
                                  ),
                                ),
                              ),
                            ),
                          Align(
                            alignment: Alignment.center,
                            child: InkWell(
                              onTap: () => _showAllPhotosDialog(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(width: 1),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.grid_view_rounded),
                                    const SizedBox(width: 4),
                                    Text(
                                      images.length > 5
                                          ? "Show all ${images.length} photos"
                                          : "Show all photos",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }

  void _showAllPhotosDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.all(40),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey, width: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${widget.controller.clinic.value?.clinicName ?? 'Clinic'} - Gallery (${widget.controller.galleryImages.length} photos)",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Obx(() {
                    final images = widget.controller.galleryImages;
                    return GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1,
                      ),
                      itemCount: images.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => _showImageDialog(images[index], index),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              images[index],
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: Icon(Icons.error, color: Colors.red),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showImageDialog(String imagePath, int index) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.9,
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imagePath,
                      fit: BoxFit.contain,
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
                          color: Colors.grey.shade200,
                          child: const Center(
                            child:
                                Icon(Icons.error, color: Colors.red, size: 64),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildClinicHeader(bool isMobile) {
    return Obx(() {
      // Get profile picture URL from controller
      final profilePicUrl = widget.controller.clinicProfilePictureUrl.value;

      return Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: profilePicUrl.isNotEmpty
                ? Image.network(
                    profilePicUrl,
                    height: 40,
                    width: 40,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 40,
                        width: 40,
                        color: Colors.grey[200],
                        child: Center(
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
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      height: 40,
                      width: 40,
                      color: Colors.grey[300],
                      child: Icon(Icons.business,
                          color: Colors.grey[600], size: 24),
                    ),
                  )
                : Container(
                    height: 40,
                    width: 40,
                    color: Colors.grey[300],
                    child:
                        Icon(Icons.business, color: Colors.grey[600], size: 24),
                  ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              widget.controller.clinic.value!.clinicName,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: isMobile ? 14 : 16,
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildAboutSection(settings, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text('About this veterinary clinic',
              style: TextStyle(
                  fontWeight: FontWeight.w600, fontSize: isMobile ? 18 : 22)),
        ),
        if (settings != null) _buildStatusBanner(settings, isMobile),
        _buildContactInfoSection(isMobile),
        const SizedBox(height: 16),
        if (settings != null) _buildOperatingHours(settings, isMobile),
        const SizedBox(height: 16),
        _buildDescriptionSection(isMobile),
      ],
    );
  }

  Widget _buildStatusBanner(settings, bool isMobile) {
    final isOpen = settings.isOpen;
    final isOpenNow = settings.isOpenNow();

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (!isOpen) {
      statusColor = Colors.red;
      statusText = "Currently Closed";
      statusIcon = Icons.cancel;
    } else if (!isOpenNow) {
      statusColor = Colors.orange;
      statusText = "Closed Now";
      statusIcon = Icons.schedule;
    } else {
      statusColor = Colors.green;
      statusText = "Open Today";
      statusIcon = Icons.check_circle;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: isMobile ? 20 : 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(statusText,
                    style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.w600,
                        color: statusColor)),
                if (isOpen) ...[
                  const SizedBox(height: 4),
                  Text("Hours: ${settings.getTodayHours()}",
                      style: TextStyle(
                          fontSize: isMobile ? 12 : 14,
                          color: Colors.grey[700])),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoSection(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Address - READ ONLY with navigation to Settings
          _buildReadOnlyInfoRow(
            icon: Icons.location_on_outlined,
            label: 'Address',
            value: _safeGetControllerText(widget.controller.addressController),
            isMobile: isMobile,
          ),
          const SizedBox(height: 8),
          // Contact - Keep editable
          _buildEditableInfoRow(
            icon: Icons.phone_outlined,
            label: 'Contact',
            value: _safeGetControllerText(widget.controller.contactController),
            isEditing: _editingContact,
            controller: _tempContactController,
            maxLength: 9,
            keyboardType: TextInputType.phone,
            onEdit: () => _startEditing('contact'),
            onSave: () => _saveEdit('contact'),
            onCancel: () => _cancelEdit('contact'),
            isContact: true,
            isMobile: isMobile,
          ),
          const SizedBox(height: 8),
          // Email - Keep editable
          _buildEditableInfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: _safeGetControllerText(widget.controller.emailController),
            isEditing: _editingEmail,
            controller: _tempEmailController,
            maxLength: 40,
            keyboardType: TextInputType.emailAddress,
            onEdit: () => _startEditing('email'),
            onSave: () => _saveEdit('email'),
            onCancel: () => _cancelEdit('email'),
            isMobile: isMobile,
          ),
        ],
      ),
    );
  }

  Widget _buildEditableInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isEditing,
    required TextEditingController controller,
    required int maxLength,
    required VoidCallback onEdit,
    required VoidCallback onSave,
    required VoidCallback onCancel,
    TextInputType keyboardType = TextInputType.text,
    bool isContact = false,
    bool isMobile = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: isMobile ? 18 : 20, color: Colors.grey.shade600),
        SizedBox(width: isMobile ? 8 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: isMobile ? 12 : 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700)),
                  const Spacer(),
                  if (!isEditing)
                    IconButton(
                      icon: Icon(Icons.edit,
                          size: isMobile ? 14 : 16,
                          color: Colors.blue.shade600),
                      onPressed: onEdit,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              if (isEditing)
                Row(
                  children: [
                    Expanded(
                      child: isContact
                          ? Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: isMobile ? 8 : 12,
                                      vertical: isMobile ? 8 : 12),
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.grey[400]!),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(4),
                                      bottomLeft: Radius.circular(4),
                                    ),
                                    color: Colors.grey[200],
                                  ),
                                  child: Text('09',
                                      style: TextStyle(
                                          fontSize: isMobile ? 12 : 14,
                                          fontWeight: FontWeight.w500)),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: controller,
                                    maxLength: maxLength,
                                    maxLengthEnforcement:
                                        MaxLengthEnforcement.enforced,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly
                                    ],
                                    style:
                                        TextStyle(fontSize: isMobile ? 12 : 14),
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(
                                        borderRadius: BorderRadius.only(
                                          topRight: Radius.circular(4),
                                          bottomRight: Radius.circular(4),
                                        ),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: isMobile ? 8 : 12,
                                          vertical: isMobile ? 8 : 8),
                                      counterText: "",
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                              ],
                            )
                          : TextField(
                              controller: controller,
                              maxLength: maxLength,
                              maxLengthEnforcement:
                                  MaxLengthEnforcement.enforced,
                              keyboardType: keyboardType,
                              style: TextStyle(fontSize: isMobile ? 12 : 14),
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: isMobile ? 8 : 12,
                                    vertical: isMobile ? 8 : 8),
                                counterText: "",
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                    ),
                    SizedBox(width: isMobile ? 4 : 8),
                    IconButton(
                        icon: Icon(Icons.check,
                            color: Colors.green, size: isMobile ? 18 : 24),
                        onPressed: onSave,
                        padding: EdgeInsets.all(isMobile ? 4 : 8)),
                    IconButton(
                        icon: Icon(Icons.close,
                            color: Colors.red, size: isMobile ? 18 : 24),
                        onPressed: onCancel,
                        padding: EdgeInsets.all(isMobile ? 4 : 8)),
                  ],
                )
              else
                Text(value.isNotEmpty ? value : 'Not provided',
                    style: TextStyle(
                        fontSize: isMobile ? 13 : 15,
                        color: value.isNotEmpty
                            ? Colors.black87
                            : Colors.grey.shade500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOperatingHours(settings, bool isMobile) {
    final operatingHours = settings.operatingHours;
    final days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];

    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(Icons.access_time,
                  color: Colors.grey[600], size: isMobile ? 18 : 20),
              const SizedBox(width: 8),
              Text('Operating Hours',
                  style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700])),
            ],
          ),
          const SizedBox(height: 12),
          ...days.map((day) {
            final dayData = operatingHours[day];
            final isOpen = dayData?['isOpen'] ?? false;
            final openTime = dayData?['openTime'] ?? '';
            final closeTime = dayData?['closeTime'] ?? '';

            // Convert to 12-hour format
            final openTime12 = _formatTimeTo12Hour(openTime);
            final closeTime12 = _formatTimeTo12Hour(closeTime);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: isMobile ? 70 : 80,
                    child: Text(day.capitalize!,
                        style: TextStyle(
                            fontSize: isMobile ? 12 : 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700])),
                  ),
                  Text(
                    isOpen ? '$openTime12 - $closeTime12' : 'Closed',
                    style: TextStyle(
                        fontSize: isMobile ? 12 : 14,
                        color: isOpen ? Colors.black87 : Colors.grey[500]),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatTimeTo12Hour(String time24) {
    if (time24.isEmpty) return '';

    try {
      final parts = time24.split(':');
      if (parts.length != 2) return time24;

      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

      return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return time24;
    }
  }

  Widget _buildDescriptionSection(bool isMobile) {
    final description = _safeGetControllerText(
                widget.controller.descriptionController)
            .isNotEmpty
        ? _safeGetControllerText(widget.controller.descriptionController)
        : "This veterinary clinic provides comprehensive pet care services.";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Description',
                style: TextStyle(
                    fontSize: isMobile ? 14 : 16, fontWeight: FontWeight.w600)),
            const Spacer(),
            if (!_editingDescription)
              IconButton(
                icon: Icon(Icons.edit,
                    size: isMobile ? 14 : 16, color: Colors.blue.shade600),
                onPressed: () => _startEditing('description'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_editingDescription)
          Column(
            children: [
              TextField(
                controller: _tempDescriptionController,
                maxLength: 1000,
                maxLines: 6,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                style: TextStyle(fontSize: isMobile ? 13 : 14),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  counterText: "${_tempDescriptionController.text.length}/1000",
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () => _cancelEdit('description'),
                      child: Text('Cancel',
                          style: TextStyle(fontSize: isMobile ? 12 : 14))),
                  ElevatedButton.icon(
                    onPressed: () => _saveEdit('description'),
                    icon: Icon(Icons.check, size: isMobile ? 16 : 20),
                    label: Text('Save',
                        style: TextStyle(fontSize: isMobile ? 12 : 14)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white),
                  ),
                ],
              ),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _showFullDescription || description.length <= 300
                    ? description
                    : '${description.substring(0, 300)}...',
                style: TextStyle(fontSize: isMobile ? 14 : 16, height: 1.5),
                textAlign: TextAlign.justify,
              ),
              if (description.length > 300)
                InkWell(
                  onTap: () => setState(
                      () => _showFullDescription = !_showFullDescription),
                  child: Row(
                    children: [
                      Text(
                        _showFullDescription ? "Show less" : "Show more",
                        style: TextStyle(
                            fontSize: isMobile ? 14 : 16,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline),
                      ),
                      Icon(
                          _showFullDescription
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_right_rounded,
                          size: isMobile ? 20 : 24),
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildServicesSection(bool isMobile) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = _isTabletLayout(screenWidth);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: SizedBox(
            width: double.infinity,
            child: Divider(height: 1, thickness: 0.5),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                'Services offered',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: isMobile ? 18 : 22,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _showServicesEditDialog,
              icon: Icon(Icons.edit, size: isMobile ? 14 : 18),
              label: Text(
                'Edit Services',
                style: TextStyle(fontSize: isMobile ? 12 : 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 16,
                  vertical: isMobile ? 8 : 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Obx(() {
          if (widget.controller.selectedServices.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.medical_services_outlined,
                      size: isMobile ? 36 : 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No services listed",
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          int crossAxisCount;
          double childAspectRatio;

          if (isMobile) {
            crossAxisCount = 1;
            childAspectRatio = 5.5;
          } else if (isTablet) {
            crossAxisCount = 2;
            childAspectRatio = 6.0;
          } else {
            crossAxisCount = 2;
            childAspectRatio = 6.5;
          }

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: isTablet ? 10 : 12,
              crossAxisSpacing: isTablet ? 10 : 12,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: widget.controller.selectedServices.length,
            itemBuilder: (context, index) {
              final service = widget.controller.selectedServices[index];
              final serviceColor = _getServiceColor(service);
              final serviceIcon = _getServiceIcon(service);

              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 12 : (isMobile ? 16 : 14),
                  vertical: isTablet ? 8 : (isMobile ? 10 : 9),
                ),
                decoration: BoxDecoration(
                  color: serviceColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: serviceColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      serviceIcon,
                      size: isTablet ? 20 : (isMobile ? 24 : 22),
                      color: serviceColor,
                    ),
                    SizedBox(width: isTablet ? 10 : (isMobile ? 12 : 10)),
                    Expanded(
                      child: Text(
                        service,
                        style: TextStyle(
                          fontSize: isTablet ? 13 : (isMobile ? 16 : 14),
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }),
      ],
    );
  }

  Widget _buildAppointmentPanel(settings, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Date',
            style: GoogleFonts.inter(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800])),
        SizedBox(height: isMobile ? 8 : 12),
        Container(
          decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.all(16),
          child: TableCalendar(
            focusedDay: _selectedDate ?? DateTime.now(),
            firstDay: DateTime.now(),
            lastDay: DateTime.now()
                .add(Duration(days: settings?.maxAdvanceBooking ?? 30)),
            selectedDayPredicate: (day) => isSameDay(day, _selectedDate),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() => _selectedDate = selectedDay);
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                  color: const Color(0xFF5173B8).withOpacity(0.6),
                  border: Border.all(color: const Color(0xFF5173B8)),
                  shape: BoxShape.circle),
              selectedDecoration: const BoxDecoration(
                  color: Color(0xFF5173B8), shape: BoxShape.circle),
              outsideDaysVisible: false,
              cellMargin: const EdgeInsets.all(4),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.w600, fontSize: isMobile ? 14 : 16),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                  fontSize: isMobile ? 12 : 13, fontWeight: FontWeight.w600),
              weekendStyle: TextStyle(
                  fontSize: isMobile ? 12 : 13, fontWeight: FontWeight.w600),
            ),
            calendarFormat: CalendarFormat.month,
            enabledDayPredicate: (day) =>
                !day.isBefore(DateTime.now().subtract(const Duration(days: 1))),
          ),
        ),
        SizedBox(height: isMobile ? 16 : 20),
        Text('Time',
            style: GoogleFonts.inter(
                fontSize: isMobile ? 12 : 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700])),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 10 : 12, vertical: isMobile ? 10 : 12),
          child: Row(
            children: [
              const Icon(Icons.access_time, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              Text('Select time',
                  style: TextStyle(
                      color: Colors.grey, fontSize: isMobile ? 12 : 14)),
            ],
          ),
        ),
        SizedBox(height: isMobile ? 12 : 16),
        Text('Service',
            style: GoogleFonts.inter(
                fontSize: isMobile ? 12 : 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700])),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 10 : 12, vertical: isMobile ? 10 : 12),
          child: Text('Choose service',
              style:
                  TextStyle(color: Colors.grey, fontSize: isMobile ? 12 : 14)),
        ),
        SizedBox(height: isMobile ? 12 : 16),
        Text('Select Pet',
            style: GoogleFonts.inter(
                fontSize: isMobile ? 12 : 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700])),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 10 : 12, vertical: isMobile ? 10 : 12),
          child: Row(
            children: [
              Icon(Icons.pets, size: isMobile ? 16 : 20, color: Colors.grey),
              SizedBox(width: isMobile ? 6 : 8),
              Text('Choose your pet',
                  style: TextStyle(
                      color: Colors.grey, fontSize: isMobile ? 12 : 14)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Preview note
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This is a preview. Actual booking functionality is available to customers.',
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
    );
  }

  Widget _buildLocationSection(bool isMobile) {
    final settings = widget.controller.clinicSettings.value;
    final location = settings?.location;
    final clinic = widget.controller.clinic.value;

    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: getResponsivePadding(MediaQuery.of(context).size.width)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: SizedBox(
                width: double.infinity,
                child: Divider(height: 1, thickness: 0.5)),
          ),
          Text("Location",
              style: TextStyle(
                  fontSize: isMobile ? 20 : 26, fontWeight: FontWeight.w600)),
          SizedBox(height: isMobile ? 10 : 14),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on,
                      color: Colors.red.shade600,
                      size: isMobile ? 20 : 24,
                    ),
                    SizedBox(width: isMobile ? 8 : 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _safeGetControllerText(
                                widget.controller.addressController),
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Full address of ${clinic?.clinicName ?? ''}",
                            style: TextStyle(
                              fontSize: isMobile ? 12 : 14,
                              color: Colors.grey.shade600,
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
          Container(
            width: double.maxFinite,
            height: isMobile ? 400 : 700,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: location == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_off,
                              size: isMobile ? 48 : 64,
                              color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text("Location not set",
                              style: TextStyle(
                                  fontSize: isMobile ? 14 : 18,
                                  color: Colors.grey[600])),
                        ],
                      ),
                    )
                  : Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter:
                                LatLng(location['lat']!, location['lng']!),
                            initialZoom: 15,
                            maxZoom: 19,
                            cameraConstraint: CameraConstraint.contain(
                              bounds: LatLngBounds(
                                const LatLng(14.7500, 121.0000),
                                const LatLng(14.8700, 121.1000),
                              ),
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png",
                              subdomains: const ['a', 'b', 'c', 'd'],
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(
                                      location['lat']!, location['lng']!),
                                  width: 70,
                                  height: 90,
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        color: Colors.red.shade600,
                                        size: 40,
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(5),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.2),
                                              blurRadius: 2,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          clinic?.clinicName ?? '',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Positioned(
                          top: 20,
                          left: 20,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 8 : 12,
                              vertical: isMobile ? 6 : 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: Colors.red.shade600,
                                  size: isMobile ? 14 : 18,
                                ),
                                SizedBox(width: isMobile ? 4 : 6),
                                Text(
                                  clinic?.clinicName ?? '',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: isMobile ? 12 : 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isMobile,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: isMobile ? 18 : 20, color: Colors.grey.shade600),
        SizedBox(width: isMobile ? 8 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Clickable badge to navigate to Settings tab
                  InkWell(
                    onTap: () => _navigateToSettingsTab(),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.settings,
                            size: 12,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Edit in Settings',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                value.isNotEmpty ? value : 'Not provided',
                style: TextStyle(
                  fontSize: isMobile ? 13 : 15,
                  color:
                      value.isNotEmpty ? Colors.black87 : Colors.grey.shade500,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _navigateToSettingsTab() {
    // Store the target tab index in GetStorage
    final storage = GetStorage();
    storage.write('clinicPageInitialTab', 2); // 2 = Settings tab index

    // Call parent callback if provided
    if (widget.onNavigateToSettings != null) {
      widget.onNavigateToSettings!();
    } else {
      // Fallback: Try to update controller
      widget.controller.update();
    }
  }
}
