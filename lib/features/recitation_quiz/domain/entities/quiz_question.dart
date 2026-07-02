import 'package:khoirunnasyien/features/recitation_check/domain/entities/ayah.dart';

/// Satu soal kuis: sebuah ayat [prompt] ditampilkan (teks Arab, tanpa label),
/// dan santri harus melanjutkan dengan membaca [answer] — 1 sampai 3 ayat
/// berikutnya.
///
/// [answer] bisa memuat penanda basmalah (ayat bernomor 0) di depan sebuah ayat
/// pertama surah baru — diletakkan agar tidak dihitung salah saat santri
/// membacanya pada soal sambungan antar surah (lihat [hasBasmalah]).
class QuizQuestion {
  /// Ayat yang ditampilkan sebagai petunjuk.
  final Ayah prompt;

  /// Ayat-ayat target pemeriksaan (bisa diselingi basmalah). Semua teks digabung
  /// menjadi referensi pencocokan bacaan.
  final List<Ayah> answer;

  const QuizQuestion({required this.prompt, required this.answer});

  /// True bila jawaban memuat basmalah (menyeberang ke awal surah baru).
  bool get hasBasmalah => answer.any((a) => a.number == 0);

  /// Ayat-ayat jawaban "sebenarnya" (tanpa penanda basmalah).
  List<Ayah> get answerAyat =>
      answer.where((a) => a.number != 0).toList(growable: false);

  /// Jumlah ayat yang harus dilanjutkan santri (basmalah tidak dihitung).
  int get answerAyahCount => answerAyat.length;

  /// Teks referensi lengkap (basmalah + ayat) untuk pencocokan.
  String get answerText => answer.map((a) => a.text).join(' ');
}
