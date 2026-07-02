import 'package:khoirunnasyien/features/recitation_check/domain/entities/ayah.dart';

/// Satu soal kuis: sebuah ayat [prompt] ditampilkan (teks Arab, tanpa label),
/// dan santri harus melanjutkan dengan [answer] — 1 sampai 3 ayat berikutnya.
///
/// Mode suara: santri membaca lanjutannya (dicek Whisper). [answer] bisa memuat
/// penanda basmalah (ayat bernomor 0) di depan ayat pertama surah baru.
///
/// Mode pilihan: santri memilih dari [options] (6 ayat teracak yang memuat
/// jawaban benar). Untuk mode ini [answer] berisi ayat asli tanpa basmalah,
/// dan [options] terisi.
class QuizQuestion {
  /// Ayat yang ditampilkan sebagai petunjuk.
  final Ayah prompt;

  /// Ayat-ayat target pemeriksaan (bisa diselingi basmalah pada mode suara).
  final List<Ayah> answer;

  /// Pilihan ayat untuk mode pilihan ganda (teracak, memuat [answerAyat]).
  /// Kosong pada mode suara.
  final List<Ayah> options;

  const QuizQuestion({
    required this.prompt,
    required this.answer,
    this.options = const [],
  });

  /// True bila jawaban memuat basmalah (menyeberang ke awal surah baru).
  bool get hasBasmalah => answer.any((a) => a.number == 0);

  /// Ayat-ayat jawaban "sebenarnya" (tanpa penanda basmalah).
  List<Ayah> get answerAyat =>
      answer.where((a) => a.number != 0).toList(growable: false);

  /// Jumlah ayat yang harus dilanjutkan santri (basmalah tidak dihitung).
  int get answerAyahCount => answerAyat.length;

  /// Teks referensi lengkap (basmalah + ayat) untuk pencocokan bacaan.
  String get answerText => answer.map((a) => a.text).join(' ');

  /// Indeks opsi yang benar, TERURUT sesuai jawaban (mode pilihan).
  /// Contoh: jawaban 2 ayat → [indeks ayat-1, indeks ayat-2] pada [options].
  List<int> get correctOptionOrder {
    return answerAyat.map((a) {
      return options.indexWhere(
        (o) => o.surahId == a.surahId && o.number == a.number,
      );
    }).toList();
  }
}
