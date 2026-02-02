import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';

sealed class SantriState {}

class SantriInitial extends SantriState {}

class SantriLoading extends SantriState {}

class SantriLoaded extends SantriState {
  final List<SantriEntity> santri;

  SantriLoaded(this.santri);
}

class SantriError extends SantriState {
  final String message;

  SantriError(this.message);
}
