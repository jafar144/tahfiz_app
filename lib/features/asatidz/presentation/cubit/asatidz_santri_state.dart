import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';

sealed class AsatidzSantriState {}

class AsatidzSantriInitial extends AsatidzSantriState {}

class AsatidzSantriLoading extends AsatidzSantriState {}

class AsatidzSantriLoaded extends AsatidzSantriState {
  final List<SantriEntity> santri;

  AsatidzSantriLoaded(this.santri);
}

class AsatidzSantriError extends AsatidzSantriState {
  final String message;

  AsatidzSantriError(this.message);
}
