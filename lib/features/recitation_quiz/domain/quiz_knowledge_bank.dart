import 'dart:math';

import 'package:khoirunnasyien/features/recitation_check/domain/entities/ayah.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/recitation/arabic_normalizer.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/vocab_match_question.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/entities/lesson_section.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/entities/surah_lesson.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/surah_lesson_seed.dart';

class MeaningToAyahCandidate {
  final Ayah ayah;
  final VocabItem vocabulary;

  const MeaningToAyahCandidate({required this.ayah, required this.vocabulary});
}

/// Materi Journey yang dapat dipakai kembali oleh Latihan dan Tantangan.
class QuizKnowledgeBank {
  QuizKnowledgeBank._();

  static FactQuestion? vocabularyMeaning({
    required Set<int> allowedSurahs,
    required List<Ayah> ayat,
    required Random rng,
  }) {
    final items = _itemsFor(allowedSurahs);
    if (items.length < 4) return null;
    items.shuffle(rng);
    final sourceByKey = {
      for (final source in ayat) '${source.surahId}:${source.number}': source,
    };
    final available = items
        .where(
          (entry) => sourceByKey.containsKey(
            '${entry.surahId}:${entry.item.ayahNumber}',
          ),
        )
        .toList();
    if (available.isEmpty) return null;
    final entry = available.first;
    final item = entry.item;
    final distractors = items.where((other) => other != entry).toList()
      ..shuffle(rng);
    final options = [
      item.displayMeaning,
      ...distractors.take(3).map((e) => e.item.displayMeaning),
    ]..shuffle(rng);
    return FactQuestion(
      question: 'Apa arti kata yang disorot pada ayat berikut?',
      options: options,
      correctIndex: options.indexOf(item.displayMeaning),
      arabicText: sourceByKey['${entry.surahId}:${item.ayahNumber}']?.text,
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
          VocabMatchPair(arabic: item.word, meaning: item.displayMeaning),
      ],
    );
  }

  /// Kandidat soal Suara "tebak ayat dari makna".
  ///
  /// Kosakata wajib benar-benar merupakan BAGIAN dari ayat. Entri yang kata
  /// Arabnya mencakup seluruh token ayat sengaja dibuang karena jawabannya akan
  /// terlalu mudah ditebak dari petunjuk yang setara dengan terjemahan ayat.
  static List<MeaningToAyahCandidate> meaningToAyahCandidates({
    required Set<int> allowedSurahs,
    required List<Ayah> ayat,
  }) {
    final sourceByKey = {
      for (final source in ayat) '${source.surahId}:${source.number}': source,
    };
    final candidates = <MeaningToAyahCandidate>[];
    for (final entry in _itemsFor(allowedSurahs)) {
      final source = sourceByKey['${entry.surahId}:${entry.item.ayahNumber}'];
      if (source == null ||
          !isEligibleMeaningToAyahVocabulary(entry.item, source)) {
        continue;
      }
      candidates.add(
        MeaningToAyahCandidate(ayah: source, vocabulary: entry.item),
      );
    }
    return candidates;
  }

  static bool isEligibleMeaningToAyahVocabulary(VocabItem item, Ayah ayah) {
    final vocabularyTokens = ArabicNormalizer.tokenize(item.word);
    final ayahTokens = ArabicNormalizer.tokenize(ayah.text);
    if (vocabularyTokens.isEmpty || ayahTokens.isEmpty) return false;
    return vocabularyTokens.length < ayahTokens.length;
  }

  static List<({int surahId, VocabItem item})> _itemsFor(
    Set<int> allowedSurahs,
  ) => [
    for (final lesson in SurahLessonSeed.lessons)
      if (allowedSurahs.contains(lesson.surahId))
        for (final item in _vocabularyOf(lesson))
          (surahId: lesson.surahId, item: item),
  ];

  static List<VocabItem> _vocabularyOf(SurahLesson lesson) => [
    for (final section in lesson.sections) ...section.vocabItems,
  ];
}
