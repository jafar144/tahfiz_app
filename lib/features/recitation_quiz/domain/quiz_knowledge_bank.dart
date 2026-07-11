import 'dart:math';

import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/vocab_match_question.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/entities/lesson_section.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/entities/surah_lesson.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/surah_lesson_seed.dart';

/// Materi Journey yang dapat dipakai kembali oleh Latihan dan Tantangan.
class QuizKnowledgeBank {
  QuizKnowledgeBank._();

  static FactQuestion? vocabularyMeaning({
    required Set<int> allowedSurahs,
    required Random rng,
  }) {
    final items = _itemsFor(allowedSurahs);
    if (items.length < 4) return null;
    items.shuffle(rng);
    final item = items.first;
    final options = [
      item.meaning,
      ...items.skip(1).take(3).map((e) => e.meaning),
    ]..shuffle(rng);
    return FactQuestion(
      question: 'Apa arti kata Arab berikut?',
      options: options,
      correctIndex: options.indexOf(item.meaning),
      arabicText: item.word,
      highlightWord: item.word,
    );
  }

  static FactQuestion? fact({
    required Set<int> allowedSurahs,
    required Random rng,
  }) {
    final facts = <FactQuestion>[
      for (final lesson in SurahLessonSeed.lessons)
        if (allowedSurahs.contains(lesson.surahId))
          for (final section in lesson.sections) ...section.test.bank,
    ];
    if (facts.isEmpty) return null;
    return facts[rng.nextInt(facts.length)];
  }

  static VocabMatchQuestion? vocabularyMatch({
    required Set<int> allowedSurahs,
    required Random rng,
  }) {
    final lessons = [
      for (final lesson in SurahLessonSeed.lessons)
        if (allowedSurahs.contains(lesson.surahId) &&
            _vocabularyOf(lesson).length >= 4)
          lesson,
    ];
    if (lessons.isEmpty) return null;
    final items = [..._vocabularyOf(lessons[rng.nextInt(lessons.length)])]
      ..shuffle(rng);
    return VocabMatchQuestion(
      pairs: [
        for (final item in items.take(4))
          VocabMatchPair(arabic: item.word, meaning: item.meaning),
      ],
    );
  }

  static List<VocabItem> _itemsFor(Set<int> allowedSurahs) => [
    for (final lesson in SurahLessonSeed.lessons)
      if (allowedSurahs.contains(lesson.surahId)) ..._vocabularyOf(lesson),
  ];

  static List<VocabItem> _vocabularyOf(SurahLesson lesson) => [
    for (final section in lesson.sections) ...section.vocabItems,
  ];
}
