import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_widgets.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/lesson_config.dart';
import 'package:khoirunnasyien/features/surah_journey/presentation/cubit/surah_lesson_cubit.dart';
import 'package:khoirunnasyien/features/surah_journey/presentation/cubit/surah_lesson_state.dart';

/// Layar HASIL ujian surah: lulus → centang hijau besar beranimasi (level
/// selesai di peta); belum lulus → ajakan mencoba lagi.
class LessonResultView extends StatelessWidget {
  const LessonResultView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SurahLessonCubit>();

    return BlocBuilder<SurahLessonCubit, SurahLessonState>(
      builder: (context, state) {
        final passed = state.passed;

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              children: [
                _ResultBadge(passed: passed),
                const SizedBox(height: 16),
                Text(
                  passed
                      ? 'Masyaa Allah! Level Selesai 🎉'
                      : 'Belum lulus, coba lagi ya!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  passed
                      ? 'Surah ${state.lesson.nameLatin} sudah kamu taklukkan!'
                      : 'Nilai minimal lulus adalah '
                            '${LessonConfig.passScore}. Semangat, pasti bisa!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13.5, color: Colors.black54),
                ),
                const SizedBox(height: 24),
                // Ring nilai + rincian benar.
                ScoreRing(percent: state.score, size: 140, caption: 'nilai'),
                const SizedBox(height: 12),
                Text(
                  'Benar ${state.correctCount} dari '
                  '${state.questions.length} soal',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                _SaveStatus(state: state),
                const SizedBox(height: 26),
                // Aksi.
                if (passed) ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => context.pop(),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.map_rounded),
                      label: const Text(
                        'Kembali ke Peta',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: cubit.retryTest,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Ulangi Ujian (perbaiki nilai)'),
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: cubit.retryTest,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text(
                        'Coba Lagi',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: cubit.backToLearning,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.menu_book_rounded),
                      label: const Text('Pelajari Ulang Materinya'),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black54,
                    ),
                    child: const Text('Kembali ke Peta'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Lencana hasil: centang hijau (lulus) / panah ulang oranye (belum) yang
/// muncul membesar dengan efek pegas.
class _ResultBadge extends StatelessWidget {
  final bool passed;

  const _ResultBadge({required this.passed});

  @override
  Widget build(BuildContext context) {
    final color = passed ? QuizColors.correct : QuizColors.gold;
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

/// Status penyimpanan nilai + nilai terbaik tersimpan.
class _SaveStatus extends StatelessWidget {
  final SurahLessonState state;

  const _SaveStatus({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.saving) {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text(
            'Menyimpan nilai…',
            style: TextStyle(fontSize: 12.5, color: Colors.black54),
          ),
        ],
      );
    }
    final saved = state.savedProgress;
    if (saved == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: QuizColors.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 16, color: QuizColors.gold),
          const SizedBox(width: 5),
          Text(
            'Nilai terbaikmu: ${saved.bestScore}',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: QuizColors.goldDark,
            ),
          ),
        ],
      ),
    );
  }
}
