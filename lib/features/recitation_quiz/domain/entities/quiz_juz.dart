/// Metadata juz yang didukung Kuis Hafalan (29 & 30) + nama surah Latin.
///
/// Dipakai bersama oleh repo (menyusun pool ayat), layar intro, dan lembar
/// pengaturan (memilih rentang target hafalan). Sumber tunggal agar rentang
/// surah tiap juz konsisten di seluruh fitur.
class QuizJuz {
  QuizJuz._();

  /// Juz yang didukung, urut menaik.
  static const List<int> supported = [29, 30];

  /// Rentang surah [pertama, terakhir] tiap juz (id surah mushaf).
  static const Map<int, (int first, int last)> _range = {
    29: (67, 77), // Al-Mulk .. Al-Mursalat
    30: (78, 114), // An-Naba' .. An-Nas
  };

  static bool isSupported(int juz) => _range.containsKey(juz);

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

  /// Nama Latin surah untuk tampilan (khusus surah dalam juz 29 & 30).
  static const Map<int, String> surahLatin = {
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
