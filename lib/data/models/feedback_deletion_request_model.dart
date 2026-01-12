import 'dart:convert';

class FeedbackDeletionRequest {
  final String? documentId;
  final String reviewId;
  final String clinicId;
  final String userId;
  final String appointmentId;
  final String requestedBy;
  final String reason;
  final String? additionalDetails;
  final List<String> attachments;
  final String status;
  final DateTime requestedAt;
  final DateTime updatedAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? reviewNotes;
  final bool isPinned;
  final DateTime? pinnedAt;
  final String? pinnedBy;

  FeedbackDeletionRequest({
    this.documentId,
    required this.reviewId,
    required this.clinicId,
    required this.userId,
    required this.appointmentId,
    required this.requestedBy,
    required this.reason,
    this.additionalDetails,
    this.attachments = const [],
    this.status = 'pending',
    DateTime? requestedAt,
    DateTime? updatedAt,
    this.reviewedBy,
    this.reviewedAt,
    this.reviewNotes,
    this.isPinned = false, 
    this.pinnedAt, 
    this.pinnedBy, 
  })  : requestedAt = requestedAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory FeedbackDeletionRequest.fromMap(Map<String, dynamic> map) {
    // CRITICAL FIX: Parse attachments properly
    List<String> parseAttachments(dynamic attachmentsData) {
      if (attachmentsData == null) return [];

      // If it's already a List, convert it
      if (attachmentsData is List) {
        return attachmentsData.map((e) => e.toString()).toList();
      }

      // If it's a String (JSON), parse it
      if (attachmentsData is String) {
        if (attachmentsData.isEmpty || attachmentsData == '[]') {
          return [];
        }
        try {
          final decoded = jsonDecode(attachmentsData);
          if (decoded is List) {
            return decoded.map((e) => e.toString()).toList();
          }
        } catch (e) {
          return [];
        }
      }

      return [];
    }

    return FeedbackDeletionRequest(
      documentId: map['\$id'],
      reviewId: map['reviewId'] ?? '',
      clinicId: map['clinicId'] ?? '',
      userId: map['userId'] ?? '',
      appointmentId: map['appointmentId'] ?? '',
      requestedBy: map['requestedBy'] ?? '',
      reason: map['reason'] ?? '',
      additionalDetails: map['additionalDetails'],
      attachments: parseAttachments(map['attachments']), // USE HELPER FUNCTION
      status: map['status'] ?? 'pending',
      requestedAt: map['requestedAt'] != null
          ? DateTime.parse(map['requestedAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
      reviewedBy: map['reviewedBy'],
      reviewedAt:
          map['reviewedAt'] != null ? DateTime.parse(map['reviewedAt']) : null,
      reviewNotes: map['reviewNotes'],
      isPinned: map['isPinned'] ?? false,
      pinnedAt: map['pinnedAt'] != null ? DateTime.parse(map['pinnedAt']) : null,
      pinnedBy: map['pinnedBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reviewId': reviewId,
      'clinicId': clinicId,
      'userId': userId,
      'appointmentId': appointmentId,
      'requestedBy': requestedBy,
      'reason': reason,
      'additionalDetails': additionalDetails,
      'attachments': jsonEncode(attachments), // ENCODE as JSON string
      'status': status,
      'requestedAt': requestedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt?.toIso8601String(),
      'reviewNotes': reviewNotes,
      'isPinned': isPinned,
      'pinnedAt': pinnedAt?.toIso8601String(),
      'pinnedBy': pinnedBy,
    };
  }

  FeedbackDeletionRequest copyWith({
    String? documentId,
    String? reviewId,
    String? clinicId,
    String? userId,
    String? appointmentId,
    String? requestedBy,
    String? reason,
    String? additionalDetails,
    List<String>? attachments,
    String? status,
    DateTime? requestedAt,
    DateTime? updatedAt,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? reviewNotes,
    bool? isPinned, 
    DateTime? pinnedAt, 
    String? pinnedBy
  }) {
    return FeedbackDeletionRequest(
      documentId: documentId ?? this.documentId,
      reviewId: reviewId ?? this.reviewId,
      clinicId: clinicId ?? this.clinicId,
      userId: userId ?? this.userId,
      appointmentId: appointmentId ?? this.appointmentId,
      requestedBy: requestedBy ?? this.requestedBy,
      reason: reason ?? this.reason,
      additionalDetails: additionalDetails ?? this.additionalDetails,
      attachments: attachments ?? this.attachments,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewNotes: reviewNotes ?? this.reviewNotes,
      isPinned: isPinned ?? this.isPinned, 
      pinnedAt: pinnedAt ?? this.pinnedAt, 
      pinnedBy: pinnedBy ?? this.pinnedBy,
    );
  }

  // Helper getters
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get hasAttachments => attachments.isNotEmpty;
  bool get hasAdditionalDetails =>
      additionalDetails != null && additionalDetails!.isNotEmpty;
}
