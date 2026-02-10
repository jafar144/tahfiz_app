abstract class SantriSetoranState {
  const SantriSetoranState();
}

class SantriSetoranInitial extends SantriSetoranState {}

class SantriSetoranLoading extends SantriSetoranState {}

class SantriSetoranSuccess extends SantriSetoranState {}

class SantriSetoranError extends SantriSetoranState {
  final String message;
  const SantriSetoranError(this.message);
}
