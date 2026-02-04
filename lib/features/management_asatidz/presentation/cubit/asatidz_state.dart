import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_entity.dart';

sealed class AsatidzState {}

class AsatidzInitial extends AsatidzState {}

class AsatidzLoading extends AsatidzState {}

class AsatidzLoaded extends AsatidzState {
  final List<AsatidzEntity> asatidz;

  AsatidzLoaded(this.asatidz);
}

class AsatidzError extends AsatidzState {
  final String message;

  AsatidzError(this.message);
}
