import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/program_schedule.dart';

class ProgramScheduleModel extends ProgramSchedule {
  const ProgramScheduleModel({
    required super.id,
    required super.programId,
    required super.day,
    required super.startTime,
    required super.endTime,
  });

  factory ProgramScheduleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProgramScheduleModel(
      id: doc.id,
      programId: data['session_id'] ?? '',
      day: _parseDay(data['hari']),
      startTime: data['jam_mulai'] ?? '',
      endTime: data['jam_selesai'] ?? '',
    );
  }

  static int _parseDay(String day) {
    return int.tryParse(day) ?? 1;
  }
}

