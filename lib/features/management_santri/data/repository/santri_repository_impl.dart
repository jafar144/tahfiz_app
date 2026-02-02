import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:khoirunnasyien/features/management_santri/data/datasource/santri_remote_datasource.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_santri/domain/repository/santri_repository.dart';

class SantriRepositoryImpl implements SantriRepository {
  final SantriRemoteDataSource remote;
  final FirebaseFirestore firestore;

  SantriRepositoryImpl(this.remote, this.firestore);

  @override
  Future<List<SantriEntity>> getSantriList({
    String? keyword,
    bool? isActive,
  }) async {
    final santriList = await remote.getSantriList(
      keyword: keyword,
      isActive: isActive,
    );

    final classSnap = await firestore
        .collection('classes')
        .where('is_active', isEqualTo: true)
        .get();

    final classMap = <String, String>{};

    for (var doc in classSnap.docs) {
      final data = doc.data();
      final ustadzName = data['ustadz_name'];
      final santriIds = List<String>.from(data['santri_ids']);

      for (final id in santriIds) {
        classMap[id] = ustadzName;
      }
    }

    return santriList.map((s) {
      return SantriEntity(
        id: s.id,
        name: s.name,
        nis: s.nis,
        kelas: s.kelas,
        jenisKelamin: s.jenisKelamin,
        isActive: s.isActive,
        pembimbing: classMap[s.id],
      );
    }).toList();
  }
}
