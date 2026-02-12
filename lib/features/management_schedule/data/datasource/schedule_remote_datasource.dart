import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:khoirunnasyien/features/management_schedule/data/models/halaqah_model.dart';
import 'package:khoirunnasyien/features/management_schedule/data/models/program_schedule_model.dart';
import 'package:khoirunnasyien/features/management_schedule/data/models/schedule_program_model.dart';

abstract class ScheduleRemoteDataSource {
  Future<List<ScheduleProgramModel>> getPrograms(String gender);
  Future<List<ProgramScheduleModel>> getSchedules(String programId);
  Future<ProgramScheduleModel> getScheduleById(String scheduleId);
  Future<List<HalaqahModel>> getHalaqahs(String programId);
  Future<List<HalaqahModel>> getHalaqahsBySchedule(String scheduleId);
  Future<List<HalaqahModel>> getHalaqahsByTeacher(String teacherId);
  Future<void> updateHalaqah(HalaqahModel halaqah);
  Future<void> createHalaqah(HalaqahModel halaqah);
  Future<HalaqahModel?> getHalaqahBySantriId(String santriId);
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
  Future<List<HalaqahModel>> getHalaqahsBySchedule(String scheduleId) async {
    final query = await firestore
        .collection('halaqahs')
        .where('schedule_ids', arrayContains: scheduleId)
        .get();
        
    return query.docs.map((doc) => HalaqahModel.fromFirestore(doc)).toList();
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
      'schedule_ids': halaqah.scheduleIds,
      'status': halaqah.status,
      'asatidz': {
        'id': halaqah.teacherId,
        'name': halaqah.teacherName,
      },
      'santris': halaqah.santris.map((s) => {'id': s.id, 'name': s.name, 'nis': s.nis}).toList(),
    });
  }

  @override
  Future<void> createHalaqah(HalaqahModel halaqah) async {
    await firestore.collection('halaqahs').add({
      'name': halaqah.name,
      'room': halaqah.room,
      'schedule_ids': halaqah.scheduleIds,
      'session_id': halaqah.programId,
      'status': halaqah.status,
      'asatidz': {
        'id': halaqah.teacherId,
        'name': halaqah.teacherName,
      },
      'santris': halaqah.santris.map((s) => {'id': s.id, 'name': s.name, 'nis': s.nis}).toList(),
    });
  }

  @override
  Future<ProgramScheduleModel> getScheduleById(String scheduleId) async {
    final doc = await firestore.collection('session_schedules').doc(scheduleId).get();
    
    if (!doc.exists) {
      throw Exception('Schedule not found');
    }
    
    return ProgramScheduleModel.fromFirestore(doc);
  }

  @override
  Future<List<HalaqahModel>> getHalaqahsByTeacher(String teacherId) async {
    final query = await firestore
        .collection('halaqahs')
        .where('asatidz.id', isEqualTo: teacherId)
        .get();
        
    return query.docs.map((doc) => HalaqahModel.fromFirestore(doc)).toList();
  }

  @override
  Future<HalaqahModel?> getHalaqahBySantriId(String santriId) async {
    // Note: iterating all halaqahs is not scalable for very large datasets,
    // but without santris_ids array field, this is the only way.
    final query = await firestore.collection('halaqahs').get();
    
    for (var doc in query.docs) {
      final data = doc.data();
      if (data['santris'] != null && data['santris'] is List) {
        final santris =List.from(data['santris']);
        final found = santris.any((s) => s is Map && s['id'] == santriId);
        if (found) {
          return HalaqahModel.fromFirestore(doc);
        }
      }
    }
    return null;
  }
}
