// lib/utils/snackbar_helper.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Snackbar types for different message contexts
enum SnackbarType {
  success,
  error,
  warning,
  info,
}

/// Global utility class for showing styled snackbars throughout the app
class SnackbarHelper {
  SnackbarHelper._(); // Private constructor to prevent instantiation

  /// Show a styled snackbar using Overlay
  static void show({
    required String title,
    required String message,
    required SnackbarType type,
    BuildContext? context,
    Duration duration = const Duration(seconds: 4),
    double top = 140,
    double right = 20,
    double? left,
    double? bottom,
    double maxWidth = 400,
  }) {
    Color backgroundColor;
    IconData icon;

    switch (type) {
      case SnackbarType.success:
        backgroundColor = const Color(0xFF10B981); // Green
        icon = Icons.check_circle;
        break;
      case SnackbarType.error:
        backgroundColor = const Color(0xFFEF4444); // Red
        icon = Icons.error;
        break;
      case SnackbarType.warning:
        backgroundColor = const Color(0xFFF59E0B); // Orange
        icon = Icons.warning;
        break;
      case SnackbarType.info:
        backgroundColor = const Color(0xFF3B82F6); // Blue
        icon = Icons.info;
        break;
    }

    _showOverlaySnackbar(
      title: title,
      message: message,
      backgroundColor: backgroundColor,
      icon: icon,
      duration: duration,
      top: top,
      right: right,
      left: left,
      bottom: bottom,
      maxWidth: maxWidth,
    );
  }

  /// Show snackbar using OverlayEntry - FIXED VERSION
  static void _showOverlaySnackbar({
    required String title,
    required String message,
    required Color backgroundColor,
    required IconData icon,
    required Duration duration,
    required double top,
    required double right,
    double? left,
    double? bottom,
    required double maxWidth,
  }) {
    // Get overlay context
    final overlayContext = Get.overlayContext;
    if (overlayContext == null) {
      return;
    }

    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (BuildContext context) {
        // ✅ SOLUTION 2: Remove Stack completely, use CompositedTransformFollower approach
        // or simple Positioned widget that doesn't block the entire screen
        return Positioned(
          top: top,
          right: right,
          child: Material(
            color: Colors.transparent,
            child: MediaQuery(
              data: MediaQueryData.fromView(View.of(context)),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 500),
                  tween: Tween(begin: 0.0, end: 1.0),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, -20 * (1 - value)),
                      child: Opacity(
                        opacity: value.clamp(0.0, 1.0),
                        child: child,
                      ),
                    );
                  },
                  child: GestureDetector(
                    onHorizontalDragEnd: (details) {
                      if (details.velocity.pixelsPerSecond.dx.abs() > 500) {
                        try {
                          overlayEntry.remove();
                        } catch (e) {
                          // Already removed
                        }
                      }
                    },
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: backgroundColor.withOpacity(0.3),
                              spreadRadius: 2,
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IntrinsicWidth(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                icon,
                                color: Colors.white,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      message,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                        height: 1.4,
                                        decoration: TextDecoration.none,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  try {
                                    overlayEntry.remove();
                                  } catch (e) {
                                    // Already removed
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white70,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    try {
      final overlay = Overlay.of(overlayContext);
      overlay.insert(overlayEntry);
    } catch (e) {
      return;
    }

    // Remove after duration
    Future.delayed(duration, () {
      try {
        overlayEntry.remove();
      } catch (e) {
        // Entry might already be removed
      }
    });
  }

  /// Convenience method for success messages
  static void showSuccess({
    required String title,
    required String message,
    BuildContext? context,
    Duration duration = const Duration(seconds: 4),
    double top = 140,
    double right = 20,
    double? left,
    double? bottom,
    double maxWidth = 400,
  }) {
    show(
      context: context,
      title: title,
      message: message,
      type: SnackbarType.success,
      duration: duration,
      top: top,
      right: right,
      left: left,
      bottom: bottom,
      maxWidth: maxWidth,
    );
  }

  /// Convenience method for error messages
  static void showError({
    required String title,
    required String message,
    BuildContext? context,
    Duration duration = const Duration(seconds: 4),
    double top = 140,
    double right = 20,
    double? left,
    double? bottom,
    double maxWidth = 400,
  }) {
    show(
      context: context,
      title: title,
      message: message,
      type: SnackbarType.error,
      duration: duration,
      top: top,
      right: right,
      left: left,
      bottom: bottom,
      maxWidth: maxWidth,
    );
  }

  /// Convenience method for warning messages
  static void showWarning({
    required String title,
    required String message,
    BuildContext? context,
    Duration duration = const Duration(seconds: 4),
    double top = 140,
    double right = 20,
    double? left,
    double? bottom,
    double maxWidth = 400,
  }) {
    show(
      context: context,
      title: title,
      message: message,
      type: SnackbarType.warning,
      duration: duration,
      top: top,
      right: right,
      left: left,
      bottom: bottom,
      maxWidth: maxWidth,
    );
  }

  /// Convenience method for info messages
  static void showInfo({
    required String title,
    required String message,
    BuildContext? context,
    Duration duration = const Duration(seconds: 4),
    double top = 140,
    double right = 20,
    double? left,
    double? bottom,
    double maxWidth = 400,
  }) {
    show(
      context: context,
      title: title,
      message: message,
      type: SnackbarType.info,
      duration: duration,
      top: top,
      right: right,
      left: left,
      bottom: bottom,
      maxWidth: maxWidth,
    );
  }
}
