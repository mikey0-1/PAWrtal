// clinic_settings_model.dart
import 'dart:convert';

class ClinicSettings {
  String? documentId;
  late String clinicId;
  late bool isOpen;
  late Map<String, Map<String, dynamic>> operatingHours;
  late List<String> gallery;
  late Map<String, double>? location;
  late List<String> services;
  late Map<String, bool>
      medicalServices; // NEW: Track which services are medical
  late int appointmentDuration;
  late int maxAdvanceBooking;
  late String emergencyContact;
  late String specialInstructions;
  late bool autoAcceptAppointments;
  late String createdAt;
  late String updatedAt;
  late String dashboardPic;
  late List<String> closedDates; // NEW: List of ISO date strings (YYYY-MM-DD)

  ClinicSettings({
    this.documentId,
    required this.clinicId,
    this.isOpen = true,
    List<String>? closedDates,
    Map<String, Map<String, dynamic>>? operatingHours,
    List<String>? gallery,
    this.location,
    List<String>? services,
    Map<String, bool>? medicalServices, // NEW
    this.appointmentDuration = 30,
    this.maxAdvanceBooking = 30,
    this.emergencyContact = '',
    this.specialInstructions = '',
    this.autoAcceptAppointments = false,
    String? createdAt,
    String? updatedAt,
    this.dashboardPic = '',
  })  : operatingHours = operatingHours ?? _getDefaultOperatingHours(),
        gallery = gallery ?? [],
        services = services ?? [],
        medicalServices = medicalServices ?? {}, // NEW
        createdAt = createdAt ?? DateTime.now().toIso8601String(),
        updatedAt = updatedAt ?? DateTime.now().toIso8601String(),
        closedDates = closedDates ?? [];

  static Map<String, Map<String, dynamic>> _getDefaultOperatingHours() {
    return {
      'monday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '17:00'},
      'tuesday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '17:00'},
      'wednesday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '17:00'},
      'thursday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '17:00'},
      'friday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '17:00'},
      'saturday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '15:00'},
      'sunday': {'isOpen': false, 'openTime': '09:00', 'closeTime': '17:00'},
    };
  }

  factory ClinicSettings.fromMap(Map<String, dynamic> map) {
    return ClinicSettings(
      documentId: map['\$id'],
      clinicId: map['clinicId'] ?? '',
      isOpen: map['isOpen'] ?? true,
      operatingHours: _parseOperatingHours(map['operatingHours']),
      gallery: List<String>.from(map['gallery'] ?? []),
      location: _parseLocation(map['location']),
      services: List<String>.from(map['services'] ?? []),
      medicalServices: _parseMedicalServices(map['medicalServices']),
      appointmentDuration: map['appointmentDuration'] ?? 30,
      maxAdvanceBooking: map['maxAdvanceBooking'] ?? 30,
      emergencyContact: map['emergencyContact'] ?? '',
      specialInstructions: map['specialInstructions'] ?? '',
      autoAcceptAppointments: map['autoAcceptAppointments'] ?? false,
      createdAt: map['createdAt'] ?? DateTime.now().toIso8601String(),
      updatedAt: map['updatedAt'] ?? DateTime.now().toIso8601String(),
      dashboardPic: map['dashboardPic'] ?? '',
      // FIX: Parse closedDates from JSON string
      closedDates: _parseClosedDates(map['closedDates']),
    );
  }

// Add this helper method
  static List<String> _parseClosedDates(dynamic closedDates) {
    if (closedDates == null) return [];
    if (closedDates is String) {
      try {
        final decoded = json.decode(closedDates);
        if (decoded is List) {
          return List<String>.from(decoded);
        }
      } catch (e) {
      }
    }
    if (closedDates is List) {
      return List<String>.from(closedDates);
    }
    return [];
  }

  // NEW: Parse medical services map
  static Map<String, bool> _parseMedicalServices(dynamic medicalServices) {
    if (medicalServices == null) return {};
    if (medicalServices is String) {
      try {
        final decoded = json.decode(medicalServices);
        if (decoded is Map) {
          return Map<String, bool>.from(decoded);
        }
      } catch (e) {
      }
    }
    if (medicalServices is Map) {
      return Map<String, bool>.from(medicalServices);
    }
    return {};
  }

  static Map<String, Map<String, dynamic>> _parseOperatingHours(dynamic hours) {
    if (hours == null) return _getDefaultOperatingHours();
    if (hours is String) {
      try {
        Map<String, dynamic> decoded = json.decode(hours);
        Map<String, Map<String, dynamic>> converted = {};
        decoded.forEach((key, value) {
          if (value is Map) {
            converted[key] = Map<String, dynamic>.from(value);
          }
        });
        return converted;
      } catch (e) {
        return _getDefaultOperatingHours();
      }
    }
    if (hours is Map<String, Map<String, dynamic>>) return hours;
    return _getDefaultOperatingHours();
  }

  static Map<String, double>? _parseLocation(dynamic location) {
    if (location == null) return null;
    if (location is String) {
      try {
        final parsed = json.decode(location);
        return {
          'lat': (parsed['lat'] as num).toDouble(),
          'lng': (parsed['lng'] as num).toDouble(),
        };
      } catch (e) {
        return null;
      }
    }
    if (location is Map<String, dynamic>) {
      return {
        'lat': (location['lat'] as num).toDouble(),
        'lng': (location['lng'] as num).toDouble(),
      };
    }
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'clinicId': clinicId,
      'isOpen': isOpen,
      'operatingHours': json.encode(operatingHours),
      'gallery': gallery,
      'location': location != null ? json.encode(location) : null,
      'services': services,
      'medicalServices':
          json.encode(medicalServices.isEmpty ? {} : medicalServices),
      'appointmentDuration': appointmentDuration,
      'maxAdvanceBooking': maxAdvanceBooking,
      'emergencyContact': emergencyContact,
      'specialInstructions': specialInstructions,
      'autoAcceptAppointments': autoAcceptAppointments,
      'createdAt': createdAt,
      'updatedAt': DateTime.now().toIso8601String(),
      'dashboardPic': dashboardPic,
      // FIX: Convert closedDates array to JSON string
      'closedDates': json.encode(closedDates),
    };
  }

  // NEW: Check if a specific date is closed
  bool isDateClosed(DateTime date) {
    final dateStr = _formatDateToString(date);
    return closedDates.contains(dateStr);
  }

  // NEW: Helper to format date to YYYY-MM-DD
  String _formatDateToString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // NEW: Helper method to check if a service is medical
  bool isServiceMedical(String serviceName) {
    return medicalServices[serviceName] ?? false;
  }

  // NEW: Helper method to set service medical status
  void setServiceMedicalStatus(String serviceName, bool isMedical) {
    medicalServices[serviceName] = isMedical;
  }

  // Existing helper methods remain unchanged...
  bool isOpenToday() {
    final today = DateTime.now().weekday;
    final dayName = _getDayName(today);
    return operatingHours[dayName]?['isOpen'] ?? false;
  }

  bool isOpenNow() {
    if (!isOpen) return false;

    final now = DateTime.now();
    final dayName = _getDayName(now.weekday);
    final dayHours = operatingHours[dayName];

    if (dayHours?['isOpen'] != true) return false;

    try {
      final openTime = dayHours?['openTime'] as String;
      final closeTime = dayHours?['closeTime'] as String;

      final openParts = openTime.split(':');
      final closeParts = closeTime.split(':');

      final openHour = int.parse(openParts[0]);
      final openMinute = int.parse(openParts[1]);
      final closeHour = int.parse(closeParts[0]);
      final closeMinute = int.parse(closeParts[1]);

      final openDateTime =
          DateTime(now.year, now.month, now.day, openHour, openMinute);
      final closeDateTime =
          DateTime(now.year, now.month, now.day, closeHour, closeMinute);

      return now.isAfter(openDateTime) && now.isBefore(closeDateTime);
    } catch (e) {
      return false;
    }
  }

  String getTodayHours() {
    final today = DateTime.now().weekday;
    final dayName = _getDayName(today);
    final dayHours = operatingHours[dayName];

    if (dayHours?['isOpen'] == true) {
      final openTime = _formatTime24To12(dayHours?['openTime'] ?? '09:00');
      final closeTime = _formatTime24To12(dayHours?['closeTime'] ?? '17:00');
      return '$openTime - $closeTime';
    }
    return 'Closed';
  }

  String getDetailedStatus() {
    if (!isOpen) return 'Closed for appointments';
    if (!isOpenToday()) return 'Closed today';
    if (!isOpenNow()) {
      final today = DateTime.now().weekday;
      final dayName = _getDayName(today);
      final dayHours = operatingHours[dayName];
      final openTime = _formatTime24To12(dayHours?['openTime'] ?? '');
      return 'Closed now (Opens at $openTime)';
    }
    return 'Open now';
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'monday';
      case 2:
        return 'tuesday';
      case 3:
        return 'wednesday';
      case 4:
        return 'thursday';
      case 5:
        return 'friday';
      case 6:
        return 'saturday';
      case 7:
        return 'sunday';
      default:
        return 'monday';
    }
  }

  List<String> getAvailableTimeSlots(DateTime date) {
    final dayName = _getDayName(date.weekday);
    final dayHours = operatingHours[dayName];

    if (dayHours?['isOpen'] != true) return [];

    final openTime = dayHours?['openTime'] as String;
    final closeTime = dayHours?['closeTime'] as String;

    final slots = <String>[];
    final openHour = int.parse(openTime.split(':')[0]);
    final openMinute = int.parse(openTime.split(':')[1]);
    final closeHour = int.parse(closeTime.split(':')[0]);
    final closeMinute = int.parse(closeTime.split(':')[1]);

    var currentTime =
        DateTime(date.year, date.month, date.day, openHour, openMinute);
    final endTime =
        DateTime(date.year, date.month, date.day, closeHour, closeMinute);

    while (currentTime.isBefore(endTime)) {
      // Convert to 12-hour format
      final hour = currentTime.hour;
      final minute = currentTime.minute;
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

      final formattedTime =
          '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
      slots.add(formattedTime);

      currentTime = currentTime.add(Duration(minutes: appointmentDuration));
    }

    return slots;
  }

  List<String> getAvailableTimeSlotsFiltered(DateTime date) {
    List<String> slots = getAvailableTimeSlots(date);

    if (_isToday(date)) {
      slots = _filterPastTimeSlots(slots, date);
    }

    return slots;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  List<String> _filterPastTimeSlots(List<String> timeSlots, DateTime date) {
    final now = DateTime.now();

    return timeSlots.where((timeSlot) {
      try {
        // Parse 12-hour format time
        final parts = timeSlot.split(' ');
        final timeParts = parts[0].split(':');
        int hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        final period = parts[1];

        // Convert to 24-hour format for comparison
        if (period == 'PM' && hour != 12) {
          hour += 12;
        } else if (period == 'AM' && hour == 12) {
          hour = 0;
        }

        final slotDateTime =
            DateTime(date.year, date.month, date.day, hour, minute);
        return slotDateTime.isAfter(now.add(const Duration(minutes: 30)));
      } catch (e) {
        return true;
      }
    }).toList();
  }

  ClinicSettings copyWith({
    String? documentId,
    String? clinicId,
    bool? isOpen,
    Map<String, Map<String, dynamic>>? operatingHours,
    List<String>? gallery,
    Map<String, double>? location,
    List<String>? services,
    Map<String, bool>? medicalServices, // NEW
    int? appointmentDuration,
    int? maxAdvanceBooking,
    String? emergencyContact,
    String? specialInstructions,
    bool? autoAcceptAppointments,
    String? createdAt,
    String? updatedAt,
    String? dashboardPic,
    List<String>? closedDates,
  }) {
    return ClinicSettings(
      documentId: documentId ?? this.documentId,
      clinicId: clinicId ?? this.clinicId,
      isOpen: isOpen ?? this.isOpen,
      operatingHours: operatingHours ?? this.operatingHours,
      gallery: gallery ?? this.gallery,
      location: location ?? this.location,
      services: services ?? this.services,
      medicalServices: medicalServices ?? this.medicalServices, // NEW
      appointmentDuration: appointmentDuration ?? this.appointmentDuration,
      maxAdvanceBooking: maxAdvanceBooking ?? this.maxAdvanceBooking,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      autoAcceptAppointments:
          autoAcceptAppointments ?? this.autoAcceptAppointments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dashboardPic: dashboardPic ?? this.dashboardPic,
      closedDates: closedDates ?? this.closedDates,
    );
  }

  String _formatTime24To12(String time24) {
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

  // Helper method to convert 12-hour time to 24-hour format
  String _formatTime12To24(String time12) {
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
