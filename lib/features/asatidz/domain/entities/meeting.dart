class Meeting {
  final String id;
  final String date;
  final String halaqahId;
  final String scheduleId;
  final String asatidzAttendanceId;
  final String asatidzId;
  final String asatidzName;
  final String createdByRole;
  final DateTime createdAt;

  Meeting({
    required this.id,
    required this.date,
    required this.halaqahId,
    required this.scheduleId,
    required this.asatidzAttendanceId,
    required this.asatidzId,
    required this.asatidzName,
    this.createdByRole = 'asatidz',
    required this.createdAt,
  });
}
