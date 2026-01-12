class Conversation {
  final String? documentId;
  final String userId;
  final String clinicId;
  final String? lastMessageId;
  final String? lastMessageText;
  final DateTime? lastMessageTime;
  final int unreadCount; // Keep for backward compatibility
  final int userUnreadCount; // New field for user's unread count
  final int clinicUnreadCount; // New field for clinic's unread count
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Conversation({
    this.documentId,
    required this.userId,
    required this.clinicId,
    this.lastMessageId,
    this.lastMessageText,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.userUnreadCount = 0,
    this.clinicUnreadCount = 0,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Conversation.fromMap(Map<String, dynamic> map) {
    return Conversation(
      documentId: map['\$id'],
      userId: map['userId'] ?? '',
      clinicId: map['clinicId'] ?? '',
      lastMessageId: map['lastMessageId'],
      lastMessageText: map['lastMessageText'],
      lastMessageTime: map['lastMessageTime'] != null
          ? DateTime.parse(map['lastMessageTime'])
          : null,
      unreadCount: map['unreadCount'] ?? 0,
      userUnreadCount: map['userUnreadCount'] ?? 0,
      clinicUnreadCount: map['clinicUnreadCount'] ?? 0,
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'clinicId': clinicId,
      'lastMessageId': lastMessageId,
      'lastMessageText': lastMessageText,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'unreadCount': unreadCount,
      'userUnreadCount': userUnreadCount,
      'clinicUnreadCount': clinicUnreadCount,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Conversation copyWith({
    String? documentId,
    String? userId,
    String? clinicId,
    String? lastMessageId,
    String? lastMessageText,
    DateTime? lastMessageTime,
    int? unreadCount,
    int? userUnreadCount,
    int? clinicUnreadCount,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Conversation(
      documentId: documentId ?? this.documentId,
      userId: userId ?? this.userId,
      clinicId: clinicId ?? this.clinicId,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastMessageText: lastMessageText ?? this.lastMessageText,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      userUnreadCount: userUnreadCount ?? this.userUnreadCount,
      clinicUnreadCount: clinicUnreadCount ?? this.clinicUnreadCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  bool get hasMessages => lastMessageId != null;

  String get conversationPreview {
    if (lastMessageText != null && lastMessageText!.isNotEmpty) {
      return lastMessageText!.length > 50
          ? '${lastMessageText!.substring(0, 50)}...'
          : lastMessageText!;
    }
    return 'No messages yet';
  }

  String get timeAgo {
    if (lastMessageTime == null) return '';

    final now = DateTime.now();
    final msgTime = lastMessageTime!;

    // Format time in 12-hour format with AM/PM
    final hour = msgTime.hour == 0
        ? 12
        : msgTime.hour > 12
            ? msgTime.hour - 12
            : msgTime.hour;
    final minute = msgTime.minute.toString().padLeft(2, '0');
    final period = msgTime.hour >= 12 ? 'PM' : 'AM';
    final timeStr = '$hour:$minute $period';

    // If message is from today, show time only
    if (msgTime.year == now.year &&
        msgTime.month == now.month &&
        msgTime.day == now.day) {
      return timeStr;
    }

    // If message is from yesterday, show "Yesterday" with time
    final yesterday = now.subtract(const Duration(days: 1));
    if (msgTime.year == yesterday.year &&
        msgTime.month == yesterday.month &&
        msgTime.day == yesterday.day) {
      return 'Yesterday';
    }

    // If message is from this week (last 7 days), show day name
    final difference = now.difference(msgTime);
    if (difference.inDays < 7) {
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[msgTime.weekday - 1];
    }

    // If message is older, show date
    return '${msgTime.month}/${msgTime.day}/${msgTime.year.toString().substring(2)}';
  }

  // Get unread count for specific user type
  int getUnreadCountForUser(String currentUserId, String currentUserType) {
    if (currentUserType == 'admin' || currentUserId == clinicId) {
      return clinicUnreadCount;
    } else {
      return userUnreadCount;
    }
  }

  // Check if conversation has unread messages for specific user
  bool hasUnreadMessagesForUser(String currentUserId, String currentUserType) {
    return getUnreadCountForUser(currentUserId, currentUserType) > 0;
  }
}
