import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_detail.dart';

abstract class SantriDetailState {
  const SantriDetailState();
}

class SantriDetailInitial extends SantriDetailState {}

class SantriDetailLoading extends SantriDetailState {}

class SantriDetailLoaded extends SantriDetailState {
  final SantriDetail detail;

  const SantriDetailLoaded(this.detail);
}

class SantriDetailError extends SantriDetailState {
  final String message;

  const SantriDetailError(this.message);
}
