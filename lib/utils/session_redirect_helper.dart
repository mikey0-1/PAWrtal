import 'package:capstone_app/pages/routes/app_pages.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Helper class to check for existing sessions and redirect users
/// to their appropriate home pages on public routes
class SessionRedirectHelper {
  /// Check if user has an existing session and redirect to appropriate home
  /// 
  /// Should be called in Bindings for public pages (Landing, Login, Signup)
  /// to prevent logged-in users from accessing these pages
  static void checkAndRedirect({required String pageName}) {
    final storage = GetStorage();
    final userId = storage.read("userId");
    final sessionId = storage.read("sessionId");
    final role = storage.read("role");


    // If user has a valid session, redirect to their home page
    if (userId != null && sessionId != null && role != null) {
      
      // Redirect based on role
      Future.delayed(Duration.zero, () {
        final targetRoute = _getHomeRouteForRole(role);
        
        if (targetRoute != null) {
          Get.offAllNamed(targetRoute);
        } else {
        }
      });
    } else {
    }
    
  }

  /// Get the appropriate home route based on user role
  static String? _getHomeRouteForRole(String role) {
    switch (role) {
      case "admin":
        return Routes.adminHome;
      case "staff":
        return Routes.adminHome;
      case "developer":
        return Routes.superAdminHome;
      case "user":
      case "customer":
        return Routes.userHome;
      default:
        return null;
    }
  }

  /// Check if user has an active session
  static bool hasActiveSession() {
    final storage = GetStorage();
    final userId = storage.read("userId");
    final sessionId = storage.read("sessionId");
    final role = storage.read("role");
    
    return userId != null && sessionId != null && role != null;
  }
}