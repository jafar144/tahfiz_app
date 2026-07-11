import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:khoirunnasyien/features/recitation_check/domain/entities/ayah.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_question.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/quiz_config.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/cubit/recitation_quiz_cubit.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/cubit/recitation_quiz_state.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_bonus_fx.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_button.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_haptics.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_trivia_widgets.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_widgets.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/vocab_match_board.dart';
import 'package:khoirunnasyien/features/surah_journey/presentation/widgets/journey_style.dart';

/// Pola nomor ayat di akhir teks Uthmani: spasi-tak-putus + angka Arab-Hindi.
final _ayahNumberTail = RegExp(r'[٠-٩ \s]+$');

/// Buang glyph nomor ayat di akhir agar pemain tak bisa menebak urutan lewat
/// nomornya (mode pilihan).
String _stripAyahNumber(String text) => text.replaceAll(_ayahNumberTail, '');

/// Layar bermain mode PILIHAN: timer mundur 60 detik, kartu ayat petunjuk,
/// lalu 6 opsi ayat. Santri memilih lanjutan yang benar (berurutan bila lebih
/// dari 1 ayat). Benar → poin; salah → 0. Auto-lanjut setelah umpan balik.
class QuizChoicePlayView extends StatefulWidget {
  const QuizChoicePlayView({super.key});

  @override
  State<QuizChoicePlayView> createState() => _QuizChoicePlayViewState();
}

class _QuizChoicePlayViewState extends State<QuizChoicePlayView> {
  final AudioPlayer _player = AudioPlayer();
  final AudioPlayer _tickPlayer = AudioPlayer();

  @override
  void dispose() {
    _player.dispose();
    _tickPlayer.dispose();
    super.dispose();
  }

  void _chimeCorrect() {
    _player.play(AssetSource('sounds/correct.wav'), volume: 0.85);
  }

  void _chimeWrong() {
    _player.play(AssetSource('sounds/wrong.wav'), volume: 0.45);
  }

  void _playTick() {
    _tickPlayer.play(AssetSource('sounds/tick.wav'), volume: 0.4);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RecitationQuizCubit>();

    return MultiBlocListener(
      listeners: [
        BlocListener<RecitationQuizCubit, RecitationQuizState>(
          listenWhen: (p, c) => p.choiceCorrect != c.choiceCorrect,
          listener: (context, state) {
            if (state.choiceCorrect == true) {
              _chimeCorrect();
              QuizHaptics.correct();
            } else if (state.choiceCorrect == false) {
              _chimeWrong();
              QuizHaptics.wrong();
            }
          },
        ),
        BlocListener<RecitationQuizCubit, RecitationQuizState>(
          listenWhen: (p, c) => p.secondsLeft != c.secondsLeft,
          listener: (context, state) {
            if (state.status == QuizStatus.playing &&
                !state.isChoiceBonus &&
                state.secondsLeft <= 10 &&
                state.secondsLeft > 0) {
              _playTick();
            }
          },
        ),
        // Detik menipis pada hitung mundur Soal Bonus (timer sendiri).
        BlocListener<RecitationQuizCubit, RecitationQuizState>(
          listenWhen: (p, c) =>
              p.choiceBonusSecondsLeft != c.choiceBonusSecondsLeft,
          listener: (context, state) {
            if (state.choiceBonusRunning &&
                state.choiceBonusSecondsLeft <= 5 &&
                state.choiceBonusSecondsLeft > 0) {
              _playTick();
            }
          },
        ),
      ],
      child: BlocBuilder<RecitationQuizCubit, RecitationQuizState>(
        builder: (context, state) {
          final q = state.currentQuestion;
          if (q == null) return const SizedBox.shrink();

          // Layar bonus "menimpa" layar soal biasa saat masuk/keluar; soal
          // biasa ↔ kosa kata memakai geser horizontal di dalam satu
          // QuestionSlideSwitcher bersama (header timer/poin tetap diam).
          final Widget screen;
          if (q.isTrivia) {
            // Soal BONUS (trivia): layar khusus bernuansa emas + gelombang tepi.
            screen = _ChoiceTriviaScreen(state: state, cubit: cubit);
          } else {
            screen = SafeArea(
              child: Column(
                children: [
                  _Header(
                    secondsLeft: state.secondsLeft,
                    points: state.runningPoints,
                    answered: state.answeredCount,
                    showTimeBonus: state.choiceCorrect == true,
                    timeBonus: state.lastTimeBonus,
                    bonusTick: state.timeBonusTick,
                  ),
                  // Hanya soal + jawaban yang bergeser saat pindah soal; header
                  // (timer/poin) di atas tetap diam.
                  Expanded(
                    child: QuestionSlideSwitcher(
                      index: state.currentIndex,
                      child: q.isKnowledge
                          ? _KnowledgeContent(state: state, cubit: cubit)
                          : _AyahChoiceContent(state: state, cubit: cubit),
                    ),
                  ),
                ],
              ),
            );
          }

          return BonusCoverSwitcher(showBonus: q.isTrivia, child: screen);
        },
      ),
    );
  }
}

// ─────────────────────────────────────── Konten soal (dalam slide switcher) ──

/// Isi soal lanjutan ayat (petunjuk + opsi + tombol Jawab) — dirender di dalam
/// [QuestionSlideSwitcher] agar ikut geser saat pindah soal.
class _AyahChoiceContent extends StatelessWidget {
  final RecitationQuizState state;
  final RecitationQuizCubit cubit;

  const _AyahChoiceContent({required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final q = state.currentQuestion!;
    final required = q.answerAyahCount;
    final locked = state.choiceLocked;

    return Column(
      children: [
        // Petunjuk soal (selalu terlihat).
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              PromptAyahCard(text: q.prompt.text, dark: true),
              const SizedBox(height: 10),
              _ChoiceHint(required: required),
              if (required > 1) ...[
                const SizedBox(height: 10),
                _OrderStrip(
                  question: q,
                  picks: state.picks,
                  locked: locked,
                  onRemove: cubit.pickOption,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Daftar opsi ayat (bergulir bila panjang).
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            itemCount: q.options.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final order = state.picks.indexOf(i);
              return _OptionCard(
                ayah: q.options[i],
                orderLabel: order >= 0 ? '${order + 1}' : null,
                selected: order >= 0,
                // Saat terkunci, jawaban benar selalu hijau dan pilihan yang
                // keliru merah agar hasil Tantangan terbaca jelas.
                lockedCorrect: !locked
                    ? null
                    : (q.correctOptionOrder.contains(i)
                          ? true
                          : (order >= 0 ? false : null)),
                onTap: locked
                    ? null
                    : () {
                        QuizHaptics.select();
                        cubit.pickOption(i);
                      },
              );
            },
          ),
        ),
        // Tombol "Jawab" untuk soal multi-ayat.
        if (required > 1)
          _SubmitBar(
            enabled: state.choiceComplete && !locked,
            onSubmit: cubit.submitChoice,
          ),
      ],
    );
  }
}

/// Isi soal kosa kata (arti bahasa Arab) — juga di dalam
/// [QuestionSlideSwitcher] agar animasi geser masuk/keluar berjalan.
class _KnowledgeContent extends StatelessWidget {
  final RecitationQuizState state;
  final RecitationQuizCubit cubit;

  const _KnowledgeContent({required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final fact = state.currentQuestion!.knowledge!;
    final locked = state.choiceLocked;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          fact.question,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (fact.arabicText != null) ...[
          const SizedBox(height: 16),
          HighlightedAyahText(
            text: fact.arabicText!,
            highlight: fact.highlightWord,
            fontSize: 24,
          ),
        ],
        const SizedBox(height: 20),
        for (var i = 0; i < fact.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _KnowledgeOption(
              text: fact.options[i],
              selected: state.picks.contains(i),
              // Kuis (Latihan/Tantangan): warnai hanya opsi yang DIPILIH —
              // salah → merah, TANPA menyingkap jawaban benar (beda dengan
              // mode belajar di Petualangan Surah).
              result: locked && state.picks.contains(i)
                  ? i == fact.correctIndex
                  : null,
              onTap: locked ? null : () => cubit.pickOption(i),
            ),
          ),
      ],
    );
  }
}

class _KnowledgeOption extends StatelessWidget {
  final String text;
  final bool selected;
  final bool? result;
  final VoidCallback? onTap;

  const _KnowledgeOption({
    required this.text,
    required this.selected,
    required this.result,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = result == true
        ? QuizColors.correctBright
        : result == false
        ? QuizColors.missingBright
        : selected
        ? QuizColors.gold
        : Colors.white24;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color.withValues(
            alpha: selected || result != null ? 0.15 : 0.05,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color,
            width: selected || result != null ? 2 : 1,
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ChoiceVocabMatchContent extends StatelessWidget {
  final RecitationQuizState state;
  final RecitationQuizCubit cubit;

  const _ChoiceVocabMatchContent({required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        children: [
          _GoldCountdown(
            secondsLeft: state.choiceBonusSecondsLeft,
            total: QuizConfig.choiceTriviaSeconds,
          ),
          const SizedBox(height: 14),
          Expanded(
            child: VocabMatchBoard(
              question: state.currentQuestion!.vocabMatch!,
              light: true,
              pinCheckButton: true,
              onCompleted: cubit.completeVocabMatch,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceTriviaScreen extends StatelessWidget {
  final RecitationQuizState state;
  final RecitationQuizCubit cubit;

  const _ChoiceTriviaScreen({required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final q = state.currentQuestion!;
    final t = q.trivia;
    final intro = state.choiceBonusIntro;
    return Stack(
      children: [
        // Latar krem lembut agar layar terasa spesial.
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFFDF8), Color(0xFFFFF4DE)],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              _TriviaTopBar(
                mainSeconds: state.secondsLeft,
                points: state.runningPoints,
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: intro
                      ? const BonusIntroSplash(
                          subtitle: 'Waktu permainan dijeda • poin lebih besar',
                        )
                      : q.isVocabMatch
                      ? _ChoiceVocabMatchContent(state: state, cubit: cubit)
                      : _TriviaContent(state: state, cubit: cubit),
                ),
              ),
              // Tombol "Jawab" untuk soal nama+arti (dua bagian).
              if (!intro &&
                  t?.needsSubmit == true &&
                  !state.choiceBonusRewardStage)
                _GoldSubmitBar(
                  enabled: state.choiceComplete && !state.choiceLocked,
                  onSubmit: cubit.submitChoice,
                ),
            ],
          ),
        ),
        // Gelombang emas tipis bergerak di tepi layar.
        const Positioned.fill(child: IgnorePointer(child: GoldEdgeGlow())),
        // Hadiah: poin & waktu gratis beranimasi terbang ke HUD.
        if (state.choiceBonusRewardStage)
          Positioned.fill(
            child: IgnorePointer(
              child: BonusRewardOverlay(
                key: ValueKey(state.currentIndex),
                seconds: state.lastTimeBonus,
                points: state.answers.isNotEmpty
                    ? state.answers.last.score + state.answers.last.bonusScore
                    : 0,
                full:
                    (state.answers.isNotEmpty
                        ? state.answers.last.score +
                              state.answers.last.bonusScore
                        : 0) >=
                    QuizConfig.choiceTriviaPoints,
              ),
            ),
          ),
      ],
    );
  }
}

/// Bilah atas Soal Bonus: timer sesi utama (DIJEDA) + poin berjalan.
class _TriviaTopBar extends StatelessWidget {
  final int mainSeconds;
  final int points;

  const _TriviaTopBar({required this.mainSeconds, required this.points});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.pause_rounded,
                  size: 15,
                  color: Colors.black45,
                ),
                const SizedBox(width: 4),
                Text(
                  '$mainSeconds dtk',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'waktu dijeda',
            style: TextStyle(fontSize: 11.5, color: Colors.black38),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: QuizColors.gold.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star_rounded,
                  size: 16,
                  color: QuizColors.gold,
                ),
                const SizedBox(width: 4),
                Text(
                  '$points',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: QuizColors.goldDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Isi Soal Bonus: hitung mundur emas + ayat rujukan + pertanyaan + jawaban.
class _TriviaContent extends StatelessWidget {
  final RecitationQuizState state;
  final RecitationQuizCubit cubit;

  const _TriviaContent({required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final t = state.currentQuestion!.trivia!;
    final locked = state.choiceLocked;
    final pick = state.picks.isNotEmpty ? state.picks.first : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GoldCountdown(
            secondsLeft: state.choiceBonusSecondsLeft,
            total: QuizConfig.choiceTriviaSeconds,
          ),
          const SizedBox(height: 16),
          PromptAyahCard(text: state.currentQuestion!.prompt.text),
          const SizedBox(height: 14),
          TriviaQuestionCard(
            text: t.questionTextWith('ayat di atas'),
            points: QuizConfig.choiceTriviaPoints,
            hint: t.hintText,
          ),
          const SizedBox(height: 16),
          if (t.isNameMeaning) ...[
            TriviaSection(
              label: 'Nama Surah',
              icon: Icons.menu_book_rounded,
              options: [
                for (var i = 0; i < t.options.length; i++) t.optionName(i),
              ],
              picked: pick,
              lockedCorrect: locked ? t.nameCorrect(pick) : null,
              onPick: locked ? null : cubit.pickOption,
            ),
            const SizedBox(height: 12),
            TriviaSection(
              label: 'Arti Surah',
              icon: Icons.translate_rounded,
              options: t.meaningOptions,
              picked: state.meaningPick,
              lockedCorrect: locked
                  ? t.meaningCorrect(state.meaningPick)
                  : null,
              onPick: locked ? null : cubit.pickMeaning,
            ),
          ] else
            TriviaNumberOptions(
              options: [for (final n in t.numberOptions) '$n'],
              picked: pick,
              lockedCorrect: locked ? t.numberCorrect(pick) : null,
              onPick: locked ? null : cubit.pickOption,
            ),
        ],
      ),
    );
  }
}

/// Hitung mundur bundar emas untuk Soal Bonus.
class _GoldCountdown extends StatelessWidget {
  final int secondsLeft;
  final int total;

  const _GoldCountdown({required this.secondsLeft, required this.total});

  @override
  Widget build(BuildContext context) {
    final urgent = secondsLeft <= 5;
    final color = urgent ? QuizColors.missing : QuizColors.goldDark;
    final progress = total <= 0 ? 0.0 : (secondsLeft / total).clamp(0.0, 1.0);
    return Column(
      children: [
        SizedBox(
          width: 84,
          height: 84,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 84,
                height: 84,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: progress, end: progress),
                  duration: const Duration(milliseconds: 300),
                  builder: (context, v, _) => CircularProgressIndicator(
                    value: v,
                    strokeWidth: 7,
                    strokeCap: StrokeCap.round,
                    backgroundColor: QuizColors.gold.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$secondsLeft',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: color,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    'dtk',
                    style: TextStyle(
                      fontSize: 11,
                      color: color.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bolt_rounded, size: 16, color: QuizColors.goldDark),
            SizedBox(width: 4),
            Text(
              'Soal Bonus',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: QuizColors.goldDark,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Tombol "Jawab" bernuansa emas untuk Soal Bonus (soal nama+arti).
class _GoldSubmitBar extends StatelessWidget {
  final bool enabled;
  final VoidCallback onSubmit;

  const _GoldSubmitBar({required this.enabled, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: SizedBox(
        width: double.infinity,
        child: QuizButton(
          label: 'Jawab',
          icon: Icons.check_rounded,
          color: QuizColors.goldDark,
          onPressed: enabled ? onSubmit : null,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────── Header ──

class _Header extends StatelessWidget {
  final int secondsLeft;
  final int points;
  final int answered;

  /// Sedang menampilkan umpan balik benar → tampilkan chip "+N dtk".
  final bool showTimeBonus;

  /// Besar tambahan waktu (detik) dari jawaban benar terakhir.
  final int timeBonus;

  /// Naik tiap bonus waktu, agar chip beranimasi ulang tiap jawaban benar.
  final int bonusTick;

  const _Header({
    required this.secondsLeft,
    required this.points,
    required this.answered,
    this.showTimeBonus = false,
    this.timeBonus = 0,
    this.bonusTick = 0,
  });

  @override
  Widget build(BuildContext context) {
    final urgent = secondsLeft <= 10;
    final timerColor = urgent ? QuizColors.missingBright : Colors.white;
    final progress = (secondsLeft / 60).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        children: [
          Row(
            children: [
              // Waktu.
              Icon(Icons.timer_rounded, size: 20, color: timerColor),
              const SizedBox(width: 6),
              Text(
                '$secondsLeft',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: timerColor,
                ),
              ),
              Text(
                ' dtk',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: timerColor.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(width: 8),
              // Chip "+2 dtk" yang muncul-pop tiap jawaban benar.
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.6, end: 1).animate(
                      CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                    ),
                    child: child,
                  ),
                ),
                child: showTimeBonus
                    ? Container(
                        key: ValueKey(bonusTick),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: QuizColors.correctBright.withValues(
                            alpha: 0.18,
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '+$timeBonus dtk',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: QuizColors.correctBright,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const Spacer(),
              // Poin berjalan.
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: QuizColors.gold.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: QuizColors.gold,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$points',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: QuizColors.goldDark,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'poin',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: QuizColors.goldDark.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: progress, end: progress),
              duration: const Duration(milliseconds: 400),
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 7,
                backgroundColor: timerColor.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation(timerColor),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Soal ${answered + 1}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceHint extends StatelessWidget {
  final int required;

  const _ChoiceHint({required this.required});

  @override
  Widget build(BuildContext context) {
    const base = TextStyle(fontWeight: FontWeight.w600, color: Colors.white70);
    const strong = TextStyle(
      fontWeight: FontWeight.w800,
      color: QuizColors.gold,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.touch_app_rounded, size: 16, color: QuizColors.gold),
        const SizedBox(width: 6),
        Text.rich(
          required > 1
              ? TextSpan(
                  style: base,
                  children: [
                    const TextSpan(text: 'Pilih '),
                    TextSpan(text: '$required ayat', style: strong),
                    const TextSpan(text: ' lanjutan sesuai urutan'),
                  ],
                )
              : const TextSpan(
                  text: 'Pilih lanjutan ayat yang benar',
                  style: base,
                ),
        ),
      ],
    );
  }
}

/// Strip urutan pilihan (mode multi-ayat): kotak bernomor 1..N.
class _OrderStrip extends StatelessWidget {
  final QuizQuestion question;
  final List<int> picks;
  final bool locked;
  final ValueChanged<int> onRemove;

  const _OrderStrip({
    required this.question,
    required this.picks,
    required this.locked,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final required = question.answerAyahCount;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(required, (slot) {
        final filled = slot < picks.length;
        final optionIndex = filled ? picks[slot] : -1;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: GestureDetector(
            onTap: (filled && !locked)
                ? () {
                    QuizHaptics.light();
                    onRemove(optionIndex);
                  }
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 42,
              height: 32,
              decoration: BoxDecoration(
                color: filled
                    ? QuizColors.gold.withValues(alpha: 0.16)
                    : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: filled ? QuizColors.gold : Colors.white12,
                  width: filled ? 1.5 : 1,
                ),
              ),
              child: Center(
                child: filled
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${slot + 1}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              color: QuizColors.gold,
                            ),
                          ),
                          if (!locked)
                            Icon(
                              Icons.close_rounded,
                              size: 12,
                              color: QuizColors.gold.withValues(alpha: 0.7),
                            ),
                        ],
                      )
                    : Text(
                        '${slot + 1}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white30,
                        ),
                      ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Kartu satu opsi ayat.
class _OptionCard extends StatelessWidget {
  final Ayah ayah;
  final String? orderLabel;
  final bool selected;

  /// null = tak terkunci; true = terpilih & benar; false = terpilih & salah.
  final bool? lockedCorrect;
  final VoidCallback? onTap;

  const _OptionCard({
    required this.ayah,
    required this.orderLabel,
    required this.selected,
    required this.lockedCorrect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color border;
    Color bg;
    Color badge;
    if (lockedCorrect == true) {
      border = QuizColors.correctBright;
      bg = QuizColors.correctBright.withValues(alpha: 0.14);
      badge = QuizColors.correctBright;
    } else if (lockedCorrect == false) {
      border = QuizColors.missingBright;
      bg = QuizColors.missingBright.withValues(alpha: 0.14);
      badge = QuizColors.missingBright;
    } else if (selected) {
      border = QuizColors.gold;
      bg = QuizColors.gold.withValues(alpha: 0.12);
      badge = QuizColors.gold;
    } else {
      border = Colors.white12;
      bg = QuizColors.nightCard;
      badge = QuizColors.gold;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: border,
            width: (selected || lockedCorrect != null) ? 1.6 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                _stripAyahNumber(ayah.text),
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'QuranHafs',
                  fontSize: 18,
                  height: 1.8,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Badge urutan / lingkaran kosong.
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: orderLabel != null ? badge : Colors.transparent,
                border: Border.all(
                  color: orderLabel != null
                      ? badge
                      : Colors.white.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: orderLabel != null
                    ? Text(
                        orderLabel!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
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

class _SubmitBar extends StatelessWidget {
  final bool enabled;
  final VoidCallback onSubmit;

  const _SubmitBar({required this.enabled, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: SizedBox(
        width: double.infinity,
        child: QuizButton(
          label: 'Jawab',
          icon: Icons.check_rounded,
          color: QuizColors.goldDark,
          onPressed: enabled ? onSubmit : null,
        ),
      ),
    );
  }
}
