import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_energy.dart';
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

/// Satu pilihan juz pada dropdown peta.
class JourneyJuzOption {
  final int juz;

  /// Sudah tersedia untuk dimainkan (false → tampil terkunci "Segera").
  final bool available;

  const JourneyJuzOption({required this.juz, required this.available});
}

enum JourneyStatus { loading, ready, error }

class SurahJourneyState {
  final JourneyStatus status;

  /// Node level urut dari level 1.
  final List<JourneyLevelNode> nodes;

  /// Total XP pengguna (top bar tengah).
  final int xp;

  /// Energi pengguna (top bar kanan); null = belum termuat.
  final QuizEnergy? energy;
  final bool energyLoading;

  /// Juz terpilih pada dropdown (sementara hanya 30 yang tersedia).
  final int selectedJuz;

  final String? errorMessage;

  const SurahJourneyState({
    this.status = JourneyStatus.loading,
    this.nodes = const [],
    this.xp = 0,
    this.energy,
    this.energyLoading = false,
    this.selectedJuz = 30,
    this.errorMessage,
  });

  /// Pilihan juz di dropdown — juz 29 dipajang tapi masih terkunci.
  static const juzOptions = [
    JourneyJuzOption(juz: 30, available: true),
    JourneyJuzOption(juz: 29, available: false),
  ];

  int get completedCount => nodes.where((n) => n.completed).length;

  SurahJourneyState copyWith({
    JourneyStatus? status,
    List<JourneyLevelNode>? nodes,
    int? xp,
    QuizEnergy? energy,
    bool? energyLoading,
    int? selectedJuz,
    String? errorMessage,
  }) {
    return SurahJourneyState(
      status: status ?? this.status,
      nodes: nodes ?? this.nodes,
      xp: xp ?? this.xp,
      energy: energy ?? this.energy,
      energyLoading: energyLoading ?? this.energyLoading,
      selectedJuz: selectedJuz ?? this.selectedJuz,
      errorMessage: errorMessage,
    );
  }
}
