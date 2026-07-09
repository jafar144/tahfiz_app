/// Konfigurasi & konstanta Petualangan Surah — SATU tempat untuk semua angka
/// yang bisa disetel: komposisi ujian akhir, ambang lulus, XP, dsb.
/// (Aturan ujian PER BAGIAN diatur di seed lewat `SectionTest`.)
class LessonConfig {
  LessonConfig._();

  // ── Ujian akhir surah ───────────────────────────────────────────────────
  /// Jumlah soal ujian akhir.
  static const int examQuestionCount = 10;

  /// Dari soal ujian akhir: sekian soal SUARA "sambung ayat".
  static const int examVoiceContinueCount = 3;

  /// Dari soal ujian akhir: sekian soal SUARA "baca ayat terakhir surah".
  static const int examVoiceLastAyahCount = 1;

  /// Jumlah benar minimal agar ujian akhir LULUS (8/10 = nilai 80).
  static const int examMinCorrect = 8;

  // ── XP ──────────────────────────────────────────────────────────────────
  /// XP lulus ujian akhir PERTAMA KALI. (XP per bagian ada di `SectionTest`.)
  static const int xpExamPass = 60;

  /// Bonus XP bila ujian akhir sempurna (semua benar).
  static const int xpExamPerfectBonus = 15;

  /// XP kecil tiap kali LULUS LAGI test yang sudah pernah lulus.
  static const int xpRepeatPass = 5;

  // ── Energi ──────────────────────────────────────────────────────────────
  /// Energi yang dipotong tiap percobaan test yang BELUM pernah lulus.
  /// Setelah pernah lulus, mengulang test itu gratis.
  static const int energyCost = 1;

  // ── Soal ────────────────────────────────────────────────────────────────
  /// Maksimum ayat lanjutan yang diminta pada soal sambung ayat (1..maks).
  static const int maxContinueAyah = 2;

  /// Ambang persentase akurasi bacaan agar soal suara dianggap BENAR.
  static const int voicePassThreshold = 80;

  /// Jeda tampil umpan balik benar/salah soal pilihan sebelum auto-lanjut.
  static const Duration choiceFeedbackDelay = Duration(milliseconds: 1100);
}
