import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_widgets.dart';
import 'package:khoirunnasyien/features/surah_journey/presentation/cubit/surah_lesson_cubit.dart';
import 'package:khoirunnasyien/features/surah_journey/presentation/cubit/surah_lesson_state.dart';
import 'package:khoirunnasyien/features/surah_journey/presentation/widgets/journey_style.dart';

/// Layar HASIL test bagian / ujian akhir — gaya malam journey, dengan XP yang
/// didapat dan aksi lanjut sesuai keadaan (bagian berikutnya / ujian / ulang).
class LessonResultView extends StatelessWidget {
  const LessonResultView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SurahLessonCubit>();

    return BlocBuilder<SurahLessonCubit, SurahLessonState>(
      builder: (context, state) {
        final passed = state.passed;
        final isExam = state.isExam;
        final section = state.activeSection;

        // Aksi "lanjut" setelah lulus test bagian: bagian berikutnya yang
        // belum lulus, atau ujian akhir bila semua sudah lulus.
        final nextSection = section == null
            ? null
            : state.nextSectionAfter(section.id);

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              children: [
                _ResultBadge(passed: passed),
                const SizedBox(height: 16),
                Text(
                  passed
                      ? (isExam
                            ? 'Masyaa Allah! Surah Ditaklukkan 🎉'
                            : 'Alhamdulillah, Lulus! 🎉')
                      : 'Belum lulus, coba lagi ya!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  passed
                      ? (isExam
                            ? 'Surah ${state.lesson.nameLatin} selesai — '
                                  'centang hijau untukmu di peta!'
                            : '${section?.title ?? 'Bagian'} sudah kamu '
                                  'kuasai. Lanjutkan perjalananmu!')
                      : 'Minimal ${state.minCorrect} benar dari '
                            '${state.questions.length} soal. '
                            'Semangat, pasti bisa!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
                const SizedBox(height: 22),

                // Skor besar: benar X dari Y.
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 18,
                  ),
                  decoration: journeyCardDecoration(
                    borderColor: passed
                        ? const Color(0xFF34D399).withValues(alpha: 0.5)
                        : QuizColors.gold.withValues(alpha: 0.4),
                    radius: 20,
                  ),
                  child: Column(
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${state.correctCount}',
                              style: TextStyle(
                                color: passed
                                    ? const Color(0xFF34D399)
                                    : QuizColors.gold,
                                fontSize: 44,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            TextSpan(
                              text: '/${state.questions.length}',
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isExam ? 'benar • nilai ${state.score}' : 'soal benar',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _XpAndSaveStatus(state: state),
                const SizedBox(height: 26),

                // ── Aksi ─────────────────────────────────────────────────
                if (passed && isExam) ...[
                  JourneyPrimaryButton(
                    onPressed: () => context.pop(),
                    icon: Icons.map_rounded,
                    label: 'Kembali ke Peta',
                  ),
                  const SizedBox(height: 10),
                  JourneySecondaryButton(
                    onPressed: cubit.backToOverview,
                    icon: Icons.list_alt_rounded,
                    label: 'Lihat Bagian Surah',
                  ),
                ] else if (passed && nextSection != null) ...[
                  JourneyPrimaryButton(
                    onPressed: () => cubit.continueToSection(nextSection),
                    icon: Icons.arrow_forward_rounded,
                    label: 'Lanjut: ${nextSection.title}',
                  ),
                  const SizedBox(height: 10),
                  JourneySecondaryButton(
                    onPressed: cubit.backToOverview,
                    label: 'Kembali ke Daftar Bagian',
                  ),
                ] else if (passed) ...[
                  // Semua bagian lulus → tawarkan ujian akhir.
                  JourneyPrimaryButton(
                    onPressed: state.examUnlocked
                        ? () {
                            cubit.backToOverview();
                            cubit.startExam();
                          }
                        : cubit.backToOverview,
                    icon: Icons.rocket_launch_rounded,
                    label: state.examUnlocked
                        ? 'Mulai Ujian Akhir'
                        : 'Kembali ke Daftar Bagian',
                    showEnergyCost:
                        state.examUnlocked && !state.progress.examPassed,
                  ),
                  if (state.examUnlocked) ...[
                    const SizedBox(height: 10),
                    JourneySecondaryButton(
                      onPressed: cubit.backToOverview,
                      label: 'Kembali ke Daftar Bagian',
                    ),
                  ],
                ] else ...[
                  // Belum lulus.
                  JourneyPrimaryButton(
                    onPressed: cubit.retryTest,
                    icon: Icons.refresh_rounded,
                    label: 'Coba Lagi',
                    showEnergyCost: !_alreadyPassed(state),
                  ),
                  const SizedBox(height: 10),
                  if (section != null)
                    JourneySecondaryButton(
                      onPressed: cubit.backToLearning,
                      icon: Icons.menu_book_rounded,
                      label: 'Pelajari Ulang Materinya',
                    ),
                  TextButton(
                    onPressed: cubit.backToOverview,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white54,
                    ),
                    child: const Text('Kembali ke Daftar Bagian'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Target test ini sudah pernah lulus sebelumnya (percobaan ulang gratis).
  bool _alreadyPassed(SurahLessonState state) {
    final section = state.activeSection;
    return section == null
        ? state.progress.examPassed
        : state.progress.of(section.id).passed;
  }
}

/// Lencana hasil: centang hijau (lulus) / panah ulang emas (belum) yang
/// muncul membesar dengan efek pegas.
class _ResultBadge extends StatelessWidget {
  final bool passed;

  const _ResultBadge({required this.passed});

  @override
  Widget build(BuildContext context) {
    final color = passed ? const Color(0xFF10B981) : QuizColors.gold;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 650),
      curve: Curves.elasticOut,
      builder: (context, t, child) => Transform.scale(scale: t, child: child),
      child: Container(
        width: 104,
        height: 104,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: passed
                ? [const Color(0xFF34D399), const Color(0xFF059669)]
                : [QuizColors.gold, QuizColors.goldDark],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.45),
              blurRadius: 26,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          passed ? Icons.check_rounded : Icons.replay_rounded,
          color: Colors.white,
          size: 56,
        ),
      ),
    );
  }
}

/// XP yang didapat + status penyimpanan hasil.
class _XpAndSaveStatus extends StatelessWidget {
  final SurahLessonState state;

  const _XpAndSaveStatus({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.saving) {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white70,
            ),
          ),
          SizedBox(width: 8),
          Text(
            'Menyimpan hasil…',
            style: TextStyle(fontSize: 12.5, color: Colors.white70),
          ),
        ],
      );
    }
    final xp = state.xpGained ?? 0;
    if (xp <= 0) return const SizedBox.shrink();
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Transform.scale(scale: t, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: QuizColors.gold.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: QuizColors.gold.withValues(alpha: 0.55)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, size: 20, color: QuizColors.gold),
            const SizedBox(width: 6),
            Text(
              '+$xp XP',
              style: const TextStyle(
                color: QuizColors.gold,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
