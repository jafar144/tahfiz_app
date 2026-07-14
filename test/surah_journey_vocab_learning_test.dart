import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/entities/ayah.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/entities/lesson_question.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/entities/lesson_section.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/lesson_config.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/surah_lesson_seed.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/vocab_learning_rules.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/vocab_lesson_question_factory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<int, List<Ayah>> ayatBySurah;
  const factory = VocabLessonQuestionFactory();

  setUpAll(() async {
    final raw = await rootBundle.loadString('assets/quran/hafs_v18.json');
    final rows = json.decode(raw) as List<dynamic>;
    ayatBySurah = {};
    for (final row in rows) {
      final surahId = row['sora'] as int;
      ayatBySurah
          .putIfAbsent(surahId, () => [])
          .add(
            Ayah(
              surahId: surahId,
              number: row['aya_no'] as int,
              text: row['aya_text'] as String,
              page: row['page'] as int,
              surahName: row['sora_name_ar'] as String,
            ),
          );
    }
  });

  test('aturan Kosa Kata dipisah menjadi kuis 5, 10, dan 3 soal', () {
    expect(VocabLearningRules.phaseOneArabicToMeaningCount, 5);
    expect(
      VocabLearningRules.questionCountFor(VocabLearningPhase.mixedPractice),
      10,
    );
    expect(VocabLearningRules.phaseThreeMeaningRecallCount, 3);
    expect(VocabLearningRules.totalQuestionCount, 18);
    expect(VocabLearningRules.minCorrect, 15);
    expect(
      [
        for (final phase in VocabLearningPhase.values)
          VocabLearningRules.minCorrectFor(phase),
      ],
      [4, 8, 3],
    );
  });

  test('seluruh surah dapat membentuk tiga fase dengan komposisi tepat', () {
    for (final lesson in SurahLessonSeed.lessons) {
      final section = lesson.sections.singleWhere(
        (section) => section.test.useVocabQuestions,
      );
      final questions = factory.buildLearningPhases(
        items: section.vocabItems,
        ayat: ayatBySurah[lesson.surahId]!,
        rng: Random(lesson.surahId),
      );

      expect(
        questions,
        hasLength(VocabLearningRules.totalQuestionCount),
        reason: lesson.nameLatin,
      );

      final phaseOne = questions
          .where(
            (question) =>
                question.vocabPhase == VocabLearningPhase.arabicToMeaning,
          )
          .toList();
      expect(phaseOne, hasLength(5), reason: lesson.nameLatin);
      expect(
        phaseOne.every(
          (question) =>
              question.fact?.arabicText != null &&
              question.fact?.arabicOptions == false,
        ),
        isTrue,
        reason: lesson.nameLatin,
      );

      final phaseTwo = questions
          .where(
            (question) =>
                question.vocabPhase == VocabLearningPhase.mixedPractice,
          )
          .toList();
      expect(phaseTwo, hasLength(10), reason: lesson.nameLatin);
      expect(
        phaseTwo.where((question) => question.isMatch),
        hasLength(2),
        reason: lesson.nameLatin,
      );
      expect(
        phaseTwo.where((question) => question.fact?.arabicText != null),
        hasLength(4),
        reason: lesson.nameLatin,
      );
      expect(
        phaseTwo.where((question) => question.fact?.arabicOptions == true),
        hasLength(4),
        reason: lesson.nameLatin,
      );

      final phaseThree = questions
          .where(
            (question) =>
                question.vocabPhase == VocabLearningPhase.meaningRecall,
          )
          .toList();
      expect(phaseThree, hasLength(3), reason: lesson.nameLatin);
      for (final question in phaseThree) {
        expect(question.isVocabRecall, isTrue, reason: lesson.nameLatin);
        expect(question.answer, hasLength(1), reason: lesson.nameLatin);
        expect(
          question.answer.single.text,
          question.vocabRecall!.arabicHint,
          reason: lesson.nameLatin,
        );
        expect(
          question.answer.single.text,
          isNot(question.prompt!.text),
          reason:
              '${lesson.nameLatin}: target harus potongan, bukan ayat penuh',
        );
      }
    }
  });

  test('kosakata yang mencakup seluruh ayat tidak eligible untuk recall', () {
    const ayah = Ayah(surahId: 1, number: 1, text: 'الْحَمْدُ لِلَّهِ');
    const fullAyah = VocabItem(
      ayahNumber: 1,
      word: 'الْحَمْدُ لِلَّهِ',
      latin: 'alhamdu lillah',
      meaning: 'segala puji bagi Allah',
    );
    const partial = VocabItem(
      ayahNumber: 1,
      word: 'الْحَمْدُ',
      latin: 'alhamdu',
      meaning: 'segala puji',
    );

    expect(
      VocabLessonQuestionFactory.isMeaningRecallEligible(fullAyah, ayah),
      isFalse,
    );
    expect(
      VocabLessonQuestionFactory.isMeaningRecallEligible(partial, ayah),
      isTrue,
    );
  });

  test('Ujian Akhir menetapkan dua soal recall dari sepuluh soal', () {
    expect(LessonConfig.examQuestionCount, 10);
    expect(VocabLearningRules.examMeaningRecallCount, 2);

    final lesson = SurahLessonSeed.lessons.first;
    final items = [
      for (final section in lesson.sections) ...section.vocabItems,
    ];
    final recalls = factory.buildMeaningRecallQuestions(
      items: items,
      ayat: ayatBySurah[lesson.surahId]!,
      count: VocabLearningRules.examMeaningRecallCount,
      rng: Random(92),
    );

    expect(recalls, hasLength(2));
    expect(recalls.every((question) => question.isVocabRecall), isTrue);
    expect(recalls.every((question) => question.vocabPhase == null), isTrue);
  });
}
