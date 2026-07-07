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

  /// Muat papan juara untuk [mode] (default: mode saat ini di state).
  Future<void> load([QuizMode? mode]) async {
    final target = mode ?? state.mode;
    emit(
      QuizLeaderboardState(
        status: LeaderboardStatus.loading,
        mode: target,
        currentUserId: auth.currentUser?.uid,
      ),
    );
    final res = await repository.getMonthlyLeaderboard(target);
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
    await load(mode);
  }
}
