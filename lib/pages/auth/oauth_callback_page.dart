import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:capstone_app/pages/routes/app_pages.dart';
import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class OAuthCallbackPage extends StatefulWidget {
  const OAuthCallbackPage({super.key});

  @override
  State<OAuthCallbackPage> createState() => _OAuthCallbackPageState();
}

class _OAuthCallbackPageState extends State<OAuthCallbackPage> {
  final _storage = GetStorage();
  late AppWriteProvider _appwriteProvider;
  late AuthRepository _authRepository;

  @override
  void initState() {
    super.initState();
    
    _appwriteProvider = Get.find<AppWriteProvider>();
    _authRepository = Get.find<AuthRepository>();
    
    _handleCallback();
  }

  Future<void> _handleCallback() async {
    try {

      // WEB SPECIFIC: Check if we have OAuth query parameters
      if (kIsWeb) {
        final uri = Uri.base;
        
        // Check if there's a userId or secret in URL (Appwrite OAuth callback params)
        if (uri.queryParameters.containsKey('userId') || 
            uri.queryParameters.containsKey('secret')) {
        }
      }

      // CRITICAL: Try different session establishment strategies
      await _establishSession();

      // Step 1: Get authenticated user
      final user = await _appwriteProvider.account!.get();

      if (user == null) {
        throw Exception('User not found in Appwrite Auth after OAuth');
      }


      // Step 2: Get current session
      final session = await _appwriteProvider.account!.getSession(sessionId: 'current');

      // Step 3: Check if user exists in database
      final existingUserDoc = await _authRepository.getUserById(user.$id);

      if (existingUserDoc == null) {

        try {
          final newUserDoc = await _authRepository.createUser({
            "userId": user.$id,
            "name": user.name,
            "email": user.email,
            "role": "user",
            "phone": "",
            "profilePictureId": "",
            "idVerified": false,
            "idVerifiedAt": null,
            "verificationDocumentId": null,
            "isArchived": false,
            "archivedAt": null,
            "archivedBy": null,
            "archiveReason": null,
            "archivedDocumentId": null,
          });

          await _storage.write('userDocumentId', newUserDoc.$id);
          
        } catch (createError) {
          throw Exception('Failed to create user in database: $createError');
        }
      } else {
        await _storage.write('userDocumentId', existingUserDoc.$id);
        
        final profilePictureId = existingUserDoc.data['profilePictureId'] as String?;
        if (profilePictureId != null && profilePictureId.isNotEmpty) {
          await _storage.write('userProfilePictureId', profilePictureId);
        }
      }

      // Step 4: Store session data
      await _storage.write('userId', user.$id);
      await _storage.write('sessionId', session.$id);
      await _storage.write('email', user.email);
      await _storage.write('userName', user.name);
      await _storage.write('role', 'user');


      await Future.delayed(const Duration(milliseconds: 500));
      
      Get.offAllNamed(Routes.userHome);
      

    } catch (e, stackTrace) {

      _showErrorDialog();
    }
  }

  /// IMPROVED: Multiple strategies to establish session
  Future<void> _establishSession() async {

    // Strategy 1: Wait with retry (works for most cases)
    try {
      await _waitForSessionWithRetry();
      return;
    } catch (e) {
    }

    // Strategy 2: Check if session exists in cookies/storage (Web only)
    if (kIsWeb) {
      try {
        final sessions = await _appwriteProvider.account!.listSessions();
        
        if (sessions.sessions.isNotEmpty) {
          // Session exists, should work now
          return;
        }
      } catch (e) {
      }
    }

    // Strategy 3: Force create a new client with proper cookie handling
    if (kIsWeb) {
      try {
        
        // Reinitialize with explicit cookie settings
        final newClient = Client()
            .setEndpoint('https://cloud.appwrite.io/v1')
            .setProject('67ef82500017dc404c6a');
        
        final newAccount = Account(newClient);
        
        // Try to get user with new client
        final user = await newAccount.get();
        
        if (user != null) {
          // Update provider to use this client
          _appwriteProvider.client = newClient;
          _appwriteProvider.account = newAccount;
          return;
        }
      } catch (e) {
      }
    }

    // If all strategies fail, throw error
    throw Exception('Could not establish OAuth session. Please try again or use email/password login.');
  }

  /// Wait for session with exponential backoff
  Future<void> _waitForSessionWithRetry() async {
    const maxAttempts = 8; // Increased from 5 to 8
    const initialDelay = Duration(milliseconds: 1000);
    
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        
        // Progressive delays: 1s, 2s, 3s, 4s, 5s, 6s, 7s, 8s
        final delay = initialDelay * (attempt + 1);
        await Future.delayed(delay);
        
        // Try to get user
        final user = await _appwriteProvider.account!.get();
        
        if (user != null) {
          return;
        }
      } catch (e) {
        
        if (attempt == maxAttempts - 1) {
          throw Exception('Session timeout after $maxAttempts attempts');
        }
      }
    }
  }

  void _showErrorDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Authentication Failed',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                kIsWeb 
                  ? 'Google Sign-In failed on this browser. This might be due to:\n\n'
                    '• Third-party cookies being blocked\n'
                    '• Privacy/tracking protection enabled\n'
                    '• Browser extensions blocking auth\n\n'
                    'Try using email/password login or a different browser.'
                  : 'Failed to complete Google Sign-In. Please try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(
                          color: Color.fromARGB(255, 81, 115, 153),
                        ),
                      ),
                      onPressed: () {
                        Get.back();
                        // Try again
                        _handleCallback();
                      },
                      child: const Text(
                        'Try Again',
                        style: TextStyle(
                          color: Color.fromARGB(255, 81, 115, 153),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Get.back();
                        Get.offAllNamed(Routes.login);
                      },
                      child: const Text(
                        'Back to Login',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
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
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'lib/images/PAWrtal_logo.png',
              height: 80,
              width: 200,
            ),
            const SizedBox(height: 32),
            
            const SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color.fromARGB(255, 81, 115, 153),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            Text(
              'Completing Google Sign-In...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            
            Text(
              kIsWeb 
                ? 'This may take up to 30 seconds...'
                : 'Please wait while we set up your account',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.black54,
              ),
            ),
            
            if (kIsWeb) ...[
              const SizedBox(height: 16),
              Text(
                'If this takes too long, your browser may be blocking cookies',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}