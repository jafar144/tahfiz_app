import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';

sealed class SantriState {}

class SantriInitial extends SantriState {}

class SantriLoading extends SantriState {}

class SantriCreated extends SantriState {
  final String nis;
  final String temporaryPassword;

  SantriCreated({required this.nis, required this.temporaryPassword});
}

class SantriLoaded extends SantriState {
  final List<SantriEntity> santri;
  final int totalCount;
  final bool hasReachedMax;
  final bool isFetchingMore;

  SantriLoaded(
    this.santri, {
    int? totalCount,
    this.hasReachedMax = false,
    this.isFetchingMore = false,
  }) : totalCount = totalCount ?? santri.length;

  SantriLoaded copyWith({
    List<SantriEntity>? santri,
    int? totalCount,
    bool? hasReachedMax,
    bool? isFetchingMore,
  }) {
    return SantriLoaded(
      santri ?? this.santri,
      totalCount: totalCount ?? this.totalCount,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
    );
  }
}

class SantriError extends SantriState {
  final String message;

  SantriError(this.message);
}
