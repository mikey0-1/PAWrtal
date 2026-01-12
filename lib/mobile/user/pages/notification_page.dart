import 'package:capstone_app/data/models/notification_model.dart';
import 'package:capstone_app/notification/services/in_app_notification_service.dart';
import 'package:capstone_app/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final InAppNotificationService _notificationService = Get.find();

  @override
  void initState() {
    super.initState();
    // Refresh notifications when page opens
    _notificationService.fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 81, 115, 153),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: _buildNotificationList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notifications',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Mark all as read button
            Obx(() {
              if (_notificationService.unreadCount.value == 0) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.done_all, color: Colors.white),
                onPressed: () async {
                  await _notificationService.markAllAsRead();
                  SnackbarHelper.showSuccess(
                    context: Get.context!,
                    title: "Success",
                    message: "All notifications marked as read",
                  );
                  // Get.snackbar(
                  //   'Success',
                  //   'All notifications marked as read',
                  //   snackPosition: SnackPosition.BOTTOM,
                  //   backgroundColor: Colors.green,
                  //   colorText: Colors.white,
                  //   duration: const Duration(seconds: 2),
                  // );
                },
                tooltip: 'Mark all as read',
              );
            }),
            // Settings
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: _showSettingsMenu,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList() {
    return Obx(() {
      if (_notificationService.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final notifications = _notificationService.notifications;

      if (notifications.isEmpty) {
        return _buildEmptyState();
      }

      return RefreshIndicator(
        onRefresh: () => _notificationService.fetchNotifications(),
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 16),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return _buildNotificationCard(notification);
          },
        ),
      );
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'re all caught up!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification notification) {
    return Dismissible(
      key: Key(notification.documentId ?? ''),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red[400],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
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
          Get.snackbar(
            'Deleted',
            'Notification removed',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2),
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        elevation: notification.isUnread ? 2 : 0,
        color: notification.isUnread
            ? const Color.fromARGB(255, 234, 236, 238)
            : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: notification.isUnread
                ? const Color.fromARGB(255, 81, 115, 153).withOpacity(0.05)
                : Colors.grey.shade200,
          ),
        ),
        child: InkWell(
          onTap: () {
            _notificationService.handleNotificationTap(notification);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNotificationIcon(notification),
                const SizedBox(width: 16),
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
                                fontSize: 16,
                                fontWeight: notification.isUnread
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          if (notification.isUnread)
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Color.fromARGB(255, 81, 115, 153),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
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
                            //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            //   decoration: BoxDecoration(
                            //     color: Colors.orange.withOpacity(0.2),
                            //     borderRadius: BorderRadius.circular(6),
                            //   ),
                            //   child: Text(
                            //     notification.priorityLabel,
                            //     style: TextStyle(
                            //       fontSize: 11,
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
      case NotificationType.deletionRequestApproved:
        icon = Icons.check_circle_outline;
        color = Colors.green;
        break;
      case NotificationType.deletionRequestRejected:
        icon = Icons.cancel_outlined;
        color = Colors.red;
        break;
      default:
        icon = Icons.notifications;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 24, color: color),
    );
  }

  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.done_all,
                  color: Color.fromARGB(255, 81, 115, 153)),
              title: const Text('Mark all as read'),
              onTap: () async {
                Navigator.pop(context);
                await _notificationService.markAllAsRead();
                SnackbarHelper.showSuccess(
                  context: Get.context!,
                  title: "Success",
                  message: "All notifications marked as read",
                );
                // Get.snackbar(
                //   'Success',
                //   'All notifications marked as read',
                //   snackPosition: SnackPosition.BOTTOM,
                //   backgroundColor: Colors.green,
                //   colorText: Colors.white,
                //   duration: const Duration(seconds: 2),
                // );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep, color: Colors.red),
              title: const Text('Clear all notifications'),
              onTap: () async {
                Navigator.pop(context);

                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
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
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Delete All',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await _notificationService.deleteAll();
                  SnackbarHelper.showSuccess(
                    context: Get.context!,
                    title: "Success",
                    message: "All notifications deleted",
                  );
                  // Get.snackbar(
                  //   'Success',
                  //   'All notifications deleted',
                  //   snackPosition: SnackPosition.BOTTOM,
                  //   backgroundColor: Colors.green,
                  //   colorText: Colors.white,
                  //   duration: const Duration(seconds: 2),
                  // );
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
