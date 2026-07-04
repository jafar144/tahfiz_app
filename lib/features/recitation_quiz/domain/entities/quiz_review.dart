/// Ringkasan satu soal untuk layar REVIEW pasca-sesi (tidak disimpan ke
/// database) — memuat pertanyaan, jawaban santri, dan jawaban benar.
///
/// Teks sudah dirender siap-tampil di sini agar layar review sederhana; ayat
/// Arab ditandai lewat flag *Arabic untuk penataan kanan-ke-kiri + font mushaf.
class QuizReviewItem {
  /// True bila soal ini dijawab benar (mode suara: bacaan lolos).
  final bool correct;

  /// Poin/nilai soal ini.
  final int score;

  /// Kalimat pertanyaan/instruksi ringkas.
  final String question;

  /// Ayat petunjuk (Arab) bila ada; null bila tak relevan.
  final String? promptArabic;

  /// Jawaban santri (Arab untuk ayat, Latin untuk trivia/akurasi).
  final String yourAnswer;
  final bool yourAnswerArabic;

  /// Jawaban benar (ditampilkan terutama saat salah).
  final String correctAnswer;
  final bool correctAnswerArabic;

  const QuizReviewItem({
    required this.correct,
    required this.score,
    required this.question,
    this.promptArabic,
    required this.yourAnswer,
    this.yourAnswerArabic = false,
    required this.correctAnswer,
    this.correctAnswerArabic = false,
  });
}
