import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_leaderboard.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_mode.dart';

enum ArenaLobbyStatus { loading, loaded, error }

class ArenaLobbyState {
  final ArenaLobbyStatus status;
  final QuizMode mode;
  final String monthKey;
  final Map<String, MonthlyLeaderboard> leaderboards;
  final String? errorMessage;

  const ArenaLobbyState({
    this.status = ArenaLobbyStatus.loading,
    this.mode = QuizMode.voice,
    required this.monthKey,
    this.leaderboards = const {},
    this.errorMessage,
  });
}
