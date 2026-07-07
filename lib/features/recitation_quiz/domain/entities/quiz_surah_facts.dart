/// Fakta surah untuk soal trivia Kuis Hafalan: ARTI nama surah & JUMLAH AYAT.
///
/// Mencakup surah juz 1-3 (Al-Fatihah, Al-Baqarah, Ali 'Imran) & juz 29-30
/// (67..114) — selaras [QuizJuz.surahLatin].
/// Sumber arti: terjemahan nama surah yang umum dipakai mushaf Indonesia
/// (Kemenag). Jumlah ayat mengikuti hitungan Kufi (mushaf Madinah/Hafs).
///
/// Catatan: beberapa surah punya arti yang sama persis (mis. Al-Insan & An-Nas
/// = "Manusia"; Al-Infitar & Al-Insyiqaq = "Terbelah"). Penyusun opsi soal
/// wajib men-dedup berdasarkan TEKS arti agar tak ada dua opsi kembar.
class QuizSurahFacts {
  QuizSurahFacts._();

  /// Arti nama surah (Indonesia) per id surah.
  static const Map<int, String> meaning = {
    1: 'Pembukaan',
    2: 'Sapi Betina',
    3: 'Keluarga Imran',
    67: 'Kerajaan',
    68: 'Pena',
    69: 'Hari Kiamat yang Pasti Terjadi',
    70: 'Tempat-Tempat Naik',
    71: 'Nabi Nuh',
    72: 'Jin',
    73: 'Orang yang Berselimut',
    74: 'Orang yang Berkemul',
    75: 'Hari Kiamat',
    76: 'Manusia',
    77: 'Malaikat yang Diutus',
    78: 'Berita Besar',
    79: 'Malaikat yang Mencabut',
    80: 'Bermuka Masam',
    81: 'Penggulungan',
    82: 'Terbelah',
    83: 'Orang-Orang yang Curang',
    84: 'Terbelah',
    85: 'Gugusan Bintang',
    86: 'Yang Datang di Malam Hari',
    87: 'Yang Mahatinggi',
    88: 'Hari Pembalasan',
    89: 'Fajar',
    90: 'Negeri',
    91: 'Matahari',
    92: 'Malam',
    93: 'Waktu Duha',
    94: 'Kelapangan',
    95: 'Buah Tin',
    96: 'Segumpal Darah',
    97: 'Kemuliaan',
    98: 'Bukti Nyata',
    99: 'Guncangan',
    100: 'Kuda yang Berlari Kencang',
    101: 'Hari Kiamat yang Menggetarkan',
    102: 'Bermegah-megahan',
    103: 'Masa',
    104: 'Pengumpat',
    105: 'Gajah',
    106: 'Suku Quraisy',
    107: 'Barang yang Berguna',
    108: 'Nikmat yang Banyak',
    109: 'Orang-Orang Kafir',
    110: 'Pertolongan',
    111: 'Sabut',
    112: 'Memurnikan Keesaan Allah',
    113: 'Waktu Subuh',
    114: 'Manusia',
  };

  /// Jumlah ayat per id surah (hitungan Kufi — mushaf Madinah/Hafs).
  static const Map<int, int> ayahCount = {
    1: 7,
    2: 286,
    3: 200,
    67: 30,
    68: 52,
    69: 52,
    70: 44,
    71: 28,
    72: 28,
    73: 20,
    74: 56,
    75: 40,
    76: 31,
    77: 50,
    78: 40,
    79: 46,
    80: 42,
    81: 29,
    82: 19,
    83: 36,
    84: 25,
    85: 22,
    86: 17,
    87: 19,
    88: 26,
    89: 30,
    90: 20,
    91: 15,
    92: 21,
    93: 11,
    94: 8,
    95: 8,
    96: 19,
    97: 5,
    98: 8,
    99: 8,
    100: 11,
    101: 11,
    102: 8,
    103: 3,
    104: 9,
    105: 5,
    106: 4,
    107: 7,
    108: 3,
    109: 6,
    110: 3,
    111: 5,
    112: 4,
    113: 5,
    114: 6,
  };

  /// True bila surah [s] punya data lengkap (arti + jumlah ayat).
  static bool has(int s) => meaning.containsKey(s) && ayahCount.containsKey(s);

  static String meaningOf(int s) => meaning[s] ?? '-';

  static int ayahCountOf(int s) => ayahCount[s] ?? 0;
}
