import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';

/// Satu hasil query daftar santri beserta total data yang cocok dengan seluruh
/// filter. [items] boleh berupa satu halaman atau seluruh hasil, tergantung
/// apakah query dapat dipaginasi sepenuhnya di Firestore.
class SantriPageResult {
  final List<SantriEntity> items;
  final int totalCount;

  const SantriPageResult({required this.items, required this.totalCount});

  bool get hasReachedMax => items.length >= totalCount;

  SantriPageResult mapItems(
    SantriEntity Function(SantriEntity santri) transform,
  ) {
    return SantriPageResult(
      items: items.map(transform).toList(),
      totalCount: totalCount,
    );
  }
}
