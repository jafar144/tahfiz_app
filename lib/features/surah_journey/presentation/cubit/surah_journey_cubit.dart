import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:khoirunnasyien/features/surah_journey/domain/entities/lesson_progress.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/repositories/surah_journey_repository.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/surah_lesson_seed.dart';
import 'package:khoirunnasyien/features/surah_journey/presentation/cubit/surah_journey_state.dart';

/// Cubit peta Petualangan Surah: memuat progres & menyusun node level.
///
/// Aturan buka level: level 1 selalu terbuka; level berikutnya terbuka bila
/// level sebelumnya sudah SELESAI. (Rencana ke depan: dikaitkan dengan data
/// hafalan santri sungguhan.)
class SurahJourneyCubit extends Cubit<SurahJourneyState> {
  final SurahJourneyRepository repository;

  SurahJourneyCubit(this.repository) : super(const SurahJourneyState());

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
        ),
      ),
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
