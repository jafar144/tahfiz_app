class MeetingMember {
  final String id;
  final String santriId;
  final String santriName;
  final String halaqahAsalId;
  final String attendanceStatus;
  final String? setoranValue;
  final String? setoranNotes;
  final DateTime createdAt;

  MeetingMember({
    required this.id,
    required this.santriId,
    required this.santriName,
    required this.halaqahAsalId,
    required this.attendanceStatus,
    this.setoranValue,
    this.setoranNotes,
    required this.createdAt,
  });
}
