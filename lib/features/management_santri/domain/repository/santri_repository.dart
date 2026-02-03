import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_detail.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_params.dart';

abstract class SantriRepository {
  Future<List<SantriEntity>> getSantriList({
    String? keyword,
    bool? isActive,
  });

  Future<SantriDetail> getSantriDetail(String id);

  Future<void> addSantri(SantriParams params);

  Future<void> updateSantri(String id, SantriParams params);
}