import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:khoirunnasyien/features/management_asatidz/data/datasource/asatidz_remote_datasource.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_detail.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_entity.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_params.dart';

class AsatidzRemoteDataSourceImpl implements AsatidzRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseFunctions functions;

  AsatidzRemoteDataSourceImpl(this.firestore, this.functions);

  @override
  Future<List<AsatidzEntity>> getAsatidzList({
    String? keyword,
    bool? isActive,
    String? gender,
    int limit = 10,
    String? lastDocumentId,
  }) async {
    Query query = firestore.collection('asatidz_profiles');

    if (isActive != null) {
      query = query.where('is_active', isEqualTo: isActive);
    }

    if (gender != null) {
      query = query.where('jenis_kelamin', isEqualTo: gender);
    }

    bool isSearching = keyword != null && keyword.isNotEmpty;

    if (!isSearching) {
      query = query.limit(limit);
      if (lastDocumentId != null) {
        final lastDoc = await firestore
            .collection('asatidz_profiles')
            .doc(lastDocumentId)
            .get();
        if (lastDoc.exists) {
          query = query.startAfterDocument(lastDoc);
        }
      }
    }

    final snapshot = await query.get();

    var docs = snapshot.docs;

    if (keyword != null && keyword.isNotEmpty) {
      final k = keyword.toLowerCase();
      docs = docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final name = (data['name'] ?? '').toString().toLowerCase();
        final nis = (data['nis'] ?? '').toString().toLowerCase();
        return name.contains(k) || nis.contains(k);
      }).toList();
    }

    return docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;

      return AsatidzEntity(
        id: doc.id,
        name: data['name'] ?? '',
        nis: data['nis'] ?? '',
        jenisKelamin: data['jenis_kelamin'] ?? '',
        isActive: data['is_active'] ?? true,
        photoUrl: data['photo_url'],
      );
    }).toList();
  }

  @override
  Future<AsatidzDetail> getAsatidzDetail(String id) async {
    final doc = await firestore.collection('asatidz_profiles').doc(id).get();
    final userDoc = await firestore.collection('users').doc(id).get();

    if (!doc.exists) {
      throw Exception('Data Asatidz tidak ditemukan');
    }

    final data = doc.data() as Map<String, dynamic>;
    final userData = userDoc.exists
        ? userDoc.data() as Map<String, dynamic>
        : <String, dynamic>{};

    return AsatidzDetail(
      id: doc.id,
      name: data['name'] ?? '',
      nis: data['nis'] ?? '',
      jenisKelamin: data['jenis_kelamin'] ?? '',
      isActive: data['is_active'] ?? true,
      phone: userData['phone'] ?? '',
      photoUrl: data['photo_url'] ?? userData['photo_url'],
    );
  }

  @override
  Future<String> addAsatidz(AsatidzParams params) async {
    final result = await functions
        .httpsCallable('provisionInstitutionUser')
        .call(<String, dynamic>{
          'role': 'asatidz',
          'name': params.name,
          'nis': params.nis,
          'phone': params.phone,
          'jenisKelamin': params.jenisKelamin,
          'isActive': params.isActive,
          if (params.photoUrl != null) 'photoUrl': params.photoUrl,
        });
    final data = Map<String, dynamic>.from(result.data as Map);
    final password = (data['temporaryPassword'] as String?)?.trim() ?? '';
    if (password.isEmpty) {
      throw StateError('Server tidak mengembalikan password sementara.');
    }
    return password;
  }

  @override
  Future<void> updateAsatidz(String id, AsatidzParams params) async {
    final Object? photoUpdate =
        params.photoUrl ?? (params.removePhoto ? FieldValue.delete() : null);

    final profileUpdate = <String, dynamic>{
      'name': params.name,
      'nis': params.nis,
      'jenis_kelamin': params.jenisKelamin,
      'is_active': params.isActive,
    };
    final userUpdate = <String, dynamic>{
      'name': params.name,
      'phone': params.phone,
      'nis': params.nis,
    };
    if (photoUpdate != null) {
      profileUpdate['photo_url'] = photoUpdate;
      userUpdate['photo_url'] = photoUpdate;
    }

    final batch = firestore.batch();
    batch.update(
      firestore.collection('asatidz_profiles').doc(id),
      profileUpdate,
    );
    batch.update(firestore.collection('users').doc(id), userUpdate);
    await batch.commit();
  }

  @override
  Future<String> getNextNis() async {
    final snapshots = await Future.wait([
      firestore.collection('santri_profiles').get(),
      firestore.collection('asatidz_profiles').get(),
    ]);

    var maxNis = 1000;
    for (final snapshot in snapshots) {
      for (final doc in snapshot.docs) {
        final rawNis = (doc.data()['nis'] ?? '').toString().trim();
        final numericNis =
            int.tryParse(rawNis) ?? double.tryParse(rawNis)?.toInt();
        if (numericNis != null && numericNis > maxNis) {
          maxNis = numericNis;
        }
      }
    }
    return (maxNis + 1).toString();
  }
}
