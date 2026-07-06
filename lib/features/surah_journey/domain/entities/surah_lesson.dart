/// Materi belajar SATU surah pada Petualangan Surah.
///
/// Konten (arti, asbabun nuzul, fakta, bank soal) disusun statis di
/// `surah_lesson_seed.dart`; teks ayat diambil dari mushaf lokal saat runtime.
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

  /// Paragraf pengenalan singkat surah (halaman pertama belajar).
  final String intro;

  /// Kisah asbabun nuzul / kisah utama surah (opsional).
  final String? asbabunNuzul;

  /// Fakta menarik surah (ditampilkan sebagai kartu-kartu poin).
  final List<String> facts;

  /// Bank soal pilihan ganda dari materi; ujian mengambil beberapa secara acak.
  final List<FactQuestion> questionBank;

  const SurahLesson({
    required this.surahId,
    required this.level,
    required this.nameLatin,
    required this.nameArabic,
    required this.meaning,
    required this.ayahCount,
    required this.place,
    required this.intro,
    this.asbabunNuzul,
    required this.facts,
    required this.questionBank,
  });
}

/// Satu soal pilihan ganda dari materi pembelajaran surah.
class FactQuestion {
  final String question;

  /// Opsi jawaban (4 buah).
  final List<String> options;

  /// Indeks opsi yang benar pada [options].
  final int correctIndex;

  const FactQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
  });
}
