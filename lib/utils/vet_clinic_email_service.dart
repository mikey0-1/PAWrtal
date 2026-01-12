import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';

class VetClinicEmailService {
  static final VetClinicEmailService _instance = VetClinicEmailService._internal();
  factory VetClinicEmailService() => _instance;
  VetClinicEmailService._internal();

  // Appwrite Function ID for sending welcome emails
  static const String sendWelcomeEmailFunctionId = '691afec400279ba0fb31'; // Replace after deployment

  /// Send welcome email with account credentials to veterinary clinic
  Future<Map<String, dynamic>> sendWelcomeEmail({
    required String clinicName,
    required String email,
    required String password,
    required String adminName,
  }) async {
    try {
      // Initialize Appwrite client
      final client = Client()
        ..setEndpoint(AppwriteConstants.endPoint)
        ..setProject(AppwriteConstants.projectID);

      final functions = Functions(client);

      // Call Appwrite function
      final execution = await functions.createExecution(
        functionId: sendWelcomeEmailFunctionId,
        body: json.encode({
          'clinicName': clinicName,
          'email': email,
          'password': password,
          'adminName': adminName,
        }),
        xasync: false, // Wait for completion
      );

      // Parse response
      if (execution.status == 'completed') {
        final response = json.decode(execution.responseBody);
        
        if (response['success'] == true) {
          return {
            'success': true,
            'message': 'Welcome email sent successfully',
          };
        } else {
          return {
            'success': false,
            'message': response['message'] ?? 'Failed to send welcome email',
          };
        }
      } else if (execution.status == 'failed') {
        return {
          'success': false,
          'message': 'Failed to send welcome email. Please try again.',
        };
      } else {
        return {
          'success': false,
          'message': 'Unexpected error. Please try again.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  /// Generate secure password based on clinic details
  static String generateSecurePassword({
    required String clinicName,
    required String email,
  }) {
    // Extract meaningful parts
    final clinicInitials = _extractInitials(clinicName);
    final emailPrefix = email.split('@')[0];
    final randomDigits = _generateRandomDigits(4);
    final specialChars = ['@', '#', '!', '\$'];
    final randomSpecial = specialChars[DateTime.now().millisecond % specialChars.length];
    
    // Combine: ClinicInitials + EmailPrefix(first3) + Random4Digits + Special + Year
    final password = '$clinicInitials${emailPrefix.substring(0, emailPrefix.length > 3 ? 3 : emailPrefix.length)}$randomDigits$randomSpecial${DateTime.now().year}';
    
    // Ensure first letter is uppercase
    return password[0].toUpperCase() + password.substring(1);
  }

  /// Extract initials from clinic name (max 3 letters)
  static String _extractInitials(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    String initials = '';
    
    for (var word in words) {
      if (word.isNotEmpty && initials.length < 3) {
        initials += word[0].toUpperCase();
      }
    }
    
    // If less than 2 initials, use first 2-3 chars of name
    if (initials.length < 2) {
      initials = name.replaceAll(RegExp(r'[^a-zA-Z]'), '').substring(0, 3).toUpperCase();
    }
    
    return initials;
  }

  /// Generate random digits
  static String _generateRandomDigits(int length) {
    final random = DateTime.now().millisecondsSinceEpoch;
    return random.toString().substring(random.toString().length - length);
  }
}