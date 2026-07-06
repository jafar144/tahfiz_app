import 'package:khoirunnasyien/features/surah_journey/domain/entities/lesson_progress.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/entities/surah_lesson.dart';

/// Satu node level pada peta Petualangan Surah.
class JourneyLevelNode {
  final SurahLesson lesson;
  final SurahProgress progress;

  /// Terbuka untuk dimainkan (level 1, atau level sebelumnya sudah selesai).
  final bool unlocked;

  const JourneyLevelNode({
    required this.lesson,
    required this.progress,
    required this.unlocked,
  });

  bool get completed => progress.completed;
}

enum JourneyStatus { loading, ready, error }

class SurahJourneyState {
  final JourneyStatus status;

  /// Node level urut dari level 1.
  final List<JourneyLevelNode> nodes;
  final String? errorMessage;

  const SurahJourneyState({
    this.status = JourneyStatus.loading,
    this.nodes = const [],
    this.errorMessage,
  });

  int get completedCount => nodes.where((n) => n.completed).length;

  SurahJourneyState copyWith({
    JourneyStatus? status,
    List<JourneyLevelNode>? nodes,
    String? errorMessage,
  }) {
    return SurahJourneyState(
      status: status ?? this.status,
      nodes: nodes ?? this.nodes,
      errorMessage: errorMessage,
    );
  }
}
