import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_params.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_detail.dart';

import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_entity.dart';

abstract class SantriRemoteDataSource {
  Future<List<SantriEntity>> getSantriList({
    String? keyword,
    bool? isActive,
    String? gender,
    String? session,
    String? kelas,
    String? asatidzId,
    bool? isFree,
    int limit = 10,
    String? lastDocumentId,
  });

  Future<List<AsatidzEntity>> getAsatidzList();

  Future<SantriDetail> getSantriDetail(String id);

  Future<String> addSantri(SantriParams params);

  Future<void> updateSantri(String id, SantriParams params);

  Future<List<SantriEntity>> getSantriByIds(List<String> ids);

  /// NIS otomatis berikutnya = NIS numerik tertinggi yang ada + 1.
  Future<String> getNextNis();

  /// Cek apakah sebuah NIS sudah dipakai santri lain.
  Future<bool> isNisTaken(String nis);
}
