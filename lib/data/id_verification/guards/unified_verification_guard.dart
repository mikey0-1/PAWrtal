// lib/utils/guards/unified_verification_guard.dart

import 'package:flutter/material.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/web/user_web/responsive_page_handlers/web_settings_and_everything_page_handler.dart';
import 'package:get/get.dart';

/// Unified guard for checking user verification before allowing features
class UnifiedVerificationGuard {
  final AuthRepository _authRepository;

  UnifiedVerificationGuard(this._authRepository);

  /// Check if user can access feature (appointments or messaging)
  /// Returns true if verified or doesn't need verification
  /// Returns false and shows dialog if verification required
  Future<bool> canAccessFeature({
    required BuildContext context,
    required String userId,
    required String email,
    required String userRole,
    required String featureName, // "appointment" or "messaging"
  }) async {
    try {

      // Admin and staff don't need ID verification
      if (userRole == 'admin' || userRole == 'staff') {
        return true;
      }

      // Check if user is verified
      final isVerified = await _authRepository.isUserIdVerified(userId);

      if (isVerified) {
        return true;
      }

      // User is not verified - show responsive dialog
      _showVerificationRequiredDialog(
        context: context,
        userId: userId,
        email: email,
        featureName: featureName,
      );

      return false;
    } catch (e) {
      
      // Show error in a user-friendly way
      if (context.mounted) {
        _showErrorDialog(
          context: context,
          message: "Unable to verify your account status. Please try again.",
        );
      }

      return false;
    }
  }

  /// Show responsive verification required dialog
  void _showVerificationRequiredDialog({
    required BuildContext context,
    required String userId,
    required String email,
    required String featureName,
  }) {
    final isWeb = MediaQuery.of(context).size.width > 600;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isWeb ? 550 : double.infinity,
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(isWeb ? 32 : 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1976D2).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_user_outlined,
                        color: Color(0xFF1976D2),
                        size: 48,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Title
                    Text(
                      'ID Verification Required',
                      style: TextStyle(
                        fontSize: isWeb ? 24 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Message
                    Text(
                      _getFeatureMessage(featureName),
                      style: TextStyle(
                        fontSize: isWeb ? 16 : 15,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Online Verification Option
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.phone_android,
                                size: 20,
                                color: Color(0xFF1976D2),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Option 1: Online Verification',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isWeb ? 15 : 14,
                                    color: const Color(0xFF1976D2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildBulletPoint('Provide a valid government ID (Driver\'s License, National ID, Passport)', isWeb),
                          _buildBulletPoint('Take facial recognition for verification', isWeb),
                          _buildBulletPoint('Wait for approval (usually instant)', isWeb),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Divider with "OR"
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              fontSize: isWeb ? 14 : 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // In-Person Verification Option
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFF9800).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.local_hospital,
                                size: 20,
                                color: Color(0xFFFF9800),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Option 2: In-Person Verification',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isWeb ? 15 : 14,
                                    color: const Color(0xFFFF9800),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildBulletPoint(
                            'Visit any veterinary clinic registered in the PAWrtal system',
                            isWeb,
                            color: const Color(0xFFFF9800),
                          ),
                          _buildBulletPoint(
                            'Ask the clinic admin to verify your account',
                            isWeb,
                            color: const Color(0xFFFF9800),
                          ),
                          _buildBulletPoint(
                            'The clinic will verify that you are a real and legitimate user',
                            isWeb,
                            color: const Color(0xFFFF9800),
                          ),
                          _buildBulletPoint(
                            'Your account will be verified immediately after approval',
                            isWeb,
                            color: const Color(0xFFFF9800),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                            },
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                vertical: isWeb ? 16 : 14,
                              ),
                              side: const BorderSide(color: Colors.grey),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Maybe Later',
                              style: TextStyle(
                                fontSize: isWeb ? 16 : 15,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.of(dialogContext).pop();

                              // Navigate to Profile/Settings page (index 0 = Profile tab)
                              // This uses the responsive handler to navigate to correct page
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const WebSettingsAndEverythingPageHandler(
                                    initialIndex: 0, // Profile tab
                                  ),
                                ),
                              );

                              // User will initiate verification from profile page
                              // No need to show success dialog here as profile page handles it
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1976D2),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: isWeb ? 16 : 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Verify Now',
                              style: TextStyle(
                                fontSize: isWeb ? 16 : 15,
                                fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildBulletPoint(String text, bool isWeb, {Color color = const Color(0xFF1976D2)}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: isWeb ? 14 : 13,
                color: Colors.grey[800],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFeatureMessage(String featureName) {
    switch (featureName.toLowerCase()) {
      case 'appointment':
        return 'To ensure the safety and security of our system, you need to verify your identity before booking appointments.';
      case 'messaging':
        return 'To ensure the safety and security of our system, you need to verify your identity before messaging clinics.';
      default:
        return 'To ensure the safety and security of our system, you need to verify your identity before accessing this feature.';
    }
  }

  void _showErrorDialog({
    required BuildContext context,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 12),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog({
    required BuildContext context,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 12),
            Text('Success'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Quick check without showing dialog (for UI state)
  Future<bool> isUserVerified(String userId, String userRole) async {
    try {
      // Admin and staff don't need verification
      if (userRole == 'admin' || userRole == 'staff') {
        return true;
      }

      return await _authRepository.isUserIdVerified(userId);
    } catch (e) {
      return false;
    }
  }
}