import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:khoirunnasyien/features/asatidz/data/models/asatidz_attendance_model.dart';
import 'package:khoirunnasyien/features/asatidz/data/models/santri_attendance_model.dart';
import 'package:khoirunnasyien/features/asatidz/data/models/santri_setoran_model.dart';
import 'package:khoirunnasyien/features/asatidz/domain/entities/santri_attendance.dart';

abstract class AsatidzRemoteDataSource {
  Future<bool> checkAttendance({
    required String asatidzId,
    required String halaqahId,
    required String scheduleId,
    required DateTime date,
  });

  Future<AsatidzAttendanceModel> createAttendance({
    required String asatidzId,
    required String asatidzName,
    required String halaqahId,
    required String halaqahName,
    required String scheduleId,
    required DateTime date,
  });

  Future<List<AsatidzAttendanceModel>> getAttendanceHistory({
    required String asatidzId,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<SantriAttendanceModel> createSantriAttendance({
    required String halaqahId,
    required String halaqahName,
    required String scheduleId,
    required DateTime date,
    required String asatidzId,
    required String asatidzName,
    required List<SantriAttendanceItem> attendanceList,
  });

  Future<SantriAttendanceModel?> getSantriAttendance({
    required String halaqahId,
    required DateTime date,
  });

  Future<SantriSetoranModel> createSetoran({
    required String santriId,
    required String santriName,
    required String halaqahId,
    required String halaqahName,
    required String asatidzId,
    required String asatidzName,
    required DateTime date,
    required String surah,
    required int ayatAwal,
    required int ayatAkhir,
    required String kualitasHafalan,
    String catatan,
  });

  Future<List<SantriSetoranModel>> getSetoranHistory({
    required String santriId,
    DateTime? startDate,
    DateTime? endDate,
  });
}

class AsatidzRemoteDataSourceImpl implements AsatidzRemoteDataSource {
  final FirebaseFirestore firestore;

  AsatidzRemoteDataSourceImpl({required this.firestore});

  @override
  Future<bool> checkAttendance({
    required String asatidzId,
    required String halaqahId,
    required String scheduleId,
    required DateTime date,
  }) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final query = await firestore
        .collection('asatidz_attendance')
        .where('asatidz_id', isEqualTo: asatidzId)
        .where('halaqah_id', isEqualTo: halaqahId)
        .where('schedule_id', isEqualTo: scheduleId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }

  @override
  Future<AsatidzAttendanceModel> createAttendance({
    required String asatidzId,
    required String asatidzName,
    required String halaqahId,
    required String halaqahName,
    required String scheduleId,
    required DateTime date,
  }) async {
    final now = DateTime.now();
    final model = AsatidzAttendanceModel(
      id: '',
      asatidzId: asatidzId,
      asatidzName: asatidzName,
      halaqahId: halaqahId,
      halaqahName: halaqahName,
      scheduleId: scheduleId,
      date: date,
      checkInTime: now,
      status: 'hadir',
      notes: '',
      createdAt: now,
    );

    final docRef = await firestore.collection('asatidz_attendance').add(model.toFirestore());
    
    return AsatidzAttendanceModel(
      id: docRef.id,
      asatidzId: asatidzId,
      asatidzName: asatidzName,
      halaqahId: halaqahId,
      halaqahName: halaqahName,
      scheduleId: scheduleId,
      date: date,
      checkInTime: now,
      status: 'hadir',
      notes: '',
      createdAt: now,
    );
  }

  @override
  Future<List<AsatidzAttendanceModel>> getAttendanceHistory({
    required String asatidzId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Query query = firestore
        .collection('asatidz_attendance')
        .where('asatidz_id', isEqualTo: asatidzId)
        .orderBy('date', descending: true);

    if (startDate != null) {
      query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => AsatidzAttendanceModel.fromFirestore(doc)).toList();
  }

  @override
  Future<SantriAttendanceModel> createSantriAttendance({
    required String halaqahId,
    required String halaqahName,
    required String scheduleId,
    required DateTime date,
    required String asatidzId,
    required String asatidzName,
    required List<SantriAttendanceItem> attendanceList,
  }) async {
    final now = DateTime.now();
    final totalPresent = attendanceList.where((item) => item.status == 'hadir').length;
    final totalAbsent = attendanceList.length - totalPresent;

    final model = SantriAttendanceModel(
      id: '',
      halaqahId: halaqahId,
      halaqahName: halaqahName,
      scheduleId: scheduleId,
      date: date,
      asatidzId: asatidzId,
      asatidzName: asatidzName,
      attendanceList: attendanceList,
      totalPresent: totalPresent,
      totalAbsent: totalAbsent,
      createdAt: now,
      updatedAt: now,
    );

    final docRef = await firestore.collection('santri_attendance').add(model.toFirestore());
    
    return SantriAttendanceModel(
      id: docRef.id,
      halaqahId: halaqahId,
      halaqahName: halaqahName,
      scheduleId: scheduleId,
      date: date,
      asatidzId: asatidzId,
      asatidzName: asatidzName,
      attendanceList: attendanceList,
      totalPresent: totalPresent,
      totalAbsent: totalAbsent,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<SantriAttendanceModel?> getSantriAttendance({
    required String halaqahId,
    required DateTime date,
  }) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final query = await firestore
        .collection('santri_attendance')
        .where('halaqah_id', isEqualTo: halaqahId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return SantriAttendanceModel.fromFirestore(query.docs.first);
  }

  @override
  Future<SantriSetoranModel> createSetoran({
    required String santriId,
    required String santriName,
    required String halaqahId,
    required String halaqahName,
    required String asatidzId,
    required String asatidzName,
    required DateTime date,
    required String surah,
    required int ayatAwal,
    required int ayatAkhir,
    required String kualitasHafalan,
    String catatan = '',
  }) async {
    final now = DateTime.now();
    final model = SantriSetoranModel(
      id: '',
      santriId: santriId,
      santriName: santriName,
      halaqahId: halaqahId,
      halaqahName: halaqahName,
      asatidzId: asatidzId,
      asatidzName: asatidzName,
      date: date,
      surah: surah,
      ayatAwal: ayatAwal,
      ayatAkhir: ayatAkhir,
      kualitasHafalan: kualitasHafalan,
      catatan: catatan,
      createdAt: now,
    );

    final docRef = await firestore.collection('santri_setoran').add(model.toFirestore());
    
    return SantriSetoranModel(
      id: docRef.id,
      santriId: santriId,
      santriName: santriName,
      halaqahId: halaqahId,
      halaqahName: halaqahName,
      asatidzId: asatidzId,
      asatidzName: asatidzName,
      date: date,
      surah: surah,
      ayatAwal: ayatAwal,
      ayatAkhir: ayatAkhir,
      kualitasHafalan: kualitasHafalan,
      catatan: catatan,
      createdAt: now,
    );
  }

  @override
  Future<List<SantriSetoranModel>> getSetoranHistory({
    required String santriId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Query query = firestore
        .collection('santri_setoran')
        .where('santri_id', isEqualTo: santriId)
        .orderBy('date', descending: true);

    if (startDate != null) {
      query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => SantriSetoranModel.fromFirestore(doc)).toList();
  }
}
