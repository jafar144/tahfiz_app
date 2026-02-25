class Halaqah {
  final String id;
  final String programId;
  final List<String> scheduleIds;
  final String name;
  final String room;
  final String teacherId;
  final String teacherName;
  final String status;
  final int santriCount;

  const Halaqah({
    required this.id,
    required this.programId,
    required this.scheduleIds,
    required this.name,
    required this.room,
    required this.teacherId,
    required this.teacherName,
    required this.status,
    this.santriCount = 0,
  });
}
