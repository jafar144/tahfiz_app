import 'package:khoirunnasyien/features/asatidz/domain/entities/santri_setoran.dart';

abstract class SantriSetoranState {
  const SantriSetoranState();
}

class SantriSetoranInitial extends SantriSetoranState {}

class SantriSetoranLoading extends SantriSetoranState {}

class SantriSetoranDataLoaded extends SantriSetoranState {
  final SantriSetoran? lastSetoran;
  final SantriSetoran? todaySetoran;
  final bool isSubmitting;

  const SantriSetoranDataLoaded({
    this.lastSetoran,
    this.todaySetoran,
    this.isSubmitting = false,
  });
}

class SantriSetoranSuccess extends SantriSetoranState {
  final String message;
  const SantriSetoranSuccess(this.message);
}

class SantriSetoranError extends SantriSetoranState {
  final String message;
  const SantriSetoranError(this.message);
}
