import 'package:khoirunnasyien/features/management_schedule/domain/entities/halaqah_santri.dart';

class Halaqah {
  final String id;
  final String programId;
  final String scheduleId;
  final String name;
  final String room;
  final String teacherId;
  final String teacherName;
  final String status;
  final List<HalaqahSantri> santris;

  const Halaqah({
    required this.id,
    required this.programId,
    required this.scheduleId,
    required this.name,
    required this.room,
    required this.teacherId,
    required this.teacherName,
    required this.status,
    required this.santris,
  });
}
