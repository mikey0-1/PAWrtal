import 'package:capstone_app/utils/logout_helper.dart';
import 'package:capstone_app/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:capstone_app/pages/routes/app_pages.dart';
import 'package:capstone_app/utils/web_error_handler.dart';

class RouteGuard extends GetMiddleware {
  final GetStorage _storage = GetStorage();

  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    // Allow public routes (landing, login, signup, splash)
    if (route == Routes.landing ||
        route == Routes.login ||
        route == Routes.signup ||
        route == Routes.splash) {
      return null;
    }

    // CRITICAL FIX: If logout is in progress, allow navigation
    // Don't interfere with the logout process
    if (LogoutHelper.isLoggingOut.value) {
      return null;
    }

    // Check if user is logged in
    final userId = _storage.read('userId');
    final sessionId = _storage.read('sessionId');
    final role = _storage.read('role');

    // If no session, redirect to landing page
    if (userId == null || sessionId == null || role == null) {

      // IMPORTANT: Don't erase storage here - let logout handle it properly
      // Only clear if we're NOT in a logout process
      if (!LogoutHelper.isLoggingOut.value) {
        _storage.erase();
      }

      return const RouteSettings(name: Routes.login);
    }

    // Validate role-based access
    final hasAccess = _validateRoleAccess(route, role);

    if (!hasAccess) {

      // Log security violation
      _logSecurityViolation(userId, role, route);

      // Redirect to appropriate home based on role
      return RouteSettings(name: _getHomeRouteForRole(role));
    }

    return null;
  }

  /// Validate if user's role can access the route
  bool _validateRoleAccess(String? route, String role) {
    // Define role-based access rules
    final Map<String, List<String>> routeAccessMap = {
      Routes.userHome: ['user'],
      Routes.adminHome: ['admin', 'staff'],
      Routes.superAdminHome: ['developer'],
      Routes.createStaff: ['admin'],
      Routes.staffHome: ['staff'],
    };

    // Check if route has access restrictions
    if (!routeAccessMap.containsKey(route)) {
      // If route not in map, allow access (or you can deny by default)
      return true;
    }

    // Check if user's role is in allowed roles for this route
    final allowedRoles = routeAccessMap[route]!;
    return allowedRoles.contains(role);
  }

  /// Get home route based on user role
  String _getHomeRouteForRole(String role) {
    switch (role) {
      case 'admin':
      case 'staff':
        return Routes.adminHome;
      case 'developer':
        return Routes.superAdminHome;
      case 'user':
        return Routes.userHome;
      case 'customer':
      default:
        return Routes.landing;
    }
  }

  /// Log security violation attempts
  void _logSecurityViolation(String userId, String role, String? targetRoute) {
    final timestamp = DateTime.now().toIso8601String();

    // Store violation in local storage for admin review
    final violations = _storage.read<List>('security_violations') ?? [];
    violations.add({
      'timestamp': timestamp,
      'userId': userId,
      'role': role,
      'attemptedRoute': targetRoute,
    });

    // Keep only last 100 violations
    if (violations.length > 100) {
      violations.removeAt(0);
    }

    _storage.write('security_violations', violations);

    // Show warning to user
    Future.delayed(const Duration(milliseconds: 500), () {
      SnackbarHelper.showError(
        context: Get.overlayContext,
        title: 'Unauthorized Access',
        message: 'You do not have permission to access this page',
      );
    });
  }
}
