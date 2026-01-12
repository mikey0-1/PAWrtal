import 'dart:async';
import 'package:appwrite/appwrite.dart';
import 'package:capstone_app/data/models/notification_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class InAppNotificationService extends GetxService {
  final AuthRepository authRepository;
  final UserSessionService session;

  InAppNotificationService({
    required this.authRepository,
    required this.session,
  });

  // Observable variables
  var notifications = <AppNotification>[].obs;
  var unreadCount = 0.obs;
  var isLoading = false.obs;

  // Track current user to detect account changes
  String _currentUserId = '';

  // Track processed notification IDs to prevent duplicates
  final Set<String> _processedNotificationIds = {};

  // Real-time subscription
  StreamSubscription<RealtimeMessage>? _notificationSubscription;

  @override
  void onInit() {
    super.onInit();
    initialize();
    // Don't auto-initialize - wait for explicit call
  }

  @override
  void onClose() {
    _notificationSubscription?.cancel();
    _processedNotificationIds.clear();
    super.onClose();
  }

  /// Initialize or reinitialize the service for current user
  /// Call this after login or when switching accounts
  Future<void> initialize() async {
    try {
      final userId = session.userId;

      if (userId.isEmpty) {
        _clearService();
        return;
      }

      // If user changed, clear everything and reinitialize
      if (_currentUserId != userId) {
        _clearService();
        _currentUserId = userId;
      }

      // Load initial notifications
      await fetchNotifications();

      // Setup real-time subscription
      _setupRealtimeSubscription();
    } catch (e) {}
  }

  /// Clear all service data (for logout or account switch)
  void _clearService() {
    // Cancel subscription
    _notificationSubscription?.cancel();
    _notificationSubscription = null;

    // Clear data
    notifications.clear();
    unreadCount.value = 0;
    _processedNotificationIds.clear();
    _currentUserId = '';
  }

  /// Public method to clear service (call on logout)
  void clearOnLogout() {
    _clearService();
  }

  void _setupRealtimeSubscription() {
    try {
      final userId = session.userId;
      if (userId.isEmpty) return;

      // Cancel existing subscription if any
      _notificationSubscription?.cancel();

      _notificationSubscription =
          authRepository.subscribeToUserNotifications(userId).listen(
        (message) {
          _handleRealtimeUpdate(message);
        },
        onError: (error) {},
        cancelOnError: false,
      );
    } catch (e) {}
  }

  void _handleRealtimeUpdate(RealtimeMessage message) {
    try {
      final payload = message.payload;
      final notificationId = payload['\$id'] as String?;

      // CRITICAL FIX: Check if we already processed this notification
      if (message.events.any((e) => e.contains('.create')) &&
          _processedNotificationIds.contains(notificationId)) {
        return;
      }

      final notification = AppNotification.fromMap(payload);

      // Verify this notification is for current user
      if (notification.userId != _currentUserId) {
        return;
      }

      for (String event in message.events) {
        if (event.contains('.create')) {
          _handleNewNotification(notification);
        } else if (event.contains('.update')) {
          _handleUpdatedNotification(notification);
        } else if (event.contains('.delete')) {
          _handleDeletedNotification(notification);
        }
      }
    } catch (e) {}
  }

  void _handleNewNotification(AppNotification notification) {
    // CRITICAL FIX: Mark as processed to prevent duplicates
    if (notification.documentId != null) {
      _processedNotificationIds.add(notification.documentId!);
    }

    // Check if notification already exists (prevent duplicates)
    final exists =
        notifications.any((n) => n.documentId == notification.documentId);
    if (exists) {
      return;
    }

    // Add to list (insert at beginning)
    notifications.insert(0, notification);

    // Update unread count
    if (notification.isUnread) {
      unreadCount.value++;
    }

    // Show in-app notification banner
    _showNotificationBanner(notification);
  }

  void _handleUpdatedNotification(AppNotification notification) {
    final index = notifications.indexWhere(
      (n) => n.documentId == notification.documentId,
    );

    if (index != -1) {
      final oldNotification = notifications[index];
      notifications[index] = notification;

      // Update unread count if read status changed
      if (oldNotification.isUnread && notification.isRead) {
        unreadCount.value = (unreadCount.value - 1).clamp(0, 999);
      } else if (oldNotification.isRead && notification.isUnread) {
        unreadCount.value++;
      }
    }

    notifications.refresh();
  }

  void _handleDeletedNotification(AppNotification notification) {
    final wasUnread = notification.isUnread;
    notifications.removeWhere((n) => n.documentId == notification.documentId);

    if (wasUnread) {
      unreadCount.value = (unreadCount.value - 1).clamp(0, 999);
    }

    // Remove from processed IDs
    if (notification.documentId != null) {
      _processedNotificationIds.remove(notification.documentId!);
    }
  }

  void _showNotificationBanner(AppNotification notification) {
    // Only show banner if Get context is available
    if (!Get.isRegistered<GetMaterialController>()) {
      return;
    }

    final overlayContext = Get.overlayContext;
    if (overlayContext == null) {
      return;
    }

    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (BuildContext context) {
        // Get screen width to adjust positioning
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 600;

        return Positioned(
          top: isMobile ? 60 : 80,
          right: isMobile ? 12 : 20,
          left: isMobile ? 12 : null,
          child: Material(
            color: Colors.transparent,
            child: MediaQuery(
              data: MediaQueryData.fromView(View.of(context)),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 400),
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
                    onTap: () {
                      try {
                        overlayEntry.remove();
                      } catch (e) {
                        // Already removed
                      }
                      handleNotificationTap(notification);
                    },
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
                      constraints: BoxConstraints(
                        maxWidth: isMobile ? double.infinity : 380,
                      ),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 14 : 16,
                          vertical: isMobile ? 12 : 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3B82F6).withOpacity(0.3),
                              spreadRadius: 1,
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Icon
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getNotificationIcon(notification.type),
                                color: Colors.white,
                                size: isMobile ? 20 : 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    notification.title,
                                    style: TextStyle(
                                      fontSize: isMobile ? 14 : 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      decoration: TextDecoration.none,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    notification.message,
                                    style: TextStyle(
                                      fontSize: isMobile ? 12 : 13,
                                      color: Colors.white.withOpacity(0.95),
                                      height: 1.3,
                                      decoration: TextDecoration.none,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Close button
                            GestureDetector(
                              onTap: () {
                                try {
                                  overlayEntry.remove();
                                } catch (e) {
                                  // Already removed
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: Colors.white.withOpacity(0.9),
                                  size: isMobile ? 16 : 18,
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
        );
      },
    );

    try {
      final overlay = Overlay.of(overlayContext);
      overlay.insert(overlayEntry);
    } catch (e) {
      return;
    }

    // Auto-remove after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      try {
        overlayEntry.remove();
      } catch (e) {
        // Entry might already be removed
      }
    });
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.appointmentBooked:
        return Icons.calendar_today;
      case NotificationType.appointmentAccepted:
        return Icons.check_circle;
      case NotificationType.appointmentDeclined:
        return Icons.cancel;
      case NotificationType.appointmentCancelled:
        return Icons.event_busy;
      case NotificationType.appointmentCompleted:
        return Icons.done_all;
      case NotificationType.appointmentReminder:
        return Icons.alarm;
      case NotificationType.message:
        return Icons.message;
      case NotificationType.deletionRequestApproved:
        return Icons.check_circle_outline;
      case NotificationType.deletionRequestRejected:
        return Icons.cancel_outlined;
      default:
        return Icons.notifications;
    }
  }

  // Public methods

  /// Fetch all notifications for current user
  Future<void> fetchNotifications() async {
    try {
      isLoading.value = true;
      final userId = session.userId;

      if (userId.isEmpty) {
        _clearService();
        return;
      }

      // Verify we're fetching for the correct user
      if (_currentUserId.isNotEmpty && _currentUserId != userId) {
        await initialize();
        return;
      }

      final docs = await authRepository.getUserNotifications(userId);

      // Clear existing data first
      notifications.clear();
      _processedNotificationIds.clear();

      // Add fetched notifications
      final fetchedNotifications = docs.map((doc) {
        final notification = AppNotification.fromMap(doc.data);
        // Track all fetched notifications to prevent duplicates
        if (notification.documentId != null) {
          _processedNotificationIds.add(notification.documentId!);
        }
        return notification;
      }).toList();

      notifications.assignAll(fetchedNotifications);

      // Update unread count
      unreadCount.value = notifications.where((n) => n.isUnread).length;
    } catch (e) {
    } finally {
      isLoading.value = false;
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await authRepository.markNotificationAsRead(notificationId);
    } catch (e) {}
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final userId = session.userId;
      if (userId.isEmpty) return;

      await authRepository.markAllNotificationsAsRead(userId);
    } catch (e) {}
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await authRepository.deleteNotification(notificationId);
    } catch (e) {}
  }

  /// Delete all notifications
  Future<void> deleteAll() async {
    try {
      final userId = session.userId;
      if (userId.isEmpty) return;

      await authRepository.deleteAllNotifications(userId);
    } catch (e) {}
  }

  /// Handle notification tap - FIXED: No navigation, just mark as read
  void handleNotificationTap(AppNotification notification) {
    // Mark as read
    if (notification.isUnread && notification.documentId != null) {
      markAsRead(notification.documentId!);
    }

    // REMOVED: Navigation code
    // You can add custom logic here if needed without navigation
  }

  // Getters
  List<AppNotification> get unreadNotifications {
    return notifications.where((n) => n.isUnread).toList();
  }

  List<AppNotification> get todayNotifications {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    return notifications.where((n) {
      return n.createdAt.isAfter(startOfDay);
    }).toList();
  }

  bool get hasUnread => unreadCount.value > 0;
}
