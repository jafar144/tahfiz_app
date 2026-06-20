import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory KelulusanEntity.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
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

  KelulusanRepository(this._firestore);

  CollectionReference get _collection => _firestore.collection('kelulusan');

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

  /// Hanya entri dalam 7 hari terakhir (kadaluwarsa setelah itu).
  Future<List<KelulusanEntity>> getKelulusan({int limit = 20}) async {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final snap = await _collection
        .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
        .orderBy('created_at', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => KelulusanEntity.fromDoc(d)).toList();
  }
}
