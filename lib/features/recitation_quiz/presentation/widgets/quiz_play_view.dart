import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:khoirunnasyien/features/recitation_quiz/presentation/cubit/recitation_quiz_cubit.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/cubit/recitation_quiz_state.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_widgets.dart';

/// Layar mengerjakan soal: kartu ayat prompt + tombol rekam + hasil per soal.
class QuizPlayView extends StatefulWidget {
  const QuizPlayView({super.key});

  @override
  State<QuizPlayView> createState() => _QuizPlayViewState();
}

class _QuizPlayViewState extends State<QuizPlayView> {
  final AudioPlayer _player = AudioPlayer();

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _playChime() {
    // Efek suara halus saat jawaban benar.
    _player.play(AssetSource('sounds/correct.wav'), volume: 0.6);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RecitationQuizCubit>();

    return BlocConsumer<RecitationQuizCubit, RecitationQuizState>(
      listenWhen: (p, c) =>
          (c.phase == AnswerPhase.revealed &&
              c.passed &&
              (p.phase != c.phase || p.currentIndex != c.currentIndex)) ||
          (c.errorMessage != null && p.errorMessage != c.errorMessage),
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
        if (state.phase == AnswerPhase.revealed && state.passed) {
          _playChime();
        }
      },
      builder: (context, state) {
        final q = state.currentQuestion;
        if (q == null) return const SizedBox.shrink();

        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SegmentedProgress(
                      total: state.total,
                      currentIndex: state.currentIndex,
                      doneScores: state.answers.map((a) => a.score).toList(),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          'Soal ${state.questionNumber} dari ${state.total}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const Spacer(),
                        if (state.attempt == 2 && !state.canAdvance)
                          _pill(context, 'Percobaan ke-2', QuizColors.gold),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    children: [
                      _PromptHint(ayahCount: q.answerAyahCount),
                      const SizedBox(height: 12),
                      PromptAyahCard(text: q.prompt.text),
                      const SizedBox(height: 24),
                      _bottomSection(context, cubit, state),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _bottomSection(
    BuildContext context,
    RecitationQuizCubit cubit,
    RecitationQuizState state,
  ) {
    switch (state.phase) {
      case AnswerPhase.idle:
        return _RecordButton(
          label: state.attempt == 2 ? 'Rekam ulang' : 'Ketuk untuk merekam',
          recording: false,
          onTap: cubit.startRecording,
        );
      case AnswerPhase.recording:
        return _RecordButton(
          label: 'Ketuk untuk berhenti',
          recording: true,
          onTap: cubit.stopAndCheck,
        );
      case AnswerPhase.processing:
        return Column(
          children: const [
            SizedBox(height: 8),
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Memeriksa bacaan…',
                style: TextStyle(color: Colors.black54)),
          ],
        );
      case AnswerPhase.revealed:
        return _ResultPanel(cubit: cubit, state: state);
    }
  }

  Widget _pill(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _PromptHint extends StatelessWidget {
  /// Jumlah ayat yang harus dilanjutkan santri.
  final int ayahCount;

  const _PromptHint({required this.ayahCount});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const base = TextStyle(fontWeight: FontWeight.w600, color: Colors.black54);
    final strong = TextStyle(
      fontWeight: FontWeight.w800,
      color: scheme.primary,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.arrow_downward_rounded, size: 16, color: scheme.primary),
        const SizedBox(width: 6),
        Text.rich(
          ayahCount > 1
              ? TextSpan(style: base, children: [
                  const TextSpan(text: 'Lanjutkan '),
                  TextSpan(text: '$ayahCount ayat', style: strong),
                  const TextSpan(text: ' berikutnya'),
                ])
              : const TextSpan(
                  text: 'Lanjutkan ayat berikutnya', style: base),
        ),
      ],
    );
  }
}

/// Tombol rekam bundar besar dengan denyut saat merekam.
class _RecordButton extends StatelessWidget {
  final String label;
  final bool recording;
  final VoidCallback onTap;

  const _RecordButton({
    required this.label,
    required this.recording,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = recording ? Colors.red : scheme.primary;
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: recording ? 0.5 : 0.3),
                  blurRadius: recording ? 28 : 16,
                  spreadRadius: recording ? 4 : 0,
                ),
              ],
            ),
            child: Icon(
              recording ? Icons.stop_rounded : Icons.mic_rounded,
              color: Colors.white,
              size: 44,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(label,
            style:
                const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

/// Panel hasil sebuah percobaan: skor + aksi (ulang / lanjut / kunci jawaban).
class _ResultPanel extends StatelessWidget {
  final RecitationQuizCubit cubit;
  final RecitationQuizState state;

  const _ResultPanel({required this.cubit, required this.state});

  @override
  Widget build(BuildContext context) {
    final pct = state.currentResult?.accuracyPercent ?? 0;
    final passed = state.passed;

    final String headline;
    if (passed) {
      headline = pct > 90 ? 'Masyaa Allah! 🎉' : 'Alhamdulillah, lolos!';
    } else if (state.canRetry) {
      headline = 'Belum cukup, coba lagi ya';
    } else {
      headline = 'Belum tepat — ini jawabannya';
    }

    return Column(
      children: [
        ScoreRing(percent: pct, size: 130),
        const SizedBox(height: 12),
        Text(
          headline,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),

        // Kunci jawaban + koreksi (hanya saat gagal 2x).
        if (state.revealAnswer && state.bestResult != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black12),
            ),
            child: Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Jawaban benar',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black54)),
                ),
                const SizedBox(height: 12),
                CorrectionText(diffs: state.bestResult!.diffs),
                const SizedBox(height: 14),
                const CorrectionLegend(),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Aksi.
        if (state.canRetry)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: cubit.retry,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Ulangi'),
                ),
              ),
            ],
          )
        else
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: cubit.next,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                state.isLastQuestion ? 'Lihat Hasil' : 'Lanjut',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }
}
