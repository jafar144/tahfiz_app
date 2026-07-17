import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:khoirunnasyien/features/arena/presentation/cubit/arena_lobby_state.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_leaderboard.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_mode.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/quiz_curriculum.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/repositories/quiz_repository.dart';

String currentMonthKey([DateTime? reference]) {
  final now = reference ?? DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}';
}

String previousMonthKey([DateTime? reference]) {
  final now = reference ?? DateTime.now();
  final previous = DateTime(now.year, now.month - 1);
  return '${previous.year}-${previous.month.toString().padLeft(2, '0')}';
}

List<String> arenaLobbyMonthKeys([DateTime? reference]) {
  return [currentMonthKey(reference), previousMonthKey(reference)];
}

class ArenaLobbyCubit extends Cubit<ArenaLobbyState> {
  final QuizRepository repository;
  final Map<String, Map<QuizMode, Map<String, MonthlyLeaderboard>>> _cache = {};
  int _requestToken = 0;

  ArenaLobbyCubit(this.repository)
    : super(ArenaLobbyState(monthKey: currentMonthKey()));

  Future<void> loadMode([QuizMode mode = QuizMode.voice]) {
    return _load(mode: mode, monthKey: state.monthKey);
  }

  Future<void> loadMonth(String monthKey) {
    if (!arenaLobbyMonthKeys().contains(monthKey)) return Future.value();
    return _load(mode: state.mode, monthKey: monthKey);
  }

  Future<void> _load({required QuizMode mode, required String monthKey}) async {
    final requestToken = ++_requestToken;
    final cached = _cache[monthKey]?[mode];
    if (cached != null) {
      emit(
        ArenaLobbyState(
          status: ArenaLobbyStatus.loaded,
          mode: mode,
          monthKey: monthKey,
          leaderboards: cached,
        ),
      );
      return;
    }

    final tiers = QuizCurriculum.leaderboardTiers;
    if (tiers.isEmpty) {
      emit(
        ArenaLobbyState(
          status: ArenaLobbyStatus.error,
          mode: mode,
          monthKey: monthKey,
          errorMessage: 'Tingkatan kuis belum tersedia.',
        ),
      );
      return;
    }

    emit(ArenaLobbyState(mode: mode, monthKey: monthKey));

    try {
      final results = await Future.wait([
        for (final tier in tiers)
          repository
              .getMonthlyLeaderboard(
                mode,
                tierKey: tier.key,
                monthKey: monthKey,
                limit: 3,
                includeCurrentUser: false,
              )
              .then((result) => (tier.key, result)),
      ]);

      if (isClosed || requestToken != _requestToken) return;

      final leaderboards = <String, MonthlyLeaderboard>{};
      String? firstError;
      for (final (tierKey, result) in results) {
        result.fold(
          ifLeft: (failure) => firstError ??= failure.message,
          ifRight: (leaderboard) => leaderboards[tierKey] = leaderboard,
        );
      }

      if (leaderboards.isEmpty && firstError != null) {
        emit(
          ArenaLobbyState(
            status: ArenaLobbyStatus.error,
            mode: mode,
            monthKey: monthKey,
            errorMessage: firstError,
          ),
        );
        return;
      }

      _cache.putIfAbsent(monthKey, () => {})[mode] = leaderboards;
      emit(
        ArenaLobbyState(
          status: ArenaLobbyStatus.loaded,
          mode: mode,
          monthKey: monthKey,
          leaderboards: leaderboards,
        ),
      );
    } catch (e) {
      if (isClosed || requestToken != _requestToken) return;
      emit(
        ArenaLobbyState(
          status: ArenaLobbyStatus.error,
          mode: mode,
          monthKey: monthKey,
          errorMessage: 'Gagal memuat leaderboard: $e',
        ),
      );
    }
  }

  Future<void> retry() => loadMode(state.mode);

  Future<void> refresh() {
    _cache[state.monthKey]?.remove(state.mode);
    return loadMode(state.mode);
  }
}
