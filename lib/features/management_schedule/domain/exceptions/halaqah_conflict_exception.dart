class HalaqahConflictException implements Exception {
  final String message;

  const HalaqahConflictException(this.message);

  @override
  String toString() => message;
}
