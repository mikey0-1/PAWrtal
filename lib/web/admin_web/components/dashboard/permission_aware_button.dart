import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:capstone_app/web/pages/web_admin_home/web_admin_home_controller.dart';

/// A button that automatically checks permissions and shows appropriate dialogs
/// Usage: PermissionAwareButton(
///   feature: 'appointments',
///   onPressed: () { /* your action */ },
///   child: Text('View Appointments'),
/// )
class PermissionAwareButton extends StatelessWidget {
  final String
      feature; // Feature name: 'appointments', 'clinic_info', 'messages', 'staffs'
  final VoidCallback onPressed;
  final Widget child;
  final ButtonStyle? style;

  const PermissionAwareButton({
    super.key,
    required this.feature,
    required this.onPressed,
    required this.child,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WebAdminHomeController>();

    return ElevatedButton(
      style: style,
      onPressed: () {
        if (controller.canAccessFeature(feature)) {
          onPressed();
        } else {
          controller.showPermissionDeniedDialog(feature);
        }
      },
      child: child,
    );
  }
}

/// A widget that wraps content and shows a lock icon if no permission
class PermissionAwareCard extends StatelessWidget {
  final String feature;
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final Color? color;

  const PermissionAwareCard({
    super.key,
    required this.feature,
    required this.child,
    this.onTap,
    this.padding,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WebAdminHomeController>();

    return Obx(() {
      final hasPermission = controller.canAccessFeature(feature);

      return InkWell(
        onTap: onTap == null
            ? null
            : () {
                if (hasPermission) {
                  onTap!();
                } else {
                  controller.showPermissionDeniedDialog(feature);
                }
              },
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color ?? Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasPermission ? Colors.grey[300]! : Colors.orange[200]!,
            ),
          ),
          child: Stack(
            children: [
              Opacity(
                opacity: hasPermission ? 1.0 : 0.5,
                child: child,
              ),
              if (!hasPermission)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.orange[700],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}

/// An icon button with permission check
class PermissionAwareIconButton extends StatelessWidget {
  final String feature;
  final VoidCallback onPressed;
  final IconData icon;
  final Color? color;
  final double? size;
  final String? tooltip;

  const PermissionAwareIconButton({
    super.key,
    required this.feature,
    required this.onPressed,
    required this.icon,
    this.color,
    this.size,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WebAdminHomeController>();

    return Obx(() {
      final hasPermission = controller.canAccessFeature(feature);

      return Tooltip(
        message: tooltip ?? (hasPermission ? '' : 'You do not have permission'),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Icon(icon),
              iconSize: size,
              color: hasPermission ? color : Colors.grey[400],
              onPressed: () {
                if (hasPermission) {
                  onPressed();
                } else {
                  controller.showPermissionDeniedDialog(feature);
                }
              },
            ),
            if (!hasPermission)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.orange[700],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

/// A list tile with permission check
class PermissionAwareListTile extends StatelessWidget {
  final String feature;
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  const PermissionAwareListTile({
    super.key,
    required this.feature,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WebAdminHomeController>();

    return Obx(() {
      final hasPermission = controller.canAccessFeature(feature);

      return ListTile(
        leading: hasPermission
            ? leading
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leading != null) leading!,
                  const SizedBox(width: 4),
                  Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: Colors.orange[700],
                  ),
                ],
              ),
        title: DefaultTextStyle(
          style: TextStyle(
            color: hasPermission ? Colors.black87 : Colors.grey[600],
          ),
          child: title,
        ),
        subtitle: subtitle,
        trailing: !hasPermission
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'No Access',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange[900],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : trailing,
        onTap: onTap == null
            ? null
            : () {
                if (hasPermission) {
                  onTap!();
                } else {
                  controller.showPermissionDeniedDialog(feature);
                }
              },
      );
    });
  }
}

/// Extension method for easy permission checks in any widget
extension PermissionCheck on BuildContext {
  bool canAccess(String feature) {
    try {
      final controller = Get.find<WebAdminHomeController>();
      return controller.canAccessFeature(feature);
    } catch (e) {
      return true; // Default to true if controller not found
    }
  }

  void showNoPermissionDialog(String feature) {
    try {
      final controller = Get.find<WebAdminHomeController>();
      controller.showPermissionDeniedDialog(feature);
    } catch (e) {
      // Fallback dialog
      showDialog(
        context: this,
        builder: (context) => AlertDialog(
          title: const Text('Access Denied'),
          content:
              const Text('You do not have permission to access this feature.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}
