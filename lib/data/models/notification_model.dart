import 'dart:convert';

enum NotificationType {
  appointmentBooked, // Admin receives when user books
  appointmentAccepted, // User receives when admin accepts
  appointmentDeclined, // User receives when admin declines
  appointmentCancelled, // Admin receives when user cancels
  appointmentCompleted, // User receives when service is done
  appointmentReminder, // User receives reminder before appointment
  message, // For future message notifications
  deletionRequestApproved, // Admin receives when deletion approved
  deletionRequestRejected, // Admin receives when deletion rejected
  general, // General system notifications
}

enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
}

class AppNotification {
  String? documentId;
  final String userId; // Who receives this notification
  final String title;
  final String message;
  final NotificationType type;
  final NotificationPriority priority;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  // Related data for navigation
  final String? appointmentId;
  final String? clinicId;
  final String? petId;
  final String? senderId; // Who triggered this notification
  final Map<String, dynamic>? metadata; // Additional data

  // For display
  final String? imageUrl;
  final String? actionUrl; // Where to navigate when tapped

  AppNotification({
    this.documentId,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.priority = NotificationPriority.normal,
    this.isRead = false,
    DateTime? createdAt,
    this.readAt,
    this.appointmentId,
    this.clinicId,
    this.petId,
    this.senderId,
    this.metadata,
    this.imageUrl,
    this.actionUrl,
  }) : createdAt = createdAt ?? DateTime.now();

  // Create from Appwrite document
  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      documentId: map['\$id'],
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: _parseNotificationType(map['type']),
      priority: _parseNotificationPriority(map['priority']),
      isRead: map['isRead'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      readAt: map['readAt'] != null ? DateTime.parse(map['readAt']) : null,
      appointmentId: map['appointmentId'],
      clinicId: map['clinicId'],
      petId: map['petId'],
      senderId: map['senderId'],
      metadata: map['metadata'] != null
          ? (map['metadata'] is String
              ? jsonDecode(map['metadata'])
              : Map<String, dynamic>.from(map['metadata']))
          : null,
      imageUrl: map['imageUrl'],
      actionUrl: map['actionUrl'],
    );
  }

  // Convert to map for Appwrite
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type.name,
      'priority': priority.name,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'appointmentId': appointmentId,
      'clinicId': clinicId,
      'petId': petId,
      'senderId': senderId,
      'metadata': metadata != null ? jsonEncode(metadata) : null,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
    };
  }

  // Helper to parse notification type from string
  static NotificationType _parseNotificationType(String? typeString) {
    if (typeString == null) return NotificationType.general;
    try {
      return NotificationType.values.firstWhere(
        (e) => e.name == typeString,
        orElse: () => NotificationType.general,
      );
    } catch (e) {
      return NotificationType.general;
    }
  }

  // Helper to parse priority from string
  static NotificationPriority _parseNotificationPriority(
      String? priorityString) {
    if (priorityString == null) return NotificationPriority.normal;
    try {
      return NotificationPriority.values.firstWhere(
        (e) => e.name == priorityString,
        orElse: () => NotificationPriority.normal,
      );
    } catch (e) {
      return NotificationPriority.normal;
    }
  }

  // Copy with method for updates
  AppNotification copyWith({
    String? documentId,
    String? userId,
    String? title,
    String? message,
    NotificationType? type,
    NotificationPriority? priority,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
    String? appointmentId,
    String? clinicId,
    String? petId,
    String? senderId,
    Map<String, dynamic>? metadata,
    String? imageUrl,
    String? actionUrl,
  }) {
    return AppNotification(
      documentId: documentId ?? this.documentId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      appointmentId: appointmentId ?? this.appointmentId,
      clinicId: clinicId ?? this.clinicId,
      petId: petId ?? this.petId,
      senderId: senderId ?? this.senderId,
      metadata: metadata ?? this.metadata,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
    );
  }

  // Helper getters
  bool get isUnread => !isRead;

  String get timeAgo {
    final difference = DateTime.now().difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  String get priorityLabel {
    switch (priority) {
      case NotificationPriority.low:
        return 'Low';
      case NotificationPriority.normal:
        return 'Normal';
      case NotificationPriority.high:
        return 'High';
      case NotificationPriority.urgent:
        return 'Urgent';
    }
  }

  // Factory methods for common notification types

  /// User booked an appointment (admin receives)
  factory AppNotification.appointmentBooked({
    required String adminId,
    required String appointmentId,
    required String clinicId,
    required String petName,
    required String ownerName,
    required String service,
    required DateTime appointmentDateTime,
  }) {
    return AppNotification(
      userId: adminId,
      title: 'New Appointment Request',
      message: '$ownerName booked $service for $petName',
      type: NotificationType.appointmentBooked,
      priority: NotificationPriority.high,
      appointmentId: appointmentId,
      clinicId: clinicId,
      metadata: {
        'petName': petName,
        'ownerName': ownerName,
        'service': service,
        'appointmentDateTime': appointmentDateTime.toIso8601String(),
      },
    );
  }

  /// Appointment accepted (user receives)
  factory AppNotification.appointmentAccepted({
    required String userId,
    required String appointmentId,
    required String clinicId,
    required String clinicName,
    required String petName,
    required String service,
    required DateTime appointmentDateTime,
  }) {
    return AppNotification(
      userId: userId,
      title: 'Appointment Confirmed! 🎉',
      message: 'Your appointment for $petName at $clinicName has been accepted',
      type: NotificationType.appointmentAccepted,
      priority: NotificationPriority.high,
      appointmentId: appointmentId,
      clinicId: clinicId,
      metadata: {
        'clinicName': clinicName,
        'petName': petName,
        'service': service,
        'appointmentDateTime': appointmentDateTime.toIso8601String(),
      },
    );
  }

  /// Appointment declined (user receives)
  factory AppNotification.appointmentDeclined({
    required String userId,
    required String appointmentId,
    required String clinicId,
    required String clinicName,
    required String petName,
    String? declineReason,
  }) {
    final reasonText = declineReason != null && declineReason.isNotEmpty
        ? ': $declineReason'
        : '';

    return AppNotification(
      userId: userId,
      title: 'Appointment Declined',
      message:
          'Your appointment for $petName at $clinicName was declined$reasonText',
      type: NotificationType.appointmentDeclined,
      priority: NotificationPriority.normal,
      appointmentId: appointmentId,
      clinicId: clinicId,
      metadata: {
        'clinicName': clinicName,
        'petName': petName,
        'declineReason': declineReason,
      },
    );
  }

  /// Appointment cancelled by user (admin receives)
  factory AppNotification.appointmentCancelled({
    required String adminId,
    required String appointmentId,
    required String clinicId,
    required String petName,
    required String ownerName,
    String? cancellationReason,
  }) {
    final reasonText =
        cancellationReason != null && cancellationReason.isNotEmpty
            ? ': $cancellationReason'
            : '';

    return AppNotification(
      userId: adminId,
      title: 'Appointment Cancelled',
      message: '$ownerName cancelled appointment for $petName$reasonText',
      type: NotificationType.appointmentCancelled,
      priority: NotificationPriority.normal,
      appointmentId: appointmentId,
      clinicId: clinicId,
      metadata: {
        'petName': petName,
        'ownerName': ownerName,
        'cancellationReason': cancellationReason,
      },
    );
  }

  /// Appointment completed (user receives)
  factory AppNotification.appointmentCompleted({
    required String userId,
    required String appointmentId,
    required String clinicId,
    required String clinicName,
    required String petName,
  }) {
    return AppNotification(
      userId: userId,
      title: 'Service Completed ✓',
      message: '$petName\'s appointment at $clinicName is complete',
      type: NotificationType.appointmentCompleted,
      priority: NotificationPriority.normal,
      appointmentId: appointmentId,
      clinicId: clinicId,
      metadata: {
        'clinicName': clinicName,
        'petName': petName,
      },
    );
  }

  factory AppNotification.appointmentReminder({
    required String userId,
    required String appointmentId,
    required String clinicId,
    required String clinicName,
    required String petName,
    required String service,
    required DateTime appointmentDateTime,
    required int minutesUntil,
  }) {
    String timeMessage;
    if (minutesUntil < 60) {
      timeMessage = 'in $minutesUntil minutes';
    } else {
      final hours = (minutesUntil / 60).floor();
      timeMessage = 'in $hours hour${hours > 1 ? 's' : ''}';
    }

    return AppNotification(
      userId: userId,
      title: '⏰ Appointment Reminder',
      message:
          '$petName\'s appointment at $clinicName is coming up $timeMessage!',
      type: NotificationType.appointmentReminder,
      priority: NotificationPriority.high,
      appointmentId: appointmentId,
      clinicId: clinicId,
      metadata: {
        'petName': petName,
        'clinicName': clinicName,
        'service': service,
        'appointmentDateTime': appointmentDateTime.toIso8601String(),
        'minutesUntil': minutesUntil.toString(),
      },
    );
  }
}
