import 'dart:math' as math;

import 'package:khoirunnasyien/features/recitation_check/domain/entities/recitation_result.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/recitation/arabic_normalizer.dart';

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

  static RecitationResult compare({
    required String referenceText,
    required String spokenText,
    String transcription = '',
  }) {
    final ref = ArabicNormalizer.tokenize(referenceText);
    final hyp = ArabicNormalizer.tokenize(spokenText);
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
        final del = score[i - 1][j] + _gap; // kata mushaf tak terbaca -> missing
        final ins = score[i][j - 1] + _gap; // kata terbaca di luar mushaf -> extra
        score[i][j] = math.max(sub, math.max(del, ins));
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
          final isCorrect = ref[i - 1] == hyp[j - 1] || sim >= _maddTolerance;
          out.add(WordDiff(
            status: isCorrect ? WordStatus.correct : WordStatus.wrong,
            referenceWord: ref[i - 1],
            spokenWord: hyp[j - 1],
          ));
          i--;
          j--;
          continue;
        }
      }
      if (i > 0 && _closeEnough(score[i][j], score[i - 1][j] + _gap)) {
        out.add(WordDiff(status: WordStatus.missing, referenceWord: ref[i - 1]));
        i--;
        continue;
      }
      out.add(WordDiff(status: WordStatus.extra, spokenWord: hyp[j - 1]));
      j--;
    }

    final diffs = out.reversed.toList();
    final correct =
        diffs.where((d) => d.status == WordStatus.correct).length;
    final accuracy = m == 0 ? 0.0 : correct / m;

    return RecitationResult(
      diffs: diffs,
      accuracy: accuracy,
      referenceWordCount: m,
      transcription: transcription,
    );
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
