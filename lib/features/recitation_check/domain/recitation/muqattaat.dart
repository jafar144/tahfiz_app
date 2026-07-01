import 'dart:math' as math;

/// Penanganan huruf **muqatta'at** (huruf-huruf terpisah di awal sebagian surah,
/// mis. `الٓمٓ`, `حمٓ`, `الٓرۚ`).
///
/// Di mushaf ditulis sebagai satu "kata", tetapi dibaca sebagai rangkaian nama
/// huruf ("alif lām mīm"). Mesin ASR bisa mentranskripsinya sebagai ejaan
/// nama huruf (`ألف لام ميم`) ATAU sebagai ligaturnya (`الم`). Agar pencocokan
/// kata-per-kata tidak salah, ejaan nama huruf pada hasil transkripsi
/// "dikuncupkan" kembali menjadi ligatur mushaf sebelum alignment.
class Muqattaat {
  /// Bentuk muqatta'at pada level ayat (sudah dinormalisasi, tanpa harakat).
  static const Set<String> forms = {
    'الم', 'المص', 'الر', 'المر', 'كهيعص', 'طه',
    'طسم', 'طس', 'يس', 'ص', 'حم', 'عسق', 'ق', 'ن',
  };

  /// Peta huruf -> nama huruf (dinormalisasi) sebagaimana dieja saat dibaca.
  static const Map<String, String> _names = {
    'ا': 'الف', 'ل': 'لام', 'م': 'ميم', 'ص': 'صاد', 'ر': 'را',
    'ك': 'كاف', 'ه': 'ها', 'ي': 'يا', 'ع': 'عين', 'ط': 'طا',
    'س': 'سين', 'ح': 'حا', 'ن': 'نون', 'ق': 'قاف',
  };

  static bool isMuqattaat(String normalizedToken) =>
      forms.contains(normalizedToken);

  /// Urutan nama huruf yang diharapkan untuk sebuah ligatur, mis.
  /// `الم` -> [`الف`, `لام`, `ميم`].
  static List<String> expectedNames(String ligature) =>
      ligature.split('').map((ch) => _names[ch] ?? ch).toList();

  /// Kuncupkan ejaan nama huruf pada [hyp] (token transkripsi, ternormalisasi)
  /// menjadi ligatur sesuai [ref]. Hanya menyentuh bagian awal, karena
  /// muqatta'at selalu di awal surah; token sebelum muqatta'at (mis. isti'adzah
  /// / basmalah yang terbaca) dibiarkan agar dinilai apa adanya.
  static List<String> collapseSpoken(List<String> ref, List<String> hyp) {
    if (ref.isEmpty || !isMuqattaat(ref.first)) return hyp;
    final out = List<String>.from(hyp);
    var r = 0;
    var from = 0;
    while (r < ref.length && isMuqattaat(ref[r])) {
      final ligature = ref[r];
      final hit = _find(out, from, ligature, expectedNames(ligature));
      if (hit == null) break;
      out.replaceRange(hit.$1, hit.$1 + hit.$2, [ligature]);
      from = hit.$1 + 1;
      r++;
    }
    return out;
  }

  /// Cari posisi muqatta'at pada [t] mulai [from] (dalam jendela kecil):
  /// ligatur langsung, atau rangkaian nama huruf lengkap. Mengembalikan
  /// (indexAwal, jumlahToken) atau null.
  static (int, int)? _find(
    List<String> t,
    int from,
    String ligature,
    List<String> names,
  ) {
    final limit = math.min(t.length, from + 8);
    for (var i = from; i < limit; i++) {
      if (_similarity(t[i], ligature) >= 0.8) return (i, 1);
      var matchesNames = names.isNotEmpty;
      for (var k = 0; k < names.length; k++) {
        if (i + k >= t.length || _similarity(t[i + k], names[k]) < 0.7) {
          matchesNames = false;
          break;
        }
      }
      if (matchesNames) return (i, names.length);
    }
    return null;
  }

  static double _similarity(String a, String b) {
    if (a == b) return 1.0;
    final maxLen = math.max(a.length, b.length);
    if (maxLen == 0) return 1.0;
    return 1.0 - _levenshtein(a, b) / maxLen;
  }

  static int _levenshtein(String a, String b) {
    final m = a.length;
    final n = b.length;
    if (m == 0) return n;
    if (n == 0) return m;
    var prev = List<int>.generate(n + 1, (k) => k);
    var cur = List<int>.filled(n + 1, 0);
    for (var i = 1; i <= m; i++) {
      cur[0] = i;
      for (var j = 1; j <= n; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        cur[j] = math.min(
          math.min(prev[j] + 1, cur[j - 1] + 1),
          prev[j - 1] + cost,
        );
      }
      final tmp = prev;
      prev = cur;
      cur = tmp;
    }
    return prev[n];
  }
}
