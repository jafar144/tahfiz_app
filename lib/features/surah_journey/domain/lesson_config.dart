/// Konfigurasi & konstanta Petualangan Surah — SATU tempat untuk semua angka
/// yang bisa disetel: jumlah soal, komposisi soal, ambang lulus, dsb.
class LessonConfig {
  LessonConfig._();

  /// Jumlah soal ujian per surah.
  static const int questionCount = 10;

  /// Dari [questionCount], sekian soal SUARA (sisanya pilihan ganda materi).
  static const int voiceQuestionCount = 5;

  /// Dari [voiceQuestionCount], sekian soal "baca ayat terakhir surah".
  static const int voiceLastAyahCount = 1;

  /// Maksimum ayat lanjutan yang diminta pada soal sambung ayat (1..maks).
  static const int maxContinueAyah = 2;

  /// Nilai per soal benar (total = [questionCount] × ini = 100).
  static const int pointsPerQuestion = 10;

  /// Ambang NILAI total agar level dianggap SELESAI (centang hijau di peta).
  static const int passScore = 80;

  /// Ambang persentase akurasi bacaan agar soal suara dianggap BENAR.
  static const int voicePassThreshold = 80;

  /// Jeda tampil umpan balik benar/salah soal pilihan sebelum auto-lanjut.
  static const Duration choiceFeedbackDelay = Duration(milliseconds: 1100);
}
