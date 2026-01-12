import 'dart:convert';

/// Model for archived clinics (30-day soft delete)
class ArchivedClinic {
  String? documentId;
  final String clinicName;
  final String email;
  final String address;
  final String contact;
  final String adminId;
  final String originalDocumentId;
  final String archivedBy; 
  final DateTime archivedAt;
  final DateTime scheduledDeletionAt;
  final String archiveReason;
  final bool isPermanentlyDeleted;
  final String originalClinicData; // JSON string of complete clinic data
  final bool isRecovered;
  final DateTime? recoveredAt;
  final String? recoveredBy;
  final DateTime? permanentlyDeletedAt;

  ArchivedClinic({
    this.documentId,
    required this.clinicName,
    required this.email,
    required this.address,
    required this.contact,
    required this.adminId,
    required this.originalDocumentId,
    required this.archivedBy,
    required this.archivedAt,
    required this.scheduledDeletionAt,
    this.archiveReason = 'No reason provided',
    this.isPermanentlyDeleted = false,
    required this.originalClinicData,
    this.isRecovered = false,
    this.recoveredAt,
    this.recoveredBy,
    this.permanentlyDeletedAt,
  });

  /// Create from Appwrite document
  factory ArchivedClinic.fromMap(Map<String, dynamic> map) {
    return ArchivedClinic(
      documentId: map['\$id'],
      clinicName: map['clinicName'] ?? '',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      contact: map['contact'] ?? '',
      adminId: map['adminId'] ?? '',
      originalDocumentId: map['originalDocumentId'] ?? '',
      archivedBy: map['archivedBy'] ?? '',
      archivedAt: DateTime.parse(map['archivedAt']),
      scheduledDeletionAt: DateTime.parse(map['scheduledDeletionAt']),
      archiveReason: map['archiveReason'] ?? 'No reason provided',
      isPermanentlyDeleted: map['isPermanentlyDeleted'] ?? false,
      originalClinicData: map['originalClinicData'] ?? '{}',
      isRecovered: map['isRecovered'] ?? false,
      recoveredAt: map['recoveredAt'] != null
          ? DateTime.parse(map['recoveredAt'])
          : null,
      recoveredBy: map['recoveredBy'],
      permanentlyDeletedAt: map['permanentlyDeletedAt'] != null
          ? DateTime.parse(map['permanentlyDeletedAt'])
          : null,
    );
  }

  /// Convert to Appwrite document
  Map<String, dynamic> toMap() {
    return {
      'clinicName': clinicName,
      'email': email,
      'address': address,
      'contact': contact,
      'adminId': adminId,
      'originalDocumentId': originalDocumentId,
      'archivedBy': archivedBy,
      'archivedAt': archivedAt.toIso8601String(),
      'scheduledDeletionAt': scheduledDeletionAt.toIso8601String(),
      'archiveReason': archiveReason,
      'isPermanentlyDeleted': isPermanentlyDeleted,
      'originalClinicData': originalClinicData,
      'isRecovered': isRecovered,
      'recoveredAt': recoveredAt?.toIso8601String(),
      'recoveredBy': recoveredBy,
      'permanentlyDeletedAt': permanentlyDeletedAt?.toIso8601String(),
    };
  }

  /// Copy with modifications
  ArchivedClinic copyWith({
    String? documentId,
    String? clinicName,
    String? email,
    String? address,
    String? contact,
    String? adminId,
    String? originalDocumentId,
    String? archivedBy,
    DateTime? archivedAt,
    DateTime? scheduledDeletionAt,
    String? archiveReason,
    bool? isPermanentlyDeleted,
    String? originalClinicData,
    bool? isRecovered,
    DateTime? recoveredAt,
    String? recoveredBy,
    DateTime? permanentlyDeletedAt,
  }) {
    return ArchivedClinic(
      documentId: documentId ?? this.documentId,
      clinicName: clinicName ?? this.clinicName,
      email: email ?? this.email,
      address: address ?? this.address,
      contact: contact ?? this.contact,
      adminId: adminId ?? this.adminId,
      originalDocumentId: originalDocumentId ?? this.originalDocumentId,
      archivedBy: archivedBy ?? this.archivedBy,
      archivedAt: archivedAt ?? this.archivedAt,
      scheduledDeletionAt: scheduledDeletionAt ?? this.scheduledDeletionAt,
      archiveReason: archiveReason ?? this.archiveReason,
      isPermanentlyDeleted: isPermanentlyDeleted ?? this.isPermanentlyDeleted,
      originalClinicData: originalClinicData ?? this.originalClinicData,
      isRecovered: isRecovered ?? this.isRecovered,
      recoveredAt: recoveredAt ?? this.recoveredAt,
      recoveredBy: recoveredBy ?? this.recoveredBy,
      permanentlyDeletedAt: permanentlyDeletedAt ?? this.permanentlyDeletedAt,
    );
  }

  /// Days remaining until permanent deletion
  int get daysUntilDeletion {
    if (isPermanentlyDeleted || isRecovered) return 0;
    final now = DateTime.now();
    final difference = scheduledDeletionAt.difference(now);
    return difference.inDays > 0 ? difference.inDays : 0;
  }

  /// Check if deletion is due
  bool get isDeletionDue {
    if (isPermanentlyDeleted || isRecovered) return false;
    return DateTime.now().isAfter(scheduledDeletionAt);
  }

  /// Status text for UI
  String get statusText {
    if (isPermanentlyDeleted) return 'Permanently Deleted';
    if (isRecovered) return 'Recovered';
    if (isDeletionDue) return 'Due for Deletion';

    final days = daysUntilDeletion;
    if (days == 0) return 'Deleting Today';
    if (days == 1) return '1 Day Remaining';
    return '$days Days Remaining';
  }

  /// Parse original clinic data from JSON
  Map<String, dynamic> get parsedOriginalData {
    try {
      return Map<String, dynamic>.from(jsonDecode(originalClinicData));
    } catch (e) {
      return {};
    }
  }
}
