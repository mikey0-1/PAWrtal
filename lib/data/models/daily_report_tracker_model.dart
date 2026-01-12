class UserDailyReportTracker {
  final String userId;
  final int reportCount;
  final DateTime lastResetAt;
  final DateTime lastReportAt;
  
  UserDailyReportTracker({
    required this.userId,
    required this.reportCount,
    required this.lastResetAt,
    required this.lastReportAt,
  });
  
  bool get hasExceededLimit => reportCount >= 3;
  
  int get remainingReports => 3 - reportCount;
  
  Duration get timeUntilReset {
    final nextReset = lastResetAt.add(const Duration(hours: 24));
    return nextReset.difference(DateTime.now());
  }
  
  bool get needsReset {
    final now = DateTime.now();
    final timeSinceReset = now.difference(lastResetAt);
    return timeSinceReset.inHours >= 24;
  }
  
  UserDailyReportTracker reset() {
    return UserDailyReportTracker(
      userId: userId,
      reportCount: 0,
      lastResetAt: DateTime.now(),
      lastReportAt: lastReportAt,
    );
  }
  
  UserDailyReportTracker incrementCount() {
    return UserDailyReportTracker(
      userId: userId,
      reportCount: reportCount + 1,
      lastResetAt: lastResetAt,
      lastReportAt: DateTime.now(),
    );
  }
}