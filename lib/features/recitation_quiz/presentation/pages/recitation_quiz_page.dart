import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:khoirunnasyien/features/recitation_quiz/presentation/cubit/recitation_quiz_cubit.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/cubit/recitation_quiz_state.dart';
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

        return PopScope(
          canPop: !playing,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            final leave = await _confirmLeave(context);
            if (leave == true && context.mounted) context.pop();
          },
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Kuis Hafalan'),
              centerTitle: true,
              actions: [
                if (state.energyLoading && state.energy == null)
                  const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Center(child: EnergyBadgeSkeleton()),
                  )
                else if (state.energy != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Center(
                      child: EnergyBadge(
                        energy: state.energy!,
                        onRefillReady: cubit.loadEnergy,
                      ),
                    ),
                  ),
              ],
            ),
            body: switch (state.status) {
              QuizStatus.intro => QuizIntroView(
                  onStart: cubit.start,
                  energy: state.energy,
                  energyLoading: state.energyLoading,
                ),
              QuizStatus.loading => const _Loading(),
              QuizStatus.error => _ErrorView(
                  message: state.errorMessage ?? 'Terjadi kesalahan.',
                  onRetry: () => cubit.start(state.settings),
                ),
              QuizStatus.playing => const QuizPlayView(),
              QuizStatus.finished => QuizResultView(
                  result: state.result!,
                  saving: state.saving,
                  saveError: state.saveError,
                  energy: state.energy,
                  onPlayAgain: cubit.playAgain,
                  onRefillReady: cubit.loadEnergy,
                  onFinish: () => context.pop(),
                ),
            },
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
