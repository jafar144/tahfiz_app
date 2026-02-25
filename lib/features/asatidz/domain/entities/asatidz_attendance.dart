class AsatidzAttendance {
  final String id;
  final String asatidzId;
  final String asatidzName;
  final String halaqahId;
  final String halaqahName;
  final String scheduleId;
  final String date;
  final DateTime checkInTime;
  final String status;
  final String notes;
  final DateTime createdAt;
  final String? substituteAsatidzId;
  final String? substituteAsatidzName;
  final String triggeredByRole;

  AsatidzAttendance({
    required this.id,
    required this.asatidzId,
    required this.asatidzName,
    required this.halaqahId,
    required this.halaqahName,
    required this.scheduleId,
    required this.date,
    required this.checkInTime,
    required this.status,
    this.notes = '',
    required this.createdAt,
    this.substituteAsatidzId,
    this.substituteAsatidzName,
    this.triggeredByRole = 'asatidz',
  });
}
