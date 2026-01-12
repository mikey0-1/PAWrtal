import 'package:flutter/material.dart';

/// Permission Guard that shows view-only banner instead of blocking completely
class PermissionGuard extends StatelessWidget {
  final bool hasPermission;
  final String requiredPermission;
  final Widget child;

  const PermissionGuard({
    super.key,
    required this.hasPermission,
    required this.requiredPermission,
    required this.child,
  });

  static const Color primaryTeal = Color(0xFF5B9BD5);
  static const Color vetOrange = Color(0xFFF59E0B);
  static const Color mediumGray = Color(0xFF9CA3AF);

  @override
  Widget build(BuildContext context) {
    if (hasPermission) {
      // Full access - no banner
      return child;
    }

    // View-only mode - show banner
    return Column(
      children: [
        _buildViewOnlyBanner(context),
        Expanded(
          child: AbsorbPointer(
            // Prevent interactions but allow viewing
            absorbing: true,
            child: child,
          ),
        ),
      ],
    );
  }

  Widget _buildViewOnlyBanner(BuildContext context) {
    // FIX: Special message for Staffs page (admin-only)
    final bool isStaffsPage = requiredPermission == 'Staffs';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isStaffsPage
              ? [Colors.red.shade100, Colors.red.shade50]
              : [Colors.orange.shade100, Colors.orange.shade50],
        ),
        border: Border(
          bottom: BorderSide(
            color: isStaffsPage
                ? Colors.red.withOpacity(0.3)
                : vetOrange.withOpacity(0.3),
            width: 2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: isStaffsPage
                ? Colors.red.withOpacity(0.1)
                : vetOrange.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isStaffsPage
                  ? Colors.red.withOpacity(0.2)
                  : vetOrange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isStaffsPage ? Icons.admin_panel_settings : Icons.visibility,
              color: isStaffsPage ? Colors.red : vetOrange,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isStaffsPage ? 'Admin-Only Page' : 'View-Only Mode',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isStaffsPage
                            ? Colors.red.withOpacity(0.2)
                            : vetOrange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: isStaffsPage
                                ? Colors.red.withOpacity(0.5)
                                : vetOrange.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock,
                              size: 12,
                              color: isStaffsPage
                                  ? Colors.red[800]
                                  : Colors.orange[800]),
                          const SizedBox(width: 4),
                          Text(
                            isStaffsPage
                                ? 'Administrator Access Required'
                                : 'No "$requiredPermission" permission',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isStaffsPage
                                  ? Colors.red[800]
                                  : Colors.orange[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isStaffsPage
                      ? 'The Staff Management page is restricted to administrators only. You can view staff information but cannot add, edit, or remove staff members. Only clinic administrators have full access to manage staff accounts and permissions.'
                      : 'You can view this page but cannot make changes. Contact your administrator to request "$requiredPermission" permission.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Wrapper for pages that need permission checks
class PermissionWrapper extends StatelessWidget {
  final String pageName;
  final Widget child;

  const PermissionWrapper({
    super.key,
    required this.pageName,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // This will be overridden in the actual implementation with GetX
    // For now, just return the child
    return child;
  }
}

/// Banner to show at top of pages when user has limited access
class PermissionBanner extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color? color;
  final bool isViewOnly;
  final bool isAdminOnly;

  const PermissionBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.color,
    this.isViewOnly = false,
    this.isAdminOnly = false,
  });

  static const Color vetOrange = Color(0xFFF59E0B);
  static const Color primaryTeal = Color(0xFF5B9BD5);

  @override
  Widget build(BuildContext context) {
    final bannerColor = color ??
        (isAdminOnly ? Colors.red : (isViewOnly ? vetOrange : primaryTeal));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bannerColor.withOpacity(0.3), width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bannerColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: bannerColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: bannerColor.withOpacity(0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DoctorPermissionGuard extends StatelessWidget {
  final bool isDoctor;
  final Widget child;

  const DoctorPermissionGuard({
    super.key,
    required this.isDoctor,
    required this.child,
  });

  static const Color primaryTeal = Color(0xFF5B9BD5);
  static const Color vetOrange = Color(0xFFF59E0B);
  static const Color mediumGray = Color(0xFF9CA3AF);

  @override
  Widget build(BuildContext context) {
    if (isDoctor) {
      // Full access - no banner
      return child;
    }

    // Doctor-only mode - show banner
    return Column(
      children: [
        _buildDoctorOnlyBanner(context),
        Expanded(
          child: AbsorbPointer(
            // Prevent interactions but allow viewing
            absorbing: true,
            child: child,
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorOnlyBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade100, Colors.red.shade50],
        ),
        border: Border(
          bottom: BorderSide(
            color: Colors.red.withOpacity(0.3),
            width: 2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.medical_services,
              color: Colors.red,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Doctor-Only Feature',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock, size: 12, color: Colors.red[800]),
                          const SizedBox(width: 4),
                          Text(
                            'Medical License Required',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.red[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'This feature requires veterinary doctor credentials. Only licensed veterinarians can complete medical appointments with diagnosis and treatment. You can view information but cannot make medical decisions or complete medical services.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
