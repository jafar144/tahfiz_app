import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Satu entri kelulusan/wisuda santri yang tampil di carousel Home santri.
class KelulusanEntity {
  final String id;
  final String santriId;
  final String santriName;
  final String kelas;
  final String hafalan;
  final String imageUrl;
  final DateTime createdAt;

  KelulusanEntity({
    required this.id,
    required this.santriId,
    required this.santriName,
    required this.kelas,
    required this.hafalan,
    required this.imageUrl,
    required this.createdAt,
  });

  factory KelulusanEntity.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return KelulusanEntity(
      id: doc.id,
      santriId: data['santri_id'] ?? '',
      santriName: data['santri_name'] ?? '',
      kelas: data['kelas'] ?? '',
      hafalan: data['hafalan'] ?? '',
      imageUrl: data['image_url'] ?? '',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class KelulusanRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  KelulusanRepository(this._firestore, this._functions);

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('kelulusan');

  Future<void> addKelulusan({
    required String santriId,
    required String santriName,
    required String kelas,
    required String hafalan,
    required String imageUrl,
  }) async {
    await _collection.add({
      'santri_id': santriId,
      'santri_name': santriName,
      'kelas': kelas,
      'hafalan': hafalan,
      'image_url': imageUrl,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Query<Map<String, dynamic>> _query({
    required int limit,
    required bool activeOnly,
  }) {
    Query<Map<String, dynamic>> query = _collection;
    if (activeOnly) {
      final cutoff = DateTime.now().subtract(const Duration(days: 7));
      query = query.where(
        'created_at',
        isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff),
      );
    }
    return query.orderBy('created_at', descending: true).limit(limit);
  }

  /// [activeOnly] mengikuti batas tampil Home Santri, yaitu tujuh hari.
  Future<List<KelulusanEntity>> getKelulusan({
    int limit = 20,
    bool activeOnly = true,
  }) async {
    final snap = await _query(limit: limit, activeOnly: activeOnly).get();
    return snap.docs.map((d) => KelulusanEntity.fromDoc(d)).toList();
  }

  Stream<List<KelulusanEntity>> watchKelulusan({
    int limit = 20,
    bool activeOnly = true,
  }) {
    return _query(limit: limit, activeOnly: activeOnly).snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => KelulusanEntity.fromDoc(doc)).toList(),
    );
  }

  Future<void> deleteKelulusan(String id) async {
    await _functions.httpsCallable('deleteKelulusanPhoto').call({'id': id});
  }
}
