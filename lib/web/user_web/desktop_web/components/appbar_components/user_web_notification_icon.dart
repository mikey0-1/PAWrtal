import 'package:capstone_app/data/models/notification_model.dart';
import 'package:capstone_app/notification/services/in_app_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class WebNotificationIcon extends StatefulWidget {
  final double? right;
  final double? top;
  final double? width;

  const WebNotificationIcon({
    super.key,
    this.right = 125,
    this.top = 70,
    this.width = 450,
  });

  @override
  State<WebNotificationIcon> createState() => _WebNotificationIconState();
}

class _WebNotificationIconState extends State<WebNotificationIcon> {
  OverlayEntry? _overlayEntry;
  final InAppNotificationService _notificationService = Get.find();

  @override
  void dispose() {
    _closePopup();
    super.dispose();
  }

  void _togglePopup(BuildContext context) {
    if (_overlayEntry == null) {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
    } else {
      _closePopup();
    }
  }

  void _closePopup() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Backdrop
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closePopup,
              child: Container(color: Colors.transparent),
            ),
          ),
          // Notification Panel
          Positioned(
            right: widget.right,
            top: widget.top,
            width: widget.width,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 600),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, Colors.grey.shade50],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    const Divider(height: 1),
                    _buildNotificationList(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.notifications_rounded,
                color: Color.fromARGB(255, 81, 115, 153),
                size: 24,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Notifications",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Obx(() {
                    final unread = _notificationService.unreadCount.value;
                    if (unread == 0) return const SizedBox.shrink();
                    return Text(
                      '$unread unread',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
          Row(
            children: [
              // Mark all as read button
              Obx(() {
                if (_notificationService.unreadCount.value == 0) {
                  return const SizedBox.shrink();
                }
                return TextButton.icon(
                  onPressed: () async {
                    await _notificationService.markAllAsRead();
                    Get.snackbar(
                      'Success',
                      'All notifications marked as read',
                      snackPosition: SnackPosition.TOP,
                      duration: const Duration(seconds: 2),
                    );
                  },
                  icon: const Icon(Icons.done_all, size: 16),
                  label: const Text('Mark all read'),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                );
              }),
              // Settings button
              IconButton(
                onPressed: () {
                  _showSettingsDialog();
                },
                icon: Icon(Icons.settings_outlined,
                    size: 20, color: Colors.grey[700]),
                tooltip: "Notification Settings",
                padding: const EdgeInsets.all(8),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList() {
    return Flexible(
      child: Obx(() {
        if (_notificationService.isLoading.value) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final notifications = _notificationService.notifications;

        if (notifications.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          shrinkWrap: true,
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return _buildNotificationItem(notification);
          },
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'re all caught up!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(AppNotification notification) {
    return Dismissible(
      key: Key(notification.documentId ?? ''),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red[400],
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Notification'),
            content: const Text(
                'Are you sure you want to delete this notification?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child:
                    const Text('Delete', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        if (notification.documentId != null) {
          _notificationService.deleteNotification(notification.documentId!);
        }
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _closePopup();
            _notificationService.handleNotificationTap(notification);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: notification.isUnread
                  ? const Color.fromARGB(255, 81, 115, 153).withOpacity(0.05)
                  : Colors.transparent,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNotificationIcon(notification),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: notification.isUnread
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          if (notification.isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color.fromARGB(255, 81, 115, 153),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            notification.timeAgo,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                          if (notification.priority ==
                                  NotificationPriority.high ||
                              notification.priority ==
                                  NotificationPriority.urgent) ...[
                            const SizedBox(width: 12),
                            // Container(
                            //   padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            //   decoration: BoxDecoration(
                            //     color: Colors.orange.withOpacity(0.2),
                            //     borderRadius: BorderRadius.circular(4),
                            //   ),
                            //   child: Text(
                            //     notification.priorityLabel,
                            //     style: TextStyle(
                            //       fontSize: 10,
                            //       fontWeight: FontWeight.w600,
                            //       color: Colors.orange[800],
                            //     ),
                            //   ),
                            // ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(AppNotification notification) {
    IconData icon;
    Color color;

    switch (notification.type) {
      case NotificationType.appointmentBooked:
        icon = Icons.calendar_today;
        color = Colors.blue;
        break;
      case NotificationType.appointmentAccepted:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case NotificationType.appointmentDeclined:
        icon = Icons.cancel;
        color = Colors.red;
        break;
      case NotificationType.appointmentCancelled:
        icon = Icons.event_busy;
        color = Colors.orange;
        break;
      case NotificationType.appointmentCompleted:
        icon = Icons.done_all;
        color = Colors.green;
        break;
      case NotificationType.appointmentReminder: // NEW
        icon = Icons.alarm;
        color = const Color.fromARGB(255, 255, 167, 38); // Orange/Amber
        break;
      case NotificationType.message:
        icon = Icons.message;
        color = Colors.purple;
        break;
      default:
        icon = Icons.notifications;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_sweep),
              title: const Text('Clear all notifications'),
              subtitle: const Text('Delete all notifications'),
              onTap: () async {
                Navigator.of(context).pop();

                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear All Notifications'),
                    content: const Text(
                      'Are you sure you want to delete all notifications? This cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        child: const Text('Delete All',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await _notificationService.deleteAll();
                  _closePopup();
                  Get.snackbar(
                    'Success',
                    'All notifications deleted',
                    snackPosition: SnackPosition.TOP,
                    duration: const Duration(seconds: 2),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_rounded),
          onPressed: () => _togglePopup(context),
          tooltip: 'Notifications',
        ),
        // Unread badge
        Obx(() {
          final unreadCount = _notificationService.unreadCount.value;
          if (unreadCount == 0) return const SizedBox.shrink();

          return Positioned(
            right: 4,
            top: 2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 81, 115, 153),
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Center(
                child: Text(
                  unreadCount > 99 ? '99+' : '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
