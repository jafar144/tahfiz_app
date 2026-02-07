import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:khoirunnasyien/features/home/data/datasource/admin_home_remote_datasource.dart';

class AdminHomeRemoteDatasourceImpl implements AdminHomeRemoteDatasource {
  final FirebaseFirestore firestore;

  AdminHomeRemoteDatasourceImpl(this.firestore);

  @override
  Future<int> getTotalSantriPutra() async {
    final snapshot = await firestore
        .collection('santri_profiles')
        .where('is_active', isEqualTo: true)
        .where('jenis_kelamin', isEqualTo: 'L')
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  @override
  Future<int> getTotalSantriPutri() async {
    final snapshot = await firestore
        .collection('santri_profiles')
        .where('is_active', isEqualTo: true)
        .where('jenis_kelamin', isEqualTo: 'P')
        .count()
        .get();

    return snapshot.count ?? 0;
  }
}
