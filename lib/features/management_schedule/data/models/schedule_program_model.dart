import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/schedule_program.dart';

class ScheduleProgramModel extends ScheduleProgram {
  const ScheduleProgramModel({
    required super.id,
    required super.name,
    required super.gender,
  });

  factory ScheduleProgramModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ScheduleProgramModel(
      id: doc.id,
      name: data['waktu'] ?? '',
      gender: data['tipe'] ?? '',
    );
  }
}
