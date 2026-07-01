/// Satu ayat dalam rentang target bacaan.
class Ayah {
  final int surahId;
  final int number; // nomor ayat (1-based)
  final String text; // teks Arab rasm Utsmani (dengan harakat + glyph nomor ayat)
  final int page; // halaman mushaf Madinah (1..604)
  final String surahName; // nama surah (Arab), untuk header halaman

  const Ayah({
    required this.surahId,
    required this.number,
    required this.text,
    this.page = 0,
    this.surahName = '',
  });

  /// Ayat pertama sebuah surah (butuh header + basmalah saat ditampilkan).
  bool get isSurahStart => number == 1;
}

/// Ringkasan satu surah untuk pemilihan target.
class SurahInfo {
  final int id; // 1..114
  final String name; // nama Arab
  final String latin; // transliterasi latin
  final int totalVerses;

  const SurahInfo({
    required this.id,
    required this.name,
    required this.latin,
    required this.totalVerses,
  });

  @override
  bool operator ==(Object other) =>
      other is SurahInfo && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
