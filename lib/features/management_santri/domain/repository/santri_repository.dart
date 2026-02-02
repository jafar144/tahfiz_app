import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';

abstract class SantriRepository {
  Future<List<SantriEntity>> getSantriList({
    String? keyword,
    bool? isActive,
  });
}