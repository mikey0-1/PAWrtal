class UserStatus {
  final String? documentId;
  final String userId;
  final bool isOnline;
  final DateTime lastSeen;
  final String status; // 'online', 'offline', 'away'
  final DateTime updatedAt;

  UserStatus({
    this.documentId,
    required this.userId,
    this.isOnline = false,
    DateTime? lastSeen,
    this.status = 'offline',
    DateTime? updatedAt,
  })  : lastSeen = lastSeen ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory UserStatus.fromMap(Map<String, dynamic> map) {
    return UserStatus(
      documentId: map['\$id'],
      userId: map['userId'] ?? '',
      isOnline: map['isOnline'] ?? false,
      lastSeen: DateTime.parse(map['lastSeen']),
      status: map['status'] ?? 'offline',
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'isOnline': isOnline,
      'lastSeen': lastSeen.toIso8601String(),
      'status': status,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  UserStatus copyWith({
    String? documentId,
    String? userId,
    bool? isOnline,
    DateTime? lastSeen,
    String? status,
    DateTime? updatedAt,
  }) {
    return UserStatus(
      documentId: documentId ?? this.documentId,
      userId: userId ?? this.userId,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  String get statusText {
    if (isOnline) return 'Online';
    
    final difference = DateTime.now().difference(lastSeen);
    
    if (difference.inMinutes < 5) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  bool get isRecentlyActive => DateTime.now().difference(lastSeen).inMinutes < 10;
  
  // Factory methods for common states
  factory UserStatus.online(String userId) {
    return UserStatus(
      userId: userId,
      isOnline: true,
      status: 'online',
    );
  }

  factory UserStatus.offline(String userId) {
    return UserStatus(
      userId: userId,
      isOnline: false,
      status: 'offline',
    );
  }
}