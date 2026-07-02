import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_leaderboard.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_mode.dart';

enum LeaderboardStatus { loading, loaded, error }

class QuizLeaderboardState {
  final LeaderboardStatus status;

  /// Mode papan yang sedang ditampilkan (toggle Suara/Pilihan).
  final QuizMode mode;

  final MonthlyLeaderboard? leaderboard;
  final String? errorMessage;

  /// UID user yang sedang login — untuk menyorot baris "Kamu".
  final String? currentUserId;

  const QuizLeaderboardState({
    this.status = LeaderboardStatus.loading,
    this.mode = QuizMode.voice,
    this.leaderboard,
    this.errorMessage,
    this.currentUserId,
  });

  QuizLeaderboardState copyWith({
    LeaderboardStatus? status,
    QuizMode? mode,
    MonthlyLeaderboard? leaderboard,
    String? errorMessage,
    String? currentUserId,
  }) {
    return QuizLeaderboardState(
      status: status ?? this.status,
      mode: mode ?? this.mode,
      leaderboard: leaderboard ?? this.leaderboard,
      errorMessage: errorMessage ?? this.errorMessage,
      currentUserId: currentUserId ?? this.currentUserId,
    );
  }
}
