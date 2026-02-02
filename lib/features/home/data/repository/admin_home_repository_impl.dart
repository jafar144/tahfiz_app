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
    final totalSantri = await dashboardDatasource.getTotalSantri();

    return AdminHomeData(
      adminName: admin.name,
      totalSantri: totalSantri,
    );
  }
}
