/// Status hasil pencocokan per kata.
enum WordStatus {
  /// Kata terbaca benar sesuai mushaf.
  correct,

  /// Kata terbaca tapi berbeda dari mushaf (tertukar/salah baca).
  wrong,

  /// Kata di mushaf tidak terbaca (kelewat / belum dibaca).
  missing,

  /// Kata terbaca tapi tidak ada di mushaf (tambahan).
  extra,
}

/// Hasil pencocokan satu kata pada alignment.
class WordDiff {
  final WordStatus status;

  /// Kata referensi (mushaf) yang sudah dinormalisasi. null untuk [WordStatus.extra].
  final String? referenceWord;

  /// Kata yang terdengar (hasil ASR) yang sudah dinormalisasi. null untuk [WordStatus.missing].
  final String? spokenWord;

  const WordDiff({
    required this.status,
    this.referenceWord,
    this.spokenWord,
  });
}

/// Hasil akhir pemeriksaan satu sesi bacaan.
class RecitationResult {
  /// Urutan diff mengikuti urutan kata pada mushaf.
  final List<WordDiff> diffs;

  /// Fraksi kata mushaf yang terbaca benar (0..1).
  final double accuracy;

  /// Jumlah kata pada teks referensi (mushaf).
  final int referenceWordCount;

  /// Teks mentah hasil transkripsi ASR (untuk debugging / ditampilkan).
  final String transcription;

  const RecitationResult({
    required this.diffs,
    required this.accuracy,
    required this.referenceWordCount,
    required this.transcription,
  });

  int get correctCount =>
      diffs.where((d) => d.status == WordStatus.correct).length;
  int get wrongCount =>
      diffs.where((d) => d.status == WordStatus.wrong).length;
  int get missingCount =>
      diffs.where((d) => d.status == WordStatus.missing).length;
  int get extraCount =>
      diffs.where((d) => d.status == WordStatus.extra).length;

  /// Persentase 0..100 untuk ditampilkan.
  int get accuracyPercent => (accuracy * 100).round();
}
