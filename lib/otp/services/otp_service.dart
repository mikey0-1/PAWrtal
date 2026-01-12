import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:appwrite/appwrite.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:get_storage/get_storage.dart';

class OTPService {
  static final OTPService _instance = OTPService._internal();
  factory OTPService() => _instance;
  OTPService._internal();

  final GetStorage _storage = GetStorage();
  
  // OTP Configuration
  static const int otpLength = 6;
  static const int otpValidityMinutes = 5; // OTP expires in 5 minutes
  static const int maxResendAttempts = 3;
  
  // Appwrite Function ID (you'll get this after creating the function)
  static const String sendOTPFunctionId = '690577990031987cc6b2'; // Replace after deployment

  /// Store OTP with expiry time
  Future<void> storeOTP(String email, String otp) async {
    final expiryTime = DateTime.now().add(Duration(minutes: otpValidityMinutes));
    
    final otpData = {
      'otp': otp,
      'email': email,
      'expiryTime': expiryTime.toIso8601String(),
      'attempts': 0,
      'createdAt': DateTime.now().toIso8601String(),
    };

    _storage.write('otp_${email.toLowerCase()}', json.encode(otpData));
  }

  /// Verify OTP
  Future<Map<String, dynamic>> verifyOTP(String email, String enteredOTP) async {
    try {
      final key = 'otp_${email.toLowerCase()}';
      final storedDataJson = _storage.read(key);

      if (storedDataJson == null) {
        return {
          'success': false,
          'message': 'OTP not found. Please request a new OTP.',
        };
      }

      final storedData = json.decode(storedDataJson);
      final storedOTP = storedData['otp'];
      final expiryTime = DateTime.parse(storedData['expiryTime']);
      final attempts = storedData['attempts'] ?? 0;

      // Check if OTP has expired
      if (DateTime.now().isAfter(expiryTime)) {
        _storage.remove(key);
        return {
          'success': false,
          'message': 'OTP has expired. Please request a new OTP.',
        };
      }

      // Check if max attempts exceeded
      if (attempts >= 5) {
        _storage.remove(key);
        return {
          'success': false,
          'message': 'Too many failed attempts. Please request a new OTP.',
        };
      }

      // Verify OTP
      if (storedOTP == enteredOTP) {
        _storage.remove(key); // Remove OTP after successful verification
        return {
          'success': true,
          'message': 'Email verified successfully!',
        };
      } else {
        // Increment attempts
        storedData['attempts'] = attempts + 1;
        _storage.write(key, json.encode(storedData));
        
        final remainingAttempts = 5 - (attempts + 1);
        return {
          'success': false,
          'message': 'Invalid OTP. $remainingAttempts attempt(s) remaining.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error verifying OTP. Please try again.',
      };
    }
  }

  /// Send OTP via Appwrite Function (calls Resend API server-side)
  Future<Map<String, dynamic>> sendOTP(String email, String name) async {
    try {

      // Initialize Appwrite client
      final client = Client()
        ..setEndpoint(AppwriteConstants.endPoint)
        ..setProject(AppwriteConstants.projectID);

      final functions = Functions(client);

      // Call Appwrite function
      
      final execution = await functions.createExecution(
        functionId: sendOTPFunctionId,
        body: json.encode({
          'email': email,
          'name': name,
        }),
        xasync: false, // Wait for completion
      );


      // Parse response
      if (execution.status == 'completed') {
        final response = json.decode(execution.responseBody);
        
        if (response['success'] == true) {
          // Store the OTP returned from the function
          final otp = response['otp'];
          await storeOTP(email, otp);
          
          
          return {
            'success': true,
            'message': 'Verification code sent to your email',
          };
        } else {
          return {
            'success': false,
            'message': response['message'] ?? 'Failed to send verification code',
          };
        }
      } else if (execution.status == 'failed') {
        
        return {
          'success': false,
          'message': 'Failed to send verification code. Please try again.',
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

  /// Check if OTP is still valid (not expired)
  bool isOTPValid(String email) {
    try {
      final key = 'otp_${email.toLowerCase()}';
      final storedDataJson = _storage.read(key);

      if (storedDataJson == null) return false;

      final storedData = json.decode(storedDataJson);
      final expiryTime = DateTime.parse(storedData['expiryTime']);

      return DateTime.now().isBefore(expiryTime);
    } catch (e) {
      return false;
    }
  }

  /// Get remaining time for OTP in seconds
  int getRemainingTime(String email) {
    try {
      final key = 'otp_${email.toLowerCase()}';
      final storedDataJson = _storage.read(key);

      if (storedDataJson == null) return 0;

      final storedData = json.decode(storedDataJson);
      final expiryTime = DateTime.parse(storedData['expiryTime']);
      
      final remaining = expiryTime.difference(DateTime.now()).inSeconds;
      return remaining > 0 ? remaining : 0;
    } catch (e) {
      return 0;
    }
  }

  /// Clear OTP for email
  void clearOTP(String email) {
    _storage.remove('otp_${email.toLowerCase()}');
  }
}