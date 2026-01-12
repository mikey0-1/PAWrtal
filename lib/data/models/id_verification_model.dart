class IdVerification {
  String? documentId;
  String userId;
  String email;
  String status; // 'pending', 'approved', 'rejected', 'in_progress'
  String? submissionId; // ARGOS submission ID
  String? verificationType; // 'id_document', 'knowledge_based'
  String? rejectionReason;
  String? idType; // 'passport', 'driver_license', etc.
  String? countryCode;
  String? fullName;
  String? birthDate;
  String? verifyByClinic; // NEW: Clinic ID that verified the user
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? verifiedAt;
  Map<String, dynamic>? additionalData;

  IdVerification({
    this.documentId,
    required this.userId,
    required this.email,
    this.status = 'pending',
    this.submissionId,
    this.verificationType,
    this.rejectionReason,
    this.idType,
    this.countryCode,
    this.fullName,
    this.birthDate,
    this.verifyByClinic, // NEW
    DateTime? createdAt,
    DateTime? updatedAt,
    this.verifiedAt,
    this.additionalData,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory IdVerification.fromMap(Map<String, dynamic> map) {
    return IdVerification(
      documentId: map['\$id'] as String?,
      userId: map['userId'] as String? ?? '',
      email: map['email'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      submissionId: map['submissionId'] as String?,
      verificationType: map['verificationType'] as String?,
      rejectionReason: map['rejectionReason'] as String?,
      idType: map['idType'] as String?,
      countryCode: map['countryCode'] as String?,
      fullName: map['fullName'] as String?,
      birthDate: map['birthDate'] as String?,
      verifyByClinic: map['verifyByClinic'] as String?, // NEW
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : DateTime.now(),
      verifiedAt: map['verifiedAt'] != null
          ? DateTime.parse(map['verifiedAt'] as String)
          : null,
      additionalData: map['additionalData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email,
      'status': status,
      'submissionId': submissionId,
      'verificationType': verificationType,
      'rejectionReason': rejectionReason,
      'idType': idType,
      'countryCode': countryCode,
      'fullName': fullName,
      'birthDate': birthDate,
      'verifyByClinic': verifyByClinic, // NEW
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'verifiedAt': verifiedAt?.toIso8601String(),
      'additionalData': additionalData,
    };
  }

  IdVerification copyWith({
    String? documentId,
    String? userId,
    String? email,
    String? status,
    String? submissionId,
    String? verificationType,
    String? rejectionReason,
    String? idType,
    String? countryCode,
    String? fullName,
    String? birthDate,
    String? verifyByClinic, // NEW
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? verifiedAt,
    Map<String, dynamic>? additionalData,
  }) {
    return IdVerification(
      documentId: documentId ?? this.documentId,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      status: status ?? this.status,
      submissionId: submissionId ?? this.submissionId,
      verificationType: verificationType ?? this.verificationType,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      idType: idType ?? this.idType,
      countryCode: countryCode ?? this.countryCode,
      fullName: fullName ?? this.fullName,
      birthDate: birthDate ?? this.birthDate,
      verifyByClinic: verifyByClinic ?? this.verifyByClinic, // NEW
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  bool get isVerified => status == 'approved';
  bool get isPending => status == 'pending' || status == 'in_progress';
  bool get isRejected => status == 'rejected';

  // NEW: Check if verified by clinic
  bool get isVerifiedByClinic =>
      verifyByClinic != null && verifyByClinic!.isNotEmpty;
}
