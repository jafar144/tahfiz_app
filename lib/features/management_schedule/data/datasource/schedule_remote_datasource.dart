import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_schedule/data/models/halaqah_model.dart';
import 'package:khoirunnasyien/features/management_schedule/data/models/program_schedule_model.dart';
import 'package:khoirunnasyien/features/management_schedule/data/models/schedule_program_model.dart';

abstract class ScheduleRemoteDataSource {
  Future<List<ScheduleProgramModel>> getPrograms(String gender);
  Future<List<ProgramScheduleModel>> getSchedules(String programId);
  Future<ProgramScheduleModel> getScheduleById(String scheduleId);
  Future<ScheduleProgramModel> getProgramById(String programId);
  Future<List<HalaqahModel>> getHalaqahs(String programId);
  Future<List<HalaqahModel>> getHalaqahsBySchedule(String scheduleId);
  Future<List<HalaqahModel>> getHalaqahsByTeacher(String teacherId);
  Future<List<HalaqahModel>> getAllHalaqahs();
  Future<void> updateHalaqah(
    HalaqahModel halaqah,
    List<String> newSantriIds,
    List<String> removedSantriIds,
  );
  Future<void> createHalaqah(HalaqahModel halaqah, List<String> santriIds);
  Future<void> deleteHalaqah(String halaqahId);
  Future<HalaqahModel?> getHalaqahBySantriId(String santriId);
  Future<void> removeSantriFromHalaqah(String santriId);
  Future<void> moveSantriToHalaqah(
    String santriId,
    String newHalaqahId, {
    String? newSession,
  });
  Future<List<SantriEntity>> getSantrisByHalaqahId(String halaqahId);
  Future<void> migrateHalaqahIds();
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
    return query.docs
        .map((doc) => ScheduleProgramModel.fromFirestore(doc))
        .toList();
  }

  @override
  Future<ScheduleProgramModel> getProgramById(String programId) async {
    final doc = await firestore.collection('sessions').doc(programId).get();
    if (!doc.exists) throw Exception('Program tidak ditemukan');
    return ScheduleProgramModel.fromFirestore(doc);
  }

  @override
  Future<List<HalaqahModel>> getHalaqahsBySchedule(String scheduleId) async {
    final query = await firestore
        .collection('halaqahs')
        .where('schedule_ids', arrayContains: scheduleId)
        .get();
    return _getHalaqahsWithCount(query.docs);
  }

  @override
  Future<List<ProgramScheduleModel>> getSchedules(String programId) async {
    final query = await firestore
        .collection('session_schedules')
        .where('session_id', isEqualTo: programId)
        .get();
    return query.docs
        .map((doc) => ProgramScheduleModel.fromFirestore(doc))
        .toList();
  }

  @override
  Future<List<HalaqahModel>> getHalaqahs(String programId) async {
    QuerySnapshot query = await firestore
        .collection('halaqahs')
        .where('session_id', isEqualTo: programId)
        .get();

    if (query.docs.isEmpty) {
      query = await firestore
          .collection('halaqahs')
          .where('schedule_id', isEqualTo: programId)
          .get();
    }
    return _getHalaqahsWithCount(query.docs);
  }

  @override
  Future<void> updateHalaqah(
    HalaqahModel halaqah,
    List<String> newSantriIds,
    List<String> removedSantriIds,
  ) async {
    final batch = firestore.batch();

    final halaqahRef = firestore.collection('halaqahs').doc(halaqah.id);
    batch.update(halaqahRef, {
      'name': halaqah.name,
      'room': halaqah.room,
      'schedule_ids': halaqah.scheduleIds,
      'status': halaqah.status,
      'asatidz': {'id': halaqah.teacherId, 'name': halaqah.teacherName},
      'santri_count': newSantriIds.length,
    });

    for (final santriId in newSantriIds) {
      final santriRef = firestore.collection('santri_profiles').doc(santriId);
      batch.update(santriRef, {'halaqah_id': halaqah.id});
    }

    for (final santriId in removedSantriIds) {
      final santriRef = firestore.collection('santri_profiles').doc(santriId);
      batch.update(santriRef, {'halaqah_id': FieldValue.delete()});
    }

    await batch.commit();
  }

  @override
  Future<void> createHalaqah(
    HalaqahModel halaqah,
    List<String> santriIds,
  ) async {
    final docRef = firestore.collection('halaqahs').doc();
    final halaqahId = docRef.id;

    final batch = firestore.batch();

    batch.set(docRef, {
      'name': halaqah.name,
      'room': halaqah.room,
      'schedule_ids': halaqah.scheduleIds,
      'session_id': halaqah.programId,
      'status': halaqah.status,
      'asatidz': {'id': halaqah.teacherId, 'name': halaqah.teacherName},
      'santri_count': santriIds.length,
    });

    for (final santriId in santriIds) {
      final santriRef = firestore.collection('santri_profiles').doc(santriId);
      batch.update(santriRef, {'halaqah_id': halaqahId});
    }

    await batch.commit();
  }

  @override
  Future<void> deleteHalaqah(String halaqahId) async {
    // Lepaskan semua santri dari halaqah ini, lalu hapus dokumen halaqah-nya.
    final santriSnapshot = await firestore
        .collection('santri_profiles')
        .where('halaqah_id', isEqualTo: halaqahId)
        .get();

    final batch = firestore.batch();
    for (final doc in santriSnapshot.docs) {
      batch.update(doc.reference, {'halaqah_id': FieldValue.delete()});
    }
    batch.delete(firestore.collection('halaqahs').doc(halaqahId));
    await batch.commit();
  }

  @override
  Future<ProgramScheduleModel> getScheduleById(String scheduleId) async {
    final doc = await firestore
        .collection('session_schedules')
        .doc(scheduleId)
        .get();
    if (!doc.exists) throw Exception('Jadwal tidak ditemukan');
    return ProgramScheduleModel.fromFirestore(doc);
  }

  @override
  Future<List<HalaqahModel>> getHalaqahsByTeacher(String teacherId) async {
    final query = await firestore
        .collection('halaqahs')
        .where('asatidz.id', isEqualTo: teacherId)
        .get();
    return _getHalaqahsWithCount(query.docs);
  }

  @override
  Future<List<HalaqahModel>> getAllHalaqahs() async {
    final query = await firestore.collection('halaqahs').get();
    return query.docs.map((doc) => HalaqahModel.fromFirestore(doc)).toList();
  }

  @override
  Future<HalaqahModel?> getHalaqahBySantriId(String santriId) async {
    final santriDoc = await firestore
        .collection('santri_profiles')
        .doc(santriId)
        .get();
    if (!santriDoc.exists) return null;

    final halaqahId = santriDoc.data()?['halaqah_id'] as String?;
    if (halaqahId == null || halaqahId.isEmpty) return null;

    final halaqahDoc = await firestore
        .collection('halaqahs')
        .doc(halaqahId)
        .get();
    if (!halaqahDoc.exists) return null;

    final halaqah = HalaqahModel.fromFirestore(halaqahDoc);
    final countQuery = await firestore
        .collection('santri_profiles')
        .where('halaqah_id', isEqualTo: halaqah.id)
        .count()
        .get();

    return HalaqahModel(
      id: halaqah.id,
      programId: halaqah.programId,
      scheduleIds: halaqah.scheduleIds,
      name: halaqah.name,
      room: halaqah.room,
      teacherId: halaqah.teacherId,
      teacherName: halaqah.teacherName,
      status: halaqah.status,
      santriCount: countQuery.count ?? 0,
    );
  }

  @override
  Future<void> removeSantriFromHalaqah(String santriId) async {
    final santriRef = firestore.collection('santri_profiles').doc(santriId);
    final santriDoc = await santriRef.get();
    if (!santriDoc.exists) return;

    final halaqahId = santriDoc.data()?['halaqah_id'] as String?;
    if (halaqahId == null || halaqahId.isEmpty) return;

    final batch = firestore.batch();
    batch.update(santriRef, {'halaqah_id': FieldValue.delete()});
    batch.update(firestore.collection('halaqahs').doc(halaqahId), {
      'santri_count': FieldValue.increment(-1),
    });
    await batch.commit();
  }

  @override
  Future<void> moveSantriToHalaqah(
    String santriId,
    String newHalaqahId, {
    String? newSession,
  }) async {
    final santriRef = firestore.collection('santri_profiles').doc(santriId);
    final santriDoc = await santriRef.get();
    if (!santriDoc.exists) throw Exception('Santri tidak ditemukan');

    final oldHalaqahId = santriDoc.data()?['halaqah_id'] as String?;
    if (oldHalaqahId == newHalaqahId) return; // tidak ada perpindahan

    final batch = firestore.batch();

    // Pindahkan santri ke halaqah baru. Sekalian samakan tipe_kelas (sesi)
    // dengan sesi halaqah barunya agar data tidak basi.
    final santriUpdate = <String, dynamic>{'halaqah_id': newHalaqahId};
    if (newSession != null && newSession.isNotEmpty) {
      santriUpdate['tipe_kelas'] = newSession;
    }
    batch.update(santriRef, santriUpdate);

    if (oldHalaqahId != null && oldHalaqahId.isNotEmpty) {
      batch.update(firestore.collection('halaqahs').doc(oldHalaqahId), {
        'santri_count': FieldValue.increment(-1),
      });
    }
    batch.update(firestore.collection('halaqahs').doc(newHalaqahId), {
      'santri_count': FieldValue.increment(1),
    });

    await batch.commit();
  }

  @override
  Future<List<SantriEntity>> getSantrisByHalaqahId(String halaqahId) async {
    final snapshot = await firestore
        .collection('santri_profiles')
        .where('halaqah_id', isEqualTo: halaqahId)
        .get();

    final now = DateTime.now();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      final freeUntil = (data['free_until'] as Timestamp?)?.toDate();
      return SantriEntity(
        id: doc.id,
        name: data['name'] ?? '',
        nis: data['nis'] ?? '',
        kelas: data['kelas'] ?? '',
        kelasFiqih: (data['kelas_fiqih'] as String?)?.trim(),
        jenisKelamin: data['jenis_kelamin'] ?? '',
        isActive: data['is_active'] ?? true,
        isFree: freeUntil != null && freeUntil.isAfter(now),
        freeUntil: freeUntil,
        nomorWali: data['nomor_wali'],
        tipeKelas: data['tipe_kelas'],
        halaqahId: halaqahId,
        tanggalMasuk: (data['tanggal_masuk'] as Timestamp?)?.toDate(),
      );
    }).toList();
  }

  @override
  Future<void> migrateHalaqahIds() async {
    final halaqahsSnapshot = await firestore.collection('halaqahs').get();

    for (final halaqahDoc in halaqahsSnapshot.docs) {
      final data = halaqahDoc.data();
      final halaqahId = halaqahDoc.id;

      if (data['santris'] == null || data['santris'] is! List) continue;

      final santrisList = List.from(data['santris'] as List);
      if (santrisList.isEmpty) continue;

      final batch = firestore.batch();
      for (final item in santrisList) {
        if (item is! Map || item['id'] == null) continue;
        final santriId = item['id'].toString();
        final santriRef = firestore.collection('santri_profiles').doc(santriId);
        batch.update(santriRef, {'halaqah_id': halaqahId});
      }
      await batch.commit();
    }
  }

  Future<List<HalaqahModel>> _getHalaqahsWithCount(
    List<DocumentSnapshot> docs,
  ) async {
    final futures = docs.map((doc) async {
      final halaqah = HalaqahModel.fromFirestore(doc);
      final countQuery = await firestore
          .collection('santri_profiles')
          .where('halaqah_id', isEqualTo: halaqah.id)
          .count()
          .get();
      return HalaqahModel(
        id: halaqah.id,
        programId: halaqah.programId,
        scheduleIds: halaqah.scheduleIds,
        name: halaqah.name,
        room: halaqah.room,
        teacherId: halaqah.teacherId,
        teacherName: halaqah.teacherName,
        status: halaqah.status,
        santriCount: countQuery.count ?? 0,
      );
    });
    return Future.wait(futures);
  }
}
