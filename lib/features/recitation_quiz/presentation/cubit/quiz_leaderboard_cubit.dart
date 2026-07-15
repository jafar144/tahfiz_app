import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_mode.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/repositories/quiz_repository.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/cubit/quiz_leaderboard_state.dart';

class QuizLeaderboardCubit extends Cubit<QuizLeaderboardState> {
  final QuizRepository repository;
  final FirebaseAuth auth;

  QuizLeaderboardCubit(this.repository, this.auth)
    : super(const QuizLeaderboardState());

  /// Muat papan juara untuk [mode] + [tierKey].
  Future<void> load({QuizMode? mode, String? tierKey}) async {
    final targetMode = mode ?? state.mode;
    final targetTierKey = tierKey ?? state.tierKey;
    if (targetTierKey == null) {
      emit(
        state.copyWith(
          status: LeaderboardStatus.error,
          errorMessage: 'Tingkatan kuis belum tersedia.',
        ),
      );
      return;
    }
    emit(
      QuizLeaderboardState(
        status: LeaderboardStatus.loading,
        mode: targetMode,
        tierKey: targetTierKey,
        currentUserId: auth.currentUser?.uid,
      ),
    );
    final res = await repository.getMonthlyLeaderboard(
      targetMode,
      tierKey: targetTierKey,
    );
    res.fold(
      ifLeft: (f) => emit(
        state.copyWith(
          status: LeaderboardStatus.error,
          errorMessage: f.message,
        ),
      ),
      ifRight: (lb) => emit(
        state.copyWith(status: LeaderboardStatus.loaded, leaderboard: lb),
      ),
    );
  }

  /// Ganti mode papan lalu muat ulang (abaikan bila mode sama).
  Future<void> switchMode(QuizMode mode) async {
    if (mode == state.mode && state.status != LeaderboardStatus.error) return;
    await load(mode: mode);
  }

  /// Ganti tingkatan papan lalu muat ulang.
  Future<void> switchTier(String tierKey) async {
    if (tierKey == state.tierKey && state.status != LeaderboardStatus.error) {
      return;
    }
    await load(tierKey: tierKey);
  }
}
