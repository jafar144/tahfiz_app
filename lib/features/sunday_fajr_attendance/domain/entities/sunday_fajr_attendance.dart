class SundayFajrAttendance {
  const SundayFajrAttendance({
    required this.id,
    required this.weekKey,
    required this.eventDate,
    required this.participantCount,
    required this.totalHadir,
    required this.totalIzin,
    required this.totalAlpha,
    required this.revision,
    required this.schemaVersion,
    required this.createdBy,
    required this.createdAt,
    required this.updatedBy,
    required this.updatedAt,
  });

  final String id;
  final String weekKey;
  final DateTime eventDate;
  final int participantCount;
  final int totalHadir;
  final int totalIzin;
  final int totalAlpha;
  final int revision;
  final int schemaVersion;
  final String createdBy;
  final DateTime createdAt;
  final String updatedBy;
  final DateTime updatedAt;

  int get recordedCount => totalHadir + totalIzin + totalAlpha;
}
