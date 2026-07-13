import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_energy.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/rules/quiz_session_rules.dart';
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

  /// Muat progres DAN energi bersamaan, lalu emit `ready` sekali saja setelah
  /// keduanya siap — supaya halaman loading dedicated menahan tampilan sampai
  /// XP & energi benar-benar ada (tidak ada lagi skeleton energi menyusul
  /// setelah peta sudah tampil).
  Future<void> load() async {
    emit(state.copyWith(status: JourneyStatus.loading));

    final progressFuture = repository.getProgress();
    final energyFuture = _fetchEnergy();

    final progressResult = await progressFuture;
    final energy = await energyFuture;

    progressResult.fold(
      ifLeft: (f) => emit(
        state.copyWith(status: JourneyStatus.error, errorMessage: f.message),
      ),
      ifRight: (progress) => emit(
        state.copyWith(
          status: JourneyStatus.ready,
          nodes: _buildNodes(progress),
          xp: progress.xp,
          energy: energy,
          energyLoading: false,
        ),
      ),
    );
  }

  /// Muat ulang progres + XP + energi TANPA masuk status loading — dipakai
  /// saat kembali dari sesi belajar/kuis agar peta ter-update di tempat,
  /// tanpa halaman loading (dan animasinya) muncul lagi. Gagal memuat →
  /// pertahankan data lama diam-diam.
  Future<void> refresh() async {
    if (state.status != JourneyStatus.ready) return load();

    final progressFuture = repository.getProgress();
    final energy = await _fetchEnergy();
    final progressResult = await progressFuture;
    if (isClosed) return;

    progressResult.fold(
      ifLeft: (_) => emit(state.copyWith(energy: energy)),
      ifRight: (progress) => emit(
        state.copyWith(
          nodes: _buildNodes(progress),
          xp: progress.xp,
          energy: energy,
          energyLoading: false,
        ),
      ),
    );
  }

  /// Muat ulang energi saja (dipanggil saat pengisian energi tiba/refill).
  Future<void> refreshEnergy() async {
    emit(state.copyWith(energyLoading: true));
    final energy = await _fetchEnergy();
    if (isClosed) return;
    emit(state.copyWith(energy: energy, energyLoading: false));
  }

  /// Admin & master switch mati → tampil penuh (samakan dengan Arena/Kuis).
  Future<QuizEnergy> _fetchEnergy() async {
    if (!QuizSessionRules.enforceServerGate ||
        await quizRepository.isCurrentUserAdmin()) {
      return const QuizEnergy(current: 10, max: 10);
    }
    final res = await quizRepository.getEnergy();
    return res.fold(
      ifLeft: (_) => state.energy ?? const QuizEnergy(current: 0, max: 10),
      ifRight: (e) => e,
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
