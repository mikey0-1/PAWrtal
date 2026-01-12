enum AppointmentViewMode {
  today('Today'),
  thisWeek('This Week'),
  thisMonth('This Month'),
  allTime('All Time');

  final String label;
  const AppointmentViewMode(this.label);
}