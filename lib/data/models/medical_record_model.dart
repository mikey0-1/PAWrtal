class MedicalRecord {
  final String? id;
  final String petId;
  final String clinicId;
  final String vetId;
  final String appointmentId;
  final DateTime visitDate;
  final String service;
  final String diagnosis;
  final String treatment;
  final String? prescription;
  final String? notes;

  // Individual vital fields (properly typed)
  final double? temperature;
  final double? weight;
  final String? bloodPressure;
  final int? heartRate;

  // REMOVED: vitals map - we now use individual fields only
  // This eliminates the confusion and potential data corruption

  final List<String>? attachments;
  final DateTime createdAt;
  final DateTime updatedAt;

  MedicalRecord({
    this.id,
    required this.petId,
    required this.clinicId,
    required this.vetId,
    required this.appointmentId,
    required this.visitDate,
    required this.service,
    required this.diagnosis,
    required this.treatment,
    this.prescription,
    this.notes,
    this.temperature,
    this.weight,
    this.bloodPressure,
    this.heartRate,
    this.attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // REMOVED: fromAppointment factory - appointments no longer have medical data
  // Medical records should only be created explicitly with medical data

  Map<String, dynamic> toMap() {

    return {
      'petId': petId,
      'clinicId': clinicId,
      'vetId': vetId,
      'appointmentId': appointmentId,
      'visitDate': visitDate.toIso8601String(),
      'service': service,
      'diagnosis': diagnosis,
      'treatment': treatment,
      'prescription': prescription,
      'notes': notes,
      // CRITICAL: Store each vital in its own column
      'temperature': temperature,
      'weight': weight,
      'bloodPressure': bloodPressure,
      'heartRate': heartRate,
      // CRITICAL: Always set vitals to null - we don't use this column anymore
      'vitals': null,
      'attachments': attachments,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MedicalRecord.fromMap(Map<String, dynamic> map) {
    // CRITICAL: Read individual vital fields from database
    // If old records have vitals as JSON string, we ignore it

    double? temp;
    double? wt;
    String? bp;
    int? hr;

    // Read from individual columns
    if (map['temperature'] != null) {
      temp = map['temperature'] is double
          ? map['temperature']
          : double.tryParse(map['temperature'].toString());
    }

    if (map['weight'] != null) {
      wt = map['weight'] is double
          ? map['weight']
          : double.tryParse(map['weight'].toString());
    }

    if (map['bloodPressure'] != null) {
      bp = map['bloodPressure'].toString();
    }

    if (map['heartRate'] != null) {
      hr = map['heartRate'] is int
          ? map['heartRate']
          : int.tryParse(map['heartRate'].toString());
    }

    return MedicalRecord(
      id: map['\$id'],
      petId: map['petId'],
      clinicId: map['clinicId'],
      vetId: map['vetId'],
      appointmentId: map['appointmentId'],
      visitDate: DateTime.parse(map['visitDate']),
      service: map['service'],
      diagnosis: map['diagnosis'],
      treatment: map['treatment'],
      prescription: map['prescription'],
      notes: map['notes'],
      // Use individual fields
      temperature: temp,
      weight: wt,
      bloodPressure: bp,
      heartRate: hr,
      attachments: map['attachments'] != null
          ? List<String>.from(map['attachments'])
          : null,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  MedicalRecord copyWith({
    String? id,
    String? petId,
    String? clinicId,
    String? vetId,
    String? appointmentId,
    DateTime? visitDate,
    String? service,
    String? diagnosis,
    String? treatment,
    String? prescription,
    String? notes,
    double? temperature,
    double? weight,
    String? bloodPressure,
    int? heartRate,
    List<String>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MedicalRecord(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      clinicId: clinicId ?? this.clinicId,
      vetId: vetId ?? this.vetId,
      appointmentId: appointmentId ?? this.appointmentId,
      visitDate: visitDate ?? this.visitDate,
      service: service ?? this.service,
      diagnosis: diagnosis ?? this.diagnosis,
      treatment: treatment ?? this.treatment,
      prescription: prescription ?? this.prescription,
      notes: notes ?? this.notes,
      temperature: temperature ?? this.temperature,
      weight: weight ?? this.weight,
      bloodPressure: bloodPressure ?? this.bloodPressure,
      heartRate: heartRate ?? this.heartRate,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper getters
  bool get hasVitals =>
      temperature != null ||
      weight != null ||
      bloodPressure != null ||
      heartRate != null;

  String get vitalsDisplay {
    if (!hasVitals) return 'No vitals recorded';

    final parts = <String>[];
    if (temperature != null) parts.add('Temp: $temperature°C');
    if (weight != null) parts.add('Weight: ${weight}kg');
    if (bloodPressure != null) parts.add('BP: $bloodPressure');
    if (heartRate != null) parts.add('HR: $heartRate bpm');

    return parts.join(' • ');
  }

  // Helper method to get vitals as a map (for display purposes)
  Map<String, dynamic>? get vitalsAsMap {
    if (!hasVitals) return null;

    final vitalsMap = <String, dynamic>{};
    if (temperature != null) vitalsMap['temperature'] = temperature;
    if (weight != null) vitalsMap['weight'] = weight;
    if (bloodPressure != null) vitalsMap['bloodPressure'] = bloodPressure;
    if (heartRate != null) vitalsMap['heartRate'] = heartRate;

    return vitalsMap.isNotEmpty ? vitalsMap : null;
  }

  // Helper method to check if specific vital is present
  bool hasTemperature() => temperature != null;
  bool hasWeight() => weight != null;
  bool hasBloodPressure() => bloodPressure != null;
  bool hasHeartRate() => heartRate != null;

  // Helper method to get formatted vital values
  String? get temperatureFormatted =>
      temperature != null ? '${temperature!.toStringAsFixed(1)}°C' : null;

  String? get weightFormatted =>
      weight != null ? '${weight!.toStringAsFixed(2)} kg' : null;

  String? get heartRateFormatted => heartRate != null ? '$heartRate bpm' : null;

  // Validation helper
  bool get isValid {
    return petId.isNotEmpty &&
        clinicId.isNotEmpty &&
        vetId.isNotEmpty &&
        appointmentId.isNotEmpty &&
        service.isNotEmpty &&
        diagnosis.isNotEmpty &&
        treatment.isNotEmpty;
  }

  // Check if record has complete information
  bool get isComplete {
    return isValid && (prescription != null || notes != null || hasVitals);
  }

  @override
  String toString() {
    return 'MedicalRecord('
        'id: $id, '
        'petId: $petId, '
        'appointmentId: $appointmentId, '
        'service: $service, '
        'diagnosis: $diagnosis, '
        'treatment: $treatment, '
        'hasVitals: $hasVitals, '
        'temperature: $temperature, '
        'weight: $weight, '
        'bloodPressure: $bloodPressure, '
        'heartRate: $heartRate'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MedicalRecord &&
        other.id == id &&
        other.petId == petId &&
        other.clinicId == clinicId &&
        other.vetId == vetId &&
        other.appointmentId == appointmentId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        petId.hashCode ^
        clinicId.hashCode ^
        vetId.hashCode ^
        appointmentId.hashCode;
  }
}
