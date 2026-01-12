import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:capstone_app/pages/vet_clinic_registration/vet_clinic_registration_controller.dart';

class VetClinicRegistrationPage
    extends GetView<VetClinicRegistrationController> {
  const VetClinicRegistrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width <= 785;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Color(0xFF517399)),
          onPressed: () => Get.back(),
        ),
        title: Image.asset(
          'lib/images/PAWrtal_logo.png',
          height: 35,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 40),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(isMobile),
                const SizedBox(height: 32),

                // Form Card
                Container(
                  padding: EdgeInsets.all(isMobile ? 20 : 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: controller.formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextField(
                          controller: controller.clinicNameController,
                          label: 'Veterinary Clinic Name',
                          hint: 'e.g., Happy Paws Veterinary Clinic',
                          icon: Icons.local_hospital_rounded,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Clinic name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Address Section Header
                        const Text(
                          'Clinic Location',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF517399),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Searchable Barangay Dropdown
                        _buildSearchableBarangayDropdown(isMobile),
                        const SizedBox(height: 16),

                        // Street/Subdivision
                        _buildTextField(
                          controller: controller.streetController,
                          label: 'Street/Subdivision Name',
                          hint: 'e.g., Main Street, Greenfield Subdivision',
                          icon: Icons.route_rounded,
                          validator: null, // Optional field
                        ),
                        const SizedBox(height: 16),

                        // Block/Lot and Building/Unit in a Row
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: controller.blockController,
                                label: 'Block/Lot No.',
                                hint: 'Block 5 Lot 10',
                                icon: Icons.tag_rounded,
                                validator: null, // Optional
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                controller: controller.buildingController,
                                label: 'Building/Unit',
                                hint: 'Unit 201',
                                icon: Icons.apartment_rounded,
                                validator: null, // Optional
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Address Preview
                        Obx(() {
                          final address = controller.getCompleteAddress();
                          if (address.isNotEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.preview_rounded,
                                          size: 16, color: Colors.blue[700]),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Address Preview:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    address,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }),

                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 24),

                        // Contact Information Header
                        const Text(
                          'Contact Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF517399),
                          ),
                        ),
                        const SizedBox(height: 12),

                        _buildTextField(
                          controller: controller.contactController,
                          label: 'Contact Number',
                          hint: '09XXXXXXXXX',
                          icon: Icons.phone_rounded,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                          ],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Contact number is required';
                            }
                            if (value.length != 11) {
                              return 'Must be 11 digits';
                            }
                            if (!value.startsWith('09')) {
                              return 'Must start with 09';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        _buildTextField(
                          controller: controller.emailController,
                          label: 'Email Address',
                          hint: 'clinic@example.com',
                          icon: Icons.email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Email is required';
                            }
                            if (!GetUtils.isEmail(value)) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        _buildDocumentUpload(isMobile),
                        const SizedBox(height: 32),

                        _buildSubmitButton(isMobile),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF517399), Color(0xFF6B8EB3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.app_registration_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clinic Registration',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 20 : 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Join PAWrtal Today',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: isMobile ? 13 : 15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Fill out the form below to register your veterinary clinic. Our team will review your application within 1-2 business days.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.95),
              fontSize: isMobile ? 13 : 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF517399)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
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
          borderSide: const BorderSide(color: Color(0xFF517399), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildSearchableBarangayDropdown(bool isMobile) {
    return Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller.barangaySearchController,
              decoration: InputDecoration(
                labelText: 'Barangay',
                hintText: 'Search or select barangay',
                prefixIcon: const Icon(Icons.location_on_rounded,
                    color: Color(0xFF517399)),
                suffixIcon: controller.barangaySearchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: controller.clearBarangaySearch,
                      )
                    : const Icon(Icons.arrow_drop_down_rounded),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
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
                  borderSide:
                      const BorderSide(color: Color(0xFF517399), width: 2),
                ),
              ),
              onTap: () {
                controller.showBarangayDropdown.value = true;
              },
              onChanged: (value) {
                // Filtering is handled by listener in controller
              },
            ),

            // Dropdown list
            if (controller.showBarangayDropdown.value &&
                controller.filteredBarangays.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                constraints: BoxConstraints(
                  maxHeight: isMobile ? 200 : 250,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: controller.filteredBarangays.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: Colors.grey[200],
                    ),
                    itemBuilder: (context, index) {
                      final barangay = controller.filteredBarangays[index];
                      final query = controller.barangaySearchController.text
                          .toLowerCase();
                      final barangayLower = barangay.toLowerCase();
                      final matchIndex = barangayLower.indexOf(query);

                      return ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.location_city_rounded,
                          color: const Color(0xFF517399),
                          size: isMobile ? 18 : 20,
                        ),
                        title: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: isMobile ? 12 : 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            children: matchIndex >= 0 && query.isNotEmpty
                                ? [
                                    TextSpan(
                                        text:
                                            barangay.substring(0, matchIndex)),
                                    TextSpan(
                                      text: barangay.substring(
                                        matchIndex,
                                        matchIndex + query.length,
                                      ),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF517399),
                                        backgroundColor: Color(0xFFE3F2FD),
                                      ),
                                    ),
                                    TextSpan(
                                      text: barangay
                                          .substring(matchIndex + query.length),
                                    ),
                                  ]
                                : [TextSpan(text: barangay)],
                          ),
                        ),
                        onTap: () => controller.selectBarangay(barangay),
                        hoverColor: const Color(0xFF517399).withOpacity(0.1),
                      );
                    },
                  ),
                ),
              ),

            // No results message
            if (controller.showBarangayDropdown.value &&
                controller.filteredBarangays.isEmpty &&
                controller.barangaySearchController.text.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search_off,
                        color: Colors.grey, size: isMobile ? 18 : 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No barangay found matching "${controller.barangaySearchController.text}"',
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Validation error for barangay
            if (controller.selectedBarangay.value.isEmpty &&
                controller.barangaySearchController.text.isEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 8),
                child: Text(
                  'Please select a barangay from the list',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
          ],
        ));
  }

  Widget _buildDocumentUpload(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Required Documents',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF517399),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Upload business registration, permits, and other relevant documents (PDF, JPG, PNG)',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        Obx(() => Column(
              children: [
                // Upload Button
                InkWell(
                  onTap: controller.isUploading.value
                      ? null
                      : controller.pickFiles,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      border: Border.all(
                        color: const Color(0xFF517399).withOpacity(0.3),
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.cloud_upload_rounded,
                          size: 48,
                          color: const Color(0xFF517399).withOpacity(0.7),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          controller.isUploading.value
                              ? 'Uploading...'
                              : 'Click to upload documents',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF517399),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'PDF, JPG, PNG (Max 5MB each)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Uploaded Files List
                if (controller.uploadedFiles.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ...controller.uploadedFiles.asMap().entries.map((entry) {
                    final index = entry.key;
                    final file = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getFileIcon(file.name),
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  file.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _formatFileSize(file.size),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () => controller.removeFile(index),
                            color: Colors.red,
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            )),
      ],
    );
  }

  Widget _buildSubmitButton(bool isMobile) {
    return Obx(() => SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: controller.isSubmitting.value
                ? null
                : controller.submitRegistration,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF517399),
              disabledBackgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: controller.isSubmitting.value
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send_rounded, size: 22, color: Colors.white),
                      SizedBox(width: 12),
                      Text(
                        'Submit Registration',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ));
  }

  IconData _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
