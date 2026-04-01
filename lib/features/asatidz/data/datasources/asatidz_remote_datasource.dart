import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:khoirunnasyien/features/asatidz/data/models/asatidz_attendance_model.dart';
import 'package:khoirunnasyien/features/asatidz/data/models/santri_attendance_model.dart';
import 'package:khoirunnasyien/features/asatidz/data/models/santri_setoran_model.dart';
import 'package:khoirunnasyien/features/asatidz/data/models/meeting_model.dart';
import 'package:khoirunnasyien/features/asatidz/data/models/meeting_member_model.dart';
import 'package:khoirunnasyien/features/asatidz/domain/entities/santri_attendance.dart';

abstract class AsatidzRemoteDataSource {
  Future<bool> checkAttendance({
    required String asatidzId,
    required String halaqahId,
    required String scheduleId,
    required String date,
  });

  Future<AsatidzAttendanceModel> createAttendance({
    required String asatidzId,
    required String asatidzName,
    required String halaqahId,
    required String halaqahName,
    required String scheduleId,
    required String date,
    String? substituteAsatidzId,
    String? substituteAsatidzName,
    String triggeredByRole = 'asatidz',
  });

  Future<MeetingModel?> getMeeting({
    required String halaqahId,
    required String scheduleId,
    required String date,
  });

  Future<List<MeetingMemberModel>> getMeetingMembers(String meetingId);

  Future<void> saveMeetingMembers({
    required String meetingId,
    required List<MeetingMemberModel> members,
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
    String catatan,
  });

  Future<void> updateSetoran({
    required String setoranId,
    required String surah,
    required String catatan,
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
    required String date,
  }) async {
    try {
      final query = await firestore
          .collection('asatidz_attendance')
          .where('asatidz_id', isEqualTo: asatidzId)
          .where('halaqah_id', isEqualTo: halaqahId)
          .where('schedule_id', isEqualTo: scheduleId)
          .where('date', isEqualTo: date)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<AsatidzAttendanceModel> createAttendance({
    required String asatidzId,
    required String asatidzName,
    required String halaqahId,
    required String halaqahName,
    required String scheduleId,
    required String date,
    String? substituteAsatidzId,
    String? substituteAsatidzName,
    String triggeredByRole = 'asatidz',
  }) async {
    final now = DateTime.now();
    final asatidzDocRef = firestore.collection('asatidz_attendance').doc();
    final meetingDocRef = firestore.collection('meetings').doc();
    
    final asatidzModel = AsatidzAttendanceModel(
      id: asatidzDocRef.id,
      asatidzId: asatidzId,
      asatidzName: asatidzName,
      halaqahId: halaqahId,
      halaqahName: halaqahName,
      scheduleId: scheduleId,
      date: date,
      checkInTime: now,
      status: substituteAsatidzId != null ? 'tidak_masuk' : 'hadir',
      notes: '',
      createdAt: now,
      substituteAsatidzId: substituteAsatidzId,
      substituteAsatidzName: substituteAsatidzName,
      triggeredByRole: triggeredByRole,
    );

    final meetingAsatidzId = substituteAsatidzId ?? asatidzId;
    final meetingAsatidzName = substituteAsatidzName ?? asatidzName;

    final meetingModel = MeetingModel(
      id: meetingDocRef.id,
      date: date,
      halaqahId: halaqahId,
      scheduleId: scheduleId,
      asatidzAttendanceId: asatidzDocRef.id,
      asatidzId: meetingAsatidzId,
      asatidzName: meetingAsatidzName,
      createdByRole: triggeredByRole,
      createdAt: now,
    );

    final batch = firestore.batch();
    batch.set(asatidzDocRef, asatidzModel.toFirestore());
    batch.set(meetingDocRef, meetingModel.toFirestore());

    await batch.commit();

    return asatidzModel;
  }

  @override
  Future<MeetingModel?> getMeeting({
    required String halaqahId,
    required String scheduleId,
    required String date,
  }) async {
    final query = await firestore
        .collection('meetings')
        .where('halaqah_id', isEqualTo: halaqahId)
        .where('schedule_id', isEqualTo: scheduleId)
        .where('date', isEqualTo: date)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return MeetingModel.fromFirestore(query.docs.first);
  }

  @override
  Future<List<MeetingMemberModel>> getMeetingMembers(String meetingId) async {
    final query = await firestore
        .collection('meetings')
        .doc(meetingId)
        .collection('members')
        .get();

    return query.docs.map((doc) => MeetingMemberModel.fromFirestore(doc)).toList();
  }

  @override
  Future<void> saveMeetingMembers({
    required String meetingId,
    required List<MeetingMemberModel> members,
  }) async {
    final batch = firestore.batch();
    for (final member in members) {
      final docRef = firestore
          .collection('meetings')
          .doc(meetingId)
          .collection('members')
          .doc(member.id); // member.id is typically santri_id
      batch.set(docRef, member.toFirestore(), SetOptions(merge: true));
    }
    await batch.commit();
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
      final startStr = "${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";
      query = query.where('date', isGreaterThanOrEqualTo: startStr);
    }
    if (endDate != null) {
      final endStr = "${endDate.year.toString().padLeft(4, '0')}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}";
      query = query.where('date', isLessThanOrEqualTo: endStr);
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
    try {
      final now = DateTime.now();
      final totalPresent = attendanceList.where((item) => item.status == 'hadir').length;
      final totalAbsent = attendanceList.length - totalPresent;

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      print('=== CHECKING EXISTING ATTENDANCE ===');
      print('halaqahId: $halaqahId');
      print('scheduleId: $scheduleId');
      print('date: $date');
      print('startOfDay: $startOfDay');
      print('endOfDay: $endOfDay');

      final existingQuery = await firestore
          .collection('santri_attendance')
          .where('halaqah_id', isEqualTo: halaqahId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      print('Found ${existingQuery.docs.length} documents');

      final existingDoc = existingQuery.docs.where((doc) {
        final data = doc.data();
        return data['schedule_id'] == scheduleId;
      }).firstOrNull;

      if (existingDoc != null) {
        print('=== UPDATING EXISTING ATTENDANCE ===');
        final docId = existingDoc.id;
        print('Document ID: $docId');
        
        await firestore.collection('santri_attendance').doc(docId).update({
          'attendance_list': attendanceList.map((item) => {
            'santri_id': item.santriId,
            'santri_name': item.santriName,
            'status': item.status,
          }).toList(),
          'total_present': totalPresent,
          'total_absent': totalAbsent,
          'updated_at': Timestamp.fromDate(now),
        });

        print('=== UPDATE SUCCESS ===');

        final existingModel = SantriAttendanceModel.fromFirestore(existingDoc);
        
        return SantriAttendanceModel(
          id: docId,
          halaqahId: halaqahId,
          halaqahName: halaqahName,
          scheduleId: scheduleId,
          date: date,
          asatidzId: asatidzId,
          asatidzName: asatidzName,
          attendanceList: attendanceList,
          totalPresent: totalPresent,
          totalAbsent: totalAbsent,
          createdAt: existingModel.createdAt,
          updatedAt: now,
        );
      }

      print('=== CREATING NEW ATTENDANCE ===');

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
      
      print('=== CREATE SUCCESS ===');
      print('New Document ID: ${docRef.id}');
      
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
    } catch (e, stackTrace) {
      print('=== FIRESTORE ERROR ===');
      print('Error Type: ${e.runtimeType}');
      print('Error Message: $e');
      print('Stack Trace:');
      print(stackTrace);
      print('=======================');
      rethrow;
    }
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
    String catatan = '',
  }) async {
    final dateStr = "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    
    // Find today's meeting for this halaqah
    final meetingQuery = await firestore
        .collection('meetings')
        .where('halaqah_id', isEqualTo: halaqahId)
        .where('date', isEqualTo: dateStr)
        .limit(1)
        .get();

    if (meetingQuery.docs.isEmpty) {
        throw Exception("Meeting belum dibuat. Asatidz harus absen terlebih dahulu.");
    }
    
    final meetingId = meetingQuery.docs.first.id;
    final now = DateTime.now();

    final memberDocRef = firestore
       .collection('meetings')
       .doc(meetingId)
       .collection('members')
       .doc(santriId);

    final memberDoc = await memberDocRef.get();

    if (memberDoc.exists) {
        await memberDocRef.update({
             'setoran_value': surah,
             'setoran_notes': catatan,
             'updated_at': FieldValue.serverTimestamp(),
        });
    } else {
        await memberDocRef.set({
             'santri_id': santriId,
             'santri_name': santriName,
             'halaqah_asal_id': halaqahId,
             'attendance_status': 'hadir',
             'setoran_value': surah,
             'setoran_notes': catatan,
             'created_at': Timestamp.fromDate(now),
        });
    }

    return SantriSetoranModel(
      id: "${meetingId}___${santriId}",
      santriId: santriId,
      santriName: santriName,
      halaqahId: halaqahId,
      halaqahName: halaqahName,
      asatidzId: asatidzId,
      asatidzName: asatidzName,
      date: date,
      surah: surah,
      catatan: catatan,
      createdAt: now,
    );
  }

  @override
  Future<void> updateSetoran({
    required String setoranId,
    required String surah,
    required String catatan,
  }) async {
    if (!setoranId.contains('___')) return; // Fallback for old data?
    final parts = setoranId.split('___');
    if (parts.length != 2) return;
    
    final meetingId = parts[0];
    final santriId = parts[1];

    await firestore
        .collection('meetings')
        .doc(meetingId)
        .collection('members')
        .doc(santriId)
        .update({
      'setoran_value': surah,
      'setoran_notes': catatan,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<SantriSetoranModel>> getSetoranHistory({
    required String santriId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Query query = firestore
        .collectionGroup('members')
        .where('santri_id', isEqualTo: santriId);

    final snapshot = await query.get();
    
    List<SantriSetoranModel> items = [];
    final meetingCache = <String, Map<String, dynamic>>{};
    final asatidzCache = <String, String>{};
    
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      
      // Filter out those without setoran
      if (data['setoran_value'] == null || (data['setoran_value'] as String).isEmpty) {
        continue;
      }
      
      final createdAt = (data['created_at'] as Timestamp).toDate();
      
      // Apply date filters in memory since collectionGroup orderBy needs an index
      if (startDate != null && createdAt.isBefore(startDate)) continue;
      if (endDate != null && createdAt.isAfter(endDate)) continue;
      
      // Get meeting ID from reference path: meetings/meetingId/members/santriId
      final meetingId = doc.reference.parent.parent?.id ?? '';
      
      String asatidzId = '';
      String asatidzName = '';

      if (meetingId.isNotEmpty) {
        if (!meetingCache.containsKey(meetingId)) {
          final meetingDoc = await firestore.collection('meetings').doc(meetingId).get();
          if (meetingDoc.exists) {
            meetingCache[meetingId] = meetingDoc.data() as Map<String, dynamic>;
          } else {
            meetingCache[meetingId] = {};
          }
        }
        
        final mData = meetingCache[meetingId]!;
        asatidzId = mData['asatidz_id'] ?? '';
        
        if (asatidzId.isNotEmpty) {
          if (!asatidzCache.containsKey(asatidzId)) {
             try {
               final profileDoc = await firestore.collection('asatidz_profiles').doc(asatidzId).get();
               if (profileDoc.exists) {
                 final pData = profileDoc.data() as Map<String, dynamic>;
                 asatidzCache[asatidzId] = pData['name'] ?? mData['asatidz_name'] ?? '';
               } else {
                 asatidzCache[asatidzId] = mData['asatidz_name'] ?? '';
               }
             } catch (_) {
               asatidzCache[asatidzId] = mData['asatidz_name'] ?? '';
             }
          }
          asatidzName = asatidzCache[asatidzId] ?? '';
        }
      }
      
      items.add(SantriSetoranModel(
        id: "${meetingId}___${santriId}",
        santriId: santriId,
        santriName: data['santri_name'] ?? '',
        halaqahId: data['halaqah_asal_id'] ?? '',
        halaqahName: '', 
        asatidzId: asatidzId, 
        asatidzName: asatidzName, 
        date: createdAt,
        surah: data['setoran_value'] ?? '',
        catatan: data['setoran_notes'] ?? '',
        createdAt: createdAt,
      ));
    }
    
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }
}
