import 'dart:convert';

/// Model for archived users
/// This tracks users who have been soft-deleted and scheduled for permanent deletion
class ArchivedUser {
  String? documentId;
  final String userId;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? profilePictureId; 
  final String? originalDocumentId;
  
  // Archive metadata
  final String archivedBy; // Admin/Developer who archived
  final DateTime archivedAt;
  final DateTime scheduledDeletionAt; // 30 days after archival
  final String archiveReason;
  final bool isPermanentlyDeleted;

  final bool idVerified;
  final String? idVerifiedAt;
  
  // Original user data (stored as JSON for recovery if needed)
  final Map<String, dynamic>? originalUserData;
  
  // Recovery tracking
  final bool isRecovered;
  final DateTime? recoveredAt;
  final String? recoveredBy;

  ArchivedUser({
    this.documentId,
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.profilePictureId,
    this.originalDocumentId,
    required this.archivedBy,
    DateTime? archivedAt,
    DateTime? scheduledDeletionAt,
    this.archiveReason = 'No reason provided',
    this.isPermanentlyDeleted = false,
    this.idVerified = false,
    this.idVerifiedAt,
    this.originalUserData,
    this.isRecovered = false,
    this.recoveredAt,
    this.recoveredBy,

  })  : archivedAt = archivedAt ?? DateTime.now(),
        scheduledDeletionAt = scheduledDeletionAt ?? 
            DateTime.now().add(const Duration(days: 30));

  // Convert from Appwrite document
  factory ArchivedUser.fromMap(Map<String, dynamic> map) {
   // Parse originalUserData from JSON string
Map<String, dynamic> originalData = {};
 try {
      final dataString = map['originalUserData'] as String?;
      if (dataString != null && dataString.isNotEmpty) {
        originalData = Map<String, dynamic>.from(jsonDecode(dataString));
      }
    } catch (e) {
    }

    return ArchivedUser(
      documentId: map['\$id'],
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'user',
      phone: map['phone'],
     profilePictureId: originalData['profilePictureId'] as String?,
      originalDocumentId: map['originalDocumentId'],
      archivedBy: map['archivedBy'] ?? 'system',
      archivedAt: DateTime.parse(map['archivedAt']),
      scheduledDeletionAt: DateTime.parse(map['scheduledDeletionAt']),
      archiveReason: map['archiveReason'] ?? 'No reason provided',
      isPermanentlyDeleted: map['isPermanentlyDeleted'] ?? false,
      originalUserData: originalData,
      isRecovered: map['isRecovered'] ?? false,
      recoveredAt: map['recoveredAt'] != null 
          ? DateTime.parse(map['recoveredAt']) 
          : null,
      recoveredBy: map['recoveredBy'],

      idVerified: originalData['idVerified'] as bool? ?? false,
      idVerifiedAt: originalData['idVerifiedAt'] as String?,
    );
  }

  // Convert to Appwrite document
Map<String, dynamic> toMap() {
  // Convert originalUserData to JSON string if it's a Map
  String? originalUserDataString;
  if (originalUserData != null) {
    try {
      originalUserDataString = jsonEncode(originalUserData);
    } catch (e) {
      originalUserDataString = '{}';
    }
  }

  return {
    'userId': userId,
    'name': name,
    'email': email,
    'role': role,
    'phone': phone ?? '',
    'profilePictureId': profilePictureId ?? '', 
    'originalDocumentId': originalDocumentId,
    'archivedBy': archivedBy,
    'archivedAt': archivedAt.toIso8601String(),
    'scheduledDeletionAt': scheduledDeletionAt.toIso8601String(),
    'archiveReason': archiveReason,
    'isPermanentlyDeleted': isPermanentlyDeleted,
    'originalUserData': originalUserDataString, // STRING, not Map
    'isRecovered': isRecovered,
    'recoveredAt': recoveredAt?.toIso8601String(),
    'recoveredBy': recoveredBy,
  };
}
  // Helper getters
  int get daysUntilDeletion {
    final now = DateTime.now();
    final difference = scheduledDeletionAt.difference(now);
    return difference.inDays;
  }

  bool get isDeletionDue {
    return DateTime.now().isAfter(scheduledDeletionAt) || 
           DateTime.now().isAtSameMomentAs(scheduledDeletionAt);
  }

  String get statusText {
    if (isPermanentlyDeleted) return 'Permanently Deleted';
    if (isRecovered) return 'Recovered';
    if (isDeletionDue) return 'Pending Permanent Deletion';
    return 'Archived (${daysUntilDeletion} days left)';
  }

  ArchivedUser copyWith({
    String? documentId,
    String? userId,
    String? name,
    String? email,
    String? role,
    String? phone,
    String? profilePictureId,
    String? originalDocumentId,
    String? archivedBy,
    DateTime? archivedAt,
    DateTime? scheduledDeletionAt,
    String? archiveReason,
    bool? isPermanentlyDeleted,

    bool? idVerified,
    String? idVerifiedAt,
    
    Map<String, dynamic>? originalUserData,
    bool? isRecovered,
    DateTime? recoveredAt,
    String? recoveredBy,
  }) {
    return ArchivedUser(
      documentId: documentId ?? this.documentId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      profilePictureId: profilePictureId ?? this.profilePictureId, 
      originalDocumentId: originalDocumentId ?? this.originalDocumentId,
      archivedBy: archivedBy ?? this.archivedBy,
      archivedAt: archivedAt ?? this.archivedAt,
      scheduledDeletionAt: scheduledDeletionAt ?? this.scheduledDeletionAt,
      archiveReason: archiveReason ?? this.archiveReason,
      isPermanentlyDeleted: isPermanentlyDeleted ?? this.isPermanentlyDeleted,
      idVerified: idVerified ?? this.idVerified,
      idVerifiedAt: idVerifiedAt ?? this.idVerifiedAt,
      originalUserData: originalUserData ?? this.originalUserData,
      isRecovered: isRecovered ?? this.isRecovered,
      recoveredAt: recoveredAt ?? this.recoveredAt,
      recoveredBy: recoveredBy ?? this.recoveredBy,
    );
  }
}