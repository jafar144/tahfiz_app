import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:khoirunnasyien/features/management_santri/data/datasource/santri_remote_datasource.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';

class SantriRemoteDataSourceImpl implements SantriRemoteDataSource {
  final FirebaseFirestore firestore;

  SantriRemoteDataSourceImpl(this.firestore);

  @override
  Future<List<SantriEntity>> getSantriList({
    String? keyword,
    bool? isActive,
  }) async {
    Query query = firestore
        .collection('santri_profiles')
        .where('role', isEqualTo: 'santri');

    if (isActive != null) {
      query = query.where('is_active', isEqualTo: isActive);
    }

    final snapshot = await query.get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;

      return SantriEntity(
        id: doc.id,
        name: data['name'],
        nis: data['nis'],
        kelas: data['kelas'],
        jenisKelamin: data['jenis_kelamin'],
        isActive: data['is_active'] ?? true,
        pembimbing: null,
      );
    }).toList();
  }
}
