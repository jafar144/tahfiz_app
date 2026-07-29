import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_detail.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_entity.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_params.dart';

abstract class AsatidzRepository {
  Future<List<AsatidzEntity>> getAsatidzList({
    String? keyword,
    bool? isActive,
    String? gender,
    int limit = 10,
    String? lastDocumentId,
  });

  Future<AsatidzDetail> getAsatidzDetail(String id);

  Future<String> addAsatidz(AsatidzParams params);

  Future<void> updateAsatidz(String id, AsatidzParams params);

  Future<String> getNextNis();
}
