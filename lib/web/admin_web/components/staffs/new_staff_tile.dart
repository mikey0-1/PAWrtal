import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class NewStaffTile extends StatelessWidget {
  final void Function(
    String name,
    String username,
    String email,
    String phone,
    List<String> authorities,
    Uint8List? imageBytes,
    String password,
    bool isDoctor, // ADDED 8th parameter
  ) onStaffCreated;

  const NewStaffTile({
    super.key,
    required this.onStaffCreated,
  });

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
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width <= 768;

    return Material(
      elevation: isSmall ? 2.0 : 3.0,
      borderRadius: BorderRadius.circular(isSmall ? 16 : 20),
      shadowColor: primaryTeal.withOpacity(0.2),
      child: InkWell(
        borderRadius: BorderRadius.circular(isSmall ? 16 : 20),
        onTap: () => _showStaffForm(context),
        hoverColor: primaryTeal.withOpacity(0.04),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isSmall ? 16 : 20),
            border: Border.all(
                color: primaryTeal.withOpacity(0.3), width: isSmall ? 2 : 2.5),
          ),
          padding: EdgeInsets.all(isSmall ? 12 : 20),
          child: isSmall ? _buildMobileLayout() : _buildDesktopLayout(),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: lightVetGreen.withOpacity(0.3),
            shape: BoxShape.circle,
            border: Border.all(color: primaryTeal.withOpacity(0.3), width: 2),
          ),
          child: const Icon(Icons.person_add_alt_1_rounded,
              color: primaryTeal, size: 24),
        ),
        const SizedBox(height: 8),
        Column(
          children: [
            const Text(
              'Add Staff',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold, color: darkText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: primaryTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Create account',
                style: TextStyle(
                    color: primaryTeal,
                    fontSize: 9,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: lightVetGreen.withOpacity(0.3),
            shape: BoxShape.circle,
            border: Border.all(color: primaryTeal.withOpacity(0.3), width: 2),
          ),
          child: const Icon(Icons.person_add_alt_1_rounded,
              color: primaryTeal, size: 40),
        ),
        const SizedBox(height: 16),
        const Text(
          'Add New Staff',
          style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.bold, color: darkText),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: primaryTeal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Text(
            'Create account',
            style: TextStyle(
                color: primaryTeal, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  void _showStaffForm(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final firstNameController = TextEditingController();
        final surnameController = TextEditingController();
        final phoneController = TextEditingController();
        final emailController = TextEditingController();

        return _StaffFormDialog(
          firstNameController: firstNameController,
          surnameController: surnameController,
          phoneController: phoneController,
          emailController: emailController,
          onStaffCreated: onStaffCreated, // This now expects 8 parameters
        );
      },
    );
  }
}

class _StaffFormDialog extends StatefulWidget {
  final TextEditingController firstNameController;
  final TextEditingController surnameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final void Function(
      String name,
      String username,
      String email,
      String phone,
      List<String> authorities,
      Uint8List? imageBytes,
      String password,
      bool isDoctor) onStaffCreated; // ADDED 8th parameter

  const _StaffFormDialog({
    required this.firstNameController,
    required this.surnameController,
    required this.phoneController,
    required this.emailController,
    required this.onStaffCreated,
  });

  @override
  State<_StaffFormDialog> createState() => _StaffFormDialogState();
}

class _StaffFormDialogState extends State<_StaffFormDialog> {
  bool clinicAuth = false;
  bool appointmentAuth = false;
  bool messagesAuth = false;
  Uint8List? selectedImageBytes;
  bool hasChanges = false;
  bool isDoctorChecked = false;

  String? firstNameError;
  String? surnameError;
  String? emailError;
  String? phoneError;

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
    widget.firstNameController.addListener(_checkForChanges);
    widget.surnameController.addListener(_checkForChanges);
    widget.phoneController.addListener(_checkForChanges);
    widget.emailController.addListener(_checkForChanges); // NEW
  }

  @override
  void dispose() {
    widget.firstNameController.removeListener(_checkForChanges);
    widget.surnameController.removeListener(_checkForChanges);
    widget.phoneController.removeListener(_checkForChanges);
    widget.emailController.removeListener(_checkForChanges); // NEW
    super.dispose();
  }

  void _checkForChanges() {
    setState(() {
      hasChanges = widget.firstNameController.text.trim().isNotEmpty ||
          widget.surnameController.text.trim().isNotEmpty ||
          widget.phoneController.text.trim().isNotEmpty ||
          widget.emailController.text.trim().isNotEmpty ||
          selectedImageBytes != null ||
          clinicAuth ||
          appointmentAuth ||
          messagesAuth ||
          isDoctorChecked; // Added to check for changes
    });
  }

  String _getFullPhoneNumber() {
    final phoneDigits = widget.phoneController.text.trim();
    if (phoneDigits.isEmpty) return '';
    return '09$phoneDigits';
  }

  // NEW: Email validation
  bool _isValidEmail(String email) {
    if (email.isEmpty) return true; // Optional field
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _handleCancel() {
    if (hasChanges) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            'You have unsaved changes. Are you sure you want to cancel? All entered data will be lost.',
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Continue Editing',
                style:
                    TextStyle(color: primaryTeal, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close confirmation dialog
                Navigator.pop(context); // Close staff form dialog
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: vetOrange,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Discard Changes'),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context);
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
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              lightVetGreen.withOpacity(0.1),
              Colors.white,
              lightVetGreen.withOpacity(0.05),
            ],
          ),
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
              padding: EdgeInsets.all(isDesktop ? 24 : 16),
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
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isDesktop ? 8 : 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.medical_services_rounded,
                      color: Colors.white,
                      size: isDesktop ? 26 : 22,
                    ),
                  ),
                  SizedBox(width: isDesktop ? 16 : 12),
                  Expanded(
                    child: Text(
                      'Create New Staff Account',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isDesktop ? 22 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isDesktop ? 28 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Photo
                    Center(
                      child: _buildProfilePhotoSection(),
                    ),
                    SizedBox(height: isDesktop ? 28 : 20),

                    // Personal Info
                    _buildSectionHeader('Personal Information',
                        Icons.person_outline, primaryBlue),
                    SizedBox(height: isDesktop ? 20 : 16),

                    _buildPersonalInfoFields(isDesktop),
                    SizedBox(height: isDesktop ? 28 : 20),

                    // Authorities
                    _buildSectionHeader(
                      'Access Permissions',
                      Icons.security_rounded,
                      vetGreen,
                      subtitle:
                          'Select which sections this staff member can access',
                    ),
                    SizedBox(height: isDesktop ? 20 : 16),

                    _buildPermissionsSection(),
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: EdgeInsets.all(isDesktop ? 24 : 16),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _handleCancel,
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                          color: mediumGray,
                          fontWeight: FontWeight.w600,
                          fontSize: isDesktop ? 14 : 13),
                    ),
                  ),
                  SizedBox(width: isDesktop ? 16 : 12),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [primaryTeal, primaryBlue]),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: primaryTeal.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed:
                          _validateAndProceed, // CHANGED: Now calls validation method
                      icon:
                          const Icon(Icons.arrow_forward, color: Colors.white),
                      label: Text('Continue',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: isDesktop ? 14 : 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 28 : 20,
                            vertical: isDesktop ? 14 : 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
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
  }

  Widget _buildDoctorToggle() {
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
                value: isDoctorChecked,
                onChanged: (value) {
                  setState(() {
                    isDoctorChecked = value;
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
              isDoctorChecked
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

  void _handleCreateStaff() {
    final fullName =
        '${widget.firstNameController.text.trim()} ${widget.surnameController.text.trim()}';
    final phone = _getFullPhoneNumber();

    final authorities = <String>[];
    if (clinicAuth) authorities.add('Clinic');
    if (appointmentAuth) authorities.add('Appointments');
    if (messagesAuth) authorities.add('Messages');

    final email = widget.emailController.text.trim();

    _showCredentialsDialog(fullName, email, phone, authorities);
  }

  Future<void> _showCredentialsDialog(
    String fullName,
    String email,
    String phone,
    List<String> authorities,
  ) async {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscurePassword = true;
    bool obscureConfirm = true;
    String? errorMessage;

    // Password validation flags
    bool hasUppercase = false;
    bool hasSpecialChar = false;
    bool hasDigit = false;
    bool hasMinLength = false;

    void validatePassword(String password) {
      hasUppercase = password.contains(RegExp(r'[A-Z]'));
      hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
      hasDigit = password.contains(RegExp(r'[0-9]'));
      hasMinLength = password.length >= 8;
    }

    // Track if credentials dialog has any input
    bool hasCredentialsInput = false;
    void checkCredentialsInput() {
      hasCredentialsInput = usernameController.text.trim().isNotEmpty ||
          passwordController.text.isNotEmpty ||
          confirmPasswordController.text.isNotEmpty;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return WillPopScope(
            onWillPop: () async {
              if (hasCredentialsInput) {
                final shouldDiscard = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
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
                          child: Text('Unsaved Progress',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    content: const Text(
                      'You have unsaved credentials. Going back will discard your progress.',
                      style: TextStyle(fontSize: 15),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Continue Editing',
                            style: TextStyle(
                                color: primaryTeal,
                                fontWeight: FontWeight.w600)),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: vetOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Discard'),
                      ),
                    ],
                  ),
                );
                return shouldDiscard ?? false;
              }
              return true;
            },
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 520),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      lightVetGreen.withOpacity(0.2),
                    ],
                  ),
                ),
                child: SingleChildScrollView(
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
                              gradient: const LinearGradient(
                                colors: [primaryTeal, primaryBlue],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.lock_outline,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Account Credentials',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: darkText,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Create username and password',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: mediumGray,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Username Field
                      TextField(
                        controller: usernameController,
                        maxLength: 50,
                        onChanged: (_) {
                          setDialogState(() {
                            errorMessage = null;
                            checkCredentialsInput();
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Username',
                          hintText: 'Enter username for login',
                          hintStyle: TextStyle(
                              color: mediumGray.withOpacity(0.5)), // MORE GREY
                          counterText: '',
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryTeal.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.person,
                                color: primaryTeal, size: 20),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: primaryTeal.withOpacity(0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: primaryTeal.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: primaryTeal, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      TextField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        maxLength: 50,
                        onChanged: (value) {
                          setDialogState(() {
                            errorMessage = null;
                            validatePassword(value);
                            checkCredentialsInput();
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter secure password',
                          hintStyle: TextStyle(
                              color: mediumGray.withOpacity(0.5)), // MORE GREY
                          counterText: '',
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryTeal.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.lock,
                                color: primaryTeal, size: 20),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: mediumGray,
                              size: 20,
                            ),
                            onPressed: () => setDialogState(
                                () => obscurePassword = !obscurePassword),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: primaryTeal.withOpacity(0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: primaryTeal.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: primaryTeal, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Password Requirements
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline,
                                    size: 16, color: Colors.blue[700]),
                                const SizedBox(width: 6),
                                Text(
                                  'Password Requirements',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildRequirement(
                                'At least 8 characters', hasMinLength),
                            _buildRequirement(
                                'One uppercase letter', hasUppercase),
                            _buildRequirement('One number', hasDigit),
                            _buildRequirement(
                                'One special character (!@#\$%^&*)',
                                hasSpecialChar),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Confirm Password Field
                      TextField(
                        controller: confirmPasswordController,
                        obscureText: obscureConfirm,
                        maxLength: 50,
                        onChanged: (_) {
                          setDialogState(() {
                            errorMessage = null;
                            checkCredentialsInput();
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          hintText: 'Re-enter password',
                          hintStyle: TextStyle(
                              color: mediumGray.withOpacity(0.5)), // MORE GREY
                          counterText: '',
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: vetGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.check_circle_outline,
                                color: vetGreen, size: 20),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureConfirm
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: mediumGray,
                              size: 20,
                            ),
                            onPressed: () => setDialogState(
                                () => obscureConfirm = !obscureConfirm),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: vetGreen.withOpacity(0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: vetGreen.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: vetGreen, width: 2),
                          ),
                        ),
                      ),

                      if (errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(10),
                            border:
                                Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.red, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  errorMessage!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () async {
                              if (hasCredentialsInput) {
                                final shouldDiscard = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                    title: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: vetOrange.withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                              Icons.warning_amber_rounded,
                                              color: vetOrange,
                                              size: 24),
                                        ),
                                        const SizedBox(width: 12),
                                        const Expanded(
                                          child: Text('Unsaved Progress',
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                    content: const Text(
                                      'Going back will discard your credentials.',
                                      style: TextStyle(fontSize: 15),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Continue Editing',
                                            style: TextStyle(
                                                color: primaryTeal,
                                                fontWeight: FontWeight.w600)),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: vetOrange,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                        ),
                                        child: const Text('Discard'),
                                      ),
                                    ],
                                  ),
                                );
                                if (shouldDiscard == true) {
                                  Navigator.pop(dialogContext);
                                }
                              } else {
                                Navigator.pop(dialogContext);
                              }
                            },
                            child: const Text(
                              'Back',
                              style: TextStyle(
                                color: mediumGray,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [primaryTeal, primaryBlue],
                              ),
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
                              onPressed: () {
                                final username = usernameController.text.trim();
                                final password = passwordController.text;
                                final confirmPassword =
                                    confirmPasswordController.text;

                                // Validate username
                                if (username.isEmpty) {
                                  setDialogState(() =>
                                      errorMessage = 'Username is required');
                                  return;
                                }

                                if (username.length < 3) {
                                  setDialogState(() => errorMessage =
                                      'Username must be at least 3 characters');
                                  return;
                                }

                                // Validate password
                                if (password.isEmpty) {
                                  setDialogState(() =>
                                      errorMessage = 'Password is required');
                                  return;
                                }

                                validatePassword(password);

                                if (!hasMinLength) {
                                  setDialogState(() => errorMessage =
                                      'Password must be at least 8 characters');
                                  return;
                                }

                                if (!hasUppercase) {
                                  setDialogState(() => errorMessage =
                                      'Password must contain at least one uppercase letter');
                                  return;
                                }

                                if (!hasDigit) {
                                  setDialogState(() => errorMessage =
                                      'Password must contain at least one number');
                                  return;
                                }

                                if (!hasSpecialChar) {
                                  setDialogState(() => errorMessage =
                                      'Password must contain at least one special character');
                                  return;
                                }

                                // Validate confirm password
                                if (password != confirmPassword) {
                                  setDialogState(() =>
                                      errorMessage = 'Passwords do not match');
                                  return;
                                }

                                // Show confirmation dialog
                                Navigator.pop(dialogContext);
                                _showConfirmationDialog(
                                  fullName,
                                  username,
                                  password,
                                  email,
                                  phone,
                                  authorities,
                                );
                              },
                              icon: const Icon(Icons.arrow_forward,
                                  color: Colors.white, size: 18),
                              label: const Text(
                                'Continue',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
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
        },
      ),
    );
  }

  Widget _buildRequirement(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.cancel,
            size: 14,
            color: isMet ? vetGreen : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: isMet ? vetGreen : Colors.grey[600],
              fontWeight: isMet ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showConfirmationDialog(
    String fullName,
    String username,
    String password,
    String email,
    String phone,
    List<String> authorities,
  ) async {
    bool showPassword = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return WillPopScope(
            onWillPop: () async {
              final shouldDiscard = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
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
                        child: Text('Unsaved Progress',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  content: const Text(
                    'Going back will discard your progress. The staff account will not be created.',
                    style: TextStyle(fontSize: 15),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Continue Editing',
                          style: TextStyle(
                              color: primaryTeal, fontWeight: FontWeight.w600)),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: vetOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Discard'),
                    ),
                  ],
                ),
              );
              return shouldDiscard ?? false;
            },
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      vetGreen.withOpacity(0.1),
                    ],
                  ),
                ),
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
                            gradient: const LinearGradient(
                              colors: [vetGreen, primaryTeal],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.check_circle_outline,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Review & Confirm',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: darkText,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Verify account details',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: mediumGray,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Account Details Box
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: lightVetGreen.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: vetGreen.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                            Icons.person,
                            'Staff Name',
                            fullName,
                            primaryBlue,
                          ),
                          const SizedBox(height: 14),
                          _buildDetailRow(
                            Icons.account_circle,
                            'Username',
                            username,
                            primaryTeal,
                          ),
                          const SizedBox(height: 14),
                          _buildDetailRow(
                            Icons.email,
                            'Email',
                            email.isNotEmpty ? email : 'Not provided',
                            vetPurple,
                          ),
                          const SizedBox(height: 14),
                          _buildDetailRow(
                            Icons.phone,
                            'Phone Number',
                            phone.isNotEmpty ? phone : 'Not provided',
                            vetOrange,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: vetOrange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.lock,
                                  color: vetOrange,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Password',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: mediumGray,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            showPassword
                                                ? password
                                                : '•' * password.length,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: darkText,
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () => setDialogState(
                                            () => showPassword = !showPassword,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  vetOrange.withOpacity(0.15),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  showPassword
                                                      ? Icons.visibility_off
                                                      : Icons.visibility,
                                                  size: 14,
                                                  color: vetOrange,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  showPassword
                                                      ? 'Hide'
                                                      : 'Show',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: vetOrange,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (authorities.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: vetGreen.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.security,
                                    color: vetGreen,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Permissions',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: mediumGray,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: authorities.map((auth) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: vetGreen.withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color:
                                                    vetGreen.withOpacity(0.4),
                                              ),
                                            ),
                                            child: Text(
                                              auth,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: vetGreen,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.security,
                                    color: Colors.grey,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'No permissions assigned',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: mediumGray,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          // FIXED: Use isDoctorChecked from state
                          if (isDoctorChecked) ...[
                            const SizedBox(height: 14),
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
                                    color: Colors.red,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Medical License',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: mediumGray,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(Icons.verified,
                                              size: 14, color: Colors.red),
                                          SizedBox(width: 6),
                                          Text(
                                            'Licensed Veterinarian',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () async {
                            final shouldDiscard = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                title: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: vetOrange.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                          Icons.warning_amber_rounded,
                                          color: vetOrange,
                                          size: 24),
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Text('Unsaved Progress',
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                content: const Text(
                                  'Going back will discard your progress.',
                                  style: TextStyle(fontSize: 15),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Continue Editing',
                                        style: TextStyle(
                                            color: primaryTeal,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: vetOrange,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                    ),
                                    child: const Text('Discard'),
                                  ),
                                ],
                              ),
                            );
                            if (shouldDiscard == true) {
                              Navigator.pop(dialogContext);
                            }
                          },
                          child: const Text(
                            'Back',
                            style: TextStyle(
                              color: mediumGray,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [vetGreen, primaryTeal],
                            ),
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
                            onPressed: () {
                              Navigator.pop(dialogContext); // close confirm
                              Navigator.of(this.context).pop(); // close form

                              // FIXED: Pass isDoctorChecked as 8th parameter
                              widget.onStaffCreated(
                                fullName,
                                username,
                                email,
                                phone,
                                authorities,
                                selectedImageBytes,
                                password,
                                isDoctorChecked, // FIXED: Now passing the correct parameter
                              );
                            },
                            icon: const Icon(Icons.check_circle,
                                color: Colors.white, size: 20),
                            label: const Text(
                              'Confirm & Create',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
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
      ),
    );
  }

  Widget _buildDetailRow(
      IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: mediumGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfilePhotoSection() {
    final ImagePicker picker = ImagePicker();

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            InkWell(
              onTap: () async {
                try {
                  final XFile? result = await picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1920,
                    maxHeight: 1080,
                  );

                  if (result != null) {
                    final bytes = await result.readAsBytes();
                    if (bytes.length > 5 * 1024 * 1024) return;
                    setState(() {
                      selectedImageBytes = bytes;
                      _checkForChanges();
                    });
                  }
                } catch (_) {}
              },
              borderRadius: BorderRadius.circular(70),
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selectedImageBytes != null
                      ? null
                      : lightVetGreen.withOpacity(0.3),
                  border: Border.all(
                    color:
                        selectedImageBytes == null ? Colors.red : primaryTeal,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (selectedImageBytes == null
                              ? Colors.red
                              : primaryTeal)
                          .withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                  image: selectedImageBytes != null
                      ? DecorationImage(
                          image: MemoryImage(selectedImageBytes!),
                          fit: BoxFit.cover)
                      : null,
                ),
                child: selectedImageBytes == null
                    ? const Icon(Icons.camera_alt_rounded,
                        size: 36, color: Colors.red)
                    : null,
              ),
            ),
            if (selectedImageBytes != null)
              Positioned(
                top: -4,
                right: -4,
                child: InkWell(
                  onTap: () => setState(() {
                    selectedImageBytes = null;
                    _checkForChanges();
                  }),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child:
                        const Icon(Icons.close, color: Colors.white, size: 16),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: (selectedImageBytes == null ? Colors.red : primaryTeal)
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (selectedImageBytes == null ? Colors.red : primaryTeal)
                  .withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selectedImageBytes != null
                    ? Icons.edit_rounded
                    : Icons.add_photo_alternate_rounded,
                size: 14,
                color: selectedImageBytes == null ? Colors.red : primaryTeal,
              ),
              const SizedBox(width: 6),
              Text(
                selectedImageBytes != null
                    ? 'Click to change photo'
                    : 'Click to upload',
                style: TextStyle(
                    color:
                        selectedImageBytes == null ? Colors.red : primaryTeal,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        if (selectedImageBytes == null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Profile photo is required',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color,
      {String? subtitle}) {
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 16 : 12, vertical: isDesktop ? 8 : 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isDesktop ? 6 : 5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: isDesktop ? 20 : 18),
          ),
          SizedBox(width: isDesktop ? 12 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: isDesktop ? 17 : 15,
                        fontWeight: FontWeight.bold,
                        color: darkText)),
                if (subtitle != null)
                  Text(subtitle,
                      style: TextStyle(
                          color: mediumGray, fontSize: isDesktop ? 13 : 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoFields(bool isDesktop) {
    return Column(
      children: [
        if (isDesktop)
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: widget.firstNameController,
                  label: 'First Name',
                  icon: Icons.badge_outlined,
                  errorText: firstNameError,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: widget.surnameController,
                  label: 'Surname',
                  icon: Icons.badge_outlined,
                  errorText: surnameError,
                ),
              ),
            ],
          )
        else
          Column(
            children: [
              _buildTextField(
                controller: widget.firstNameController,
                label: 'First Name',
                icon: Icons.badge_outlined,
                errorText: firstNameError,
              ),
              const SizedBox(height: 18),
              _buildTextField(
                controller: widget.surnameController,
                label: 'Surname',
                icon: Icons.badge_outlined,
                errorText: surnameError,
              ),
            ],
          ),
        const SizedBox(height: 18),
        _buildEmailTextField(errorText: emailError),
        const SizedBox(height: 18),
        _buildPhoneTextField(errorText: phoneError),
        const SizedBox(height: 24),
        _buildSectionHeader(
          'Medical Credentials',
          Icons.medical_services,
          Colors.red,
          subtitle: 'Specify if this staff member is a licensed veterinarian',
        ),
        const SizedBox(height: 16),
        _buildDoctorToggle(),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? errorText,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primaryTeal.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLength: 50,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
            ],
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(
                  color: mediumGray, fontWeight: FontWeight.w500),
              hintText: 'Enter $label',
              hintStyle: TextStyle(color: mediumGray.withOpacity(0.5)),
              counterText: '',
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: primaryTeal, size: 20),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: errorText != null
                        ? Colors.red
                        : primaryTeal.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: errorText != null
                        ? Colors.red
                        : primaryTeal.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: errorText != null ? Colors.red : primaryTeal,
                    width: 2.5),
              ),
            ),
          ),
          if (errorText != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      errorText,
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // NEW: Email field
  Widget _buildEmailTextField({String? errorText}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primaryTeal.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: widget.emailController,
            keyboardType: TextInputType.emailAddress,
            maxLength: 50,
            decoration: InputDecoration(
              labelText: 'Email (Optional)',
              labelStyle: const TextStyle(
                  color: mediumGray, fontWeight: FontWeight.w500),
              hintText: 'example@email.com',
              hintStyle: TextStyle(color: mediumGray.withOpacity(0.5)),
              counterText: '',
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: vetPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.email_outlined,
                    color: vetPurple, size: 20),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: errorText != null
                        ? Colors.red
                        : vetPurple.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: errorText != null
                        ? Colors.red
                        : vetPurple.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: errorText != null ? Colors.red : vetPurple,
                    width: 2.5),
              ),
            ),
          ),
          if (errorText != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      errorText,
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhoneTextField({String? errorText}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primaryTeal.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: widget.phoneController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(9),
            ],
            decoration: InputDecoration(
              labelText: 'Phone Number (Optional)',
              labelStyle: const TextStyle(
                  color: mediumGray, fontWeight: FontWeight.w500),
              hintText: '696934651',
              hintStyle: TextStyle(color: mediumGray.withOpacity(0.5)),
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.phone_outlined,
                    color: primaryTeal, size: 20),
              ),
              prefix: Container(
                padding: const EdgeInsets.only(right: 4),
                child: const Text(
                  '09',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: errorText != null
                        ? Colors.red
                        : primaryTeal.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: errorText != null
                        ? Colors.red
                        : primaryTeal.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: errorText != null ? Colors.red : primaryTeal,
                    width: 2.5),
              ),
            ),
          ),
          if (errorText != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      errorText,
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPermissionsSection() {
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
          CheckboxListTile(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: primaryTeal.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.local_hospital_rounded,
                    size: 18,
                    color: primaryTeal,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Clinic Page',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ],
            ),
            subtitle: const Padding(
              padding: EdgeInsets.only(left: 40, top: 4),
              child: Text(
                'Access to clinic information and settings',
                style: TextStyle(fontSize: 13),
              ),
            ),
            value: clinicAuth,
            onChanged: (val) {
              setState(() => clinicAuth = val ?? false);
              _checkForChanges();
            },
            activeColor: primaryTeal,
            checkColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          Divider(height: 1, color: Colors.grey[300]),
          CheckboxListTile(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    size: 18,
                    color: primaryBlue,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Appointments',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ],
            ),
            subtitle: const Padding(
              padding: EdgeInsets.only(left: 40, top: 4),
              child: Text(
                'Manage and view appointments',
                style: TextStyle(fontSize: 13),
              ),
            ),
            value: appointmentAuth,
            onChanged: (val) {
              setState(() => appointmentAuth = val ?? false);
              _checkForChanges();
            },
            activeColor: primaryBlue,
            checkColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          Divider(height: 1, color: Colors.grey[300]),
          CheckboxListTile(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: vetOrange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.message_rounded,
                      size: 18, color: vetOrange),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Messages',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ],
            ),
            subtitle: const Padding(
              padding: EdgeInsets.only(left: 40, top: 4),
              child: Text(
                'Access to messaging system',
                style: TextStyle(fontSize: 13),
              ),
            ),
            value: messagesAuth,
            onChanged: (val) {
              setState(() => messagesAuth = val ?? false);
              _checkForChanges();
            },
            activeColor: vetOrange,
            checkColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ],
      ),
    );
  }

  void _validateAndProceed() {
    setState(() {
      // Clear previous errors
      firstNameError = null;
      surnameError = null;
      emailError = null;
      phoneError = null;

      // Validate first name
      if (widget.firstNameController.text.trim().isEmpty) {
        firstNameError = 'First name is required';
      }

      // Validate surname
      if (widget.surnameController.text.trim().isEmpty) {
        surnameError = 'Surname is required';
      }

      // Validate email
      final email = widget.emailController.text.trim();
      if (email.isNotEmpty && !_isValidEmail(email)) {
        emailError = 'Please enter a valid email address';
      }

      // Validate phone
      final phoneDigits = widget.phoneController.text.trim();
      if (phoneDigits.isNotEmpty && phoneDigits.length != 9) {
        phoneError = 'Phone number must be exactly 9 digits';
      }

      // Check if any errors exist
      if (firstNameError != null ||
          surnameError != null ||
          emailError != null ||
          phoneError != null ||
          selectedImageBytes == null) {
        return; // Stop here if there are errors
      }

      // If all validations pass, proceed
      _handleCreateStaff();
    });
  }
}
