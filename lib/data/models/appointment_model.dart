class Appointment {
  final String? documentId;
  final String userId;
  final String clinicId;
  final String petId;
  final String service;
  final DateTime dateTime;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Medical service flag
  final bool isMedicalService;

  // Cancellation/rejection tracking
  final String? cancellationReason;
  final String? cancelledBy;
  final DateTime? cancelledAt;

  // Workflow tracking
  final DateTime? checkedInAt;
  final DateTime? serviceStartedAt;
  final DateTime? serviceCompletedAt;

  // Payment tracking
  final double? totalCost;
  final bool isPaid;
  final String? paymentMethod;

  // Follow-up
  final String? followUpInstructions;
  final DateTime? nextAppointmentDate;

  // Attachments
  final List<String>? attachments;

  // Reminder tracking
  final bool reminderSent;
  final DateTime? reminderSentAt;

  Appointment({
    this.documentId,
    required this.userId,
    required this.clinicId,
    required this.petId,
    required this.service,
    required this.dateTime,
    this.status = 'pending',
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isMedicalService = false,
    this.cancellationReason,
    this.cancelledBy,
    this.cancelledAt,
    this.checkedInAt,
    this.serviceStartedAt,
    this.serviceCompletedAt,
    this.attachments,
    this.totalCost,
    this.isPaid = false,
    this.paymentMethod,
    this.followUpInstructions,
    this.nextAppointmentDate,
    this.reminderSent = false,
    this.reminderSentAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'clinicId': clinicId,
      'petId': petId,
      'service': service,
      'dateTime': dateTime.toIso8601String(),
      'status': status,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isMedicalService': isMedicalService,
      'cancellationReason': cancellationReason,
      'cancelledBy': cancelledBy,
      'cancelledAt': cancelledAt?.toIso8601String(),
      'checkedInAt': checkedInAt?.toIso8601String(),
      'serviceStartedAt': serviceStartedAt?.toIso8601String(),
      'serviceCompletedAt': serviceCompletedAt?.toIso8601String(),
      'attachments': attachments,
      'totalCost': totalCost,
      'isPaid': isPaid,
      'paymentMethod': paymentMethod,
      'followUpInstructions': followUpInstructions,
      'nextAppointmentDate': nextAppointmentDate?.toIso8601String(),
      'reminderSent': reminderSent,
      'reminderSentAt': reminderSentAt?.toIso8601String(),
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      documentId: map['\$id'],
      userId: map['userId'],
      clinicId: map['clinicId'] ?? '',
      petId: map['petId'] ?? '',
      service: map['service'] ?? '',
      dateTime: DateTime.parse(map['dateTime']),
      status: map['status'] ?? 'pending',
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      isMedicalService: map['isMedicalService'] ?? false,
      cancellationReason: map['cancellationReason'],
      cancelledBy: map['cancelledBy'],
      cancelledAt: map['cancelledAt'] != null
          ? DateTime.parse(map['cancelledAt'])
          : null,
      checkedInAt: map['checkedInAt'] != null
          ? DateTime.parse(map['checkedInAt'])
          : null,
      serviceStartedAt: map['serviceStartedAt'] != null
          ? DateTime.parse(map['serviceStartedAt'])
          : null,
      serviceCompletedAt: map['serviceCompletedAt'] != null
          ? DateTime.parse(map['serviceCompletedAt'])
          : null,
      attachments: map['attachments'] != null
          ? List<String>.from(map['attachments'])
          : null,
      totalCost: map['totalCost']?.toDouble(),
      isPaid: map['isPaid'] ?? false,
      paymentMethod: map['paymentMethod'],
      followUpInstructions: map['followUpInstructions'],
      nextAppointmentDate: map['nextAppointmentDate'] != null
          ? DateTime.parse(map['nextAppointmentDate'])
          : null,
      reminderSent: map['reminderSent'] ?? false,
      reminderSentAt: map['reminderSentAt'] != null
          ? DateTime.parse(map['reminderSentAt'])
          : null,
    );
  }

  Appointment copyWith({
    String? documentId,
    String? userId,
    String? clinicId,
    String? petId,
    String? service,
    DateTime? dateTime,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isMedicalService,
    String? cancellationReason,
    String? cancelledBy,
    DateTime? cancelledAt,
    DateTime? checkedInAt,
    DateTime? serviceStartedAt,
    DateTime? serviceCompletedAt,
    List<String>? attachments,
    double? totalCost,
    bool? isPaid,
    String? paymentMethod,
    String? followUpInstructions,
    DateTime? nextAppointmentDate,
    bool? reminderSent,
    DateTime? reminderSentAt,
  }) {
    return Appointment(
      documentId: documentId ?? this.documentId,
      userId: userId ?? this.userId,
      clinicId: clinicId ?? this.clinicId,
      petId: petId ?? this.petId,
      service: service ?? this.service,
      dateTime: dateTime ?? this.dateTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isMedicalService: isMedicalService ?? this.isMedicalService,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      serviceStartedAt: serviceStartedAt ?? this.serviceStartedAt,
      serviceCompletedAt: serviceCompletedAt ?? this.serviceCompletedAt,
      attachments: attachments ?? this.attachments,
      totalCost: totalCost ?? this.totalCost,
      isPaid: isPaid ?? this.isPaid,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      followUpInstructions: followUpInstructions ?? this.followUpInstructions,
      nextAppointmentDate: nextAppointmentDate ?? this.nextAppointmentDate,
      reminderSent: reminderSent ?? this.reminderSent,
      reminderSentAt: reminderSentAt ?? this.reminderSentAt,
    );
  }

  // Helper methods
  bool get isCompleted => status == 'completed';
  bool get isInProgress => status == 'in_progress';
  bool get isAccepted => status == 'accepted';
  bool get isPending => status == 'pending';
  bool get isCancelled => status == 'cancelled';
  bool get isDeclined => status == 'declined';
  bool get hasArrived => checkedInAt != null;
  bool get hasServiceStarted => serviceStartedAt != null;
  bool get hasServiceCompleted => serviceCompletedAt != null;

  bool get isCancelledByUser => isCancelled && cancelledBy == 'user';
  bool get isCancelledByClinic =>
      (isCancelled || isDeclined) && cancelledBy == 'clinic';

  bool get isToday {
    final now = DateTime.now();
    final localDate = dateTime;
    return localDate.year == now.year &&
        localDate.month == now.month &&
        localDate.day == now.day;
  }

  bool get isPast {
    final now = DateTime.now();
    final localDate = dateTime;
    final appointmentDate =
        DateTime(localDate.year, localDate.month, localDate.day);
    final today = DateTime(now.year, now.month, now.day);
    return appointmentDate.isBefore(today);
  }

  Duration? get serviceDuration {
    if (serviceStartedAt != null && serviceCompletedAt != null) {
      return serviceCompletedAt!.difference(serviceStartedAt!);
    }
    return null;
  }

  Duration? get waitingTime {
    if (checkedInAt != null && serviceStartedAt != null) {
      return serviceStartedAt!.difference(checkedInAt!);
    }
    return null;
  }

  // Helper method to format time in 12-hour format
  String get formattedTime {
    final localDateTime = dateTime.toLocal();
    final hour = localDateTime.hour;
    final minute = localDateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  // Helper method to format date and time together
  String get formattedDateTime {
    final localDateTime = dateTime.toLocal();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final month = months[localDateTime.month - 1];
    final day = localDateTime.day;
    final year = localDateTime.year;

    return '$month $day, $year at $formattedTime';
  }

  // Helper method to format just the date
  String get formattedDate {
    final localDateTime = dateTime.toLocal();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final month = months[localDateTime.month - 1];
    final day = localDateTime.day;
    final year = localDateTime.year;

    return '$month $day, $year';
  }

  // Static method to convert 24-hour time string to 12-hour format
  static String formatTime24To12(String time24) {
    try {
      final parts = time24.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

      return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return time24;
    }
  }

  // Static method to convert 12-hour time string to 24-hour format (for saving)
  static String formatTime12To24(String time12) {
    try {
      final parts = time12.trim().split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final period = parts.length > 1 ? parts[1].toUpperCase() : 'AM';

      if (period == 'PM' && hour != 12) {
        hour += 12;
      } else if (period == 'AM' && hour == 12) {
        hour = 0;
      }

      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return time12;
    }
  }
}
