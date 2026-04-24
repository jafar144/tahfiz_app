import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyEntity {
  final String id;
  final List<String> santriIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  FamilyEntity({
    required this.id,
    required this.santriIds,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FamilyEntity.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FamilyEntity(
      id: doc.id,
      santriIds: List<String>.from(data['santri_ids'] ?? []),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class FamilyRepository {
  final FirebaseFirestore _firestore;

  FamilyRepository(this._firestore);

  CollectionReference get _collection => _firestore.collection('families');

  Future<List<FamilyEntity>> getFamilies() async {
    final snap = await _collection.orderBy('created_at', descending: true).get();
    return snap.docs.map((doc) => FamilyEntity.fromDoc(doc)).toList();
  }

  Future<void> addFamily(List<String> santriIds) async {
    await _collection.add({
      'santri_ids': santriIds,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateFamily(String id, List<String> santriIds) async {
    await _collection.doc(id).update({
      'santri_ids': santriIds,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteFamily(String id) async {
    await _collection.doc(id).delete();
  }

  Future<FamilyEntity?> getFamilyBySantriId(String santriId) async {
    final snap = await _collection
        .where('santri_ids', arrayContains: santriId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return FamilyEntity.fromDoc(snap.docs.first);
  }

  Future<Set<String>> getAllFamilySantriIds() async {
    final snap = await _collection.get();
    final ids = <String>{};
    for (final doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      ids.addAll(List<String>.from(data['santri_ids'] ?? []));
    }
    return ids;
  }
}
