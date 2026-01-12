class FeedbackAndReport {
  String? documentId;
  final String userId;
  final String userName;
  final String userEmail;
  final FeedbackType feedbackType;
  final FeedbackCategory category;
  final String subject;
  final String description;
  final List<String> attachments;
  final Priority priority;
  final FeedbackStatus status;
  final String appVersion;
  final bool isPinned; 
  final DateTime? pinnedAt; 
  final String? pinnedBy; 
  final bool isArchived;
  final String deviceInfo;
  final String platform;
  final DateTime submittedAt;
  final DateTime? archivedAt;
  final String? archivedBy;

  // Admin/Staff Feedback Fields
  final String? reportedBy; // 'admin', 'staff', 'user'
  final String? adminId; // If reportedBy == 'admin'
  final String? staffId; // If reportedBy == 'staff'
  final String? clinicId; // Required for admin/staff, optional for users

  FeedbackAndReport({
    this.documentId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.feedbackType,
    required this.category,
    required this.subject,
    required this.description,
    this.attachments = const [],
    this.priority = Priority.medium,
    this.status = FeedbackStatus.pending,
    required this.appVersion,
    this.isPinned = false, 
    this.pinnedAt,
    this.pinnedBy,
    this.isArchived = false,
    required this.deviceInfo,
    required this.platform,
    DateTime? submittedAt,
    this.archivedAt,
    this.archivedBy,
    this.reportedBy,
    this.adminId,
    this.staffId,
    this.clinicId,
  }) : submittedAt = submittedAt ?? DateTime.now();

  factory FeedbackAndReport.fromMap(Map<String, dynamic> map) {
    return FeedbackAndReport(
      documentId: map['\$id'],
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      feedbackType: FeedbackType.values.firstWhere(
        (e) => e.toString().split('.').last == map['feedbackType'],
        orElse: () => FeedbackType.bug,
      ),
      category: FeedbackCategory.values.firstWhere(
        (e) => e.toString().split('.').last == map['category'],
        orElse: () => FeedbackCategory.other,
      ),
      subject: map['subject'] ?? '',
      description: map['description'] ?? '',
      attachments: List<String>.from(map['attachments'] ?? []),
      priority: Priority.values.firstWhere(
        (e) => e.toString().split('.').last == map['priority'],
        orElse: () => Priority.medium,
      ),
      status: FeedbackStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => FeedbackStatus.pending,
      ),
      appVersion: map['appVersion'] ?? '',
      isPinned: map['isPinned'] ?? false,
      pinnedAt: map['pinnedAt'] != null ? DateTime.parse(map['pinnedAt']) : null,
      pinnedBy: map['pinnedBy'], 
      isArchived: map['isArchived'] ?? false,
      deviceInfo: map['deviceInfo'] ?? '',
      platform: map['platform'] ?? 'web',
      submittedAt: map['submittedAt'] != null
          ? DateTime.parse(map['submittedAt'])
          : DateTime.now(),
      archivedAt:
          map['archivedAt'] != null ? DateTime.parse(map['archivedAt']) : null,
      archivedBy: map['archivedBy'],
      reportedBy: map['reportedBy'],
      adminId: map['adminId'],
      staffId: map['staffId'],
      clinicId: map['clinicId'],
    );
  }

  Map<String, dynamic> toMap() {
    final now = DateTime.now().toIso8601String();
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'feedbackType': feedbackType.toString().split('.').last,
      'category': category.toString().split('.').last,
      'subject': subject,
      'description': description,
      'attachments': attachments,
      'priority': priority.toString().split('.').last,
      'status': status.toString().split('.').last,
      'appVersion': appVersion,
      'deviceInfo': deviceInfo,
      'platform': platform,
      'submittedAt': submittedAt.toIso8601String(),
      'updatedAt': now,
      'isArchived': isArchived,
      'archivedAt': archivedAt?.toIso8601String(),
      'archivedBy': archivedBy,
      'reportedBy': reportedBy,
      'isPinned': isPinned, 
      'pinnedAt': pinnedAt?.toIso8601String(), 
      'pinnedBy': pinnedBy, 
      'adminId': adminId,
      'staffId': staffId,
      'clinicId': clinicId,
    };
  }

  FeedbackAndReport copyWith({
    String? documentId,
    String? userId,
    String? userName,
    String? userEmail,
    FeedbackType? feedbackType,
    FeedbackCategory? category,
    String? subject,
    String? description,
    List<String>? attachments,
    Priority? priority,
    FeedbackStatus? status,
    String? appVersion,
    String? deviceInfo,
    String? platform,
    DateTime? submittedAt,
    DateTime? archivedAt,
    String? archivedBy,
    String? reportedBy,
    String? adminId,
    String? staffId,
    String? clinicId,
    bool? isPinned, 
    DateTime? pinnedAt, 
    String? pinnedBy,
    bool? isArchived,
  }) {
    return FeedbackAndReport(
      documentId: documentId ?? this.documentId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      feedbackType: feedbackType ?? this.feedbackType,
      category: category ?? this.category,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      attachments: attachments ?? this.attachments,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      appVersion: appVersion ?? this.appVersion,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      platform: platform ?? this.platform,
      submittedAt: submittedAt ?? this.submittedAt,
      archivedAt: archivedAt ?? this.archivedAt,
      archivedBy: archivedBy ?? this.archivedBy,
      reportedBy: reportedBy ?? this.reportedBy,
      adminId: adminId ?? this.adminId,
      staffId: staffId ?? this.staffId,
      clinicId: clinicId ?? this.clinicId,
      isPinned: isPinned ?? this.isPinned, 
      pinnedAt: pinnedAt ?? this.pinnedAt,
      pinnedBy: pinnedBy ?? this.pinnedBy,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}

enum FeedbackType { bug, feature, complaint, question, compliment, systemIssue }

enum FeedbackCategory {
  appointments,
  pets,
  messaging,
  profile,
  clinicSearch,
  uiUx,
  performance,
  security,
  staffManagement,
  clinicSettings,
  systemIssue,
  other
}

enum Priority { low, medium, high, critical }

enum FeedbackStatus { pending, inProgress, completed, closed }

// Helper extensions for display text
extension FeedbackTypeExtension on FeedbackType {
  String get displayName {
    switch (this) {
      case FeedbackType.bug:
        return 'Bug Report';
      case FeedbackType.feature:
        return 'Feature Request';
      case FeedbackType.complaint:
        return 'Complaint';
      case FeedbackType.question:
        return 'Question';
      case FeedbackType.compliment:
        return 'Compliment';
      case FeedbackType.systemIssue:
        return 'System Issue';
    }
  }
}

extension FeedbackCategoryExtension on FeedbackCategory {
  String get displayName {
    switch (this) {
      case FeedbackCategory.appointments:
        return 'Appointments';
      case FeedbackCategory.pets:
        return 'Pet Management';
      case FeedbackCategory.messaging:
        return 'Messaging';
      case FeedbackCategory.profile:
        return 'Profile & Settings';
      case FeedbackCategory.clinicSearch:
        return 'Clinic Search';
      case FeedbackCategory.uiUx:
        return 'UI/UX Design';
      case FeedbackCategory.performance:
        return 'Performance';
      case FeedbackCategory.security:
        return 'Security';
      case FeedbackCategory.staffManagement:
        return 'Staff Management';
      case FeedbackCategory.clinicSettings:
        return 'Clinic Settings';
      case FeedbackCategory.systemIssue:
        return 'System Issue';
      case FeedbackCategory.other:
        return 'Other';
    }
  }
}

extension PriorityExtension on Priority {
  String get displayName {
    switch (this) {
      case Priority.low:
        return 'Low';
      case Priority.medium:
        return 'Medium';
      case Priority.high:
        return 'High';
      case Priority.critical:
        return 'Critical';
    }
  }
}

extension FeedbackStatusExtension on FeedbackStatus {
  String get displayName {
    switch (this) {
      case FeedbackStatus.pending:
        return 'Pending';
      case FeedbackStatus.inProgress:
        return 'In Progress';
      case FeedbackStatus.completed:
        return 'Resolved';
      case FeedbackStatus.closed:
        return 'Closed';
    }
  }
}
