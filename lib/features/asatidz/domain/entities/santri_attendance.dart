class SantriAttendanceItem {
  final String santriId;
  final String santriName;
  final String status;
  final String notes;

  SantriAttendanceItem({
    required this.santriId,
    required this.santriName,
    required this.status,
    this.notes = '',
  });
}

class SantriAttendance {
  final String id;
  final String halaqahId;
  final String halaqahName;
  final String scheduleId;
  final DateTime date;
  final String asatidzId;
  final String asatidzName;
  final List<SantriAttendanceItem> attendanceList;
  final int totalPresent;
  final int totalAbsent;
  final DateTime createdAt;
  final DateTime updatedAt;

  SantriAttendance({
    required this.id,
    required this.halaqahId,
    required this.halaqahName,
    required this.scheduleId,
    required this.date,
    required this.asatidzId,
    required this.asatidzName,
    required this.attendanceList,
    required this.totalPresent,
    required this.totalAbsent,
    required this.createdAt,
    required this.updatedAt,
  });
}
