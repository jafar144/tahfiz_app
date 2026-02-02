import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:khoirunnasyien/features/home/data/datasource/admin_home_remote_datasource.dart';

class AdminHomeRemoteDatasourceImpl implements AdminHomeRemoteDatasource {
  final FirebaseFirestore firestore;

  AdminHomeRemoteDatasourceImpl(this.firestore);

  @override
  Future<int> getTotalSantri() async {
    final snapshot = await firestore
        .collection('users')
        .where('role', isEqualTo: 'santri')
        .get();

    return snapshot.docs.length;
  }
}
