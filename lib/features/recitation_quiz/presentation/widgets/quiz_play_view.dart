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

  void _playWrong() {
    _player.play(AssetSource('sounds/wrong.wav'), volume: 0.5);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RecitationQuizCubit>();

    return BlocConsumer<RecitationQuizCubit, RecitationQuizState>(
      listenWhen: (p, c) =>
          (c.phase == AnswerPhase.revealed &&
              c.passed &&
              (p.phase != c.phase || p.currentIndex != c.currentIndex)) ||
          (c.bonusStage == BonusStage.done &&
              p.bonusStage != BonusStage.done) ||
          (c.errorMessage != null && p.errorMessage != c.errorMessage),
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
        // Denting saat bacaan lolos (sebelum tahap bonus).
        if (state.phase == AnswerPhase.revealed &&
            state.passed &&
            (state.bonusStage == BonusStage.none ||
                state.bonusStage == BonusStage.offered)) {
          _playChime();
        }
        // Umpan balik saat soal bonus selesai.
        if (state.bonusStage == BonusStage.done) {
          state.bonusCorrect == true ? _playChime() : _playWrong();
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
                        if (state.attempt == 2 && !state.canAdvance) ...[
                          _pill(context, 'Percobaan ke-2', QuizColors.gold),
                          const SizedBox(width: 8),
                        ],
                        if (state.phase == AnswerPhase.idle ||
                            state.phase == AnswerPhase.recording)
                          _VoiceTimerChip(secondsLeft: state.voiceSecondsLeft),
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
                      // Petunjuk "lanjutkan" disembunyikan saat tahap bonus
                      // (ayat tetap tampil sebagai acuan soal tebak surah).
                      if (state.bonusStage == BonusStage.none) ...[
                        _PromptHint(ayahCount: q.answerAyahCount),
                        const SizedBox(height: 12),
                      ],
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
    // "Lanjutkan" & "berikutnya": tetap biru, sedikit lebih tipis dari "N ayat".
    final base = TextStyle(
      fontWeight: FontWeight.w500,
      color: scheme.primary.withValues(alpha: 0.85),
    );
    final strong = TextStyle(
      fontWeight: FontWeight.w900,
      color: scheme.primary,
    );
    // Kartu instruksi selebar penuh + label "SOAL" agar keseluruhan perintah
    // (bukan cuma ayatnya) langsung terbaca jelas — tanpa memperbesar teksnya.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'SOAL',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              ayahCount > 1
                  ? TextSpan(style: base, children: [
                      const TextSpan(text: 'Lanjutkan '),
                      TextSpan(text: '$ayahCount ayat', style: strong),
                      const TextSpan(text: ' berikutnya'),
                    ])
                  : TextSpan(text: 'Lanjutkan ayat berikutnya', style: base),
            ),
          ),
          Icon(Icons.arrow_downward_rounded, size: 20, color: scheme.primary),
        ],
      ),
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

/// Panel hasil sebuah percobaan: skor + aksi (ulang / bonus / lanjut / kunci).
class _ResultPanel extends StatelessWidget {
  final RecitationQuizCubit cubit;
  final RecitationQuizState state;

  const _ResultPanel({required this.cubit, required this.state});

  @override
  Widget build(BuildContext context) {
    // Tahap bonus berjalan → fokuskan layar pada soal tebak surah.
    if (state.bonusStage == BonusStage.running && state.bonus != null) {
      return _BonusRunningView(cubit: cubit, state: state);
    }

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

    final hasBonus = passed && state.bonus != null;

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

        // Hasil bonus (tahap done).
        if (hasBonus && state.bonusStage == BonusStage.done) ...[
          _BonusResultCard(state: state),
          const SizedBox(height: 16),
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
        else if (hasBonus && state.bonusStage == BonusStage.offered)
          _BonusPrep(secondsLeft: state.bonusPrepSecondsLeft)
        else
          _nextButton(),
      ],
    );
  }

  Widget _nextButton() {
    return SizedBox(
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
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

/// Jeda berpikir setelah lolos: kartu + hitung mundur; Soal Bonus mulai
/// otomatis di akhir hitungan (tanpa tombol).
class _BonusPrep extends StatelessWidget {
  final int secondsLeft;

  const _BonusPrep({required this.secondsLeft});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: QuizColors.gold.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: QuizColors.gold.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bolt_rounded, color: QuizColors.goldDark, size: 20),
              SizedBox(width: 6),
              Text('Soal Bonus • Tebak Surah',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: QuizColors.goldDark)),
            ],
          ),
          const SizedBox(height: 12),
          // Angka hitung mundur besar.
          TweenAnimationBuilder<double>(
            key: ValueKey(secondsLeft),
            tween: Tween(begin: 0.7, end: 1),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Text(
              '$secondsLeft',
              style: const TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w900,
                color: QuizColors.goldDark,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Bersiap… Soal Bonus dimulai otomatis',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

/// Chip hitung mundur waktu berpikir per soal (mode suara); memerah saat menipis.
class _VoiceTimerChip extends StatelessWidget {
  final int secondsLeft;

  const _VoiceTimerChip({required this.secondsLeft});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final urgent = secondsLeft <= 10;
    final color = urgent ? QuizColors.missing : scheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_rounded, size: 15, color: color),
          const SizedBox(width: 4),
          Text(
            '$secondsLeft dtk',
            style: TextStyle(
                color: color, fontWeight: FontWeight.w800, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// Layar soal bonus berjalan: hitung mundur + pertanyaan + opsi surah.
class _BonusRunningView extends StatelessWidget {
  final RecitationQuizCubit cubit;
  final RecitationQuizState state;

  const _BonusRunningView({required this.cubit, required this.state});

  @override
  Widget build(BuildContext context) {
    final b = state.bonus!;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        _BonusTimerBar(
          secondsLeft: state.bonusSecondsLeft,
          total: b.durationSeconds,
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.35)),
          ),
          child: Text(
            b.questionText,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, height: 1.4),
          ),
        ),
        if (b.isMulti) ...[
          const SizedBox(height: 8),
          Text(
            'Pilih ${b.requiredPicks} surah sesuai urutan',
            style: TextStyle(
                fontSize: 12.5,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600),
          ),
        ],
        const SizedBox(height: 14),
        ...List.generate(b.options.length, (i) {
          final order = state.bonusPicks.indexOf(i);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SurahOptionTile(
              name: b.optionName(i),
              orderLabel: b.isMulti && order >= 0 ? '${order + 1}' : null,
              selected: order >= 0,
              onTap: () => cubit.pickBonus(i),
            ),
          );
        }),
        if (b.isMulti) ...[
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: state.bonusComplete ? cubit.submitBonus : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Jawab',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ],
    );
  }
}

/// Hitung mundur soal bonus (angka + bar), memerah saat waktu menipis.
class _BonusTimerBar extends StatelessWidget {
  final int secondsLeft;
  final int total;

  const _BonusTimerBar({required this.secondsLeft, required this.total});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final urgent = secondsLeft <= 3;
    final color = urgent ? QuizColors.missing : scheme.primary;
    final progress =
        total <= 0 ? 0.0 : (secondsLeft / total).clamp(0.0, 1.0);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer_rounded, size: 20, color: color),
            const SizedBox(width: 6),
            Text(
              '$secondsLeft',
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w900, color: color),
            ),
            Text(' dtk',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color.withValues(alpha: 0.8))),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: progress, end: progress),
            duration: const Duration(milliseconds: 300),
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 7,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
      ],
    );
  }
}

/// Kartu opsi nama surah pada soal bonus.
class _SurahOptionTile extends StatelessWidget {
  final String name;
  final String? orderLabel;
  final bool selected;
  final VoidCallback? onTap;

  const _SurahOptionTile({
    required this.name,
    required this.orderLabel,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? scheme.primary : Colors.black12,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: selected ? scheme.primary : Colors.black87,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? scheme.primary : Colors.transparent,
                border: Border.all(
                  color: selected ? scheme.primary : Colors.black26,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: selected
                    ? Text(
                        orderLabel ?? '✓',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kartu hasil soal bonus (benar +poin / salah / waktu habis).
class _BonusResultCard extends StatelessWidget {
  final RecitationQuizState state;

  const _BonusResultCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final b = state.bonus!;
    final correct = state.bonusCorrect == true;
    final color = correct ? QuizColors.correct : QuizColors.missing;
    final String title;
    if (correct) {
      title = 'Benar! +${state.bonusEarned} poin bonus';
    } else if (state.bonusSecondsLeft == 0) {
      title = 'Waktu habis';
    } else {
      title = 'Kurang tepat';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                correct
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                      color: color)),
            ],
          ),
          if (!correct) ...[
            const SizedBox(height: 6),
            Text(
              'Jawaban: ${b.answerNames.join(', ')}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ],
      ),
    );
  }
}
