/// Tingkatan kompetisi kuis berdasarkan cakupan soal, bukan kelas santri.
class QuizTier {
  /// Kunci stabil untuk path/field Firestore, mis. `juz_30`.
  final String key;

  /// Label yang ditampilkan pada chip leaderboard.
  final String label;

  /// Kelas kurikulum pertama yang mendefinisikan cakupan soal tingkatan ini.
  final String scopeClass;

  const QuizTier({
    required this.key,
    required this.label,
    required this.scopeClass,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuizTier &&
          key == other.key &&
          label == other.label &&
          scopeClass == other.scopeClass;

  @override
  int get hashCode => Object.hash(key, label, scopeClass);

  @override
  String toString() => 'QuizTier($key, $label, $scopeClass)';
}
