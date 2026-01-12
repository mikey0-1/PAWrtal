import 'package:capstone_app/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:appwrite/appwrite.dart';
import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';

class StaffFullDetails extends StatefulWidget {
  final String staffName;
  final String username;
  final String? phone;
  final String? email;
  final Function(List<String>) onAuthoritiesUpdated;
  final List<String> initialAuthorities;
  final VoidCallback onRemove;
  final Uint8List? imageBytes;
  final String staffDocumentId;
  final String? currentImageUrl;
  final bool isDoctor; // ADD THIS

  const StaffFullDetails({
    required this.staffName,
    required this.username,
    this.phone,
    this.email,
    required this.onAuthoritiesUpdated,
    required this.initialAuthorities,
    required this.onRemove,
    this.imageBytes,
    required this.staffDocumentId,
    this.currentImageUrl,
    this.isDoctor = false, // ADD THIS with default
    super.key,
  });

  @override
  State<StaffFullDetails> createState() => _StaffFullDetailsState();
}

class _StaffFullDetailsState extends State<StaffFullDetails> {
  late bool hasClinicAuthority;
  late bool hasAppointmentsAuthority;
  late bool hasMessagesAuthority;
  late TextEditingController phoneController;
  late TextEditingController emailController;

  late bool isDoctor;
  late bool originalIsDoctor;

  bool isEditMode = false;
  bool showDeleteConfirm = false;
  bool hasChanges = false;

  // Image editing variables
  Uint8List? newImageBytes;
  bool imageChanged = false;

  // Store original values for comparison
  late bool originalClinicAuth;
  late bool originalAppointmentsAuth;
  late bool originalMessagesAuth;
  late String originalPhone;
  late String originalEmail;

  static const Color primaryBlue = Color(0xFF4A6FA5);
  static const Color primaryTeal = Color(0xFF5B9BD5);
  static const Color lightTeal = Color(0xFF9FC5E8);
  static const Color deepBlue = Color(0xFF2F4F7F);
  static const Color softBlue = Color(0xFF6FA8DC);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color mediumGray = Color(0xFF9CA3AF);
  static const Color darkText = Color(0xFF374151);
  static const Color vetGreen = Color(0xFF34D399);
  static const Color vetOrange = Color(0xFFF59E0B);
  static const Color vetPurple = Color(0xFFA855F7);
  static const Color lightVetGreen = Color(0xFFE5F7E5);

  @override
  void initState() {
    super.initState();
    hasClinicAuthority = widget.initialAuthorities.contains('Clinic');
    hasAppointmentsAuthority =
        widget.initialAuthorities.contains('Appointments');
    hasMessagesAuthority = widget.initialAuthorities.contains('Messages');

    // Store original values
    originalClinicAuth = hasClinicAuthority;
    originalAppointmentsAuth = hasAppointmentsAuthority;
    originalMessagesAuth = hasMessagesAuthority;

    // Initialize phone controller
    final phoneValue = widget.phone ?? '';
    final phoneDigits = phoneValue.startsWith('09') && phoneValue.length == 11
        ? phoneValue.substring(2)
        : phoneValue;
    phoneController = TextEditingController(text: phoneDigits);
    originalPhone = phoneDigits;

    // Initialize email controller
    final emailValue = widget.email ?? '';
    emailController = TextEditingController(text: emailValue);
    originalEmail = emailValue;

    // FIXED: Initialize isDoctor from widget parameter
    isDoctor = widget.isDoctor;
    originalIsDoctor = widget.isDoctor;

    phoneController.addListener(_checkForChanges);
    emailController.addListener(_checkForChanges);
  }

  @override
  void dispose() {
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  void _checkForChanges() {
    setState(() {
      hasChanges = hasClinicAuthority != originalClinicAuth ||
          hasAppointmentsAuthority != originalAppointmentsAuth ||
          hasMessagesAuthority != originalMessagesAuth ||
          phoneController.text.trim() != originalPhone ||
          emailController.text.trim() != originalEmail ||
          imageChanged ||
          isDoctor != originalIsDoctor;
    });
  }

  Future<void> _pickImage() async {
    if (!isEditMode) return;

    final ImagePicker picker = ImagePicker();
    try {
      final XFile? result = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (result != null) {
        final bytes = await result.readAsBytes();
        if (bytes.length > 5 * 1024 * 1024) {
          SnackbarHelper.showError(
            context: Get.context,
            title: "Image Too Large",
            message: "Image size must be less than 5MB",
          );
          return;
        }
        setState(() {
          newImageBytes = bytes;
          imageChanged = true;
          _checkForChanges();
        });
      }
    } catch (e) {
      SnackbarHelper.showError(
        context: Get.context,
        title: "Error",
        message: "Failed to pick image",
      );
    }
  }

  void _toggleEditMode() {
    if (isEditMode && hasChanges) {
      _showUnsavedChangesDialog();
    } else {
      setState(() {
        isEditMode = !isEditMode;
        showDeleteConfirm = false;
        if (!isEditMode) {
          // Reset to original values
          hasClinicAuthority = originalClinicAuth;
          hasAppointmentsAuthority = originalAppointmentsAuth;
          hasMessagesAuthority = originalMessagesAuth;
          phoneController.text = originalPhone;
          emailController.text = originalEmail;
          hasChanges = false;
          imageChanged = false;
          newImageBytes = null;
          isDoctor = originalIsDoctor;
        }
      });
    }
  }

  void _showUnsavedChangesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: vetOrange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: vetOrange, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Unsaved Changes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          'You have unsaved changes. Are you sure you want to discard them?',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: mediumGray, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                isEditMode = false;
                showDeleteConfirm = false;
                hasClinicAuthority = originalClinicAuth;
                hasAppointmentsAuthority = originalAppointmentsAuth;
                hasMessagesAuthority = originalMessagesAuth;
                phoneController.text = originalPhone;
                emailController.text = originalEmail;
                hasChanges = false;
                imageChanged = false;
                newImageBytes = null;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: vetOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Discard Changes'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleUpdate() async {
    final updatedAuthorities = <String>[];
    if (hasClinicAuthority) updatedAuthorities.add('Clinic');
    if (hasAppointmentsAuthority) updatedAuthorities.add('Appointments');
    if (hasMessagesAuthority) updatedAuthorities.add('Messages');

    final phoneValue = phoneController.text.trim();
    final fullPhone = phoneValue.isNotEmpty ? '09$phoneValue' : '';

    final emailValue = emailController.text.trim();

    try {
      final authRepo = Get.find<AuthRepository>();

      // Handle image upload if changed
      String? finalImageUrl = widget.currentImageUrl;
      if (imageChanged && newImageBytes != null) {
        try {
          final inputFile = InputFile.fromBytes(
            bytes: newImageBytes!,
            filename:
                "${DateTime.now().millisecondsSinceEpoch}_staff_${widget.staffDocumentId}.jpg",
          );

          final uploadedImage = await authRepo.uploadImage(inputFile);
          finalImageUrl = authRepo.getImageUrl(uploadedImage.$id);

          // Delete old image if present
          if (widget.currentImageUrl != null &&
              widget.currentImageUrl!.isNotEmpty) {
            try {
              final oldFileId =
                  widget.currentImageUrl!.split('/').last.split('?').first;
              await authRepo.deleteImage(oldFileId);
            } catch (e) {}
          }
        } catch (e) {
          SnackbarHelper.showWarning(
            context: Get.context,
            title: "Warning",
            message: "Failed to upload new image, other changes will be saved",
          );
        }
      }

      // Update authorities
      await authRepo.updateStaffAuthorities(
        widget.staffDocumentId,
        updatedAuthorities,
      );

      // Update staff info (phone + email + image)
      await authRepo.updateStaffInfo(
        staffDocumentId: widget.staffDocumentId,
        phone: fullPhone,
        email: emailValue,
        image: finalImageUrl,
      );

      await authRepo.updateStaffDoctorStatus(
        widget.staffDocumentId,
        isDoctor,
      );

      // Persist originals for future comparisons
      originalClinicAuth = hasClinicAuthority;
      originalAppointmentsAuth = hasAppointmentsAuthority;
      originalMessagesAuth = hasMessagesAuthority;
      originalPhone = phoneValue;
      originalEmail = emailValue;
      originalIsDoctor = isDoctor;

      widget.onAuthoritiesUpdated(updatedAuthorities);

      setState(() {
        isEditMode = false;
        hasChanges = false;
        imageChanged = false;
        newImageBytes = null;
      });

      Navigator.of(context).pop();

      SnackbarHelper.showSuccess(
        context: Get.context,
        title: "Success",
        message: "${widget.staffName}'s details updated successfully",
      );
    } catch (e) {
      SnackbarHelper.showError(
        context: Get.context,
        title: "Error",
        message: "Failed to update staff details",
      );
    }
  }

  void _handleRemove() {
    if (showDeleteConfirm) {
      widget.onRemove();
      Navigator.of(context).pop();

      SnackbarHelper.showSuccess(
        context: context,
        title: "Success",
        message: "${widget.staffName} has been removed",
      );
    } else {
      setState(() {
        showDeleteConfirm = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isDesktop = screenWidth > 768;
    final dialogWidth = isDesktop ? 520.0 : screenWidth * 0.9;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.9,
          maxWidth: screenWidth * 0.95,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: primaryTeal.withOpacity(0.15),
              blurRadius: 25,
              offset: const Offset(0, 10),
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isDesktop ? 28 : 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primaryBlue, primaryTeal, softBlue],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryTeal.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: _buildHeader(),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isDesktop ? 28 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      'Account Information',
                      Icons.account_circle_outlined,
                      primaryBlue,
                      subtitle: 'Login credentials and contact details',
                    ),
                    const SizedBox(height: 20),
                    _buildAccountInfoSection(),
                    const SizedBox(height: 28),
                    _buildSectionHeader(
                      'Access Permissions',
                      Icons.security_rounded,
                      vetGreen,
                      subtitle: isEditMode
                          ? 'Toggle permissions for this staff member'
                          : 'View permissions for this staff member',
                    ),
                    const SizedBox(height: 20),
                    _buildPermissionsSection(),
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      'Medical Credentials',
                      Icons.medical_services,
                      Colors.red,
                      subtitle: isEditMode
                          ? 'Toggle if this staff member is a licensed veterinarian'
                          : 'View medical license status',
                    ),
                    const SizedBox(height: 20),
                    _buildDoctorSection(),
                    if (showDeleteConfirm && isEditMode) ...[
                      const SizedBox(height: 20),
                      _buildDeleteConfirmation(),
                    ],
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: EdgeInsets.all(isDesktop ? 24 : 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [lightGray, lightVetGreen.withOpacity(0.3)],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: _buildActionButtons(screenWidth > 500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Profile Image with Edit Option
        Stack(
          children: [
            GestureDetector(
              onTap: isEditMode ? _pickImage : null,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: isEditMode
                        ? (imageChanged ? vetGreen : primaryTeal)
                        : Colors.white,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _getCurrentImage(),
                ),
              ),
            ),
            if (isEditMode)
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: primaryTeal,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: primaryTeal.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          widget.staffName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: const Text(
            'Staff Member',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (isEditMode && imageChanged) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: vetGreen.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.5)),
            ),
            child: const Text(
              'Image Changed - Save to Apply',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _getCurrentImage() {
    if (imageChanged && newImageBytes != null) {
      return Image.memory(
        newImageBytes!,
        fit: BoxFit.cover,
        width: 92,
        height: 92,
      );
    }

    if (widget.currentImageUrl != null && widget.currentImageUrl!.isNotEmpty) {
      return Image.network(
        widget.currentImageUrl!,
        fit: BoxFit.cover,
        width: 92,
        height: 92,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: lightVetGreen.withOpacity(0.3),
            ),
            child: const Icon(Icons.person, size: 45, color: primaryTeal),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: lightVetGreen.withOpacity(0.3),
            ),
            child: const CircularProgressIndicator(
              color: primaryTeal,
              strokeWidth: 2,
            ),
          );
        },
      );
    }

    if (widget.imageBytes != null) {
      return Image.memory(
        widget.imageBytes!,
        fit: BoxFit.cover,
        width: 92,
        height: 92,
      );
    }

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: lightVetGreen.withOpacity(0.3),
      ),
      child: const Icon(Icons.person, size: 45, color: primaryTeal),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color,
      {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: const TextStyle(color: mediumGray, fontSize: 13),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: lightGray,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryTeal.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: primaryTeal.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Username (Read-only)
          _buildInfoRow(
            Icons.account_circle,
            'Username',
            widget.username,
            isReadOnly: true,
          ),
          const SizedBox(height: 16),

          // Password (Hidden, Read-only)
          _buildPasswordRow(),
          const SizedBox(height: 16),

          // Email (Editable)
          if (isEditMode)
            _buildEmailEditField()
          else
            _buildInfoRow(
              Icons.email_outlined,
              'Email',
              (widget.email != null && widget.email!.isNotEmpty)
                  ? widget.email!
                  : 'Not provided',
            ),
          const SizedBox(height: 16),

          // Phone (Editable)
          if (isEditMode)
            _buildPhoneEditField()
          else
            _buildInfoRow(
              Icons.phone_outlined,
              'Phone',
              (widget.phone != null && widget.phone!.isNotEmpty)
                  ? widget.phone!
                  : 'Not provided',
            ),
        ],
      ),
    );
  }

  Widget _buildPasswordRow() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: vetOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.lock_outline, size: 20, color: vetOrange),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Password',
                style: TextStyle(
                  fontSize: 12,
                  color: mediumGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text(
                    '••••••••',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: darkText,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, size: 10, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Hidden',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
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
      ],
    );
  }

  Widget _buildEmailEditField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: vetPurple.withOpacity(0.3)),
      ),
      child: TextFormField(
        controller: emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          labelText: 'Email (Optional)',
          labelStyle: const TextStyle(color: mediumGray, fontSize: 14),
          hintText: 'example@email.com',
          hintStyle: TextStyle(color: mediumGray.withOpacity(0.4)),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: vetPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.email_outlined, color: vetPurple, size: 18),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: false,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildPhoneEditField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryTeal.withOpacity(0.3)),
      ),
      child: TextFormField(
        controller: phoneController,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(9),
        ],
        decoration: InputDecoration(
          labelText: 'Phone Number (Optional)',
          labelStyle: const TextStyle(color: mediumGray, fontSize: 14),
          hintText: '123456789',
          hintStyle: TextStyle(color: mediumGray.withOpacity(0.4)),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryTeal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                const Icon(Icons.phone_outlined, color: primaryTeal, size: 18),
          ),
          prefix: Container(
            padding: const EdgeInsets.only(right: 4),
            child: const Text(
              '09',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: false,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildPermissionsSection() {
    if (isEditMode) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: primaryTeal.withOpacity(0.3), width: 2),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primaryTeal.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildAuthSwitchTile(
              'Clinic Page',
              'Access to clinic information',
              Icons.local_hospital_rounded,
              [primaryTeal, primaryBlue],
              hasClinicAuthority,
              (val) {
                setState(() {
                  hasClinicAuthority = val ?? false;
                  _checkForChanges();
                });
              },
            ),
            Divider(height: 1, color: Colors.grey[300]),
            _buildAuthSwitchTile(
              'Appointments',
              'Manage appointments',
              Icons.calendar_month_rounded,
              [primaryBlue, softBlue],
              hasAppointmentsAuthority,
              (val) {
                setState(() {
                  hasAppointmentsAuthority = val ?? false;
                  _checkForChanges();
                });
              },
            ),
            Divider(height: 1, color: Colors.grey[300]),
            _buildAuthSwitchTile(
              'Messages',
              'Access messaging system',
              Icons.message_rounded,
              [vetOrange, primaryTeal],
              hasMessagesAuthority,
              (val) {
                setState(() {
                  hasMessagesAuthority = val ?? false;
                  _checkForChanges();
                });
              },
            ),
          ],
        ),
      );
    } else {
      // Display-only mode
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: lightGray,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryTeal.withOpacity(0.3), width: 2),
        ),
        child: Column(
          children: [
            _buildPermissionDisplayRow(
              'Clinic Page',
              Icons.local_hospital_rounded,
              hasClinicAuthority,
              primaryTeal,
            ),
            const SizedBox(height: 12),
            _buildPermissionDisplayRow(
              'Appointments',
              Icons.calendar_month_rounded,
              hasAppointmentsAuthority,
              primaryBlue,
            ),
            const SizedBox(height: 12),
            _buildPermissionDisplayRow(
              'Messages',
              Icons.message_rounded,
              hasMessagesAuthority,
              vetOrange,
            ),
          ],
        ),
      );
    }
  }

  Widget _buildPermissionDisplayRow(
    String title,
    IconData icon,
    bool hasPermission,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: darkText,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: hasPermission
                ? vetGreen.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: hasPermission
                  ? vetGreen.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasPermission ? Icons.check_circle : Icons.cancel,
                size: 16,
                color: hasPermission ? vetGreen : Colors.grey,
              ),
              const SizedBox(width: 6),
              Text(
                hasPermission ? 'Granted' : 'Denied',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: hasPermission ? vetGreen : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeleteConfirmation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[300]!, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.warning_amber_rounded,
                color: Colors.red[700], size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Are you sure you want to remove ${widget.staffName}? This action cannot be undone.',
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isWide) {
    if (!isEditMode) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Close',
              style: TextStyle(
                color: mediumGray,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient:
                  const LinearGradient(colors: [primaryTeal, primaryBlue]),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: primaryTeal.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _toggleEditMode,
              icon: const Icon(Icons.edit, size: 18, color: Colors.white),
              label: const Text('Edit', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      );
    }

    if (isWide) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!showDeleteConfirm)
            TextButton.icon(
              onPressed: _handleRemove,
              icon: const Icon(Icons.delete_outline, size: 20),
              label: const Text('Remove'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            )
          else
            Row(
              children: [
                TextButton(
                  onPressed: () => setState(() => showDeleteConfirm = false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: mediumGray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _handleRemove,
                  icon: const Icon(Icons.delete_forever, size: 18),
                  label: const Text('Confirm Remove'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          if (!showDeleteConfirm)
            Row(
              children: [
                TextButton(
                  onPressed: _toggleEditMode,
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      color: mediumGray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  decoration: BoxDecoration(
                    gradient:
                        const LinearGradient(colors: [vetGreen, primaryTeal]),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: vetGreen.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: hasChanges ? _handleUpdate : null,
                    icon: const Icon(Icons.save_outlined,
                        size: 18, color: Colors.white),
                    label: const Text('Save Changes',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      disabledBackgroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
        ],
      );
    } else {
      return Column(
        children: [
          if (showDeleteConfirm) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => setState(() => showDeleteConfirm = false),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: mediumGray,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _handleRemove,
                    icon: const Icon(Icons.delete_forever, size: 18),
                    label: const Text('Confirm'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: _handleRemove,
                    icon: const Icon(Icons.delete_outline, size: 20),
                    label: const Text('Remove'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton(
                    onPressed: _toggleEditMode,
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        color: mediumGray,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  gradient:
                      const LinearGradient(colors: [vetGreen, primaryTeal]),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: vetGreen.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: hasChanges ? _handleUpdate : null,
                  icon: const Icon(Icons.save_outlined,
                      size: 18, color: Colors.white),
                  label: const Text('Save Changes',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    disabledBackgroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {bool isReadOnly = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryTeal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: primaryTeal),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: mediumGray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isReadOnly) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock, size: 9, color: Colors.grey[600]),
                          const SizedBox(width: 3),
                          Text(
                            'Read-only',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: darkText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAuthSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    List<Color> colors,
    bool value,
    Function(bool?) onChanged,
  ) {
    return SwitchListTile(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colors.first.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: colors.first),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(left: 40, top: 6),
        child: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: mediumGray),
        ),
      ),
      value: value,
      onChanged: (b) => onChanged(b),
      activeColor: colors.first,
      activeTrackColor: colors.first.withOpacity(0.3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Widget _buildDoctorSection() {
    if (!isEditMode) {
      // Display mode
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDoctor ? Colors.red.withOpacity(0.05) : lightGray,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDoctor
                ? Colors.red.withOpacity(0.3)
                : primaryTeal.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDoctor
                    ? Colors.red.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.medical_services,
                size: 20,
                color: isDoctor ? Colors.red : Colors.grey,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Medical License',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isDoctor
                        ? 'Licensed Veterinarian'
                        : 'Not a licensed veterinarian',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDoctor
                    ? Colors.red.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDoctor
                      ? Colors.red.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isDoctor ? Icons.verified : Icons.close,
                    size: 16,
                    color: isDoctor ? Colors.red : Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isDoctor ? 'Doctor' : 'Staff',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDoctor ? Colors.red : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Edit mode
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.2), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.medical_services,
                  size: 18,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Licensed Veterinarian',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: darkText,
                  ),
                ),
              ),
              Switch(
                value: isDoctor,
                onChanged: (value) {
                  setState(() {
                    isDoctor = value;
                    _checkForChanges();
                  });
                },
                activeColor: Colors.red,
                activeTrackColor: Colors.red.withOpacity(0.3),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: Text(
              isDoctor
                  ? 'This staff member is a licensed veterinarian and can complete medical appointments with diagnosis and treatment.'
                  : 'Enable this if the staff member is a licensed veterinarian who can diagnose and treat patients.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
