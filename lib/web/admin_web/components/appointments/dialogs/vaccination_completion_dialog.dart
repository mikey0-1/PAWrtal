import 'package:capstone_app/data/models/appointment_model.dart';
import 'package:capstone_app/utils/snackbar_helper.dart';
import 'package:capstone_app/web/admin_web/components/appointments/admin_web_appointment_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class VaccinationCompletionDialog extends StatefulWidget {
  final Appointment appointment;

  const VaccinationCompletionDialog({
    super.key,
    required this.appointment,
  });

  @override
  State<VaccinationCompletionDialog> createState() =>
      _VaccinationCompletionDialogState();
}

class _VaccinationCompletionDialogState
    extends State<VaccinationCompletionDialog> {
  final _formKey = GlobalKey<FormState>();

  // Vaccination fields
  final _vaccineNameController = TextEditingController();
  final _vaccineTypeController = TextEditingController();
  final _batchNumberController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _notesController = TextEditingController();
  final _vetNotesController = TextEditingController();

  // ADDED: Vitals fields
  final _tempController = TextEditingController();
  final _weightController = TextEditingController();
  final _bpController = TextEditingController();
  final _hrController = TextEditingController();

  DateTime? _nextDueDate;
  bool _isBooster = false;

  // Common vaccine types for quick selection
  final List<String> _commonVaccineTypes = [
    'Rabies',
    'DHPP (Distemper, Hepatitis, Parvovirus, Parainfluenza)',
    'Bordetella',
    'Leptospirosis',
    'Lyme Disease',
    'Canine Influenza',
    'Feline Viral Rhinotracheitis',
    'Feline Calicivirus',
    'Feline Panleukopenia',
    'Feline Leukemia',
    'Other',
  ];

  String? _selectedVaccineType;

  @override
  void initState() {
    super.initState();
    _loadPendingVitals();
  }

  // ADDED: Load pending vitals if they exist
  void _loadPendingVitals() {
    final controller = Get.find<WebAppointmentController>();
    final pendingVitals =
        controller.getPendingVitals(widget.appointment.documentId!);

    if (pendingVitals != null) {
      if (pendingVitals['temperature'] != null) {
        _tempController.text = pendingVitals['temperature'].toString();
      }
      if (pendingVitals['weight'] != null) {
        _weightController.text = pendingVitals['weight'].toString();
      }
      if (pendingVitals['bloodPressure'] != null) {
        _bpController.text = pendingVitals['bloodPressure'].toString();
      }
      if (pendingVitals['heartRate'] != null) {
        _hrController.text = pendingVitals['heartRate'].toString();
      }
    }
  }

  @override
  void dispose() {
    _vaccineNameController.dispose();
    _vaccineTypeController.dispose();
    _batchNumberController.dispose();
    _manufacturerController.dispose();
    _notesController.dispose();
    _vetNotesController.dispose();
    // ADDED: Dispose vitals controllers
    _tempController.dispose();
    _weightController.dispose();
    _bpController.dispose();
    _hrController.dispose();
    super.dispose();
  }

  bool _hasFormChanges() {
    return _vaccineNameController.text.isNotEmpty ||
        _vaccineTypeController.text.isNotEmpty ||
        _batchNumberController.text.isNotEmpty ||
        _manufacturerController.text.isNotEmpty ||
        _notesController.text.isNotEmpty ||
        _vetNotesController.text.isNotEmpty ||
        _tempController.text.isNotEmpty ||
        _weightController.text.isNotEmpty ||
        _bpController.text.isNotEmpty ||
        _hrController.text.isNotEmpty ||
        _nextDueDate != null ||
        _isBooster;
  }

  Future<bool?> _showDiscardChangesDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text(
            'Discard Vaccination Data?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          content: const Text(
            'You have unsaved vaccination information. Are you sure you want to discard it? This action cannot be undone.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(
                'Continue Editing',
                style: TextStyle(
                  color: Color.fromARGB(255, 81, 115, 153),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
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

  void _disposeControllers() {
    _vaccineNameController.dispose();
    _vaccineTypeController.dispose();
    _batchNumberController.dispose();
    _manufacturerController.dispose();
    _notesController.dispose();
    _vetNotesController.dispose();
    _tempController.dispose();
    _weightController.dispose();
    _bpController.dispose();
    _hrController.dispose();
  }

  Future<bool> _onWillPop() async {
    if (_hasFormChanges()) {
      final shouldDiscard = await _showDiscardChangesDialog();
      return shouldDiscard ?? false;
    }
    return true;
  }

  // ADDED: Validation methods for vitals
  String? _validateTemperature(String? value) {
    if (value == null || value.isEmpty) return null;
    final temp = double.tryParse(value);
    if (temp == null) return 'Enter a valid number';
    if (temp < 0 || temp > 50) return 'Temperature must be 0-50°C';
    return null;
  }

  String? _validateWeight(String? value) {
    if (value == null || value.isEmpty) return null;
    final weight = double.tryParse(value);
    if (weight == null) return 'Enter a valid number';
    if (weight < 0 || weight > 500) return 'Weight must be 0-500kg';
    return null;
  }

  String? _validateHeartRate(String? value) {
    if (value == null || value.isEmpty) return null;
    final hr = int.tryParse(value);
    if (hr == null) return 'Enter a valid whole number';
    if (hr < 0 || hr > 300) return 'Heart rate must be 0-300 bpm';
    return null;
  }

  String? _validateBloodPressure(String? value) {
    if (value == null || value.isEmpty) return null;
    final bpPattern = RegExp(r'^\d{2,3}\/\d{2,3}');
    if (!bpPattern.hasMatch(value)) return 'Format: 120/80';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WebAppointmentController>();
    final petName = controller.getPetName(widget.appointment.petId);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 700,
          constraints: const BoxConstraints(maxHeight: 800),
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.vaccines,
                        color: Colors.green,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Complete Vaccination Service',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 81, 115, 153),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Recording vaccination for $petName',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        if (_hasFormChanges()) {
                          final shouldDiscard =
                              await _showDiscardChangesDialog();
                          if (shouldDiscard == true) {
                            if (mounted) Navigator.pop(context);
                          }
                        } else {
                          if (mounted) Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Vaccine Type Dropdown
                        const Text(
                          'Vaccine Type *',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color.fromARGB(255, 81, 115, 153),
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedVaccineType,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Select vaccine type',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          items: _commonVaccineTypes.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(
                                type,
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedVaccineType = value;
                              if (value != 'Other') {
                                _vaccineTypeController.text = value!;
                              } else {
                                _vaccineTypeController.clear();
                              }
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a vaccine type';
                            }
                            return null;
                          },
                        ),

                        if (_selectedVaccineType == 'Other') ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _vaccineTypeController,
                            decoration: const InputDecoration(
                              labelText: 'Custom Vaccine Type *',
                              border: OutlineInputBorder(),
                              hintText: 'Enter vaccine type',
                            ),
                            onChanged: (value) => setState(() {}),
                            validator: (value) {
                              if (_selectedVaccineType == 'Other' &&
                                  (value == null || value.isEmpty)) {
                                return 'Please enter vaccine type';
                              }
                              return null;
                            },
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Vaccine Name
                        TextFormField(
                          controller: _vaccineNameController,
                          decoration: const InputDecoration(
                            labelText: 'Vaccine Brand/Product Name *',
                            border: OutlineInputBorder(),
                            hintText: 'e.g., Nobivac, Purevax, etc.',
                          ),
                          onChanged: (value) => setState(() {}),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter vaccine name';
                            }
                            return null;
                          },
                        ),

                        // const SizedBox(height: 24),
                        // const Divider(),
                        const SizedBox(height: 16),

                        // Batch Number and Manufacturer
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _batchNumberController,
                                decoration: const InputDecoration(
                                  labelText: 'Batch Number',
                                  border: OutlineInputBorder(),
                                  hintText: 'Optional',
                                ),
                                onChanged: (value) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _manufacturerController,
                                decoration: const InputDecoration(
                                  labelText: 'Manufacturer',
                                  border: OutlineInputBorder(),
                                  hintText: 'Optional',
                                ),
                                onChanged: (value) => setState(() {}),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Booster checkbox
                        CheckboxListTile(
                          title: const Text('This is a booster shot'),
                          subtitle: const Text(
                            'Check if this is a follow-up/booster vaccination',
                            style: TextStyle(fontSize: 12),
                          ),
                          value: _isBooster,
                          onChanged: (value) {
                            setState(() {
                              _isBooster = value ?? false;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),

                        const SizedBox(height: 16),

                        // Next Due Date
                        InkWell(
                          onTap: () => _selectNextDueDate(context),
                          child: FormField<DateTime>(
                            validator: (value) {
                              if (_nextDueDate == null) {
                                return 'Please select next due date';
                              }
                              return null;
                            },
                            builder: (FormFieldState<DateTime> state) {
                              return InkWell(
                                onTap: () => _selectNextDueDate(context),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Next Due Date *',
                                    border: const OutlineInputBorder(),
                                    suffixIcon:
                                        const Icon(Icons.calendar_today),
                                    errorText: state.errorText,
                                  ),
                                  child: Text(
                                    _nextDueDate != null
                                        ? DateFormat('MMMM dd, yyyy')
                                            .format(_nextDueDate!)
                                        : 'Select date',
                                    style: TextStyle(
                                      color: _nextDueDate != null
                                          ? Colors.black87
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Vaccination Notes
                        TextFormField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            labelText: 'Vaccination Notes',
                            border: OutlineInputBorder(),
                            hintText:
                                'Any reactions, special instructions, etc.',
                          ),
                          maxLines: 3,
                          onChanged: (value) => setState(() {}),
                        ),

                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),

                        // ADDED: Vitals Section
                        Row(
                          children: [
                            Icon(Icons.favorite,
                                color: Colors.red[700], size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Vital Signs (Optional)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 81, 115, 153),
                              ),
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
                                  color: Colors.blue[700], size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Record vital signs taken during vaccination visit',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.blue[700]),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Temperature and Weight
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _tempController,
                                decoration: const InputDecoration(
                                  labelText: 'Temperature (°C)',
                                  border: OutlineInputBorder(),
                                  hintText: '36.0 - 40.0',
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                validator: _validateTemperature,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _weightController,
                                decoration: const InputDecoration(
                                  labelText: 'Weight (kg)',
                                  border: OutlineInputBorder(),
                                  hintText: '5.0 - 50.0',
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                validator: _validateWeight,
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
                                controller: _bpController,
                                decoration: const InputDecoration(
                                  labelText: 'Blood Pressure',
                                  border: OutlineInputBorder(),
                                  hintText: '120/80',
                                ),
                                validator: _validateBloodPressure,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _hrController,
                                decoration: const InputDecoration(
                                  labelText: 'Heart Rate (bpm)',
                                  border: OutlineInputBorder(),
                                  hintText: '60 - 100',
                                ),
                                keyboardType: TextInputType.number,
                                validator: _validateHeartRate,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Veterinary Notes
                        TextFormField(
                          controller: _vetNotesController,
                          decoration: const InputDecoration(
                            labelText: 'Medical Record Notes',
                            border: OutlineInputBorder(),
                            hintText: 'Additional notes for the medical record',
                          ),
                          maxLines: 3,
                          onChanged: (value) => setState(() {}),
                        ),

                        const SizedBox(height: 16),

                        // Info box
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle,
                                  color: Colors.green[700]),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'This will create a vaccination record, medical record, and save any vitals recorded.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () async {
                        if (_hasFormChanges()) {
                          final shouldDiscard =
                              await _showDiscardChangesDialog();
                          if (shouldDiscard == true) {
                            _disposeControllers();
                            if (mounted) Navigator.pop(context);
                          }
                        } else {
                          _disposeControllers();
                          if (mounted) Navigator.pop(context);
                        }
                      },
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _submitVaccination,
                      icon: const Icon(Icons.check),
                      label: const Text('Complete Vaccination'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectNextDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      helpText: 'Select next vaccination due date',
    );

    if (picked != null && mounted) {
      setState(() {
        _nextDueDate = picked;
      });
    }
  }

  void _submitVaccination() async {
    if (_formKey.currentState!.validate()) {
      final controller = Get.find<WebAppointmentController>();
      final vetName = controller.getVeterinarianName();

      // Build vitals map if any vital data is present
      Map<String, dynamic>? vitalsData;
      if (_tempController.text.isNotEmpty ||
          _weightController.text.isNotEmpty ||
          _bpController.text.isNotEmpty ||
          _hrController.text.isNotEmpty) {
        vitalsData = {};

        if (_tempController.text.isNotEmpty) {
          vitalsData['temperature'] = double.parse(_tempController.text);
        }
        if (_weightController.text.isNotEmpty) {
          vitalsData['weight'] = double.parse(_weightController.text);
        }
        if (_bpController.text.isNotEmpty) {
          vitalsData['bloodPressure'] = _bpController.text;
        }
        if (_hrController.text.isNotEmpty) {
          vitalsData['heartRate'] = int.parse(_hrController.text);
        }
      }

      final vaccinationData = {
        'vaccineType': _vaccineTypeController.text.trim(),
        'vaccineName': _vaccineNameController.text.trim(),
        'batchNumber': _batchNumberController.text.trim().isNotEmpty
            ? _batchNumberController.text.trim()
            : null,
        'manufacturer': _manufacturerController.text.trim().isNotEmpty
            ? _manufacturerController.text.trim()
            : null,
        'nextDueDate': _nextDueDate,
        'isBooster': _isBooster,
        'notes': _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        'veterinarianName': vetName,
      };

      // Close dialog BEFORE starting the async operation
      if (mounted) Navigator.pop(context);

      try {
        // Call the updated method with vitals
        await controller.completeVaccinationServiceWithVitals(
          appointment: widget.appointment,
          vaccinationData: vaccinationData,
          vetNotes: _vetNotesController.text.trim().isNotEmpty
              ? _vetNotesController.text.trim()
              : null,
          vitals: vitalsData,
        );

        // Success snackbar is already shown in the controller method
      } catch (e) {
        // Error snackbar is already shown in the controller method
      }
    } else {
      // Show validation error
      SnackbarHelper.showWarning(
        context: context,
        title: "Validation Error",
        message: "Please fill in all required fields correctly.",
      );
    }
  }
}
