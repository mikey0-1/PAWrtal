import 'package:intl/intl.dart';

class Message {
  final String? documentId;
  final String conversationId;
  final String senderId;
  final String messageText;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isRead;
  final bool isStarterMessage;
  final String? attachment;
  final DateTime? sentAt;
  final String? receiverId; // REQUIRED in Appwrite

  Message({
    this.documentId,
    required this.conversationId,
    required this.senderId,
    required this.messageText,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isRead = false,
    this.isStarterMessage = false,
    this.attachment,
    this.sentAt,
    this.receiverId,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Factory constructor to create Message from Firestore/Appwrite document
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      documentId: map['\$id'] ?? map['documentId'],
      conversationId: map['conversationId'] ?? '',
      senderId: map['senderId'] ?? '',
      messageText: map['messageText'] ?? map['message'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : (map['timestamp'] != null
              ? DateTime.parse(map['timestamp'] as String)
              : DateTime.now()),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : (map['\$updatedAt'] != null
              ? DateTime.parse(map['\$updatedAt'] as String)
              : DateTime.now()),
      isRead: map['isRead'] ?? false,
      isStarterMessage: map['isStarterMessage'] ?? false,
      attachment: map['attachment'] ?? map['attachmentUrl'],
      sentAt: map['sentAt'] != null
          ? DateTime.parse(map['sentAt'] as String)
          : null,
      receiverId: map['receiverId'],
    );
  }

  /// Convert Message to Map for storing in database
  Map<String, dynamic> toMap() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'messageText': messageText,
      'isRead': isRead,
      'isStarterMessage': isStarterMessage,
      'timestamp': createdAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (sentAt != null) 'sentAt': sentAt!.toIso8601String(),
      if (receiverId != null) 'receiverId': receiverId,
      if (attachment != null) 'attachment': attachment,
      if (attachment != null) 'attachmentUrl': attachment,
    };
  }

  /// Copy constructor for creating modified copies
  Message copyWith({
    String? documentId,
    String? conversationId,
    String? senderId,
    String? messageText,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isRead,
    bool? isStarterMessage,
    String? attachment,
    DateTime? sentAt,
    String? receiverId,
  }) {
    return Message(
      documentId: documentId ?? this.documentId,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      messageText: messageText ?? this.messageText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isRead: isRead ?? this.isRead,
      isStarterMessage: isStarterMessage ?? this.isStarterMessage,
      attachment: attachment ?? this.attachment,
      sentAt: sentAt ?? this.sentAt,
      receiverId: receiverId ?? this.receiverId,
    );
  }

  // ============================================
  // TIMESTAMP HELPER - Use sentAt if available, otherwise createdAt
  // ============================================

  /// Get the actual message timestamp (sentAt or fallback to createdAt)
  DateTime get messageTimestamp => sentAt ?? createdAt;

  // ============================================
  // TIMESTAMP FORMATTING PROPERTIES
  // ============================================

  /// Simple time format: "02:30 PM"
  String get timeFormatted {
    try {
      final now = DateTime.now();
      final msgTime = messageTimestamp;

      // Check if message is from today
      final isToday = now.year == msgTime.year &&
          now.month == msgTime.month &&
          now.day == msgTime.day;

      if (isToday) {
        // If today, show only time (e.g., "02:30 PM")
        return DateFormat('hh:mm a').format(msgTime);
      }

      // Check if message is from yesterday
      final yesterday = now.subtract(const Duration(days: 1));
      final isYesterday = yesterday.year == msgTime.year &&
          yesterday.month == msgTime.month &&
          yesterday.day == msgTime.day;

      if (isYesterday) {
        // If yesterday, show "Yesterday" and time (e.g., "Yesterday, 02:30 PM")
        return 'Yesterday, ${DateFormat('hh:mm a').format(msgTime)}';
      }

      // Check if message is from this week (last 7 days)
      final difference = now.difference(msgTime);
      if (difference.inDays < 7) {
        // Show day name and time (e.g., "Monday, 02:30 PM")
        return DateFormat('EEEE, hh:mm a').format(msgTime);
      }

      // Check if message is from this year
      if (msgTime.year == now.year) {
        // Show month, day and time (e.g., "Jan 15, 02:30 PM")
        return DateFormat('MMM dd, hh:mm a').format(msgTime);
      }

      // If older than this year, show full date and time (e.g., "Jan 15, 2024, 02:30 PM")
      return DateFormat('MMM dd, yyyy, hh:mm a').format(msgTime);
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Detailed time with date: "Jan 15, 02:30 PM"
  String get detailedTimeFormatted {
    // Use the same logic as timeFormatted for consistency
    return timeFormatted;
  }

  String get compactTimeFormatted {
    try {
      final now = DateTime.now();
      final msgTime = messageTimestamp;

      // Check if message is from today
      final isToday = now.year == msgTime.year &&
          now.month == msgTime.month &&
          now.day == msgTime.day;

      if (isToday) {
        // If today, show only time (e.g., "2:30 PM")
        return DateFormat('h:mm a').format(msgTime);
      }

      // Check if message is from yesterday
      final yesterday = now.subtract(const Duration(days: 1));
      final isYesterday = yesterday.year == msgTime.year &&
          yesterday.month == msgTime.month &&
          yesterday.day == msgTime.day;

      if (isYesterday) {
        // If yesterday, show "Yesterday"
        return 'Yesterday';
      }

      // Check if message is from this week (last 7 days)
      final difference = now.difference(msgTime);
      if (difference.inDays < 7) {
        // Show day name (e.g., "Monday")
        return DateFormat('EEEE').format(msgTime);
      }

      // Check if message is from this year
      if (msgTime.year == now.year) {
        // Show month and day (e.g., "Jan 15")
        return DateFormat('MMM dd').format(msgTime);
      }

      // If older than this year, show date with year (e.g., "Jan 15, 2024")
      return DateFormat('MMM dd, yyyy').format(msgTime);
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Real-time relative time: "5m ago", "2h ago", etc.
  /// This updates dynamically based on current time
  String get relativeTime {
    try {
      final now = DateTime.now();
      final msgTime = messageTimestamp;
      final difference = now.difference(msgTime);

      if (difference.inSeconds < 60) {
        return 'now';
      } else if (difference.inMinutes < 60) {
        final minutes = difference.inMinutes;
        return minutes == 1 ? '1m ago' : '${minutes}m ago';
      } else if (difference.inHours < 24) {
        final hours = difference.inHours;
        return hours == 1 ? '1h ago' : '${hours}h ago';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        final days = difference.inDays;
        return '${days}d ago';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return weeks == 1 ? '1w ago' : '${weeks}w ago';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return months == 1 ? '1 month ago' : '${months} months ago';
      } else {
        final years = (difference.inDays / 365).floor();
        return years == 1 ? '1 year ago' : '${years} years ago';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Full date and time: "Monday, January 15, 2024 at 02:30 PM"
  String get fullDateTime {
    try {
      return DateFormat('EEEE, MMMM dd, yyyy \'at\' hh:mm a')
          .format(messageTimestamp);
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Short date format: "Jan 15"
  String get shortDate {
    try {
      return DateFormat('MMM dd').format(messageTimestamp);
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Check if message was sent today
  bool get isSentToday {
    final now = DateTime.now();
    final msgTime = messageTimestamp;
    return msgTime.year == now.year &&
        msgTime.month == now.month &&
        msgTime.day == now.day;
  }

  /// Check if message was sent yesterday
  bool get isSentYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final msgTime = messageTimestamp;
    return msgTime.year == yesterday.year &&
        msgTime.month == yesterday.month &&
        msgTime.day == yesterday.day;
  }

  bool get isSentThisWeek {
    final now = DateTime.now();
    final msgTime = messageTimestamp;
    final difference = now.difference(msgTime);
    return difference.inDays < 7;
  }

  /// Check if message is recent (within last hour)
  bool get isRecent {
    return DateTime.now().difference(messageTimestamp).inMinutes < 60;
  }

  /// Check if message is old (older than 7 days)
  bool get isOld {
    return DateTime.now().difference(messageTimestamp).inDays >= 7;
  }

  String get dateSeparator {
    try {
      final now = DateTime.now();
      final msgTime = messageTimestamp;

      if (isSentToday) {
        return 'Today';
      }

      if (isSentYesterday) {
        return 'Yesterday';
      }

      if (isSentThisWeek) {
        return DateFormat('EEEE').format(msgTime); // "Monday", "Tuesday", etc.
      }

      if (msgTime.year == now.year) {
        return DateFormat('MMMM dd').format(msgTime); // "January 15"
      }

      return DateFormat('MMMM dd, yyyy').format(msgTime); // "January 15, 2024"
    } catch (e) {
      return '';
    }
  }

  String get conversationListTime {
    try {
      final now = DateTime.now();
      final msgTime = messageTimestamp;

      // Check if message is from today
      final isToday = now.year == msgTime.year &&
          now.month == msgTime.month &&
          now.day == msgTime.day;

      if (isToday) {
        // If today, show only time (e.g., "2:30 PM")
        return DateFormat('h:mm a').format(msgTime);
      }

      // Check if message is from yesterday
      final yesterday = now.subtract(const Duration(days: 1));
      final isYesterday = yesterday.year == msgTime.year &&
          yesterday.month == msgTime.month &&
          yesterday.day == msgTime.day;

      if (isYesterday) {
        return 'Yesterday';
      }

      // Check if message is from this week (last 7 days)
      final difference = now.difference(msgTime);
      if (difference.inDays < 7) {
        // Show abbreviated day name (e.g., "Mon", "Tue")
        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return days[msgTime.weekday - 1];
      }

      // Show date (e.g., "1/15" for this year, "1/15/24" for other years)
      if (msgTime.year == now.year) {
        return DateFormat('M/d').format(msgTime);
      }

      return DateFormat('M/d/yy').format(msgTime);
    } catch (e) {
      return '';
    }
  }

  // ============================================
  // UTILITY METHODS
  // ============================================

  /// Get display text with truncation option
  String getDisplayText({int maxLength = 100}) {
    if (messageText.length <= maxLength) {
      return messageText;
    }
    return '${messageText.substring(0, maxLength)}...';
  }

  /// Check if message contains specific text (case-insensitive)
  bool containsText(String searchText) {
    return messageText.toLowerCase().contains(searchText.toLowerCase());
  }

  /// Get a preview of the message for notifications
  String getPreview({int maxLength = 50}) {
    final text = messageText.replaceAll('\n', ' ').trim();
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}...';
  }

  /// Check if message is from current user
  bool isFromUser(String userId) {
    return senderId == userId;
  }

  @override
  String toString() =>
      'Message(id: $documentId, from: $senderId, text: ${getPreview()}, sent: $timeFormatted)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Message &&
          runtimeType == other.runtimeType &&
          documentId == other.documentId &&
          conversationId == other.conversationId &&
          senderId == other.senderId;

  @override
  int get hashCode =>
      documentId.hashCode ^ conversationId.hashCode ^ senderId.hashCode;
}
