import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:capstone_app/web/admin_web/components/appointments/admin_web_appointment_controller.dart';
import 'package:capstone_app/web/admin_web/pages/admin_web_appointments.dart';
import 'package:capstone_app/web/admin_web/pages/admin_web_clinicpage.dart';
import 'package:capstone_app/web/admin_web/pages/admin_web_dashboard.dart';
import 'package:capstone_app/web/admin_web/pages/admin_web_messages.dart';
import 'package:capstone_app/web/admin_web/pages/admin_web_staffs.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:capstone_app/data/models/clinic_model.dart';

class WebAdminHomeController extends GetxController {
  final GetStorage _getStorage = GetStorage();

  final selectedIndex = 0.obs;
  final userRole = ''.obs;
  final userAuthorities = <String>[].obs;

  // Dynamic pages based on permissions
  final RxList<Widget> pages = <Widget>[].obs;
  final RxList<String> navigationLabels = <String>[].obs;

  @override
  void onInit() {
    super.onInit();

    _loadUserRole();
    _buildNavigationBasedOnPermissions();

    // 🔧 FIX: Register WebAppointmentController early
    _registerControllers();
  }

// 🆕 ADD THIS METHOD
  void _registerControllers() {
    try {
      // Register WebAppointmentController if not already registered
      if (!Get.isRegistered<WebAppointmentController>()) {
        Get.put(
          WebAppointmentController(
            authRepository: Get.find<AuthRepository>(),
            session: Get.find<UserSessionService>(),
          ),
          permanent: true, // Keep it alive
        );
      } else {}
    } catch (e) {}
  }

  void _loadUserRole() {
    final role = _getStorage.read("role") as String?;
    final clinicId = _getStorage.read("clinicId") as String?;
    final userId = _getStorage.read("userId") as String?;

    if (role == null || role.isEmpty) {
      userRole.value = '';
    } else {
      userRole.value = role;
    }

    // Load authorities for staff users
    if (role == "staff") {
      final authorities = _getStorage.read("authorities");

      if (authorities != null) {
        if (authorities is List) {
          userAuthorities.value = List<String>.from(authorities);
        } else if (authorities is String) {
          userAuthorities.value = [authorities];
        } else {
          userAuthorities.value = [];
        }
      } else {
        userAuthorities.value = [];
      }
    } else {
      userAuthorities.value = [];
    }

    _printAccessSummary();
  }

  void _buildNavigationBasedOnPermissions() {
    // Clear existing pages and labels
    pages.clear();
    navigationLabels.clear();

    // HOME is always available for everyone
    pages.add(const AdminWebDashboard());
    navigationLabels.add("Home");

    if (userRole.value == "admin") {
      // Admin sees all pages
      pages.add(const AdminWebClinicpage());
      navigationLabels.add("Clinic");

      pages.add(const AdminWebAppointments());
      navigationLabels.add("Appointments");

      pages.add(const AdminWebMessages());
      navigationLabels.add("Messages");

      pages.add(const AdminWebStaffs());
      navigationLabels.add("Staffs");
    } else if (userRole.value == "staff") {
      // Staff only sees pages they have permission for
      if (hasAuthority("Clinic")) {
        pages.add(const AdminWebClinicpage());
        navigationLabels.add("Clinic");
      }

      if (hasAuthority("Appointments")) {
        pages.add(const AdminWebAppointments());
        navigationLabels.add("Appointments");
      }

      if (hasAuthority("Messages")) {
        pages.add(const AdminWebMessages());
        navigationLabels.add("Messages");
      }

      // Staffs page is NEVER shown to staff users
    }
  }

  void _printAccessSummary() {
    if (userRole.value == "admin") {
    } else if (userRole.value == "staff") {
      final allPages = ["Clinic", "Appointments", "Messages"];
      final noAccess =
          allPages.where((page) => !userAuthorities.contains(page)).toList();
      if (noAccess.isNotEmpty) {}
    }
  }

  void setSelectedIndex(int index) {
    final maxIndex = pages.length - 1;

    if (index >= 0 && index <= maxIndex) {
      selectedIndex.value = index;

      // Permission info
      if (userRole.value == "staff" && index > 0) {
        final pageName = navigationLabels[index];
      }
    } else {
      selectedIndex.value = 0;
    }
  }

  String get userName {
    return _getStorage.read("userName") ?? "User";
  }

  String get userEmail {
    return _getStorage.read("email") ?? "";
  }

  String get clinicId {
    return _getStorage.read("clinicId") ?? "";
  }

  bool get isAdmin => userRole.value == "admin";
  bool get isStaff => userRole.value == "staff";

  bool hasAuthority(String authority) {
    if (isAdmin) {
      return true; // Admins have full access to everything
    }

    // Staff users - check their authorities
    final hasAuth = userAuthorities.contains(authority);
    return hasAuth;
  }

  bool hasFullAccessToCurrentPage() {
    if (isAdmin) return true;
    if (selectedIndex.value == 0) return true; // Home is always accessible

    final pageName = navigationLabels[selectedIndex.value];
    return hasAuthority(pageName);
  }

  String getCurrentPagePermission() {
    if (selectedIndex.value == 0) return "Home";
    return navigationLabels[selectedIndex.value];
  }

  /// NEW: Check if staff can access a specific dashboard feature/widget
  bool canAccessFeature(String featureName) {
    if (isAdmin) return true;

    // Map feature names to permissions
    final featurePermissions = {
      'appointments': 'Appointments',
      'messages': 'Messages',
      'clinic_info': 'Clinic',
      'clinic_settings': 'Clinic',
      'staffs': 'admin_only', // Admin only - staff never see this
    };

    final requiredPermission = featurePermissions[featureName];

    // Staff can never access admin-only features
    if (requiredPermission == 'admin_only') {
      return false;
    }

    // If no permission mapping, allow by default
    if (requiredPermission == null) {
      return true;
    }

    // Check if staff has the required authority
    return hasAuthority(requiredPermission);
  }

  /// NEW: Get a list of accessible features for the current user
  List<String> getAccessibleFeatures() {
    final allFeatures = [
      'appointments',
      'messages',
      'clinic_info',
      'clinic_settings',
    ];

    if (isAdmin) {
      return [...allFeatures, 'staffs'];
    }

    return allFeatures.where((feature) => canAccessFeature(feature)).toList();
  }

  /// NEW: Get dashboard widget visibility
  Map<String, bool> getDashboardWidgetVisibility() {
    return {
      'todaySchedule': canAccessFeature('appointments'),
      'recentMessages': canAccessFeature('messages'),
      'upcomingAppointments': canAccessFeature('appointments'),
      'appointmentCalendar': canAccessFeature('appointments'),
      'quickStats': canAccessFeature('appointments'),
      'clinicInfo': canAccessFeature('clinic_info'),
    };
  }

  /// NEW: Enhanced permission denied dialog with suggestion
  void showPermissionDeniedDialog(String featureName) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock, color: Colors.orange[700], size: 28),
            const SizedBox(width: 12),
            const Text('Access Denied'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You do not have permission to access $featureName.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Permission Required',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Contact your administrator to request access to $featureName.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange[900],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb, color: Colors.blue[700], size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your current permissions: ${userAuthorities.value.join(", ")}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void refreshRoleData() {
    _loadUserRole();
    _buildNavigationBasedOnPermissions();
  }

  /// NEW: Get permission summary for staff
  String getPermissionSummary() {
    if (isAdmin) {
      return 'Admin - Full access to all features';
    }

    final features = getAccessibleFeatures();
    if (features.isEmpty) {
      return 'No features available';
    }

    if (features.length == 4) {
      return 'Full staff access';
    }

    return 'Access: ${features.join(", ")}';
  }

  /// NEW: Log permission details for debugging
  void debugPrintPermissions() {
    getDashboardWidgetVisibility().forEach((widget, visible) {});
  }

  void debugPrintState() {}

  @override
  void onClose() {
    super.onClose();
  }

  Future<bool> shouldPromptPasswordChange() async {
    try {
      // Only check for admin users
      if (!isAdmin) return false;

      final clinicId = _getStorage.read("clinicId") as String?;
      if (clinicId == null || clinicId.isEmpty) return false;

      // Check if password has been changed (nullable check)
      final hasChangedPassword =
          _getStorage.read('hasChangedPassword') as bool?;

      // If already changed (true), no need to prompt
      if (hasChangedPassword == true) return false;

      // Fetch from database to confirm
      final authRepository = Get.find<AuthRepository>();

      // ✅ FIX: Get the document and convert to Clinic model
      final clinicDoc = await authRepository.getClinicById(clinicId);

      if (clinicDoc != null) {
        // ✅ Convert Document to Clinic model
        final clinic = Clinic.fromMap(clinicDoc.data);
        clinic.documentId = clinicDoc.$id;

        // ✅ Now we can safely access hasChangedPassword
        final dbHasChanged = clinic.hasChangedPassword ?? false;

        // Update local storage to match database
        _getStorage.write('hasChangedPassword', dbHasChanged);

        // Return true if password has NOT been changed (false or null)
        return !dbHasChanged;
      }

      return false;
    } catch (e) {
      return false;
    }
  }
}
