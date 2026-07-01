import 'package:khoirunnasyien/features/recitation_check/domain/entities/ayah.dart';

/// Satu soal kuis: sebuah ayat [prompt] ditampilkan (teks Arab, tanpa label),
/// dan santri harus melanjutkan dengan membaca ayat [answer] berikutnya.
///
/// [answer] bisa berisi lebih dari satu entri bila jawaban adalah ayat pertama
/// sebuah surah baru — basmalah diletakkan di depan agar tidak dihitung salah
/// saat santri membacanya (lihat [hasBasmalah]).
class QuizQuestion {
  /// Ayat yang ditampilkan sebagai petunjuk.
  final Ayah prompt;

  /// Ayat target pemeriksaan (bisa diawali basmalah). Semua teks digabung
  /// menjadi referensi pencocokan bacaan.
  final List<Ayah> answer;

  const QuizQuestion({required this.prompt, required this.answer});

  /// True bila jawaban diawali basmalah (jawaban = ayat 1 surah baru).
  bool get hasBasmalah => answer.length > 1;

  /// Ayat jawaban "sebenarnya" (tanpa basmalah) — dipakai untuk menampilkan
  /// info surah/ayat saat kunci dibuka.
  Ayah get answerAyah => answer.last;

  /// Teks referensi lengkap (basmalah + ayat) untuk pencocokan.
  String get answerText => answer.map((a) => a.text).join(' ');
}
