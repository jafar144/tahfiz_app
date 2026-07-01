import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/entities/ayah.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/entities/recitation_result.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/recitation/arabic_normalizer.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/recitation/recitation_matcher.dart';
import 'package:khoirunnasyien/features/recitation_check/presentation/widgets/mushaf_view.dart';

/// Mirror dari uji JS (Node) yang sudah lolos 14/14. Memuat asset Quran asli.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> fatihah; // ayat[0] = ayat 1, dst.
  late List<String> kafirun; // surah 109
  late List<String> baqarah; // surah 2 (ayat 1 = muqatta'at الٓمٓ)

  setUpAll(() async {
    final raw = await rootBundle.loadString('assets/quran/quran.json');
    final data = json.decode(raw) as List<dynamic>;
    fatihah = ((data.firstWhere((e) => e['id'] == 1))['verses'] as List<dynamic>)
        .cast<String>();
    kafirun = ((data.firstWhere((e) => e['id'] == 109))['verses'] as List<dynamic>)
        .cast<String>();
    baqarah = ((data.firstWhere((e) => e['id'] == 2))['verses'] as List<dynamic>)
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

    test('tokenizeWithOriginal sejajar & simpan harakat asli', () {
      final pairs = ArabicNormalizer.tokenizeWithOriginal(fatihah[1]);
      final plain = ArabicNormalizer.tokenize(fatihah[1]);
      expect(pairs.length, plain.length);
      for (var i = 0; i < pairs.length; i++) {
        expect(pairs[i].normalized, plain[i]);
      }
      // Minimal satu kata harus punya harakat (beda dari bentuk telanjang).
      expect(pairs.any((p) => p.original != p.normalized), true);
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

    test('diff membawa teks asli berharakat untuk ditampilkan', () {
      final r = RecitationMatcher.compare(
        referenceText: fatihah[1],
        spokenText: fatihah[1],
      );
      // Semua kata benar; tiap diff harus punya bentuk tampilan berharakat
      // dan berbeda dari bentuk ternormalisasinya.
      expect(r.diffs.isNotEmpty, true);
      for (final d in r.diffs) {
        expect(d.referenceWordDisplay, isNotNull);
      }
      expect(
        r.diffs.any((d) => d.referenceWordDisplay != d.referenceWord),
        true,
      );
    });
  });

  group('Muqattaat (huruf terpisah)', () {
    test('dieja per huruf (ألف لام ميم) tetap benar', () {
      final r = RecitationMatcher.compare(
        referenceText: baqarah[0], // الٓمٓ
        spokenText: 'ألف لام ميم',
      );
      expect(r.diffs.length, 1);
      expect(r.diffs.first.status, WordStatus.correct);
      expect(r.accuracy, 1.0);
    });

    test('ligatur langsung (الم) juga benar', () {
      final r = RecitationMatcher.compare(
        referenceText: baqarah[0],
        spokenText: 'الم',
      );
      expect(r.diffs.first.status, WordStatus.correct);
    });

    test('isti\'adzah/basmalah sebelum muqatta\'at tidak merusak', () {
      final r = RecitationMatcher.compare(
        referenceText: baqarah[0],
        spokenText: 'بسم الله الرحمن الرحيم ألف لام ميم',
      );
      // Muqatta'at tetap dinilai benar; kata basmalah jadi "tambahan".
      expect(
        r.diffs.any((d) =>
            d.status == WordStatus.correct && d.referenceWord == 'الم'),
        true,
      );
    });

    test('muqatta\'at + lanjutan ayat berikutnya', () {
      // الٓمٓ (2:1) + ذٰلِكَ ٱلۡكِتَٰبُ ... (2:2) dieja huruf lalu lanjut normal.
      final ref = '${baqarah[0]} ${baqarah[1]}';
      final spoken = 'ألف لام ميم ${baqarah[1]}';
      final r = RecitationMatcher.compare(referenceText: ref, spokenText: spoken);
      expect(r.diffs.any((d) => d.status == WordStatus.wrong), false);
      expect(r.accuracy, 1.0);
    });
  });

  group('buildTargetColoring', () {
    test('memetakan diff per ayat & mencakup seluruh diff', () {
      final targetAyat = [
        Ayah(surahId: 1, number: 1, text: fatihah[0]),
        Ayah(surahId: 1, number: 2, text: fatihah[1]),
        Ayah(surahId: 1, number: 3, text: fatihah[2]),
      ];
      final ref = targetAyat.map((a) => a.text).join(' ');
      final r = RecitationMatcher.compare(referenceText: ref, spokenText: ref);
      final map = buildTargetColoring(targetAyat, r);

      // Tiap ayat: jumlah diff referensi == jumlah token ayat.
      for (final a in targetAyat) {
        final slice = map['${a.surahId}:${a.number}']!;
        final refCount =
            slice.where((d) => d.status != WordStatus.extra).length;
        expect(refCount, ArabicNormalizer.tokenizeWithOriginal(a.text).length);
      }
      // Gabungan seluruh slice == seluruh diff (tak ada yang hilang/ganda).
      final total = map.values.fold<int>(0, (s, l) => s + l.length);
      expect(total, r.diffs.length);
    });
  });
}
