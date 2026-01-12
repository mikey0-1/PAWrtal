import 'dart:io';
import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/mobile/user/components/pets_components/pet_creation_controller.dart';
import 'package:capstone_app/web/user_web/services/web_image_picker_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart'; // NEW: For date formatting

class PetCardCreation extends StatelessWidget {
  final Pet? existingPet;
  PetCardCreation({super.key, this.existingPet}) {
    final tag = existingPet?.petId ?? DateTime.now().toString();
    controller = Get.put(
      PetCreationController(Get.find(), existingPet: existingPet),
      tag: tag,
      permanent: false,
    );
  }

  late final PetCreationController controller;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(BuildContext context) async {
    if (kIsWeb) {
      final result = await WebImagePickerService.pickImage();
      if (result != null && result.isWeb) {
        controller.pickWebImage(result.bytes!, result.name);
      }
    } else {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Choose Photo',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3498DB).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Color(0xFF3498DB),
                    ),
                  ),
                  title: const Text('Camera'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3498DB).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.photo_library,
                      color: Color(0xFF3498DB),
                    ),
                  ),
                  title: const Text('Gallery'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          ),
        ),
      );

      if (source != null) {
        final pickedFile = await _picker.pickImage(source: source);
        if (pickedFile != null) {
          controller.pickImage(File(pickedFile.path));
        }
      }
    }
  }

  // NEW: Show date picker for birthdate
  Future<void> _pickBirthdate(BuildContext context) async {
    final initialDate = controller.selectedBirthdate.value ?? DateTime.now();
    final firstDate = DateTime(1990);
    final lastDate = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(lastDate) ? lastDate : initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF3498DB),
              onPrimary: Colors.white,
              onSurface: Color(0xFF2C3E50),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      controller.selectedBirthdate.value = pickedDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = existingPet != null;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF3498DB),
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Get.back(result: true),
        ),
        title: Text(
          isEditing ? "Edit Pet" : "Add New Pet",
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Picker Section
              Center(
                child: GestureDetector(
                  onTap: () => _pickImage(context),
                  child: Obx(() {
                    final file = controller.imageFile.value;
                    final url = controller.imageUrl.value;
                    final bytes = controller.imageBytes.value;

                    return Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF3498DB).withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: () {
                        if (kIsWeb && bytes != null) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.memory(bytes, fit: BoxFit.cover),
                          );
                        } else if (!kIsWeb && file != null) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.file(file, fit: BoxFit.cover),
                          );
                        } else if (url.isNotEmpty) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.network(url, fit: BoxFit.cover),
                          );
                        } else {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF3498DB).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add_a_photo,
                                  size: 40,
                                  color: Color(0xFF3498DB),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Add Pet Photo",
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF3498DB),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Tap to upload",
                                style: GoogleFonts.inter(
                                  color: Colors.grey[500],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          );
                        }
                      }(),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 28),

              Text(
                "Pet Information",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 16),

              // Pet Name
              _buildTextField(
                controller.nameController,
                "Pet Name",
                Icons.pets,
                required: true,
              ),

              // Type & Breed Row
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller.typeController,
                      "Type",
                      Icons.category,
                      hint: "Dog, Cat, etc.",
                      required: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller.breedController,
                      "Breed",
                      Icons.pets_outlined,
                      required: true,
                    ),
                  ),
                ],
              ),

              // NEW: Birthdate Picker
              _buildBirthdatePicker(context),

              // Color & Weight Row
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller.colorController,
                      "Color",
                      Icons.palette,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller.weightController,
                      "Weight (kg)",
                      Icons.monitor_weight,
                      isNumber: true,
                    ),
                  ),
                ],
              ),

              // Gender Dropdown
              _buildGenderDropdown(),

              // Notes
              _buildTextField(
                controller.notesController,
                "Notes",
                Icons.notes,
                maxLines: 4,
                hint: "Any additional information...",
              ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: Obx(() => ElevatedButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : (isEditing
                              ? controller.updatePet
                              : controller.createPet),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3498DB),
                        disabledBackgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: controller.isLoading.value
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isEditing ? Icons.check : Icons.add,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isEditing ? "Update Pet" : "Add Pet",
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    )),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // NEW: Birthdate Picker Widget
  Widget _buildBirthdatePicker(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Birthdate",
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          Obx(() {
            final birthdate = controller.selectedBirthdate.value;
            final displayText = birthdate != null
                ? DateFormat('MMMM dd, yyyy').format(birthdate)
                : 'Select birthdate';

            return InkWell(
              onTap: () => _pickBirthdate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cake, color: Colors.grey[500], size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        displayText,
                        style: TextStyle(
                          fontSize: 15,
                          color: birthdate != null
                              ? const Color(0xFF2C3E50)
                              : Colors.grey[400],
                        ),
                      ),
                    ),
                    if (birthdate != null)
                      IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[400], size: 20),
                        onPressed: () {
                          controller.selectedBirthdate.value = null;
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              ),
            );
          }),
          // NEW: Show calculated age
          Obx(() {
            final birthdate = controller.selectedBirthdate.value;
            if (birthdate == null) return const SizedBox.shrink();

            final pet = Pet(
              petId: '',
              userId: '',
              name: '',
              type: '',
              breed: '',
              birthdate: birthdate,
            );

            return Padding(
              padding: const EdgeInsets.only(top: 8, left: 12),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 6),
                  Text(
                    'Age: ${pet.ageString}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController textController,
    String label,
    IconData icon, {
    bool isNumber = false,
    int maxLines = 1,
    String? hint,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label + (required ? ' *' : ''),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: textController,
            maxLines: maxLines,
            keyboardType: isNumber
                ? const TextInputType.numberWithOptions(decimal: true) 
                : TextInputType.text,
            inputFormatters: isNumber
                ? [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ]
                : null,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              prefixIcon: Icon(icon, color: Colors.grey[500], size: 22),
              filled: true,
              fillColor: Colors.white,
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
                  color: Color(0xFF3498DB),
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            validator: (value) {
              if (required && (value == null || value.isEmpty)) {
                return "Please enter $label";
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Gender",
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: controller.genderController.text.isEmpty
                ? null
                : controller.genderController.text,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.wc, color: Colors.grey[500], size: 22),
              filled: true,
              fillColor: Colors.white,
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
                  color: Color(0xFF3498DB),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            hint: Text(
              'Select gender',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            items: const [
              DropdownMenuItem(value: 'Male', child: Text('Male')),
              DropdownMenuItem(value: 'Female', child: Text('Female')),
            ],
            onChanged: (value) {
              controller.genderController.text = value ?? '';
            },
          ),
        ],
      ),
    );
  }
}