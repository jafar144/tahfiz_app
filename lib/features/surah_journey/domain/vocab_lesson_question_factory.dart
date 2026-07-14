import 'dart:math';

import 'package:khoirunnasyien/features/recitation_check/domain/entities/ayah.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/recitation/arabic_normalizer.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/vocab_match_question.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/entities/lesson_question.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/entities/lesson_section.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/entities/surah_lesson.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/vocab_learning_rules.dart';

/// Generator murni untuk rangkaian penguatan Kosa Kata Journey.
///
/// Pengulangan item disengaja saat bank hanya berisi empat kata: pola spaced
/// repetition tetap menghasilkan jumlah latihan yang konsisten.
class VocabLessonQuestionFactory {
  const VocabLessonQuestionFactory();

  List<LessonQuestion> buildLearningPhases({
    required List<VocabItem> items,
    required List<Ayah> ayat,
    required Random rng,
  }) {
    if (items.length < 4) return const [];

    final phaseOne = _arabicToMeaningQuestions(
      items: items,
      count: VocabLearningRules.phaseOneArabicToMeaningCount,
      phase: VocabLearningPhase.arabicToMeaning,
      rng: rng,
    );

    final phaseTwo = <LessonQuestion>[
      ..._arabicToMeaningQuestions(
        items: items,
        count: VocabLearningRules.phaseTwoArabicToMeaningCount,
        phase: VocabLearningPhase.mixedPractice,
        rng: rng,
      ),
      ..._meaningToArabicQuestions(
        items: items,
        count: VocabLearningRules.phaseTwoMeaningToArabicCount,
        phase: VocabLearningPhase.mixedPractice,
        rng: rng,
      ),
      for (var i = 0; i < VocabLearningRules.phaseTwoMatchCount; i++)
        _matchQuestion(
          items: items,
          phase: VocabLearningPhase.mixedPractice,
          rng: rng,
        ),
    ]..shuffle(rng);

    final phaseThree = buildMeaningRecallQuestions(
      items: items,
      ayat: ayat,
      count: VocabLearningRules.phaseThreeMeaningRecallCount,
      phase: VocabLearningPhase.meaningRecall,
      rng: rng,
    );

    if (phaseOne.length != VocabLearningRules.phaseOneArabicToMeaningCount ||
        phaseTwo.length !=
            VocabLearningRules.questionCountFor(
              VocabLearningPhase.mixedPractice,
            ) ||
        phaseThree.length != VocabLearningRules.phaseThreeMeaningRecallCount) {
      return const [];
    }
    return [...phaseOne, ...phaseTwo, ...phaseThree];
  }

  List<LessonQuestion> buildMeaningRecallQuestions({
    required List<VocabItem> items,
    required List<Ayah> ayat,
    required int count,
    required Random rng,
    VocabLearningPhase? phase,
  }) {
    final sourceByNumber = {for (final source in ayat) source.number: source};
    final eligible = [
      for (final item in items)
        if (sourceByNumber[item.ayahNumber] case final source?)
          if (isMeaningRecallEligible(item, source))
            (item: item, source: source),
    ];
    if (eligible.isEmpty) return const [];

    final selected = _cycled(eligible, count, rng);
    return [
      for (final entry in selected)
        LessonQuestion.vocabRecall(
          sourceAyah: entry.source,
          answerTarget: _answerFragment(entry.source, entry.item.word),
          meaning: entry.item.displayMeaning,
          arabicHint: entry.item.word,
          vocabPhase: phase,
        ),
    ];
  }

  /// Potongan yang sama panjang dengan seluruh ayat tidak layak ditebak.
  static bool isMeaningRecallEligible(VocabItem item, Ayah ayah) {
    final wordTokens = ArabicNormalizer.tokenize(item.word);
    final ayahTokens = ArabicNormalizer.tokenize(ayah.text);
    return wordTokens.isNotEmpty &&
        ayahTokens.isNotEmpty &&
        wordTokens.length < ayahTokens.length;
  }

  List<LessonQuestion> _arabicToMeaningQuestions({
    required List<VocabItem> items,
    required int count,
    required VocabLearningPhase phase,
    required Random rng,
  }) => [
    for (final item in _cycled(items, count, rng))
      LessonQuestion.choice(
        _choiceQuestion(
          target: item,
          items: items,
          prompt: 'Apa arti kosa kata Arab berikut?',
          correctValue: (item) => item.displayMeaning,
          optionValue: (item) => item.displayMeaning,
          arabicText: item.word,
          rng: rng,
        ),
        vocabPhase: phase,
      ),
  ];

  List<LessonQuestion> _meaningToArabicQuestions({
    required List<VocabItem> items,
    required int count,
    required VocabLearningPhase phase,
    required Random rng,
  }) => [
    for (final item in _cycled(items, count, rng))
      LessonQuestion.choice(
        _choiceQuestion(
          target: item,
          items: items,
          prompt:
              'Manakah kosa kata Arab yang berarti '
              '"${item.displayMeaning}"?',
          correctValue: (item) => item.word,
          optionValue: (item) => item.word,
          arabicOptions: true,
          rng: rng,
        ),
        vocabPhase: phase,
      ),
  ];

  FactQuestion _choiceQuestion({
    required VocabItem target,
    required List<VocabItem> items,
    required String prompt,
    required String Function(VocabItem item) correctValue,
    required String Function(VocabItem item) optionValue,
    required Random rng,
    String? arabicText,
    bool arabicOptions = false,
  }) {
    final correct = correctValue(target);
    final distractors = [...items]
      ..remove(target)
      ..shuffle(rng);
    final options = <String>[correct];
    for (final item in distractors) {
      final value = optionValue(item);
      if (!options.contains(value)) options.add(value);
      if (options.length == 4) break;
    }
    if (options.length < 4) {
      throw StateError('Bank kosa kata membutuhkan empat jawaban unik.');
    }
    options.shuffle(rng);
    return FactQuestion(
      question: prompt,
      options: options,
      correctIndex: options.indexOf(correct),
      arabicText: arabicText,
      arabicOptions: arabicOptions,
    );
  }

  LessonQuestion _matchQuestion({
    required List<VocabItem> items,
    required VocabLearningPhase phase,
    required Random rng,
  }) {
    final selected = [...items]..shuffle(rng);
    return LessonQuestion.match(
      VocabMatchQuestion(
        pairs: [
          for (final item in selected.take(4))
            VocabMatchPair(arabic: item.word, meaning: item.displayMeaning),
        ],
      ),
      vocabPhase: phase,
    );
  }

  List<T> _cycled<T>(List<T> source, int count, Random rng) {
    final selected = <T>[];
    while (selected.length < count) {
      final round = [...source]..shuffle(rng);
      selected.addAll(round.take(count - selected.length));
    }
    return selected;
  }

  Ayah _answerFragment(Ayah source, String word) => Ayah(
    surahId: source.surahId,
    number: source.number,
    text: word,
    page: source.page,
    surahName: source.surahName,
  );
}
