import 'dart:async';

import 'package:dart_either/dart_either.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/core/config/app_config.dart';
import 'package:khoirunnasyien/core/error/failure.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/entities/ayah.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/entities/recitation_result.dart';
import 'package:khoirunnasyien/features/recitation_quiz/data/quiz_settings_store.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_difficulty.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_energy.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_leaderboard.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_launch.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_mode.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_question.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_settings.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_tier.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/repositories/quiz_repository.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/rules/choice_quiz_rules.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/cubit/recitation_quiz_cubit.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/cubit/recitation_quiz_state.dart';
import 'package:khoirunnasyien/flavors/khoirunnasyien/app_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => AppConfig.configure(khoirunnasyienAppConfig));

  test(
    'double tap Main Lagi tidak mereset poin sesi yang sudah dimulai',
    () async {
      final repository = _QuizRepositoryFake();
      final cubit = RecitationQuizCubit(repository, _QuizSettingsStoreFake());
      addTearDown(cubit.close);

      await cubit.start(_choiceSettings);
      cubit.pickOption(0);
      await Future<void>.delayed(ChoiceQuizRules.feedbackDuration);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.status, QuizStatus.finished);

      repository.controlQuestionGeneration = true;
      final firstReplay = cubit.playAgain();
      final secondReplay = cubit.playAgain();
      await Future<void>.delayed(Duration.zero);

      expect(repository.pendingQuestionGenerations, hasLength(1));
      repository.completeQuestionGeneration(0);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.status, QuizStatus.playing);

      cubit.pickOption(0);
      expect(cubit.state.choiceCorrect, isTrue);
      expect(cubit.state.runningPoints, 10);

      expect(cubit.state.status, QuizStatus.playing);
      expect(cubit.state.runningPoints, 10);
      expect(cubit.state.answers.single.score, 10);

      await Future.wait([firstReplay, secondReplay]);
    },
  );

  test(
    'retry skor challenge memakai attempt id yang sama tepat satu kali',
    () async {
      final repository = _QuizRepositoryFake()..failNextSave = true;
      final cubit = RecitationQuizCubit(repository, _QuizSettingsStoreFake());
      addTearDown(cubit.close);

      await cubit.init(
        challenge: const QuizLaunch(
          mode: QuizMode.choice,
          difficulty: QuizDifficulty.easy,
          ownKelas: 'Mutawassith',
          scopeKelas: 'Mutawassith',
          tier: QuizTier(
            key: 'juz_30',
            label: 'Juz 30',
            scopeClass: 'Mutawassith',
          ),
        ),
      );
      cubit.pickOption(0);
      await Future<void>.delayed(ChoiceQuizRules.feedbackDuration);
      await Future<void>.delayed(const Duration(milliseconds: 1500));

      expect(cubit.state.status, QuizStatus.finished);
      expect(cubit.state.saveError, isNotNull);

      await cubit.retrySave();

      expect(cubit.state.saveError, isNull);
      expect(repository.savedAttemptIds, hasLength(2));
      expect(repository.savedAttemptIds.first, isNotEmpty);
      expect(repository.savedAttemptIds.toSet(), hasLength(1));
      expect(repository.awardXpCalls, 0);
    },
  );
}

const _choiceSettings = QuizSettings(
  mode: QuizMode.choice,
  difficulty: QuizDifficulty.easy,
  juz: {30},
);

const _prompt = Ayah(surahId: 114, number: 1, text: 'prompt');
const _answer = Ayah(surahId: 114, number: 2, text: 'answer');
const _wrong = Ayah(surahId: 114, number: 3, text: 'wrong');
const _question = QuizQuestion(
  prompt: _prompt,
  answer: [_answer],
  options: [_answer, _wrong],
  difficulty: QuizDifficulty.easy,
);

class _QuizSettingsStoreFake extends QuizSettingsStore {
  @override
  Future<QuizSettings> load() async => _choiceSettings;

  @override
  Future<void> save(QuizSettings settings) async {}
}

class _QuizRepositoryFake implements QuizRepository {
  bool controlQuestionGeneration = false;
  bool failNextSave = false;
  int awardXpCalls = 0;
  final savedAttemptIds = <String>[];
  final pendingQuestionGenerations =
      <Completer<Either<Failure, List<QuizQuestion>>>>[];

  void completeQuestionGeneration(int index) {
    pendingQuestionGenerations[index].complete(const Right([_question]));
  }

  @override
  Future<Either<Failure, List<QuizQuestion>>> generateQuestions({
    int count = 10,
    required QuizSettings settings,
  }) {
    if (!controlQuestionGeneration) {
      return Future.value(const Right([_question]));
    }
    final completer = Completer<Either<Failure, List<QuizQuestion>>>();
    pendingQuestionGenerations.add(completer);
    return completer.future;
  }

  @override
  Future<bool> isCurrentUserAdmin() async => true;

  @override
  Future<Either<Failure, void>> awardXp(int amount) async {
    awardXpCalls++;
    return const Right(null);
  }

  @override
  Future<Either<Failure, RecitationResult>> checkAnswer({
    required List<Ayah> answerAyat,
    required String audioFilePath,
    required String mimeType,
  }) async => const Left(UnknownFailure('not used'));

  @override
  Future<void> endSession() async {}

  @override
  Future<Either<Failure, QuizEnergy>> getEnergy() async =>
      const Right(QuizEnergy(current: 15, max: 15));

  @override
  Future<Either<Failure, MonthlyLeaderboard>> getMonthlyLeaderboard(
    QuizMode mode, {
    required String tierKey,
    String? monthKey,
    int? limit,
    bool includeCurrentUser = true,
  }) async => Right(
    MonthlyLeaderboard(
      mode: mode,
      monthKey: monthKey ?? '2026-07',
      entries: const [],
    ),
  );

  @override
  Future<void> heartbeat() async {}

  @override
  Future<Either<Failure, void>> saveAttempt({
    required String attemptId,
    required QuizMode mode,
    QuizDifficulty difficulty = QuizDifficulty.easy,
    required int score,
    required List<int> questionScores,
    required List<int> juz,
    int bonusTotal = 0,
    int earnedXp = 0,
    required String studentClass,
    required String scopeClass,
    required QuizTier tier,
  }) async {
    savedAttemptIds.add(attemptId);
    if (failNextSave) {
      failNextSave = false;
      return const Left(NetworkFailure('Koneksi terputus'));
    }
    return const Right(null);
  }

  @override
  Future<Either<Failure, QuizEnergy>> startSession({
    required QuizMode mode,
    bool challenge = false,
  }) async => const Right(QuizEnergy(current: 14, max: 15));
}
