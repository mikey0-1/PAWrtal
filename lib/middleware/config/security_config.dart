class SecurityConfig {
  // Session timeout (in minutes)
  static const int sessionTimeoutMinutes = 360;

  // Maximum login attempts before lockout
  static const int maxLoginAttempts = 5;

  // Lockout duration (in minutes)
  static const int lockoutDurationMinutes = 5;

  // Maximum security violations before auto-logout
  static const int maxSecurityViolations = 3;

  // Enable security logging
  static const bool enableSecurityLogging = true;

  // Enable session validation on page navigation
  static const bool enableSessionValidation = true;

  // Role-based access control map
  static const Map<String, List<String>> roleAccessMap = {
    // User/Customer routes
    '/userHome': ['user', 'customer'],
    
    // Admin/Staff routes
    '/adminHome': ['admin', 'staff'],
    '/createStaff': ['admin'],
    
    // Staff-only routes
    '/staffHome': ['staff'],
    
    // Developer/Super Admin routes
    '/superAdminHome': ['developer'],
    '/super-admin/clinics': ['developer'],
    '/super-admin/users': ['developer'],
    '/super-admin/feedback': ['developer'],
  };

  /// Check if a role can access a specific route
  static bool canAccess(String route, String role) {
    // If route not in map, deny access by default (secure by default)
    if (!roleAccessMap.containsKey(route)) {
      return false;
    }

    final allowedRoles = roleAccessMap[route]!;
    return allowedRoles.contains(role);
  }

  /// Get home route for a specific role
  static String getHomeRoute(String role) {
    switch (role) {
      case 'admin':
      case 'staff':
        return '/adminHome';
      case 'developer':
        return '/superAdminHome';
      case 'user':
      case 'customer':
      default:
        return '/userHome';
    }
  }

  /// Validate role string
  static bool isValidRole(String role) {
    return ['user', 'customer', 'admin', 'staff', 'developer'].contains(role);
  }

  /// Get all routes accessible by a role
  static List<String> getAccessibleRoutes(String role) {
    return roleAccessMap.entries
        .where((entry) => entry.value.contains(role))
        .map((entry) => entry.key)
        .toList();
  }

  /// Security headers for web (if needed)
  static Map<String, String> get securityHeaders => {
    'X-Frame-Options': 'DENY',
    'X-Content-Type-Options': 'nosniff',
    'X-XSS-Protection': '1; mode=block',
    'Referrer-Policy': 'strict-origin-when-cross-origin',
  };
}