import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';

abstract class SantriRemoteDataSource {
  Future<List<SantriEntity>> getSantriList({
    String? keyword,
    bool? isActive,
  });
}
