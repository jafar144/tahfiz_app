import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_energy.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/quiz_config.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/repositories/quiz_repository.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/entities/lesson_progress.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/repositories/surah_journey_repository.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/surah_lesson_seed.dart';
import 'package:khoirunnasyien/features/surah_journey/presentation/cubit/surah_journey_state.dart';

/// Cubit peta Petualangan Surah: memuat progres + XP, menyusun node level,
/// dan energi untuk top bar (juz kiri • XP tengah • energi kanan).
///
/// Aturan buka level: level 1 selalu terbuka; level berikutnya terbuka bila
/// level sebelumnya sudah SELESAI (lulus ujian akhirnya). (Rencana ke depan:
/// dikaitkan dengan data hafalan santri sungguhan.)
class SurahJourneyCubit extends Cubit<SurahJourneyState> {
  final SurahJourneyRepository repository;
  final QuizRepository quizRepository;

  SurahJourneyCubit(this.repository, this.quizRepository)
    : super(const SurahJourneyState());

  Future<void> load() async {
    emit(state.copyWith(status: JourneyStatus.loading));
    final res = await repository.getProgress();
    res.fold(
      ifLeft: (f) => emit(
        state.copyWith(status: JourneyStatus.error, errorMessage: f.message),
      ),
      ifRight: (progress) => emit(
        state.copyWith(
          status: JourneyStatus.ready,
          nodes: _buildNodes(progress),
          xp: progress.xp,
        ),
      ),
    );
    // Energi menyusul agar peta tidak menunggu panggilan server.
    await refreshEnergy();
  }

  /// Muat ulang energi (dipanggil saat kembali dari sesi / pengisian tiba).
  /// Admin & master switch mati → tampil penuh (samakan dengan Arena/Kuis).
  Future<void> refreshEnergy() async {
    if (!QuizConfig.enforceEnergy || await quizRepository.isCurrentUserAdmin()) {
      emit(
        state.copyWith(
          energy: const QuizEnergy(current: 10, max: 10),
          energyLoading: false,
        ),
      );
      return;
    }
    emit(state.copyWith(energyLoading: true));
    final res = await quizRepository.getEnergy();
    if (isClosed) return;
    res.fold(
      ifLeft: (_) => emit(state.copyWith(energyLoading: false)),
      ifRight: (e) => emit(state.copyWith(energy: e, energyLoading: false)),
    );
  }

  List<JourneyLevelNode> _buildNodes(JourneyProgress progress) {
    final lessons = SurahLessonSeed.lessons;
    var previousCompleted = true; // level pertama selalu terbuka
    return [
      for (final lesson in lessons)
        () {
          final p = progress.of(lesson.surahId);
          final node = JourneyLevelNode(
            lesson: lesson,
            progress: p,
            unlocked: previousCompleted,
          );
          previousCompleted = p.completed;
          return node;
        }(),
    ];
  }
}
