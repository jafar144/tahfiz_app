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

  /// Muat papan juara untuk [mode] + [kelas] (default: nilai di state).
  /// [kelas] wajib untuk papan Tantangan per kelas (Tahfiz Arena).
  Future<void> load({QuizMode? mode, String? kelas}) async {
    final targetMode = mode ?? state.mode;
    final targetKelas = kelas ?? state.kelas;
    emit(
      QuizLeaderboardState(
        status: LeaderboardStatus.loading,
        mode: targetMode,
        kelas: targetKelas,
        currentUserId: auth.currentUser?.uid,
      ),
    );
    final res = await repository.getMonthlyLeaderboard(
      targetMode,
      kelas: targetKelas,
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

  /// Ganti kelas papan lalu muat ulang (abaikan bila kelas sama).
  Future<void> switchKelas(String kelas) async {
    if (kelas == state.kelas && state.status != LeaderboardStatus.error) {
      return;
    }
    await load(kelas: kelas);
  }
}
