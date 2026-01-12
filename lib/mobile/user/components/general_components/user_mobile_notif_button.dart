import 'package:capstone_app/mobile/user/pages/notification_page.dart';
import 'package:capstone_app/notification/services/in_app_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MyNotifButton extends StatelessWidget {
  const MyNotifButton({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationService = Get.find<InAppNotificationService>();

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Stack(
        children: [
          IconButton(
            icon: const Icon(Icons.notifications_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationPage(),
                ),
              );
            },
          ),
          // Unread badge
          Obx(() {
            final unreadCount = notificationService.unreadCount.value;
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
      ),
    );
  }
}