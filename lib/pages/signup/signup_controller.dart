import 'package:appwrite/appwrite.dart';
import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/pages/routes/app_pages.dart';
import 'package:capstone_app/otp/components/otp_verification_dialog.dart';
import 'package:capstone_app/otp/services/otp_service.dart';
import 'package:capstone_app/utils/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class SignUpController extends GetxController {
  final AuthRepository _authRepository;
  SignUpController(this._authRepository);

  final GetStorage _getStorage = GetStorage();
  final OTPService _otpService = OTPService();

  late TextEditingController emailController;
  late TextEditingController nameController;
  late TextEditingController passwordController;
  late TextEditingController confirmPasswordController;

  final isLoading = false.obs;
  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;
  final termsAccepted = false.obs;
  final isGoogleLoading = false.obs;
  final isSendingOTP = false.obs;

  // Error messages for each field
  final emailError = Rx<String?>(null);
  final nameError = Rx<String?>(null);
  final passwordError = Rx<String?>(null);
  final confirmPasswordError = Rx<String?>(null);
  final termsError = Rx<String?>(null);
  final generalError = Rx<String?>(null);

  @override
  void onInit() {
    super.onInit();
    emailController = TextEditingController();
    nameController = TextEditingController();
    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();

    // Add listeners to clear errors on text change
    emailController.addListener(() => emailError.value = null);
    nameController.addListener(() => nameError.value = null);
    passwordController.addListener(() {
      passwordError.value = null;
      if (confirmPasswordController.text.isNotEmpty) {
        confirmPasswordError.value = null;
      }
    });
    confirmPasswordController
        .addListener(() => confirmPasswordError.value = null);
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  void navigateToLogin() {
    _clearControllersBeforeNavigation();
    Get.offAllNamed(Routes.login);
  }

  void _clearControllersBeforeNavigation() {
    try {
      emailController.clear();
      nameController.clear();
      passwordController.clear();
      confirmPasswordController.clear();
      termsAccepted.value = false;
      _clearAllErrors();
    } catch (e) {
    }
  }

  void _clearAllErrors() {
    emailError.value = null;
    nameError.value = null;
    passwordError.value = null;
    confirmPasswordError.value = null;
    termsError.value = null;
    generalError.value = null;
  }

  void showPrivacyPolicy() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(32),
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Privacy Policy",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 81, 115, 153),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPrivacySection(
                        "1. Introduction",
                        "PAWrtal respects your privacy and is committed to protecting your personal data. This Privacy Policy explains how we collect, use, store, and safeguard information when you use the PAWrtal application—our cross-platform system for veterinary clinic appointments, pet record management, and communication between clinics and pet owners.\n\n"
                            "This Privacy Policy follows the Data Privacy Act of 2012 (Republic Act No. 10173) of the Philippines.",
                      ),
                      _buildPrivacySection(
                        "2. Information We Collect",
                        "We collect different types of data to deliver our services effectively:\n\n"
                            "a. Personal Information: Full name, email address, contact number, account credentials (username and password).\n\n"
                            "b. Pet Information: Pet name, species, breed, age, and gender, vaccination history and medical records, appointment history with veterinary clinics.\n\n"
                            "c. Location Information: Real-time geolocation to help you find nearby veterinary clinics. Location data is only used for the Nearest Clinic Locator feature.\n\n"
                            "d. Usage Data: Device type, operating system, and app version, login activities, bug reports to improve app functionality.\n\n"
                            "e. Communication Data: Messages exchanged with veterinary clinics through the app, appointment notifications.",
                      ),
                      _buildPrivacySection(
                        "3. How We Use Your Information",
                        "Your data is used only for the following purposes: To create and manage your account, to enable appointment scheduling with veterinary clinics, to maintain your pet's virtual health card, to help you find nearby veterinary clinics, to facilitate communication between you and clinics, to send you appointment reminders and notifications, to improve app features and performance.\n\n"
                            "We do not sell, rent, or share your data with third parties for marketing purposes.",
                      ),
                      _buildPrivacySection(
                        "4. Data Storage and Security",
                        "Your information is securely stored in the PAWrtal database with the following protections: Password protection and secure authentication, access limited to authorized personnel only, regular data backups, security measures compliant with Philippine Data Privacy Laws.",
                      ),
                      _buildPrivacySection(
                        "5. Who Can Access Your Data",
                        "• You (Pet Owner) can view and manage your own profile, pets, and appointment history.\n"
                            "• Veterinary Clinics you book with can view relevant pet information and appointment details.\n"
                            "• PAWrtal Developers maintain system security and functionality.\n"
                            "• Data Protection Officer oversees privacy compliance.\n\n"
                            "All parties are required to keep your information confidential.",
                      ),
                      _buildPrivacySection(
                        "6. Data Sharing",
                        "PAWrtal may share limited data with: Veterinary clinics you choose to book appointments with, service providers for app hosting, notifications, and analytics only.\n\n"
                            "All partners must comply with Philippine Data Privacy Laws (RA 10173).",
                      ),
                      _buildPrivacySection(
                        "7. Your Rights",
                        "As a PAWrtal user, you have the right to: Access your personal data, correct any inaccurate information, delete your account and data, download your pet's information, object to how your data is used.\n\n"
                            "To exercise these rights, email us at: pawrtal.app@gmail.com",
                      ),
                      _buildPrivacySection(
                        "8. Data Retention",
                        "Your information is kept as long as your account is active. You can request account deletion at any time. After deletion, your data will be removed within 30 days. Some information may be retained if required by law.",
                      ),
                      _buildPrivacySection(
                        "9. Contact Information",
                        "For privacy concerns or questions:\n\n"
                            "Email: pawrtal.app@gmail.com\n"
                            "Response Time: Within 48 hours",
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Last Updated: November 2025",
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "By using PAWrtal, you acknowledge that you have read and agree to this Privacy Policy.",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Get.back();
                  },
                  child: const Text(
                    "Close",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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

  Widget _buildPrivacySection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
              height: 1.6,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  void showTermsAndConditions() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(32),
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Terms and Conditions",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 81, 115, 153),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTermsSection(
                        "1. Acceptance of Terms",
                        "By accessing or using PAWrtal, you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions. If you do not agree with any part of these terms, you must discontinue use of the service immediately.",
                      ),
                      _buildTermsSection(
                        "2. User Accounts",
                        "You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account. You agree to provide accurate, current, and complete information during registration. You must immediately notify the PAWrtal Developers of any unauthorized use or security breach. Misuse or fraudulent activity may result in suspension or termination of your account.",
                      ),
                      _buildTermsSection(
                        "3. Privacy Policy",
                        "Your use of PAWrtal is also governed by our Privacy Policy. The platform collects and processes data—including your name, contact details, location, pet information, and appointment records—in accordance with Philippine Data Privacy Laws (RA 10173). We are committed to protecting your privacy and will only use your data to operate, maintain, and improve the services offered by PAWrtal.",
                      ),
                      _buildTermsSection(
                        "4. User Data and Information Handling",
                        "PAWrtal collects data you provide when registering, scheduling appointments, or updating your pet's information. This may include personal details, pet records, geolocation data, and chat communication. Your information is used exclusively for scheduling, clinic management, and improving veterinary services. Data is never sold or shared without your consent, except as required by law.",
                      ),
                      _buildTermsSection(
                        "5. Service Usage",
                        "PAWrtal provides an integrated platform for veterinary clinics, professionals, and pet owners. Core features include appointment booking, consultation and medical record management, vaccination tracking, virtual pet cards, chat and notification systems, and feedback tools. Users agree to use PAWrtal only for lawful purposes and to follow all professional veterinary advice for medical concerns.",
                      ),
                      _buildTermsSection(
                        "6. Prohibited Activities",
                        "You may not upload or distribute viruses, attempt unauthorized access, use PAWrtal for illegal or fraudulent activity, post misleading information, or disrupt the system's functionality. Violations may result in immediate account termination, data removal, or legal action.",
                      ),
                      _buildTermsSection(
                        "7. Roles and Responsibilities",
                        "Developers maintain the system's performance, security, and integrity. Admins (veterinary clinics) manage their clinic profiles, services, and schedules. Staff handle appointments, vaccinations, and client communication. Veterinary Professionals (Doctors) provide legitimate medical advice, perform vaccinations, and maintain records. Users (Pet Owners) schedule appointments, manage their pet data, and communicate responsibly. All users must act ethically and protect confidential information.",
                      ),
                      _buildTermsSection(
                        "8. Intellectual Property",
                        "All content, design, code, and features of PAWrtal are owned by the Developers and protected under Philippine law. However, medical and vaccination records created by veterinary professionals remain the property of the respective clinics. Reproduction or redistribution of any platform component without written consent is prohibited.",
                      ),
                      _buildTermsSection(
                        "9. Medical Disclaimer",
                        "PAWrtal connects pet owners with licensed veterinary professionals who provide real consultations, treatments, and vaccinations. All medical advice and procedures are performed solely by registered veterinarians or authorized staff. PAWrtal does not employ or control these professionals and is not liable for the results of veterinary services. Always follow professional veterinary judgment for medical decisions.",
                      ),
                      _buildTermsSection(
                        "10. Veterinary Professional Responsibilities",
                        "Veterinary professionals using PAWrtal must ensure the accuracy of medical data, vaccination logs, and treatment notes. They must maintain client confidentiality, comply with all veterinary and data privacy laws, and use PAWrtal only for legitimate veterinary purposes. Sharing confidential client data outside authorized use may result in account suspension.",
                      ),
                      _buildTermsSection(
                        "11. Limitation of Liability",
                        "While the Developers strive to provide a reliable system, they are not liable for technical issues, inaccurate clinic data, delayed appointments, or indirect damages arising from the use of PAWrtal. The Developers' total liability shall not exceed any amount paid (if applicable) for the use of the platform.",
                      ),
                      _buildTermsSection(
                        "12. Connectivity and Availability",
                        "Some features, such as appointment booking, notifications, and clinic locator, require an active internet connection. PAWrtal is available on Android and Web platforms. Veterinary clinics listed are limited to those within San Jose del Monte, Bulacan.",
                      ),
                      _buildTermsSection(
                        "13. Changes to Terms",
                        "The Developers reserve the right to modify or update these Terms and Conditions at any time. Users will be notified through email or in-app messages of any significant changes. Continued use after updates means you accept the revised terms.",
                      ),
                      _buildTermsSection(
                        "14. Termination of Access",
                        "The Developers may suspend or terminate accounts that violate these terms, engage in fraudulent actions, or harm the platform. Upon termination, access to related data will be removed immediately. Clinics and professionals are responsible for backing up their patient records before termination.",
                      ),
                      _buildTermsSection(
                        "15. Contact Information",
                        "For inquiries, technical concerns, or questions about these Terms and Conditions, please contact: pawrtal.app@gmail.com. The PAWrtal Developers aim to respond to inquiries within 48 hours.",
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Last Updated: November 2025",
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Get.back();
                  },
                  child: const Text(
                    "Close",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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

  Widget _buildTermsSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
              height: 1.6,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  /// NEW: Step 1 - Validate and send OTP
  Future<void> signUp() async {
    _clearAllErrors();

    if (!_validateForm()) return;

    // Check if terms are accepted
    if (!termsAccepted.value) {
      termsError.value = 'Please accept the Terms and Conditions to continue';
      return;
    }

    try {
      isSendingOTP.value = true;

      final email = emailController.text.trim();
      final name = nameController.text.trim();

      // Validate email domain
      if (!EmailValidator.isValidEmailDomain(email)) {
        emailError.value = EmailValidator.getEmailDomainError(email);
        isSendingOTP.value = false;
        return;
      }

      // Send OTP
      final result = await _otpService.sendOTP(email, name);

      if (result['success'] == true) {
        // Show OTP verification dialog
        _showOTPVerificationDialog(email, name);
      } else {
        generalError.value =
            result['message'] ?? 'Failed to send verification code';
      }
    } catch (error) {
      generalError.value =
          'Network error. Please check your connection and try again.';
    } finally {
      isSendingOTP.value = false;
    }
  }

  /// NEW: Show OTP verification dialog
  void _showOTPVerificationDialog(String email, String name) {
    Get.dialog(
      OTPVerificationDialog(
        email: email,
        name: name,
        onVerify: (otp) => _verifyOTPAndCreateAccount(email, otp),
        onResend: () => _resendOTP(email, name),
      ),
      barrierDismissible: false,
    );
  }

  /// NEW: Resend OTP
  Future<void> _resendOTP(String email, String name) async {
    try {
      final result = await _otpService.sendOTP(email, name);

      if (result['success'] == true) {
        Get.snackbar(
          'Code Sent',
          'A new verification code has been sent to your email',
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFF4CAF50),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? 'Failed to resend code',
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFFEF5350),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Network error. Please try again.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFFEF5350),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// NEW: Step 2 - Verify OTP and create account
  Future<void> _verifyOTPAndCreateAccount(String email, String otp) async {
    try {
      isLoading.value = true;

      // Verify OTP
      final verifyResult = await _otpService.verifyOTP(email, otp);

      if (verifyResult['success'] != true) {
        // Show error in dialog
        Get.snackbar(
          'Verification Failed',
          verifyResult['message'] ?? 'Invalid code',
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFFEF5350),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        isLoading.value = false;
        return;
      }

      // OTP verified! Now create the account

      final user = await _authRepository.signup({
        "userId": ID.unique(),
        "name": nameController.text.trim(),
        "email": email,
        "password": passwordController.text,
      });

      final userId = user.$id;

      await _authRepository.createUser({
        "userId": userId,
        "name": nameController.text.trim(),
        "email": email,
        "role": "user",
      });

      // Close OTP dialog
      Get.back();

      // Show success dialog
      Get.dialog(
        Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(24),
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Color(0xFF4CAF50),
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Account Created!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your account has been created successfully. You can now sign in.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Get.back();
                      _clearControllersBeforeNavigation();
                      Get.offAllNamed(Routes.login);
                    },
                    child: const Text(
                      'Continue to Sign In',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );
    } catch (error) {
      String errorMessage = "Something went wrong. Please try again.";

      if (error is AppwriteException) {
        if (error.code == 409) {
          errorMessage =
              "This email is already registered. Please use a different email or sign in.";
        } else {
          errorMessage = error.response ?? "An error occurred during sign up";
        }
      }

      Get.back(); // Close OTP dialog
      generalError.value = errorMessage;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signUpWithGoogle() async {
    if (isLoading.value || isGoogleLoading.value) return;

    try {
      isGoogleLoading.value = true;
      _clearAllErrors();


      final appWriteProvider = Get.find<AppWriteProvider>();

      // This will redirect to Google OAuth
      // The callback page will create user in database if new
      await appWriteProvider.signInWithGoogle();

      // Code won't reach here due to redirect
    } catch (e) {

      isGoogleLoading.value = false;

      generalError.value =
          'Google Sign-Up failed. Please try again or use email/password.';
    }
  }

  bool _validateForm() {
    final email = emailController.text.trim();
    final name = nameController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    bool isValid = true;

    // Check empty fields
    if (email.isEmpty) {
      emailError.value = 'Email is required';
      isValid = false;
    }

    if (name.isEmpty) {
      nameError.value = 'Full name is required';
      isValid = false;
    }

    if (password.isEmpty) {
      passwordError.value = 'Password is required';
      isValid = false;
    }

    if (confirmPassword.isEmpty) {
      confirmPasswordError.value = 'Please confirm your password';
      isValid = false;
    }

    // Email validation
    if (email.isNotEmpty && !GetUtils.isEmail(email)) {
      emailError.value = 'Please enter a valid email address';
      isValid = false;
    }

    // Text length limit
    if (email.length > 50) {
      emailError.value = 'Email must not exceed 50 characters';
      isValid = false;
    }

    if (name.length > 50) {
      nameError.value = 'Name must not exceed 50 characters';
      isValid = false;
    }

    if (password.length > 50) {
      passwordError.value = 'Password must not exceed 50 characters';
      isValid = false;
    }

    // Password length
    if (password.isNotEmpty && password.length < 8) {
      passwordError.value = 'Password must be at least 8 characters';
      isValid = false;
    }

    // Password complexity
    if (password.isNotEmpty && password.length >= 8) {
      final passwordRegex =
          RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$%^&*(),.?":{}|<>]).{8,}$');
      if (!passwordRegex.hasMatch(password)) {
        passwordError.value =
            'Password must contain uppercase, digit, and special character';
        isValid = false;
      }
    }

    // Password confirmation
    if (password.isNotEmpty &&
        confirmPassword.isNotEmpty &&
        password != confirmPassword) {
      confirmPasswordError.value = 'Passwords do not match';
      isValid = false;
    }

    return isValid;
  }

  @override
  void onClose() {
    try {
      emailController.dispose();
      nameController.dispose();
      passwordController.dispose();
      confirmPasswordController.dispose();
    } catch (e) {
    }
    super.onClose();
  }
}
