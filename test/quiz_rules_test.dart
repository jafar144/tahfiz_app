import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/entities/ayah.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_difficulty.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_mode.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_result.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/quiz_knowledge_bank.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/rules/choice_quiz_rules.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/rules/quiz_bonus_rules.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/rules/quiz_difficulty_rules.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/rules/quiz_question_types.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/rules/quiz_session_rules.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/rules/voice_quiz_rules.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/rules/weighted_quiz_rule.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/entities/lesson_section.dart';

void main() {
  group('QuizDifficultyRules', () {
    test('profil Mudah adalah 80% mudah dan 20% sedang', () {
      expect(
        WeightedQuizPicker.probabilityPercent(
          QuizDifficultyRules.easyMix,
          QuizDifficulty.easy,
        ),
        80,
      );
      expect(
        WeightedQuizPicker.probabilityPercent(
          QuizDifficultyRules.easyMix,
          QuizDifficulty.medium,
        ),
        20,
      );
      expect(
        WeightedQuizPicker.probabilityPercent(
          QuizDifficultyRules.easyMix,
          QuizDifficulty.hard,
        ),
        0,
      );
    });

    test('profil Sedang adalah 40%, 40%, 20%', () {
      expect(
        [
          for (final difficulty in QuizDifficulty.values)
            WeightedQuizPicker.probabilityPercent(
              QuizDifficultyRules.mediumMix,
              difficulty,
            ),
        ],
        [40, 40, 20],
      );
    });

    test('profil Sulit adalah 10%, 30%, 60%', () {
      expect(
        [
          for (final difficulty in QuizDifficulty.values)
            WeightedQuizPicker.probabilityPercent(
              QuizDifficultyRules.hardMix,
              difficulty,
            ),
        ],
        [10, 30, 60],
      );
    });

    test('multiplier rekomendasi berlaku pada skor dan XP', () {
      expect(QuizDifficultyRules.scoreMultiplier(QuizDifficulty.medium), 1.5);
      expect(QuizDifficultyRules.scoreMultiplier(QuizDifficulty.hard), 2);
      expect(
        QuizDifficultyRules.xpMultiplier(QuizMode.choice, QuizDifficulty.hard),
        2,
      );
      expect(
        QuizDifficultyRules.xpMultiplier(QuizMode.voice, QuizDifficulty.hard),
        3,
      );
    });
  });

  group('VoiceQuizRules', () {
    test('lanjutan maksimal 20 kata mudah, selebihnya sedang', () {
      expect(VoiceQuizRules.continuationDifficulty(20), QuizDifficulty.easy);
      expect(VoiceQuizRules.continuationDifficulty(21), QuizDifficulty.medium);
      expect(VoiceQuizRules.meaningToAyahDifficulty, QuizDifficulty.hard);
      expect(VoiceQuizRules.meaningToAyahSeconds, 60);
      expect(VoiceQuizRules.meaningToAyahHintAtSeconds, 30);
    });

    test('sumber bonus terbaca sebagai 50% kosakata dan 50% pengetahuan', () {
      expect(
        WeightedQuizPicker.probabilityPercent(
          VoiceQuizRules.bonusSourceDistribution,
          VoiceBonusSource.vocabularyMatch,
        ),
        50,
      );
      expect(
        WeightedQuizPicker.probabilityPercent(
          VoiceQuizRules.bonusSourceDistribution,
          VoiceBonusSource.surahKnowledge,
        ),
        50,
      );
    });

    test('skor mempertahankan ambang bacaan', () {
      expect(VoiceQuizRules.passes(79), isFalse);
      expect(VoiceQuizRules.passes(80), isTrue);
      expect(
        VoiceQuizRules.finalScore(accuracyPercent: 90, bestAccuracyPercent: 90),
        90,
      );
      expect(
        VoiceQuizRules.finalScore(accuracyPercent: 91, bestAccuracyPercent: 91),
        100,
      );
    });
  });

  group('Tebak ayat dari makna', () {
    const ayah = Ayah(
      surahId: 92,
      number: 2,
      text: 'وَٱلنَّهَارِ إِذَا تَجَلَّىٰ',
      page: 595,
      surahName: 'Al-Lail',
    );

    test('kata Tajalla yang hanya bagian ayat tetap eligible', () {
      const item = VocabItem(
        ayahNumber: 2,
        word: 'تَجَلَّىٰ',
        latin: 'tajalla',
        meaning: 'menjadi terang',
      );
      expect(
        QuizKnowledgeBank.isEligibleMeaningToAyahVocabulary(item, ayah),
        isTrue,
      );
    });

    test('kosakata yang mencakup seluruh ayat dibuang', () {
      const item = VocabItem(
        ayahNumber: 2,
        word: 'وَٱلنَّهَارِ إِذَا تَجَلَّىٰ',
        latin: 'wan-nahari idza tajalla',
        meaning: 'demi siang apabila terang',
      );
      expect(
        QuizKnowledgeBank.isEligibleMeaningToAyahVocabulary(item, ayah),
        isFalse,
      );
    });
  });

  group('ChoiceQuizRules', () {
    test('lanjutan 1-2 ayat mudah dan 3 ayat sedang', () {
      expect(ChoiceQuizRules.continuationDifficulty(1), QuizDifficulty.easy);
      expect(ChoiceQuizRules.continuationDifficulty(2), QuizDifficulty.easy);
      expect(ChoiceQuizRules.continuationDifficulty(3), QuizDifficulty.medium);
    });

    test('slot bonus membagi sumber kosakata dan trivia secara 50:50', () {
      expect(
        WeightedQuizPicker.probabilityPercent(
          ChoiceQuizRules.bonusSourceDistribution,
          ChoiceBonusSource.vocabularyMatch,
        ),
        50,
      );
      expect(
        WeightedQuizPicker.probabilityPercent(
          ChoiceQuizRules.bonusSourceDistribution,
          ChoiceBonusSource.surahTrivia,
        ),
        50,
      );
    });

    test('rumus poin dan tambahan waktu lanjutan ayat', () {
      expect(
        [for (var n = 1; n <= 3; n++) ChoiceQuizRules.continuationPoints(n)],
        [10, 14, 18],
      );
      expect(
        [for (var n = 1; n <= 3; n++) ChoiceQuizRules.continuationTimeBonus(n)],
        [1, 2, 3],
      );
    });
  });

  test('bonus terbuka setelah 5 benar beruntun dan salah mereset', () {
    final streak = QuizBonusStreak();
    for (var i = 0; i < 4; i++) {
      streak.registerCoreAnswer(correct: true);
    }
    expect(streak.canOfferBonus, isFalse);
    streak.registerCoreAnswer(correct: true);
    expect(streak.canOfferBonus, isTrue);
    streak.consumeBonus();
    expect(streak.count, 0);

    streak.registerCoreAnswer(correct: true);
    streak.registerCoreAnswer(correct: false);
    expect(streak.count, 0);
    expect(streak.canOfferBonus, isFalse);
  });

  test('hasil Sulit memakai multiplier final', () {
    const result = QuizResult(
      answers: [
        QuizAnswer(questionIndex: 0, score: 100, attempts: 1, passed: true),
      ],
      questionCount: 1,
      mode: QuizMode.voice,
      difficulty: QuizDifficulty.hard,
    );
    expect(result.finalScore, 200);
    expect(result.leaderboardScore, 200);
    expect(result.earnedXp, 30);
  });

  test('hanya Tantangan yang menyimpan hasil', () {
    expect(QuizSessionRules.storesResult(QuizSessionKind.practice), isFalse);
    expect(QuizSessionRules.storesResult(QuizSessionKind.challenge), isTrue);
  });
}
