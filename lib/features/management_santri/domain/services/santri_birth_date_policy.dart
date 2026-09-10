class SantriBirthDatePolicy {
  const SantriBirthDatePolicy._();

  static String dateKey(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)}';
  }

  static bool hasChanged(DateTime? previous, DateTime next) =>
      previous == null || dateKey(previous) != dateKey(next);

  /// Pending marker keeps a failed server reset retryable even when the
  /// profile birth date was already updated by the first request.
  static bool requiresPasswordReset({
    required DateTime? previous,
    required DateTime next,
    String? pendingDateKey,
  }) {
    final nextKey = dateKey(next);
    return hasChanged(previous, next) || pendingDateKey?.trim() == nextKey;
  }
}
