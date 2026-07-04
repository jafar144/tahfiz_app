import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:khoirunnasyien/core/router/route_names.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_mode.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/cubit/recitation_quiz_cubit.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/cubit/recitation_quiz_state.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_choice_play_view.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_intro_view.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_play_view.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_result_view.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_widgets.dart';

class RecitationQuizPage extends StatelessWidget {
  const RecitationQuizPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RecitationQuizCubit>();

    return BlocConsumer<RecitationQuizCubit, RecitationQuizState>(
      listenWhen: (p, c) =>
          c.startBlock != null && p.startBlock != c.startBlock,
      listener: (context, state) async {
        await showQuizBlockSheet(context, state.startBlock!);
        if (context.mounted) context.read<RecitationQuizCubit>().clearStartBlock();
      },
      builder: (context, state) {
        final playing = state.status == QuizStatus.playing;
        final atIntro = state.status == QuizStatus.intro;
        final isChoice = state.settings.mode.isChoice;

        return PopScope(
          // Hanya di layar intro tombol back keluar ke halaman sebelumnya;
          // di layar lain back kembali ke intro (bukan langsung ke home).
          canPop: atIntro,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            if (state.status == QuizStatus.playing) {
              final leave = await _confirmLeave(context);
              if (leave != true) return;
            }
            if (context.mounted) context.read<RecitationQuizCubit>().backToIntro();
          },
          child: Scaffold(
            // Sembunyikan AppBar saat bermain agar layar lebih lega.
            appBar: playing
                ? null
                : AppBar(
                    title: const Text('Kuis Hafalan'),
                    centerTitle: true,
                    actions: [
                      _LeaderboardButton(
                        onTap: () => context.pushNamed(
                          RouteNames.quizLeaderboard,
                          extra: state.settings.mode,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                  ),
            body: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              // Halaman baru meluncur masuk dari kanan sambil memudar; halaman
              // lama memudar keluar ke kiri (nuansa maju ke depan).
              transitionBuilder: (child, animation) {
                final slide = Tween<Offset>(
                  begin: const Offset(0.18, 0),
                  end: Offset.zero,
                ).animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(position: slide, child: child),
                );
              },
              child: KeyedSubtree(
                key: ValueKey(state.status),
                child: switch (state.status) {
                  QuizStatus.intro => QuizIntroView(
                      settings: state.settings,
                      onSettingsChanged: cubit.setSettings,
                      onStart: cubit.start,
                      energy: state.energy,
                      energyLoading: state.energyLoading,
                      onRefillReady: cubit.loadEnergy,
                    ),
                  QuizStatus.loading => const _Loading(),
                  QuizStatus.error => _ErrorView(
                      message: state.errorMessage ?? 'Terjadi kesalahan.',
                      onRetry: () => cubit.start(state.settings),
                    ),
                  QuizStatus.playing => isChoice
                      ? const QuizChoicePlayView()
                      : const QuizPlayView(),
                  QuizStatus.finished => QuizResultView(
                      result: state.result!,
                      review: state.review,
                      saving: state.saving,
                      saveError: state.saveError,
                      energy: state.energy,
                      onPlayAgain: cubit.playAgain,
                      onRefillReady: cubit.loadEnergy,
                      // "Selesai" kembali ke layar awal (bukan keluar ke home).
                      onFinish: cubit.backToIntro,
                    ),
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _confirmLeave(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari kuis?'),
        content: const Text('Progres kuis saat ini tidak akan disimpan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}

/// Tombol leaderboard bergaya (piala emas) untuk AppBar kuis.
class _LeaderboardButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LeaderboardButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Leaderboard',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Ink(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [QuizColors.gold, QuizColors.goldDark],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: QuizColors.gold.withValues(alpha: 0.45),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.emoji_events_rounded,
                  color: Colors.white, size: 21),
            ),
          ),
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Menyiapkan soal…', style: TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: const Text('Coba Lagi')),
          ],
        ),
      ),
    );
  }
}
