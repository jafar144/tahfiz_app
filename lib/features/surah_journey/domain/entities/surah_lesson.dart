import 'package:khoirunnasyien/features/surah_journey/domain/entities/lesson_section.dart';

/// Materi belajar SATU surah pada Petualangan Surah.
///
/// Konten disusun modular per BAGIAN ([LessonSection]) di
/// `surah_lesson_seed.dart`; teks ayat diambil dari mushaf lokal saat runtime.
/// Setiap bagian punya ujian kecil; setelah semua bagian lulus, terbuka
/// UJIAN AKHIR surah (aturannya di `lesson_config.dart`).
class SurahLesson {
  /// Nomor surah pada mushaf (mis. 92 = Al-Lail).
  final int surahId;

  /// Urutan level pada peta journey (1-based; level 1 paling bawah).
  final int level;

  final String nameLatin;
  final String nameArabic;

  /// Arti nama surah (Indonesia).
  final String meaning;

  final int ayahCount;

  /// Golongan turunnya surah: 'Makkiyah' / 'Madaniyah'.
  final String place;

  /// Bagian-bagian pembelajaran, urut sesuai alur belajar.
  final List<LessonSection> sections;

  const SurahLesson({
    required this.surahId,
    required this.level,
    required this.nameLatin,
    required this.nameArabic,
    required this.meaning,
    required this.ayahCount,
    required this.place,
    required this.sections,
  });
}

/// Satu soal pilihan ganda.
class FactQuestion {
  final String question;

  /// Opsi jawaban (4 buah).
  final List<String> options;

  /// Indeks opsi yang benar pada [options].
  final int correctIndex;

  /// Teks Arab yang ditampilkan besar di kartu soal (mis. ayat kosa kata).
  final String? arabicText;

  /// Potongan [arabicText] yang disorot (mis. kata yang ditanya artinya).
  final String? highlightWord;

  /// Opsi jawaban berupa teks Arab (dirender dengan font mushaf).
  final bool arabicOptions;

  const FactQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    this.arabicText,
    this.highlightWord,
    this.arabicOptions = false,
  });
}
