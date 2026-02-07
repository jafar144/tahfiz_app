class ProgramSchedule {
  final String id;
  final String programId;
  final int day; // 1 = Mondays, etc.
  final String startTime;
  final String endTime;

  const ProgramSchedule({
    required this.id,
    required this.programId,
    required this.day,
    required this.startTime,
    required this.endTime,
  });
}
