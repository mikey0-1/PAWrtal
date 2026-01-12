// import 'package:capstone_app/utils/logout_helper.dart';
// import 'package:get_storage/get_storage.dart';
// import 'package:capstone_app/middleware/config/security_config.dart';
// import 'package:get/get.dart';
// import 'package:capstone_app/pages/routes/app_pages.dart';

// class SessionManager {
//   static final GetStorage _storage = GetStorage();

//   /// Update session activity timestamp
//   static void updateActivity() {
//     _storage.write('sessionTimestamp', DateTime.now().toIso8601String());
//   }

//   /// Check if session is valid and not expired
//   static bool isSessionValid() {
//     final sessionId = _storage.read('sessionId');
//     final userId = _storage.read('userId');
//     final sessionTimestamp = _storage.read('sessionTimestamp');

//     if (sessionId == null || userId == null) {
//       return false;
//     }

//     // Check session timeout
//     if (sessionTimestamp != null) {
//       final lastActivity = DateTime.parse(sessionTimestamp);
//       final now = DateTime.now();
//       final minutesSinceActivity = now.difference(lastActivity).inMinutes;

//       if (minutesSinceActivity > SecurityConfig.sessionTimeoutMinutes) {
//         print('>>> Session expired: ${minutesSinceActivity} minutes inactive');
//         return false;
//       }
//     }

//     return true;
//   }

//   /// Force logout user
//   static Future<void> forceLogout({String? reason}) async {
//     print('>>> ============================================');
//     print('>>> FORCE LOGOUT');
//     if (reason != null) {
//       print('>>> Reason: $reason');
//     }
//     print('>>> ============================================');


//     LogoutHelper.logout();
//     // // Clear all session data
//     // await _storage.erase();

//     // // Navigate to login
//     // Get.offAllNamed(Routes.login);

//     // // Show message
//     // if (reason != null) {
//     //   Get.snackbar(
//     //     'Session Ended',
//     //     reason,
//     //     snackPosition: SnackPosition.TOP,
//     //     duration: const Duration(seconds: 5),
//     //   );
//     // }
//   }

//   /// Refresh session (extend timeout)
//   static void refreshSession() {
//     if (isSessionValid()) {
//       updateActivity();
//       print('>>> Session refreshed');
//     }
//   }

//   /// Get session info
//   static Map<String, dynamic> getSessionInfo() {
//     return {
//       'userId': _storage.read('userId'),
//       'sessionId': _storage.read('sessionId'),
//       'role': _storage.read('role'),
//       'userName': _storage.read('userName'),
//       'email': _storage.read('email'),
//       'lastActivity': _storage.read('sessionTimestamp'),
//     };
//   }

//   /// Check if user has exceeded security violation limit
//   static bool hasExceededViolationLimit(String userId) {
//     final violations = _storage.read<List>('security_violations') ?? [];
    
//     final userViolations = violations.where((v) => 
//       v['userId'] == userId
//     ).toList();

//     // Check violations in last hour
//     final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
//     final recentViolations = userViolations.where((v) {
//       try {
//         final timestamp = DateTime.parse(v['timestamp']);
//         return timestamp.isAfter(oneHourAgo);
//       } catch (e) {
//         return false;
//       }
//     }).toList();

//     return recentViolations.length >= SecurityConfig.maxSecurityViolations;
//   }

//   /// Start session monitoring (call this after login)
//   static void startSessionMonitoring() {
//     print('>>> Session monitoring started');
//     updateActivity();
    
//     // Set up periodic session validation
//     _setupPeriodicValidation();
//   }

//   /// Set up periodic session validation
//   static void _setupPeriodicValidation() {
//     // Check session every 5 minutes
//     Future.delayed(const Duration(minutes: 360), () {
//       if (!isSessionValid()) {
//         forceLogout(reason: 'Session expired due to inactivity');
//       } else {
//         _setupPeriodicValidation(); // Continue monitoring
//       }
//     });
//   }

//   /// Clean up old session data
//   static Future<void> cleanupOldData() async {
//     final violations = _storage.read<List>('security_violations') ?? [];
    
//     // Remove violations older than 30 days
//     final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
//     final recentViolations = violations.where((v) {
//       try {
//         final timestamp = DateTime.parse(v['timestamp']);
//         return timestamp.isAfter(thirtyDaysAgo);
//       } catch (e) {
//         return false;
//       }
//     }).toList();

//     await _storage.write('security_violations', recentViolations);
    
//     print('>>> Cleaned up old security data');
//     print('>>> Violations before: ${violations.length}');
//     print('>>> Violations after: ${recentViolations.length}');
//   }
// }