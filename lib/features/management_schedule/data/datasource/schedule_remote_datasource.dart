import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:khoirunnasyien/features/management_schedule/data/models/halaqah_model.dart';
import 'package:khoirunnasyien/features/management_schedule/data/models/program_schedule_model.dart';
import 'package:khoirunnasyien/features/management_schedule/data/models/schedule_program_model.dart';

abstract class ScheduleRemoteDataSource {
  Future<List<ScheduleProgramModel>> getPrograms(String gender);
  Future<List<ProgramScheduleModel>> getSchedules(String programId);
  Future<List<HalaqahModel>> getHalaqahs(String programId);
  Future<void> updateHalaqah(HalaqahModel halaqah);
  Future<void> createHalaqah(HalaqahModel halaqah);
}

class ScheduleRemoteDataSourceImpl implements ScheduleRemoteDataSource {
  final FirebaseFirestore firestore;

  ScheduleRemoteDataSourceImpl(this.firestore);

  @override
  Future<List<ScheduleProgramModel>> getPrograms(String gender) async {
    final query = await firestore
        .collection('sessions')
        .where('tipe', isEqualTo: gender)
        .get();
    
    return query.docs.map((doc) => ScheduleProgramModel.fromFirestore(doc)).toList();
  }

  @override
  Future<List<ProgramScheduleModel>> getSchedules(String programId) async {
    final query = await firestore
        .collection('session_schedules')
        .where('session_id', isEqualTo: programId)
        .get();

    return query.docs.map((doc) => ProgramScheduleModel.fromFirestore(doc)).toList();
  }

  @override
  Future<List<HalaqahModel>> getHalaqahs(String programId) async {
    // Try session_id first
    QuerySnapshot query = await firestore
        .collection('halaqahs')
        .where('session_id', isEqualTo: programId)
        .get();

    // If empty, try schedule_id (alias per user spec)
    if (query.docs.isEmpty) {
      query = await firestore
          .collection('halaqahs')
          .where('schedule_id', isEqualTo: programId)
          .get();
    }

    return query.docs.map((doc) => HalaqahModel.fromFirestore(doc)).toList();
  }

  @override
  Future<void> updateHalaqah(HalaqahModel halaqah) async {
    await firestore.collection('halaqahs').doc(halaqah.id).update({
      'name': halaqah.name,
      'room': halaqah.room,
      'schedule_id': halaqah.scheduleId,
      'status': halaqah.status,
      'asatidz': {
        'id': halaqah.teacherId,
        'name': halaqah.teacherName,
      },
      'santris': halaqah.santris.map((s) => {'id': s.id, 'name': s.name}).toList(),
    });
  }

  @override
  Future<void> createHalaqah(HalaqahModel halaqah) async {
    await firestore.collection('halaqahs').add({
      'name': halaqah.name,
      'room': halaqah.room,
      'schedule_id': halaqah.scheduleId,
      'status': halaqah.status,
      'asatidz': {
        'id': halaqah.teacherId,
        'name': halaqah.teacherName,
      },
      'santris': halaqah.santris.map((s) => {'id': s.id, 'name': s.name}).toList(),
    });
  }
}
