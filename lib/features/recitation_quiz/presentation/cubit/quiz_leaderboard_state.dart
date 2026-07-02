import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_leaderboard.dart';

enum LeaderboardStatus { loading, loaded, error }

class QuizLeaderboardState {
  final LeaderboardStatus status;
  final MonthlyLeaderboard? leaderboard;
  final String? errorMessage;

  /// UID user yang sedang login — untuk menyorot baris "Kamu".
  final String? currentUserId;

  const QuizLeaderboardState({
    this.status = LeaderboardStatus.loading,
    this.leaderboard,
    this.errorMessage,
    this.currentUserId,
  });

  QuizLeaderboardState copyWith({
    LeaderboardStatus? status,
    MonthlyLeaderboard? leaderboard,
    String? errorMessage,
    String? currentUserId,
  }) {
    return QuizLeaderboardState(
      status: status ?? this.status,
      leaderboard: leaderboard ?? this.leaderboard,
      errorMessage: errorMessage ?? this.errorMessage,
      currentUserId: currentUserId ?? this.currentUserId,
    );
  }
}
