import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/pages/admin_home/admin_home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class ClinicProfileEditPage extends StatefulWidget {
  const ClinicProfileEditPage({super.key});

  @override
  State<ClinicProfileEditPage> createState() => _ClinicProfileEditPageState();
}

class _ClinicProfileEditPageState extends State<ClinicProfileEditPage> {
  final AdminHomeController controller = Get.find<AdminHomeController>();
  
  final _formKey = GlobalKey<FormState>();
  final _clinicNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactController = TextEditingController();
  final _emailController = TextEditingController();
  final _servicesController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  void _loadCurrentData() {
    final clinic = controller.clinic.value;
    if (clinic != null) {
      _clinicNameController.text = clinic.clinicName;
      _addressController.text = clinic.address;
      _contactController.text = clinic.contact;
      _emailController.text = clinic.email;
      _servicesController.text = clinic.services;
      _descriptionController.text = clinic.description;
    }
  }

  @override
  void dispose() {
    _clinicNameController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _servicesController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Create updated clinic data
      final updatedClinic = Clinic.fromMap({
        '\$id': controller.clinic.value?.documentId,
        'clinicName': _clinicNameController.text.trim(),
        'address': _addressController.text.trim(),
        'contact': _contactController.text.trim(),
        'email': _emailController.text.trim(),
        'services': _servicesController.text.trim(),
        'description': _descriptionController.text.trim(),
        'adminId': controller.clinic.value?.adminId,
        'createdBy': controller.clinic.value?.createdBy,
        'role': controller.clinic.value?.role,
        'createdAt': controller.clinic.value?.createdAt,
        'image': controller.clinic.value?.image,
      });

      // TODO: Add update clinic method to your repository
      // await Get.find<AuthRepository>().updateClinic(updatedClinic);
      
      // Update local state
      controller.clinic.value = updatedClinic;
      
      Get.snackbar(
        "Success", 
        "Clinic profile updated successfully!",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      
      Get.back();
    } catch (e) {
      Get.snackbar(
        "Error", 
        "Failed to update clinic profile: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Edit Clinic Profile',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: const Color.fromARGB(255, 81, 115, 153),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Color.fromARGB(255, 81, 115, 153),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveChanges,
            child: Text(
              'Save',
              style: TextStyle(
                color: _isLoading ? Colors.grey : const Color.fromARGB(255, 81, 115, 153),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color.fromARGB(255, 81, 115, 153),
                      Colors.blue.shade400,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.local_hospital,
                        size: 40,
                        color: Color.fromARGB(255, 81, 115, 153),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Clinic Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Update your clinic details that customers will see',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Basic Information Section
              _buildSectionTitle('Basic Information'),
              const SizedBox(height: 12),
              
              _buildTextField(
                controller: _clinicNameController,
                label: 'Clinic Name',
                icon: Icons.local_hospital,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Clinic name is required';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _addressController,
                label: 'Address',
                icon: Icons.location_on,
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Address is required';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _contactController,
                label: 'Contact Number',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Contact number is required';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _emailController,
                label: 'Email Address',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!GetUtils.isEmail(value.trim())) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 32),
              
              // Services Section
              _buildSectionTitle('Services & Description'),
              const SizedBox(height: 12),
              
              _buildTextField(
                controller: _servicesController,
                label: 'Services Offered',
                icon: Icons.medical_services,
                maxLines: 3,
                hintText: 'e.g., Vaccination, Check-up, Grooming, Surgery...',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please describe your services';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _descriptionController,
                label: 'Clinic Description',
                icon: Icons.description,
                maxLines: 4,
                hintText: 'Tell customers about your clinic, experience, and what makes you special...',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide a clinic description';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 32),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Cancel Button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _isLoading ? null : () => Get.back(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color.fromARGB(255, 81, 115, 153),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          prefixIcon: Icon(
            icon,
            color: const Color.fromARGB(255, 81, 115, 153),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          labelStyle: const TextStyle(
            color: Color.fromARGB(255, 81, 115, 153),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color.fromARGB(255, 81, 115, 153),
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}