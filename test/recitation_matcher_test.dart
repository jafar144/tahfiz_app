import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/entities/recitation_result.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/recitation/arabic_normalizer.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/recitation/recitation_matcher.dart';

/// Mirror dari uji JS (Node) yang sudah lolos 14/14. Memuat asset Quran asli.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> fatihah; // ayat[0] = ayat 1, dst.
  late List<String> kafirun; // surah 109

  setUpAll(() async {
    final raw = await rootBundle.loadString('assets/quran/quran.json');
    final data = json.decode(raw) as List<dynamic>;
    fatihah = ((data.firstWhere((e) => e['id'] == 1))['verses'] as List<dynamic>)
        .cast<String>();
    kafirun = ((data.firstWhere((e) => e['id'] == 109))['verses'] as List<dynamic>)
        .cast<String>();
  });

  int countStatus(RecitationResult r, WordStatus s) =>
      r.diffs.where((d) => d.status == s).length;

  group('ArabicNormalizer', () {
    test('hasil normalisasi bebas harakat & non-huruf', () {
      final norm = ArabicNormalizer.normalizeWord(fatihah[0].split(' ').first);
      expect(norm.isNotEmpty, true);
      expect(RegExp('[^ء-ي]').hasMatch(norm), false);
    });

    test('tokenize ayat menghasilkan token sesuai jumlah kata', () {
      final words = fatihah[1].split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
      expect(ArabicNormalizer.tokenize(fatihah[1]).length, words.length);
    });
  });

  group('RecitationMatcher', () {
    test('case 1: bacaan sempurna -> 100%', () {
      final ref = '${fatihah[0]} ${fatihah[1]}';
      final r = RecitationMatcher.compare(referenceText: ref, spokenText: ref);
      expect(r.accuracy, 1.0);
      expect(r.diffs.every((d) => d.status == WordStatus.correct), true);
    });

    test('case 2: satu kata salah -> 1 wrong', () {
      final w = fatihah[1].split(RegExp(r'\s+'));
      // ganti kata ke-3 dengan kata lain (pakai kata dari ayat 1 agar beda).
      final other = fatihah[0].split(RegExp(r'\s+')).first;
      final spoken = [w[0], w[1], other, w[3]].join(' ');
      final r = RecitationMatcher.compare(
        referenceText: fatihah[1],
        spokenText: spoken,
      );
      expect(countStatus(r, WordStatus.wrong), 1);
      expect(countStatus(r, WordStatus.missing), 0);
      expect(countStatus(r, WordStatus.extra), 0);
    });

    test('case 3: satu kata kelewat -> 1 missing', () {
      final w = fatihah[1].split(RegExp(r'\s+'));
      final spoken = [w[0], w[1], w[3]].join(' ');
      final r = RecitationMatcher.compare(
        referenceText: fatihah[1],
        spokenText: spoken,
      );
      expect(countStatus(r, WordStatus.missing), 1);
    });

    test('case 4: kata tambahan -> 1 extra', () {
      final extra = fatihah[1].split(RegExp(r'\s+')).first;
      final spoken = '${fatihah[0]} $extra';
      final r = RecitationMatcher.compare(
        referenceText: fatihah[0],
        spokenText: spoken,
      );
      expect(countStatus(r, WordStatus.extra), 1);
    });

    test('case 5: skip ayat penuh di tengah -> missing sepanjang ayat itu', () {
      final ref = '${fatihah[0]} ${fatihah[1]} ${fatihah[2]}';
      final spoken = '${fatihah[0]} ${fatihah[2]}';
      final r = RecitationMatcher.compare(referenceText: ref, spokenText: spoken);
      expect(
        countStatus(r, WordStatus.missing),
        ArabicNormalizer.tokenize(fatihah[1]).length,
      );
      expect(r.accuracy < 1.0, true);
    });

    test('case 6: dagger-alef (عَٰبِدُونَ) vs alef penuh ASR -> tetap benar', () {
      final ref = kafirun[2]; // mengandung عَٰبِدُونَ (dagger alef U+0670)
      // Simulasi Whisper menulis alef penuh: ganti U+0670 -> U+0627.
      final spoken = String.fromCharCodes(
        ref.runes.map((r) => r == 0x0670 ? 0x0627 : r),
      );
      final r = RecitationMatcher.compare(referenceText: ref, spokenText: spoken);
      expect(r.diffs.any((d) => d.status == WordStatus.wrong), false);
      expect(r.accuracy, 1.0);
    });

    test('case 7: kata pendek beda (قل vs قال) tetap salah', () {
      final r = RecitationMatcher.compare(referenceText: 'قُلۡ', spokenText: 'قَالَ');
      expect(
        r.diffs.any((d) =>
            d.status == WordStatus.wrong || d.status == WordStatus.missing),
        true,
      );
    });
  });
}
