import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:khoirunnasyien/features/recitation_quiz/domain/repositories/quiz_repository.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/cubit/quiz_leaderboard_state.dart';

class QuizLeaderboardCubit extends Cubit<QuizLeaderboardState> {
  final QuizRepository repository;
  final FirebaseAuth auth;

  QuizLeaderboardCubit(this.repository, this.auth)
      : super(const QuizLeaderboardState());

  Future<void> load() async {
    emit(QuizLeaderboardState(
      status: LeaderboardStatus.loading,
      currentUserId: auth.currentUser?.uid,
    ));
    final res = await repository.getMonthlyLeaderboard();
    res.fold(
      ifLeft: (f) => emit(state.copyWith(
        status: LeaderboardStatus.error,
        errorMessage: f.message,
      )),
      ifRight: (lb) => emit(state.copyWith(
        status: LeaderboardStatus.loaded,
        leaderboard: lb,
      )),
    );
  }
}
