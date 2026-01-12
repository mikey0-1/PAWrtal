import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/mobile/user/components/pets_components/pet_creation_controller.dart';
import 'package:capstone_app/utils/snackbar_helper.dart';
import 'package:capstone_app/web/user_web/services/web_image_picker_service.dart';
import 'package:capstone_app/web/user_web/services/web_snack_bar_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // NEW: For input formatters
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class WebPetCreationPanel extends StatefulWidget {
  final Pet? existingPet;
  final VoidCallback? onSuccess;

  const WebPetCreationPanel({
    super.key,
    this.existingPet,
    this.onSuccess,
  });

  @override
  State<WebPetCreationPanel> createState() => _WebPetCreationPanelState();
}

class _WebPetCreationPanelState extends State<WebPetCreationPanel> {
  late final PetCreationController controller;
  ImagePickerResult? _selectedImage;

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      PetCreationController(Get.find(), existingPet: widget.existingPet),
      tag: widget.existingPet?.petId ?? 'web_new',
    );
  }

  Future<void> _pickImage() async {
    try {
      final result = await WebImagePickerService.pickImage();
      if (result != null) {
        setState(() {
          _selectedImage = result;
        });

        if (result.isWeb && result.bytes != null) {
          controller.pickWebImage(result.bytes!, result.name);
        } else if (result.isFile && result.file != null) {
          controller.pickImage(result.file!);
        }
      }
    } catch (e) {
      SnackbarHelper.showError(
        title: "Error",
        message: "Failed to pick image: $e",
      );
    }
  }

  Future<void> _pickBirthdate() async {
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
    final isEditing = widget.existingPet != null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? "Edit Pet" : "Add New Pet",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      widget.onSuccess?.call();
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Form(
                key: controller.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Section
                    GestureDetector(
                      onTap: _pickImage,
                      child: Obx(() {
                        final file = controller.imageFile.value;
                        final url = controller.imageUrl.value;

                        Widget imageWidget;

                        if (_selectedImage?.isWeb == true &&
                            _selectedImage?.bytes != null) {
                          imageWidget = ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(_selectedImage!.bytes!,
                                fit: BoxFit.cover),
                          );
                        } else if (file != null) {
                          imageWidget = ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(file, fit: BoxFit.cover),
                          );
                        } else if (url.isNotEmpty) {
                          imageWidget = ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(url, fit: BoxFit.cover),
                          );
                        } else {
                          imageWidget = Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF3498DB).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add_a_photo,
                                  size: 30,
                                  color: Color(0xFF3498DB),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                "Click to add photo",
                                style: TextStyle(
                                  color: Color(0xFF3498DB),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          );
                        }

                        return Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: imageWidget,
                        );
                      }),
                    ),
                    const SizedBox(height: 20),

                    // Form Fields
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller.nameController,
                            "Pet Name *",
                            Icons.pets,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller.typeController,
                            "Type (e.g. Dog, Cat) *",
                            Icons.category,
                            hint: "Dog, Cat, etc.",
                          ),
                        ),
                      ],
                    ),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller.breedController,
                            "Breed *",
                            Icons.pets_outlined,
                            hint: "Enter breed",
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller.colorController,
                            "Color",
                            Icons.palette,
                          ),
                        ),
                      ],
                    ),

                    // Birthdate Picker
                    _buildBirthdatePicker(),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller.weightController,
                            "Weight (kg)",
                            Icons.monitor_weight,
                            isNumber: true,
                            hint: "e.g. 15.5",
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Gender",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value:
                                      controller.genderController.text.isEmpty
                                          ? null
                                          : controller.genderController.text,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                          BorderSide(color: Colors.grey[300]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: Color(0xFF3498DB), width: 2),
                                    ),
                                    fillColor: Colors.grey[50],
                                    filled: true,
                                    contentPadding: const EdgeInsets.all(16),
                                    prefixIcon: Icon(Icons.person_outline,
                                        color: Colors.grey[500]),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'Male', child: Text('Male')),
                                    DropdownMenuItem(
                                        value: 'Female', child: Text('Female')),
                                  ],
                                  onChanged: (value) {
                                    controller.genderController.text =
                                        value ?? '';
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    _buildTextField(
                      controller.notesController,
                      "Notes",
                      Icons.notes,
                      maxLines: 3,
                    ),

                    const SizedBox(height: 32),

                    // Action Buttons
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: Obx(() => ElevatedButton(
                            onPressed: controller.isLoading.value
                                ? null
                                : () async {
                                    if (isEditing) {
                                      await controller.updatePet();
                                    } else {
                                      await controller.createPet();
                                    }
                                    widget.onSuccess?.call();
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3498DB),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: controller.isLoading.value
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    isEditing ? "Update Pet" : "Save Pet",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          )),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBirthdatePicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Birthdate",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          Obx(() {
            final birthdate = controller.selectedBirthdate.value;
            final displayText = birthdate != null
                ? DateFormat('MMMM dd, yyyy').format(birthdate)
                : 'Select birthdate';

            return InkWell(
              onTap: _pickBirthdate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
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
                      )
                    else
                      Icon(Icons.calendar_today, color: Colors.grey[400], size: 18),
                  ],
                ),
              ),
            );
          }),
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
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
    int maxLines = 1,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF3498DB), width: 2),
              ),
              fillColor: Colors.grey[50],
              filled: true,
              contentPadding: const EdgeInsets.all(16),
              prefixIcon: Icon(icon, color: Colors.grey[500]),
            ),
            validator: (value) {
              if (label.contains('*') && (value == null || value.isEmpty)) {
                return "Please enter ${label.replaceAll(' *', '')}";
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    Get.delete<PetCreationController>(
        tag: widget.existingPet?.petId ?? 'web_new');
    super.dispose();
  }
}