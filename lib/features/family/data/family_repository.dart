import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:khoirunnasyien/features/family/domain/entities/family_account.dart';

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
  final FirebaseFunctions _functions;

  FamilyRepository(this._firestore, this._functions);

  CollectionReference get _collection => _firestore.collection('families');

  Future<List<FamilyEntity>> getFamilies() async {
    final snap = await _collection
        .orderBy('created_at', descending: true)
        .get();
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

  /// Mengambil profil minimum anggota keluarga melalui server. Callable
  /// memverifikasi bahwa pengguna aktif benar-benar anggota keluarga tersebut,
  /// sehingga profil santri lain tidak perlu dibuka lewat Firestore rules.
  Future<List<FamilyAccount>> getFamilyAccounts() async {
    final result = await _functions.httpsCallable('getFamilyAccounts').call();
    final data = Map<Object?, Object?>.from(result.data as Map);
    final accounts = data['accounts'];
    if (accounts is! List) {
      throw const FormatException('Respons akun keluarga tidak valid.');
    }

    return accounts
        .whereType<Map>()
        .map((item) => FamilyAccount.fromMap(Map<Object?, Object?>.from(item)))
        .where((account) => account.id.isNotEmpty)
        .toList(growable: false);
  }

  /// Meminta token Firebase untuk berpindah ke akun santri lain yang telah
  /// diverifikasi server sebagai anggota keluarga yang sama.
  Future<String> createSwitchToken(String targetSantriId) async {
    final result = await _functions.httpsCallable('switchFamilyAccount').call(
      <String, dynamic>{'targetSantriId': targetSantriId},
    );
    final data = Map<Object?, Object?>.from(result.data as Map);
    final token = data['customToken']?.toString().trim() ?? '';
    if (token.isEmpty) {
      throw const FormatException('Token ganti akun tidak tersedia.');
    }
    return token;
  }
}
