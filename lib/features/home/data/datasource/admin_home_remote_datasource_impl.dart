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

  @override
  Future<int> getTotalSantriByGenderAndSession({
    required String gender,
    required String session,
  }) async {
    final snapshot = await firestore
        .collection('santri_profiles')
        .where('is_active', isEqualTo: true)
        .where('jenis_kelamin', isEqualTo: gender)
        .where('tipe_kelas', isEqualTo: session)
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  @override
  Future<int> getTotalAsatidzPutra() async {
    // Assuming 'L' for laki-laki
    final snapshot = await firestore
        .collection('asatidz_profiles')
        .where('is_active', isEqualTo: true)
        .where('jenis_kelamin', isEqualTo: 'L')
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  @override
  Future<int> getTotalAsatidzPutri() async {
    // Assuming 'P' for perempuan
    final snapshot = await firestore
        .collection('asatidz_profiles')
        .where('is_active', isEqualTo: true)
        .where('jenis_kelamin', isEqualTo: 'P')
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  /// Awal jendela 30 hari terakhir.
  Timestamp get _since30d =>
      Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 30)));

  @override
  Future<int> getSantriMasuk30d(String gender) async {
    final snapshot = await firestore
        .collection('santri_profiles')
        .where('jenis_kelamin', isEqualTo: gender)
        .where('tanggal_masuk', isGreaterThanOrEqualTo: _since30d)
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  @override
  Future<int> getSantriKeluar30d(String gender) async {
    final snapshot = await firestore
        .collection('santri_profiles')
        .where('jenis_kelamin', isEqualTo: gender)
        .where('tanggal_keluar', isGreaterThanOrEqualTo: _since30d)
        .count()
        .get();

    return snapshot.count ?? 0;
  }
}
