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
  // Tanda harakat + tanda anotasi mushaf yang dibuang.
  static final RegExp _harakat = RegExp(
    '[ؐ-ًؚ-ٰٟۖ-ۜ۟-۪ۤۧۨ-ۭ]',
  );
  static final RegExp _tatweel = RegExp('ـ');
  // Varian alef (آ أ إ ٱ ٲ ٳ) -> ا (ا)
  static final RegExp _alef = RegExp('[آأإٱٲٳ]');
  static final RegExp _alefMaqsura = RegExp('ى'); // ى -> ي
  static final RegExp _taaMarbuta = RegExp('ة'); // ة -> ه
  static final RegExp _wawHamza = RegExp('ؤ'); // ؤ -> و
  static final RegExp _yaaHamza = RegExp('ئ'); // ئ -> ي
  static final RegExp _hamza = RegExp('ء'); // ء -> hapus
  // Sisakan hanya huruf Arab dasar (ء..ي).
  static final RegExp _nonArabicLetter = RegExp('[^ء-ي]');
  static final RegExp _whitespace = RegExp(r'\s+');

  /// Normalisasi satu kata menjadi huruf Arab telanjang tanpa harakat.
  static String normalizeWord(String text) {
    if (text.isEmpty) return '';
    var t = text.replaceAll(_harakat, '').replaceAll(_tatweel, '');
    t = t
        .replaceAll(_alef, 'ا') // -> ا
        .replaceAll(_alefMaqsura, 'ي') // -> ي
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
