import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_entity.dart';

sealed class AsatidzState {}

class AsatidzInitial extends AsatidzState {}

class AsatidzLoading extends AsatidzState {}

class AsatidzCreated extends AsatidzState {
  final String nis;
  final String temporaryPassword;

  AsatidzCreated({required this.nis, required this.temporaryPassword});
}

class AsatidzLoaded extends AsatidzState {
  final List<AsatidzEntity> asatidz;
  final bool hasReachedMax;
  final bool isFetchingMore;

  AsatidzLoaded(
    this.asatidz, {
    this.hasReachedMax = false,
    this.isFetchingMore = false,
  });

  AsatidzLoaded copyWith({
    List<AsatidzEntity>? asatidz,
    bool? hasReachedMax,
    bool? isFetchingMore,
  }) {
    return AsatidzLoaded(
      asatidz ?? this.asatidz,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
    );
  }
}

class AsatidzError extends AsatidzState {
  final String message;

  AsatidzError(this.message);
}
