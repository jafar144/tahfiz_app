/// Normalisasi teks Arab agar perbandingan toleran terhadap perbedaan harakat
/// dan varian huruf.
///
/// Logika ini identik dengan referensi JS yang sudah diuji (14/14 kasus:
/// strip harakat, dagger alef, taa marbuta, substitusi, missing, extra, dst).
///
/// Semua kelas/karakter Arab ditulis sebagai escape `\u` di dalam string biasa
/// (bukan raw, bukan karakter Arab langsung). Dart mengubah `\uXXXX` menjadi
/// karakter asli saat kompilasi string, jadi source tetap ASCII murni dan aman
/// dari combining-mark yang tidak terlihat di editor.
class ArabicNormalizer {
  // Alef maqsura (ى) berdagger alef (ٰ) — satu bunyi mad "aa" (mis. ٱبۡتَلَىٰهُ).
  static final RegExp _alefMaqsuraDagger = RegExp('ىٰ');
  // Dagger alef berdiri sendiri (mis. هَٰذَا, ٱلرَّحۡمَٰن) — bunyi mad "aa".
  static final RegExp _daggerAlef = RegExp('ٰ');
  // Tanda huruf kecil Qurani untuk mad "uu"/"ii" (mis. إِۦلَٰفِهِمۡ).
  static final RegExp _smallWaw = RegExp('ۥ');
  static final RegExp _smallYeh = RegExp('ۦ');
  // Tanda harakat + tanda anotasi mushaf yang dibuang. Dagger alef (U+0670)
  // sudah ditangani lebih dulu di atas sehingga tak lagi tergantung di sini.
  static final RegExp _harakat = RegExp('[ؐ-ًؚ-ٰٟۖ-ۜ۟-۪ۤۧۨ-ۭ]');
  static final RegExp _tatweel = RegExp('ـ');
  // Varian alef (آ أ إ ٱ ٲ ٳ) -> ا (ا)
  static final RegExp _alef = RegExp('[آأإٱٲٳ]');
  static final RegExp _alefMaqsura = RegExp('ى'); // ى -> ا (bunyi "aa")
  static final RegExp _taaMarbuta = RegExp('ة'); // ة -> ه
  static final RegExp _wawHamza = RegExp('ؤ'); // ؤ -> و
  static final RegExp _yaaHamza = RegExp('ئ'); // ئ -> ي
  static final RegExp _hamza = RegExp('ء'); // ء -> hapus
  // Sisakan hanya huruf Arab dasar (ء..ي).
  static final RegExp _nonArabicLetter = RegExp('[^ء-ي]');
  static final RegExp _whitespace = RegExp(r'\s+');

  /// Alef washal (hamzatul wasl, ٱ U+0671) — di tengah kalimat dibaca menyambung
  /// (bunyinya gugur). Dipakai pencocok untuk menggabung kata saat washal.
  static const int hamzatulWaslRune = 0x0671;

  /// True bila kata mentah [rawWord] diawali hamzatul wasl (ٱ) — kandidat kata
  /// yang menyambung ke kata sebelumnya saat dibaca washal.
  static bool startsWithHamzatulWasl(String rawWord) =>
      rawWord.isNotEmpty && rawWord.runes.first == hamzatulWaslRune;

  /// Normalisasi satu kata menjadi huruf Arab telanjang tanpa harakat.
  ///
  /// Mad yang ditulis sebagai dagger alef (ٰ) atau alef maqsura+dagger (ىٰ)
  /// disamakan menjadi ا (fonetik "aa"), sedangkan small waw/yeh Qurani
  /// disamakan menjadi و/ي, agar cocok dengan tulisan ASR (Whisper) yang
  /// mengeja bunyi panjang itu sebagai huruf penuh.
  static String normalizeWord(String text) {
    if (text.isEmpty) return '';
    // Tangani mad "aa" (dagger alef & alef maqsura+dagger) SEBELUM harakat
    // lain dibuang, agar bunyinya tetap terwakili sebagai huruf penuh.
    var t = text
        .replaceAll(_alefMaqsuraDagger, 'ا') // ىٰ -> ا (satu mad)
        .replaceAll(_daggerAlef, 'ا') // ٰ  -> ا
        .replaceAll(_smallWaw, 'و') // ۥ  -> و
        .replaceAll(_smallYeh, 'ي'); // ۦ  -> ي
    t = t.replaceAll(_harakat, '').replaceAll(_tatweel, '');
    t = t
        .replaceAll(_alef, 'ا') // -> ا
        .replaceAll(_alefMaqsura, 'ا') // ى -> ا (bunyi "aa")
        .replaceAll(_taaMarbuta, 'ه') // -> ه
        .replaceAll(_wawHamza, 'و') // -> و
        .replaceAll(_yaaHamza, 'ي') // -> ي
        .replaceAll(_hamza, '');
    t = t.replaceAll(_nonArabicLetter, '');
    return t;
  }

  /// Pisah teks menjadi token kata yang sudah dinormalisasi (token kosong dibuang).
  static List<String> tokenize(String text) {
    if (text.isEmpty) return const [];
    return text
        .split(_whitespace)
        .map(normalizeWord)
        .where((w) => w.isNotEmpty)
        .toList();
  }

  /// Seperti [tokenize] tapi menyimpan bentuk asli (berharakat) tiap kata
  /// sejajar dengan bentuk ternormalisasinya. Token yang ternormalisasi kosong
  /// (mis. hanya tanda baca) dibuang agar tetap sinkron dengan [tokenize].
  static List<({String original, String normalized})> tokenizeWithOriginal(
    String text,
  ) {
    if (text.isEmpty) return const [];
    final result = <({String original, String normalized})>[];
    for (final raw in text.split(_whitespace)) {
      if (raw.isEmpty) continue;
      final norm = normalizeWord(raw);
      if (norm.isEmpty) continue;
      result.add((original: raw, normalized: norm));
    }
    return result;
  }
}
