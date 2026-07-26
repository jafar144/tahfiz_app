import 'package:khoirunnasyien/features/management_asatidz/data/datasource/asatidz_remote_datasource.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_detail.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_entity.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_params.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/repository/asatidz_repository.dart';

class AsatidzRepositoryImpl implements AsatidzRepository {
  final AsatidzRemoteDataSource remote;

  AsatidzRepositoryImpl(this.remote);

  @override
  Future<List<AsatidzEntity>> getAsatidzList({
    String? keyword,
    bool? isActive,
    String? gender,
    int limit = 10,
    String? lastDocumentId,
  }) async {
    return await remote.getAsatidzList(
      keyword: keyword,
      isActive: isActive,
      gender: gender,
      limit: limit,
      lastDocumentId: lastDocumentId,
    );
  }

  @override
  Future<AsatidzDetail> getAsatidzDetail(String id) async {
    return await remote.getAsatidzDetail(id);
  }

  @override
  Future<String> addAsatidz(AsatidzParams params) {
    return remote.addAsatidz(params);
  }

  @override
  Future<void> updateAsatidz(String id, AsatidzParams params) async {
    await remote.updateAsatidz(id, params);
  }
}
