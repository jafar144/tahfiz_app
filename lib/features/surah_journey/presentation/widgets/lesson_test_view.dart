import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_widgets.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/entities/lesson_question.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/lesson_config.dart';
import 'package:khoirunnasyien/features/surah_journey/presentation/cubit/surah_lesson_cubit.dart';
import 'package:khoirunnasyien/features/surah_journey/presentation/cubit/surah_lesson_state.dart';
import 'package:khoirunnasyien/features/surah_journey/presentation/widgets/journey_style.dart';

/// Layar TEST bergaya journey (malam): campuran soal suara (sambung ayat /
/// ayat terakhir) dan soal pilihan (materi / arti kata). Soal berganti dengan
/// animasi geser.
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
                          '${state.isExam ? 'Ujian Akhir — ' : ''}'
                          'Soal ${state.currentIndex + 1} dari '
                          '${state.questions.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
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
    final (icon, label) = question.isVoice
        ? (Icons.mic_rounded, 'Soal Suara')
        : (Icons.touch_app_rounded, 'Pilihan');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: QuizColors.gold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: QuizColors.gold.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: QuizColors.gold),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: QuizColors.gold,
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
          // Ayat petunjuk.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: journeyCardDecoration(
              borderColor: QuizColors.gold.withValues(alpha: 0.3),
              radius: 20,
            ),
            child: HighlightedAyahText(text: q.prompt!.text, fontSize: 23),
          ),
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
                CircularProgressIndicator(color: Colors.white70),
                SizedBox(height: 16),
                Text(
                  'Memeriksa bacaan…',
                  style: TextStyle(color: Colors.white70),
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
    const base = TextStyle(fontWeight: FontWeight.w500, color: Colors.white70);
    const strong = TextStyle(
      fontWeight: FontWeight.w900,
      color: QuizColors.gold,
    );

    final ayahCount = question.answer.length;
    final TextSpan instruction = switch (question.type) {
      LessonTaskType.voiceLastAyah => const TextSpan(
        style: base,
        children: [
          TextSpan(text: 'Baca '),
          TextSpan(text: 'ayat TERAKHIR', style: strong),
          TextSpan(text: ' dari surah ini'),
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
            : const TextSpan(text: 'Lanjutkan ayat berikutnya', style: base),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: QuizColors.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: QuizColors.gold.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: QuizColors.goldDark,
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
          const Icon(
            Icons.arrow_downward_rounded,
            size: 20,
            color: QuizColors.gold,
          ),
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
    final color = recording ? Colors.red : QuizColors.gold;
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
                  color: color.withValues(alpha: recording ? 0.5 : 0.35),
                  blurRadius: recording ? 28 : 18,
                  spreadRadius: recording ? 4 : 1,
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
            color: Colors.white70,
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
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16.5,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),
        if (!passed) ...[
          // Koreksi memakai kartu terang agar warna koreksi tetap terbaca.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
        JourneyPrimaryButton(
          onPressed: cubit.next,
          label: state.isLastQuestion ? 'Lihat Hasil' : 'Lanjut',
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
                  QuizColors.gold.withValues(alpha: 0.20),
                  QuizColors.gold.withValues(alpha: 0.06),
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
                  color: QuizColors.gold,
                ),
                const SizedBox(height: 10),
                Text(
                  fact.question,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                  ),
                ),
                // Ayat kosa kata dengan kata disorot (bila ada).
                if (fact.arabicText != null) ...[
                  const SizedBox(height: 12),
                  HighlightedAyahText(
                    text: fact.arabicText!,
                    highlight: fact.highlightWord,
                    fontSize: 21,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Opsi jawaban A-D.
          for (var i = 0; i < fact.options.length; i++) ...[
            _OptionTile(
              letter: String.fromCharCode(65 + i),
              text: fact.options[i],
              arabic: fact.arabicOptions,
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

/// Kartu satu opsi jawaban dengan huruf A/B/C/D — gaya gelap journey.
class _OptionTile extends StatelessWidget {
  final String letter;
  final String text;

  /// Teks opsi berupa Arab (font mushaf, RTL).
  final bool arabic;
  final bool picked;

  /// null = netral; true = tampil benar (hijau); false = tampil salah (merah).
  final bool? lockedState;
  final VoidCallback? onTap;

  const _OptionTile({
    required this.letter,
    required this.text,
    required this.arabic,
    required this.picked,
    required this.lockedState,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const correctColor = Color(0xFF34D399);
    const wrongColor = Color(0xFFF87171);

    Color border;
    Color bg;
    Color badge;
    if (lockedState == true) {
      border = correctColor;
      bg = correctColor.withValues(alpha: 0.14);
      badge = correctColor;
    } else if (lockedState == false) {
      border = wrongColor;
      bg = wrongColor.withValues(alpha: 0.14);
      badge = wrongColor;
    } else if (picked) {
      border = QuizColors.gold;
      bg = QuizColors.gold.withValues(alpha: 0.10);
      badge = QuizColors.gold;
    } else {
      border = JourneyColors.cardBorder;
      bg = JourneyColors.card;
      badge = Colors.white38;
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
                  alpha: lockedState != null || picked ? 1 : 0.10,
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
                              ? const Color(0xFF0B2540)
                              : Colors.white70,
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: arabic
                  ? Text(
                      text,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontFamily: 'QuranHafs',
                        color: Colors.white,
                        fontSize: 19,
                        height: 1.6,
                      ),
                    )
                  : Text(
                      text,
                      style: const TextStyle(
                        color: Colors.white,
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
