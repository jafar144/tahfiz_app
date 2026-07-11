import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/entities/ayah.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_juz.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/quiz_knowledge_bank.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/arabic_highlight_matcher.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/surah_lesson_seed.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  String ayahKey(int surahId, int ayahNumber) => '$surahId:$ayahNumber';

  group('QuizJuz', () {
    test('supports the full ayah segments for Juz 4 and 5', () {
      expect(QuizJuz.supported, containsAll([4, 5]));
      expect(QuizJuz.ayahSegments(4), [(3, 92, 200), (4, 1, 23)]);
      expect(QuizJuz.ayahSegments(5), [(4, 24, 147)]);
      expect(QuizJuz.spanLabel(4), "Ali 'Imran 92 — An-Nisa 23");
      expect(QuizJuz.spanLabel(5), 'An-Nisa 24—147');
    });
  });

  group('SurahJourneySeed', () {
    test('continues sequentially from Al-Lail to An-Naba', () {
      final lessons = SurahLessonSeed.lessons;

      expect(lessons.map((lesson) => lesson.surahId), [
        for (var id = 92; id >= 78; id--) id,
      ]);
      expect(lessons.map((lesson) => lesson.level), [
        for (var level = 1; level <= 15; level++) level,
      ]);
    });

    test(
      'every vocabulary item can be highlighted in its source ayah',
      () async {
        final raw = await rootBundle.loadString('assets/quran/hafs_v18.json');
        final rows = json.decode(raw) as List<dynamic>;
        final ayahText = <String, String>{};
        for (final row in rows) {
          final surahId = row['sora'] as int;
          final ayahNumber = row['aya_no'] as int;
          ayahText[ayahKey(surahId, ayahNumber)] = row['aya_text'] as String;
        }

        for (final lesson in SurahLessonSeed.lessons) {
          for (final section in lesson.sections) {
            for (final item in section.vocabItems) {
              final lessonName = lesson.nameLatin;
              final itemNumber = item.ayahNumber;
              final word = item.word;
              final key = ayahKey(lesson.surahId, itemNumber);
              final source = ayahText[key];
              expect(
                source,
                isNotNull,
                reason: '$lessonName ayat $itemNumber tidak ada',
              );
              expect(
                ArabicHighlightMatcher.find(text: source!, highlight: word),
                isNotNull,
                reason:
                    '$lessonName ayat $itemNumber: "$word" tidak dapat disorot',
              );
            }
          }
        }
      },
    );

    test(
      'quiz vocabulary shows its source ayah and capitalized meanings',
      () async {
        final raw = await rootBundle.loadString('assets/quran/hafs_v18.json');
        final rows = json.decode(raw) as List<dynamic>;
        final ayat = [
          for (final row in rows)
            if (row['sora'] == 92)
              Ayah(
                surahId: row['sora'] as int,
                number: row['aya_no'] as int,
                text: row['aya_text'] as String,
              ),
        ];

        final question = QuizKnowledgeBank.vocabularyMeaning(
          allowedSurahs: const {92},
          ayat: ayat,
          rng: Random(7),
        );

        expect(question, isNotNull);
        expect(question!.arabicText, isNotNull);
        expect(question.highlightWord, isNotNull);
        expect(question.arabicText, isNot(question.highlightWord));
        expect(
          ArabicHighlightMatcher.find(
            text: question.arabicText!,
            highlight: question.highlightWord!,
          ),
          isNotNull,
        );
        for (final meaning in question.options) {
          expect(meaning[0], meaning[0].toUpperCase());
        }
      },
    );
  });
}
