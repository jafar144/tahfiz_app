import 'dart:math' as math;

import 'package:khoirunnasyien/features/recitation_check/domain/entities/recitation_result.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/recitation/arabic_normalizer.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/recitation/muqattaat.dart';

/// Mesin pencocokan bacaan: membandingkan teks mushaf (referensi) dengan hasil
/// transkripsi (ASR) memakai global alignment Needleman-Wunsch pada level kata.
///
/// Karena teks Al-Qur'an sudah pasti, kita tidak butuh model akustik — cukup
/// transkripsi lalu align ke teks yang seharusnya. Selisihnya = kesalahan.
///
/// Algoritma & parameter ini sudah diuji lewat referensi JS (14/14 kasus).
class RecitationMatcher {
  /// Penalti gap (kata di mushaf tak terbaca / kata terbaca di luar mushaf).
  /// Sedikit lebih besar dari -1 agar dua kata yang mirip lebih disukai
  /// ter-align sebagai substitusi (wrong) ketimbang missing + extra.
  static const double _gap = -1.1;

  /// Ambang toleransi ejaan/mad: bila dua kata cukup mirip (beda hanya ~1 huruf
  /// vokal panjang pada kata yang agak panjang), dianggap BENAR — bukan salah.
  ///
  /// Ini menutup beda ejaan rasm Utsmani vs hasil ASR (mis. dagger alef:
  /// عَٰبِدُونَ -> عبدون vs Whisper عابدون). Catatan: panjang-pendek (mad) memang
  /// tidak bisa dideteksi dari teks; ini hanya mencegah false-positive ejaan,
  /// bukan menilai tajwid. Kata pendek yang benar-benar beda (قل vs قال) tetap
  /// kena karena kemiripannya di bawah ambang.
  static const double _maddTolerance = 0.75;

  /// Ambang kemiripan agar DUA kata mushaf yang dibaca MENYATU (washal / liaison)
  /// lalu ditranskripsi ASR sebagai SATU kata dianggap benar keduanya. Mis.
  /// `مَا ٱبۡتَلَىٰهُ` dibaca "mabtalāhu" → Whisper menulis `مبتلاه`. Tanpa ini,
  /// satu kata jadi "kelewat" dan satunya "salah" padahal bacaannya benar.
  static const double _mergeTolerance = 0.72;

  static RecitationResult compare({
    required String referenceText,
    required String spokenText,
    String transcription = '',
  }) {
    final refPairs = ArabicNormalizer.tokenizeWithOriginal(referenceText);
    final ref = refPairs.map((p) => p.normalized).toList(growable: false);
    // Tandai kata yang diawali hamzatul wasl (ٱ): saat digabung ke kata
    // sebelumnya (washal), alef awalnya gugur dari bunyi.
    final refWasl = refPairs
        .map((p) => ArabicNormalizer.startsWithHamzatulWasl(p.original))
        .toList(growable: false);
    // Kuncupkan ejaan huruf muqatta'at (mis. "ألف لام ميم" -> "الم") agar cocok
    // dengan penulisan mushaf sebelum di-align.
    final hyp = Muqattaat.collapseSpoken(
      ref,
      ArabicNormalizer.tokenize(spokenText),
    );
    final m = ref.length;
    final n = hyp.length;

    // Matriks skor (m+1) x (n+1).
    final score = List.generate(
      m + 1,
      (_) => List<double>.filled(n + 1, 0.0),
      growable: false,
    );
    for (var i = 1; i <= m; i++) {
      score[i][0] = i * _gap;
    }
    for (var j = 1; j <= n; j++) {
      score[0][j] = j * _gap;
    }
    for (var i = 1; i <= m; i++) {
      for (var j = 1; j <= n; j++) {
        final sim = _similarity(ref[i - 1], hyp[j - 1]);
        final sub = score[i - 1][j - 1] + (2 * sim - 1); // sama:+1, beda:-1
        final del =
            score[i - 1][j] + _gap; // kata mushaf tak terbaca -> missing
        final ins =
            score[i][j - 1] + _gap; // kata terbaca di luar mushaf -> extra
        var best = math.max(sub, math.max(del, ins));
        // Merge: DUA kata mushaf (i-2, i-1) menyatu jadi SATU kata terbaca
        // (j-1) karena washal. Diterima hanya bila gabungan lebih mirip ke kata
        // terdengar daripada MASING-MASING kata sendirian — pembeda washal asli
        // vs kata yang memang kelewat/salah. Hadiahnya setara dua kata benar.
        if (i >= 2 && _mergeFits(ref, refWasl, hyp, i, j)) {
          final sm = _similarity(_mergedRef(ref, refWasl, i - 2), hyp[j - 1]);
          best = math.max(best, score[i - 2][j - 1] + 2 * sm);
        }
        // Split ASR: SATU kata mushaf kadang dipecah Whisper menjadi DUA token
        // (mis. "إيلافهم" -> "إيلا فهم"). Selama gabungannya paling cocok ke
        // kata mushaf, perlakukan sebagai satu bacaan kata yang benar.
        if (j >= 2 && _splitFits(ref, hyp, i, j)) {
          final sm = _similarity(ref[i - 1], hyp[j - 2] + hyp[j - 1]);
          best = math.max(best, score[i - 1][j - 2] + (2 * sm - 1));
        }
        score[i][j] = best;
      }
    }

    // Traceback. Prioritas: diagonal (sub) -> atas (missing) -> kiri (extra),
    // sama dengan referensi JS.
    final out = <WordDiff>[];
    var i = m;
    var j = n;
    while (i > 0 || j > 0) {
      if (i > 0 && j > 0) {
        final sim = _similarity(ref[i - 1], hyp[j - 1]);
        if (_closeEnough(score[i][j], score[i - 1][j - 1] + (2 * sim - 1))) {
          final isCorrect = _isCorrectWord(
            referenceOriginal: refPairs[i - 1].original,
            reference: ref[i - 1],
            spoken: hyp[j - 1],
            similarity: sim,
          );
          out.add(
            WordDiff(
              status: isCorrect ? WordStatus.correct : WordStatus.wrong,
              referenceWord: ref[i - 1],
              referenceWordDisplay: refPairs[i - 1].original,
              spokenWord: hyp[j - 1],
            ),
          );
          i--;
          j--;
          continue;
        }
      }
      // Split ASR: satu kata mushaf terpecah menjadi dua token transkripsi.
      if (i > 0 && j >= 2 && _splitFits(ref, hyp, i, j)) {
        final mergedHyp = hyp[j - 2] + hyp[j - 1];
        final sm = _similarity(ref[i - 1], mergedHyp);
        if (_closeEnough(score[i][j], score[i - 1][j - 2] + (2 * sm - 1))) {
          final isCorrect = _isCorrectWord(
            referenceOriginal: refPairs[i - 1].original,
            reference: ref[i - 1],
            spoken: mergedHyp,
            similarity: sm,
          );
          out.add(
            WordDiff(
              status: isCorrect ? WordStatus.correct : WordStatus.wrong,
              referenceWord: ref[i - 1],
              referenceWordDisplay: refPairs[i - 1].original,
              spokenWord: mergedHyp,
            ),
          );
          i--;
          j -= 2;
          continue;
        }
      }
      // Merge washal: dua kata mushaf (i-2, i-1) menyatu jadi satu kata terbaca
      // (j-1). Keduanya ditandai BENAR (bukan kelewat + salah).
      if (i >= 2 && j > 0 && _mergeFits(ref, refWasl, hyp, i, j)) {
        final sm = _similarity(_mergedRef(ref, refWasl, i - 2), hyp[j - 1]);
        if (_closeEnough(score[i][j], score[i - 2][j - 1] + 2 * sm)) {
          out.add(
            WordDiff(
              status: WordStatus.correct,
              referenceWord: ref[i - 1],
              referenceWordDisplay: refPairs[i - 1].original,
              spokenWord: hyp[j - 1],
            ),
          );
          out.add(
            WordDiff(
              status: WordStatus.correct,
              referenceWord: ref[i - 2],
              referenceWordDisplay: refPairs[i - 2].original,
              spokenWord: hyp[j - 1],
            ),
          );
          i -= 2;
          j--;
          continue;
        }
      }
      if (i > 0 && _closeEnough(score[i][j], score[i - 1][j] + _gap)) {
        out.add(
          WordDiff(
            status: WordStatus.missing,
            referenceWord: ref[i - 1],
            referenceWordDisplay: refPairs[i - 1].original,
          ),
        );
        i--;
        continue;
      }
      out.add(WordDiff(status: WordStatus.extra, spokenWord: hyp[j - 1]));
      j--;
    }

    final diffs = out.reversed.toList();
    final correct = diffs.where((d) => d.status == WordStatus.correct).length;
    final accuracy = m == 0 ? 0.0 : correct / m;

    return RecitationResult(
      diffs: diffs,
      accuracy: accuracy,
      referenceWordCount: m,
      transcription: transcription,
    );
  }

  static bool _isCorrectWord({
    required String referenceOriginal,
    required String reference,
    required String spoken,
    required double similarity,
  }) {
    if (reference == spoken || similarity >= _maddTolerance) return true;
    return _matchesWeakGeminatedTaaMarbuta(
      referenceOriginal: referenceOriginal,
      reference: reference,
      spoken: spoken,
    );
  }

  /// ASR can collapse words ending in geminated taa marbuta (`...\u0651\u0629`)
  /// to a common shorter spelling. A real example is Al-Haqqah:
  /// `\u0627\u0644\u062d\u0627\u0642\u0647` may be transcribed as
  /// `\u0627\u0644\u062d\u0642`.
  ///
  /// Keep this narrow: only raw mushaf words with shadda right before taa
  /// marbuta get this fallback, so ordinary short-word substitutions remain
  /// wrong.
  static bool _matchesWeakGeminatedTaaMarbuta({
    required String referenceOriginal,
    required String reference,
    required String spoken,
  }) {
    if (!_hasShaddaBeforeTaaMarbuta(referenceOriginal)) return false;
    if (!reference.endsWith('\u0647')) return false;
    if (spoken.endsWith('\u0647')) return false;

    final withoutFinalHa = reference.substring(0, reference.length - 1);
    final withoutMadd = _dropLastMaddLetter(withoutFinalHa);
    return withoutMadd != withoutFinalHa && spoken == withoutMadd;
  }

  static bool _hasShaddaBeforeTaaMarbuta(String rawWord) {
    final taaIndex = rawWord.lastIndexOf('\u0629');
    if (taaIndex <= 0) return false;
    for (var i = taaIndex - 1; i >= 0; i--) {
      final code = rawWord.codeUnitAt(i);
      if (code == 0x0651) return true;
      if (_isArabicMark(code) || code == 0x0640) continue;
      return false;
    }
    return false;
  }

  static bool _isArabicMark(int code) =>
      (code >= 0x0610 && code <= 0x061A) ||
      (code >= 0x064B && code <= 0x065F) ||
      code == 0x0670 ||
      (code >= 0x06D6 && code <= 0x06ED);

  static String _dropLastMaddLetter(String text) {
    for (var i = text.length - 2; i >= 1; i--) {
      final code = text.codeUnitAt(i);
      if (code == 0x0627 || code == 0x0648 || code == 0x064A) {
        return text.substring(0, i) + text.substring(i + 1);
      }
    }
    return text;
  }

  /// True bila menggabung dua kata mushaf (i-2, i-1) menjadi satu kata terbaca
  /// (j-1) layak — yakni gabungannya cukup mirip DAN lebih menjelaskan kata
  /// terdengar dibanding masing-masing kata sendirian. Guard "lebih baik dari
  /// keduanya" mencegah merge menutupi kata yang sebenarnya kelewat/salah
  /// (kasus itu: satu kata sudah cocok sendirian dengan kata terdengar).
  static bool _mergeFits(
    List<String> ref,
    List<bool> wasl,
    List<String> hyp,
    int i,
    int j,
  ) {
    final merged = _similarity(_mergedRef(ref, wasl, i - 2), hyp[j - 1]);
    if (merged < _mergeTolerance) return false;
    final single1 = _similarity(ref[i - 1], hyp[j - 1]);
    final single2 = _similarity(ref[i - 2], hyp[j - 1]);
    return merged > single1 && merged > single2;
  }

  /// True bila satu kata mushaf (i-1) paling masuk akal sebagai gabungan dua
  /// token ASR (j-2, j-1). Ini menutup variasi tokenisasi Whisper tanpa
  /// menganggap kata tambahan biasa sebagai benar.
  static bool _splitFits(List<String> ref, List<String> hyp, int i, int j) {
    final mergedHyp = hyp[j - 2] + hyp[j - 1];
    final merged = _similarity(ref[i - 1], mergedHyp);
    if (merged < _maddTolerance) return false;
    final single1 = _similarity(ref[i - 1], hyp[j - 2]);
    final single2 = _similarity(ref[i - 1], hyp[j - 1]);
    return merged > single1 && merged > single2;
  }

  /// Bentuk gabungan dua kata mushaf berurutan (indeks [a] dan [a]+1) untuk
  /// pengecekan washal: bila kata kedua diawali hamzatul wasl, alef awalnya
  /// digugurkan lebih dulu (bunyinya memang menyatu ke kata sebelumnya).
  static String _mergedRef(List<String> ref, List<bool> wasl, int a) {
    final b = a + 1;
    var second = ref[b];
    if (wasl[b] && second.startsWith('ا')) {
      second = second.substring(1);
    }
    return ref[a] + second;
  }

  static bool _closeEnough(double a, double b) => (a - b).abs() < 1e-9;

  /// Kemiripan karakter 0..1 (1 = identik) berbasis jarak Levenshtein.
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
        final del = prev[j] + 1;
        final ins = cur[j - 1] + 1;
        final subst = prev[j - 1] + cost;
        cur[j] = math.min(del, math.min(ins, subst));
      }
      final tmp = prev;
      prev = cur;
      cur = tmp;
    }
    return prev[n];
  }
}
