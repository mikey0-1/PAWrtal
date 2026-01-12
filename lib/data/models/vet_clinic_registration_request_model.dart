import 'package:flutter/material.dart';

class VetClinicRegistrationRequest {
  String? documentId;
  String clinicName;
  String barangay;
  String contactNumber;
  String email;
  List<String> documentFileIds;
  String status;
  String? reviewedBy;
  String? reviewNotes;
  DateTime submittedAt;
  DateTime? reviewedAt;

  // NEW: Address detail fields
  String? street;
  String? blockLot;
  String? buildingUnit;

  VetClinicRegistrationRequest({
    this.documentId,
    required this.clinicName,
    required this.barangay,
    required this.contactNumber,
    required this.email,
    required this.documentFileIds,
    this.status = 'pending',
    this.reviewedBy,
    this.reviewNotes,
    required this.submittedAt,
    this.reviewedAt,
    this.street,
    this.blockLot,
    this.buildingUnit,
  });

  // From Appwrite Document
  factory VetClinicRegistrationRequest.fromMap(Map<String, dynamic> map) {
    return VetClinicRegistrationRequest(
      documentId: map['\$id'],
      clinicName: map['clinicName'] ?? '',
      barangay: map['barangay'] ?? '',
      contactNumber: map['contactNumber'] ?? '',
      email: map['email'] ?? '',
      documentFileIds: List<String>.from(map['documentFileIds'] ?? []),
      status: map['status'] ?? 'pending',
      reviewedBy: map['reviewedBy'],
      reviewNotes: map['reviewNotes'],
      submittedAt: DateTime.parse(map['submittedAt']),
      reviewedAt:
          map['reviewedAt'] != null ? DateTime.parse(map['reviewedAt']) : null,
      // NEW: Parse address details
      street: map['street'] ?? '',
      blockLot: map['blockLot'] ?? '',
      buildingUnit: map['buildingUnit'] ?? '',
    );
  }

  // To Appwrite Document
  Map<String, dynamic> toMap() {
    return {
      'clinicName': clinicName,
      'barangay': barangay,
      'contactNumber': contactNumber,
      'email': email,
      'documentFileIds': documentFileIds,
      'status': status,
      'reviewedBy': reviewedBy ?? '',
      'reviewNotes': reviewNotes ?? '',
      'submittedAt': submittedAt.toIso8601String(),
      'reviewedAt': reviewedAt?.toIso8601String() ?? '',
      // NEW: Include address details
      'street': street ?? '',
      'blockLot': blockLot ?? '',
      'buildingUnit': buildingUnit ?? '',
    };
  }

  // Full address with all components
  String get fullAddress {
    List<String> addressParts = [];

    // Add building/unit if provided
    if (buildingUnit != null && buildingUnit!.isNotEmpty) {
      addressParts.add(buildingUnit!);
    }

    // Add block/lot if provided
    if (blockLot != null && blockLot!.isNotEmpty) {
      addressParts.add(blockLot!);
    }

    // Add street if provided
    if (street != null && street!.isNotEmpty) {
      addressParts.add(street!);
    }

    // Add barangay
    addressParts.add('Brgy. $barangay');

    // Always add city and province
    addressParts.add('San Jose del Monte');
    addressParts.add('Bulacan');

    return addressParts.join(', ');
  }

  // Status color
  Color get statusColor {
    switch (status) {
      case 'approved':
        return const Color(0xFF4CAF50);
      case 'rejected':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFFFF9800);
    }
  }

  // Status icon
  IconData get statusIcon {
    switch (status) {
      case 'approved':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.pending_rounded;
    }
  }

  // Copy with
  VetClinicRegistrationRequest copyWith({
    String? documentId,
    String? clinicName,
    String? barangay,
    String? contactNumber,
    String? email,
    List<String>? documentFileIds,
    String? status,
    String? reviewedBy,
    String? reviewNotes,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? street,
    String? blockLot,
    String? buildingUnit,
  }) {
    return VetClinicRegistrationRequest(
      documentId: documentId ?? this.documentId,
      clinicName: clinicName ?? this.clinicName,
      barangay: barangay ?? this.barangay,
      contactNumber: contactNumber ?? this.contactNumber,
      email: email ?? this.email,
      documentFileIds: documentFileIds ?? this.documentFileIds,
      status: status ?? this.status,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewNotes: reviewNotes ?? this.reviewNotes,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      street: street ?? this.street,
      blockLot: blockLot ?? this.blockLot,
      buildingUnit: buildingUnit ?? this.buildingUnit,
    );
  }
}
