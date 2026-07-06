import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_widgets.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/entities/lesson_question.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/lesson_config.dart';
import 'package:khoirunnasyien/features/surah_journey/presentation/cubit/surah_lesson_cubit.dart';
import 'package:khoirunnasyien/features/surah_journey/presentation/cubit/surah_lesson_state.dart';

/// Layar UJIAN surah: campuran soal suara (sambung ayat / ayat terakhir) dan
/// soal pilihan dari materi belajar. Soal berganti dengan animasi geser.
class LessonTestView extends StatefulWidget {
  const LessonTestView({super.key});

  @override
  State<LessonTestView> createState() => _LessonTestViewState();
}

class _LessonTestViewState extends State<LessonTestView> {
  final AudioPlayer _player = AudioPlayer();

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SurahLessonCubit>();

    return BlocConsumer<SurahLessonCubit, SurahLessonState>(
      // Denting benar/salah tiap ada jawaban baru tercatat.
      listenWhen: (p, c) => c.answers.length > p.answers.length,
      listener: (context, state) {
        final correct = state.answers.isNotEmpty && state.answers.last;
        _player.play(
          AssetSource(correct ? 'sounds/correct.wav' : 'sounds/wrong.wav'),
          volume: correct ? 0.5 : 0.45,
        );
      },
      builder: (context, state) {
        final q = state.currentQuestion;
        if (q == null) return const SizedBox.shrink();

        return SafeArea(
          child: Column(
            children: [
              // Kepala: progres bersegmen + nomor soal + jenis soal.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SegmentedProgress(
                      total: state.questions.length,
                      currentIndex: state.currentIndex,
                      doneScores: [
                        for (final ok in state.answers) ok ? 100 : 0,
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          'Soal ${state.currentIndex + 1} dari '
                          '${state.questions.length}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const Spacer(),
                        _TypeChip(question: q),
                      ],
                    ),
                  ],
                ),
              ),
              // Isi soal — hanya bagian ini yang bergeser saat pindah soal.
              Expanded(
                child: QuestionSlideSwitcher(
                  index: state.currentIndex,
                  child: q.isVoice
                      ? _VoiceQuestion(state: state, cubit: cubit)
                      : _ChoiceQuestion(state: state, cubit: cubit),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Chip penanda jenis soal (suara / pilihan).
class _TypeChip extends StatelessWidget {
  final LessonQuestion question;

  const _TypeChip({required this.question});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, label, color) = question.isVoice
        ? (Icons.mic_rounded, 'Soal Suara', scheme.primary)
        : (Icons.touch_app_rounded, 'Pilihan', QuizColors.goldDark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────── Soal suara ──

class _VoiceQuestion extends StatelessWidget {
  final SurahLessonState state;
  final SurahLessonCubit cubit;

  const _VoiceQuestion({required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final q = state.currentQuestion!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        children: [
          _InstructionCard(question: q),
          const SizedBox(height: 12),
          PromptAyahCard(text: q.prompt!.text),
          const SizedBox(height: 24),
          switch (state.phase) {
            LessonPhase.idle => _RecordButton(
              label: 'Ketuk untuk merekam',
              recording: false,
              onTap: cubit.startRecording,
            ),
            LessonPhase.recording => _RecordButton(
              label: 'Ketuk untuk berhenti',
              recording: true,
              onTap: cubit.stopAndCheck,
            ),
            LessonPhase.processing => const Column(
              children: [
                SizedBox(height: 8),
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Memeriksa bacaan…',
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
            LessonPhase.revealed => _VoiceResult(state: state, cubit: cubit),
          },
        ],
      ),
    );
  }
}

/// Kartu instruksi soal suara — teks menyesuaikan jenis tugas.
class _InstructionCard extends StatelessWidget {
  final LessonQuestion question;

  const _InstructionCard({required this.question});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = TextStyle(
      fontWeight: FontWeight.w500,
      color: scheme.primary.withValues(alpha: 0.85),
    );
    final strong = TextStyle(
      fontWeight: FontWeight.w900,
      color: scheme.primary,
    );

    final ayahCount = question.answer.length;
    final TextSpan instruction = switch (question.type) {
      LessonTaskType.voiceLastAyah => TextSpan(
        style: base,
        children: [
          const TextSpan(text: 'Baca '),
          TextSpan(text: 'ayat TERAKHIR', style: strong),
          const TextSpan(text: ' dari surah ini'),
        ],
      ),
      _ =>
        ayahCount > 1
            ? TextSpan(
                style: base,
                children: [
                  const TextSpan(text: 'Lanjutkan '),
                  TextSpan(text: '$ayahCount ayat', style: strong),
                  const TextSpan(text: ' berikutnya'),
                ],
              )
            : TextSpan(text: 'Lanjutkan ayat berikutnya', style: base),
    };

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
          Expanded(child: Text.rich(instruction)),
          Icon(Icons.arrow_downward_rounded, size: 20, color: scheme.primary),
        ],
      ),
    );
  }
}

/// Tombol rekam bundar besar dengan nuansa denyut saat merekam.
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
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Panel hasil pemeriksaan bacaan: skor + koreksi bila salah + tombol lanjut.
class _VoiceResult extends StatelessWidget {
  final SurahLessonState state;
  final SurahLessonCubit cubit;

  const _VoiceResult({required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final result = state.voiceResult;
    if (result == null) return const SizedBox.shrink();
    final pct = result.accuracyPercent;
    final passed = pct >= LessonConfig.voicePassThreshold;

    return Column(
      children: [
        ScoreRing(percent: pct, size: 120),
        const SizedBox(height: 12),
        Text(
          passed
              ? (pct > 90
                    ? 'Masyaa Allah, sempurna! 🎉'
                    : 'Alhamdulillah, benar!')
              : 'Belum tepat — perhatikan koreksinya',
          style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),
        if (!passed) ...[
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
                  child: Text(
                    'Jawaban benar',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                CorrectionText(diffs: result.diffs),
                const SizedBox(height: 14),
                const CorrectionLegend(),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: cubit.next,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              state.isLastQuestion ? 'Lihat Hasil' : 'Lanjut',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────── Soal pilihan ──

class _ChoiceQuestion extends StatelessWidget {
  final SurahLessonState state;
  final SurahLessonCubit cubit;

  const _ChoiceQuestion({required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final fact = state.currentQuestion!.fact!;
    final locked = state.choiceLocked;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Kartu pertanyaan.
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  QuizColors.gold.withValues(alpha: 0.14),
                  QuizColors.gold.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: QuizColors.gold.withValues(alpha: 0.4)),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.psychology_rounded,
                  size: 30,
                  color: QuizColors.goldDark,
                ),
                const SizedBox(height: 10),
                Text(
                  fact.question,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Opsi jawaban A-D.
          for (var i = 0; i < fact.options.length; i++) ...[
            _OptionTile(
              letter: String.fromCharCode(65 + i),
              text: fact.options[i],
              picked: state.choicePick == i,
              // Setelah terkunci: opsi benar hijau; pilihan salah merah.
              lockedState: !locked
                  ? null
                  : (i == fact.correctIndex
                        ? true
                        : (state.choicePick == i ? false : null)),
              onTap: locked ? null : () => cubit.pickChoice(i),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

/// Kartu satu opsi jawaban dengan huruf A/B/C/D.
class _OptionTile extends StatelessWidget {
  final String letter;
  final String text;
  final bool picked;

  /// null = netral; true = tampil benar (hijau); false = tampil salah (merah).
  final bool? lockedState;
  final VoidCallback? onTap;

  const _OptionTile({
    required this.letter,
    required this.text,
    required this.picked,
    required this.lockedState,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Color border;
    Color bg;
    Color badge;
    if (lockedState == true) {
      border = QuizColors.correct;
      bg = QuizColors.correct.withValues(alpha: 0.10);
      badge = QuizColors.correct;
    } else if (lockedState == false) {
      border = QuizColors.missing;
      bg = QuizColors.missing.withValues(alpha: 0.10);
      badge = QuizColors.missing;
    } else if (picked) {
      border = scheme.primary;
      bg = scheme.primary.withValues(alpha: 0.06);
      badge = scheme.primary;
    } else {
      border = Colors.black12;
      bg = Colors.white;
      badge = Colors.black38;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: border,
            width: lockedState != null || picked ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: badge.withValues(
                  alpha: lockedState != null || picked ? 1 : 0.08,
                ),
                border: Border.all(
                  color: badge.withValues(
                    alpha: lockedState != null || picked ? 0 : 0.4,
                  ),
                ),
              ),
              child: Center(
                child: lockedState == true
                    ? const Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: Colors.white,
                      )
                    : lockedState == false
                    ? const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Colors.white,
                      )
                    : Text(
                        letter,
                        style: TextStyle(
                          color: lockedState != null || picked
                              ? Colors.white
                              : Colors.black54,
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
