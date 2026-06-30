import 'package:flutter/foundation.dart';
import 'package:khoirunnasyien/features/auth/domain/user_repository.dart';

import '../../domain/entities/admin_home_data.dart';
import '../../domain/repositories/admin_home_repository.dart';
import '../datasource/admin_home_remote_datasource.dart';

class AdminHomeRepositoryImpl implements AdminHomeRepository {
  final AdminHomeRemoteDatasource dashboardDatasource;
  final UserRepository userRepository;

  AdminHomeRepositoryImpl(
    this.dashboardDatasource,
    this.userRepository,
  );

  @override
  Future<AdminHomeData> getHomeData({
    required String adminUid,
  }) async {
    final admin = await userRepository.getUserByUid(adminUid);

    // Metrik mutasi bersifat fail-soft: bila gagal (mis. composite index belum
    // dibuat) cukup tampil 0 agar total santri utama tidak ikut error.
    Future<int> safe(Future<int> f) => f.catchError((Object e) {
          // Cetak error asli (mis. URL pembuatan composite index) ke console,
          // karena ErrorHandler menyederhanakannya menjadi pesan generik.
          debugPrint('[AdminHome] metrik mutasi gagal: $e');
          return 0;
        });

    final futures = await Future.wait([
      dashboardDatasource.getTotalSantriPutra(),
      dashboardDatasource.getTotalSantriPutri(),
      dashboardDatasource.getTotalAsatidzPutra(),
      dashboardDatasource.getTotalAsatidzPutri(),
      safe(dashboardDatasource.getSantriMasuk30d('L')),
      safe(dashboardDatasource.getSantriMasuk30d('P')),
      safe(dashboardDatasource.getSantriKeluar30d('L')),
      safe(dashboardDatasource.getSantriKeluar30d('P')),
    ]);

    return AdminHomeData(
      adminName: admin.name,
      totalSantriPutra: futures[0],
      totalSantriPutri: futures[1],
      totalAsatidzPutra: futures[2],
      totalAsatidzPutri: futures[3],
      masukPutra: futures[4],
      masukPutri: futures[5],
      keluarPutra: futures[6],
      keluarPutri: futures[7],
    );
  }
}
