import '../entities/admin_home_data.dart';

abstract class AdminHomeRepository {
  Future<AdminHomeData> getHomeData({required String adminUid});
}
