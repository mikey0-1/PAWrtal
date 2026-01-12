class Vaccination {
  final String? documentId;
  final String petId;
  final String clinicId;
  final String vaccineType;
  final String vaccineName;
  final DateTime dateGiven;
  final DateTime? nextDueDate;
  final String veterinarianName;
  final String? veterinarianId;
  final String? batchNumber;
  final String? manufacturer;
  final String? notes;
  final bool isBooster;
  final DateTime createdAt;
  final DateTime updatedAt;

  Vaccination({
    this.documentId,
    required this.petId,
    required this.clinicId,
    required this.vaccineType,
    required this.vaccineName,
    required this.dateGiven,
    this.nextDueDate,
    required this.veterinarianName,
    this.veterinarianId,
    this.batchNumber,
    this.manufacturer,
    this.notes,
    this.isBooster = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Vaccination.fromMap(Map<String, dynamic> map) {
    return Vaccination(
      documentId: map['\$id'],
      petId: map['petId'] ?? '',
      clinicId: map['clinicId'] ?? '',
      vaccineType: map['vaccineType'] ?? '',
      vaccineName: map['vaccineName'] ?? '',
      dateGiven: DateTime.parse(map['dateGiven']),
      nextDueDate: map['nextDueDate'] != null 
          ? DateTime.parse(map['nextDueDate']) 
          : null,
      veterinarianName: map['veterinarianName'] ?? '',
      veterinarianId: map['veterinarianId'],
      batchNumber: map['batchNumber'],
      manufacturer: map['manufacturer'],
      notes: map['notes'],
      isBooster: map['isBooster'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'petId': petId,
      'clinicId': clinicId,
      'vaccineType': vaccineType,
      'vaccineName': vaccineName,
      'dateGiven': dateGiven.toIso8601String(),
      'nextDueDate': nextDueDate?.toIso8601String(),
      'veterinarianName': veterinarianName,
      'veterinarianId': veterinarianId,
      'batchNumber': batchNumber,
      'manufacturer': manufacturer,
      'notes': notes,
      'isBooster': isBooster,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Vaccination copyWith({
    String? documentId,
    String? petId,
    String? clinicId,
    String? vaccineType,
    String? vaccineName,
    DateTime? dateGiven,
    DateTime? nextDueDate,
    String? veterinarianName,
    String? veterinarianId,
    String? batchNumber,
    String? manufacturer,
    String? notes,
    bool? isBooster,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vaccination(
      documentId: documentId ?? this.documentId,
      petId: petId ?? this.petId,
      clinicId: clinicId ?? this.clinicId,
      vaccineType: vaccineType ?? this.vaccineType,
      vaccineName: vaccineName ?? this.vaccineName,
      dateGiven: dateGiven ?? this.dateGiven,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      veterinarianName: veterinarianName ?? this.veterinarianName,
      veterinarianId: veterinarianId ?? this.veterinarianId,
      batchNumber: batchNumber ?? this.batchNumber,
      manufacturer: manufacturer ?? this.manufacturer,
      notes: notes ?? this.notes,
      isBooster: isBooster ?? this.isBooster,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper getters
  bool get isOverdue {
    if (nextDueDate == null) return false;
    return DateTime.now().isAfter(nextDueDate!);
  }

  bool get isDueSoon {
    if (nextDueDate == null) return false;
    final daysUntilDue = nextDueDate!.difference(DateTime.now()).inDays;
    return daysUntilDue > 0 && daysUntilDue <= 30;
  }

  String get statusText {
    if (isOverdue) return 'Overdue';
    if (isDueSoon) return 'Due Soon';
    return 'Up to Date';
  }
}