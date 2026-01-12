import 'package:get_storage/get_storage.dart';

class SecurityMonitor {
  static final GetStorage _storage = GetStorage();

  /// Get all security violations
  static List<Map<String, dynamic>> getSecurityViolations() {
    final violations = _storage.read<List>('security_violations');
    if (violations == null) return [];
    
    return violations.map((v) => Map<String, dynamic>.from(v)).toList();
  }

  /// Clear all security violations
  static void clearViolations() {
    _storage.remove('security_violations');
  }

  /// Get violations for a specific user
  static List<Map<String, dynamic>> getUserViolations(String userId) {
    final allViolations = getSecurityViolations();
    return allViolations
        .where((v) => v['userId'] == userId)
        .toList();
  }

  /// Get violations count by role
  static Map<String, int> getViolationsByRole() {
    final violations = getSecurityViolations();
    final Map<String, int> counts = {};

    for (var violation in violations) {
      final role = violation['role'] as String? ?? 'unknown';
      counts[role] = (counts[role] ?? 0) + 1;
    }

    return counts;
  }

  /// Get recent violations (last 24 hours)
  static List<Map<String, dynamic>> getRecentViolations() {
    final violations = getSecurityViolations();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));

    return violations.where((v) {
      try {
        final timestamp = DateTime.parse(v['timestamp']);
        return timestamp.isAfter(yesterday);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  /// Check if user has multiple violation attempts (potential attack)
  static bool isPotentialAttack(String userId) {
    final userViolations = getUserViolations(userId);
    
    // If more than 3 violations in last hour, flag as potential attack
    if (userViolations.length < 3) return false;

    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
    final recentViolations = userViolations.where((v) {
      try {
        final timestamp = DateTime.parse(v['timestamp']);
        return timestamp.isAfter(oneHourAgo);
      } catch (e) {
        return false;
      }
    }).toList();

    return recentViolations.length >= 3;
  }

  /// Log custom security event
  static void logSecurityEvent({
    required String eventType,
    required String userId,
    String? details,
  }) {
    final events = _storage.read<List>('security_events') ?? [];
    
    events.add({
      'timestamp': DateTime.now().toIso8601String(),
      'eventType': eventType,
      'userId': userId,
      'details': details,
    });

    // Keep only last 200 events
    if (events.length > 200) {
      events.removeAt(0);
    }

    _storage.write('security_events', events);
    
  }

  /// Get security report
  static Map<String, dynamic> getSecurityReport() {
    final violations = getSecurityViolations();
    final recentViolations = getRecentViolations();
    final violationsByRole = getViolationsByRole();

    return {
      'totalViolations': violations.length,
      'recentViolations': recentViolations.length,
      'violationsByRole': violationsByRole,
      'oldestViolation': violations.isNotEmpty 
          ? violations.first['timestamp'] 
          : null,
      'latestViolation': violations.isNotEmpty 
          ? violations.last['timestamp'] 
          : null,
    };
  }
}