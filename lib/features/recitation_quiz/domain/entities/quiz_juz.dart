/// Metadata juz yang didukung Kuis Hafalan + nama surah Latin.
///
/// Dua macam juz:
///  • Juz "surah utuh" (29 & 30): batas juz pas di batas surah → boleh memilih
///    rentang target hafalan (surah awal kustom).
///  • Juz "rentang ayat" (1, 2, 3): batasnya di TENGAH surah (Al-Baqarah
///    membentang juz 1-3) → didefinisikan sebagai segmen ayat mushaf, tanpa
///    kustomisasi rentang.
///
/// Dipakai bersama oleh repo (menyusun pool ayat), layar intro, dan lembar
/// pengaturan. Sumber tunggal agar rentang tiap juz konsisten di seluruh fitur.
class QuizJuz {
  QuizJuz._();

  /// Juz yang didukung, urut menaik.
  static const List<int> supported = [1, 2, 3, 29, 30];

  /// Juz "surah utuh": rentang surah [pertama, terakhir] (id surah mushaf).
  /// Hanya juz ini yang mendukung pemilihan rentang target (surah awal kustom).
  static const Map<int, (int first, int last)> _range = {
    29: (67, 77), // Al-Mulk .. Al-Mursalat
    30: (78, 114), // An-Naba' .. An-Nas
  };

  /// Juz "rentang ayat": daftar segmen (surah, ayatAwal, ayatAkhir) mushaf.
  /// Untuk juz yang batasnya di tengah surah.
  static const Map<int, List<(int surah, int from, int to)>> _ayahSegments = {
    1: [(1, 1, 7), (2, 1, 141)], // Al-Fatihah utuh + Al-Baqarah 1-141
    2: [(2, 142, 252)], // Al-Baqarah 142-252
    3: [(2, 253, 286), (3, 1, 91)], // Al-Baqarah 253-286 + Ali 'Imran 1-91
  };

  static bool isSupported(int juz) =>
      _range.containsKey(juz) || _ayahSegments.containsKey(juz);

  /// True bila juz boleh memilih rentang target hafalan (surah awal kustom) —
  /// hanya juz "surah utuh" (29 & 30).
  static bool supportsCustomRange(int juz) => _range.containsKey(juz);

  /// True bila juz didefinisikan sebagai segmen ayat (batas di tengah surah).
  static bool hasAyahSegments(int juz) => _ayahSegments.containsKey(juz);

  /// Segmen ayat (surah, from, to) pembentuk juz "rentang ayat"; kosong untuk
  /// juz "surah utuh".
  static List<(int surah, int from, int to)> ayahSegments(int juz) =>
      _ayahSegments[juz] ?? const [];

  /// Label ringkas cakupan juz untuk ditampilkan di kartu pilihan juz.
  static String spanLabel(int juz) {
    switch (juz) {
      case 1:
        return 'Al-Fatihah — Al-Baqarah 141';
      case 2:
        return 'Al-Baqarah 142–252';
      case 3:
        return 'Al-Baqarah 253 — Ali Imran 91';
      default:
        final r = _range[juz];
        return r == null ? 'Juz $juz' : '${nameOf(r.$1)} — ${nameOf(r.$2)}';
    }
  }

  /// Surah pertama juz (di awal juz secara mushaf).
  static int firstSurah(int juz) => _range[juz]!.$1;

  /// Surah terakhir juz — DIKUNCI sebagai ujung rentang target hafalan.
  static int lastSurah(int juz) => _range[juz]!.$2;

  /// Semua id surah dalam juz, urut mushaf (pertama → terakhir).
  static List<int> surahsOf(int juz) {
    final r = _range[juz]!;
    return [for (var s = r.$1; s <= r.$2; s++) s];
  }

  /// Batasi [surah] agar berada dalam rentang juz (untuk data tersimpan usang).
  static int clampStart(int juz, int surah) {
    final r = _range[juz]!;
    if (surah < r.$1) return r.$1;
    if (surah > r.$2) return r.$2;
    return surah;
  }

  /// Nama Latin surah untuk tampilan (surah dalam juz 1-3 & 29-30).
  static const Map<int, String> surahLatin = {
    1: 'Al-Fatihah',
    2: 'Al-Baqarah',
    3: "Ali 'Imran",
    67: 'Al-Mulk',
    68: 'Al-Qalam',
    69: 'Al-Haqqah',
    70: "Al-Ma'arij",
    71: 'Nuh',
    72: 'Al-Jinn',
    73: 'Al-Muzzammil',
    74: 'Al-Muddassir',
    75: 'Al-Qiyamah',
    76: 'Al-Insan',
    77: 'Al-Mursalat',
    78: "An-Naba'",
    79: "An-Nazi'at",
    80: 'Abasa',
    81: 'At-Takwir',
    82: 'Al-Infitar',
    83: 'Al-Muthaffifin',
    84: 'Al-Insyiqaq',
    85: 'Al-Buruj',
    86: 'At-Tariq',
    87: "Al-A'la",
    88: 'Al-Gasyiyah',
    89: 'Al-Fajr',
    90: 'Al-Balad',
    91: 'Asy-Syams',
    92: 'Al-Lail',
    93: 'Ad-Duha',
    94: 'Asy-Syarh',
    95: 'At-Tin',
    96: "Al-'Alaq",
    97: 'Al-Qadr',
    98: 'Al-Bayyinah',
    99: 'Az-Zalzalah',
    100: "Al-'Adiyat",
    101: "Al-Qari'ah",
    102: 'At-Takasur',
    103: "Al-'Asr",
    104: 'Al-Humazah',
    105: 'Al-Fil',
    106: 'Quraisy',
    107: "Al-Ma'un",
    108: 'Al-Kausar',
    109: 'Al-Kafirun',
    110: 'An-Nasr',
    111: 'Al-Masad',
    112: 'Al-Ikhlas',
    113: 'Al-Falaq',
    114: 'An-Nas',
  };

  static String nameOf(int surah) => surahLatin[surah] ?? 'Surah $surah';

  /// Label rentang target untuk juz [juz] bila mulai dari [startSurah]
  /// sampai surah terakhir (mis. "Al-Muthaffifin — An-Nas").
  static String rangeLabel(int juz, int startSurah) {
    final start = clampStart(juz, startSurah);
    final last = lastSurah(juz);
    if (start == last) return nameOf(last);
    return '${nameOf(start)} — ${nameOf(last)}';
  }
}
