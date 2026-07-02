import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:khoirunnasyien/features/recitation_check/domain/entities/ayah.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_question.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/cubit/recitation_quiz_cubit.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/cubit/recitation_quiz_state.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_widgets.dart';

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
    _player.play(AssetSource('sounds/correct.wav'), volume: 0.5);
  }

  void _chimeWrong() {
    _player.play(AssetSource('sounds/wrong.wav'), volume: 0.45);
  }

  void _playTick() {
    _tickPlayer.play(AssetSource('sounds/tick.wav'), volume: 0.25);
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
            } else if (state.choiceCorrect == false) {
              _chimeWrong();
            }
          },
        ),
        BlocListener<RecitationQuizCubit, RecitationQuizState>(
          listenWhen: (p, c) => p.secondsLeft != c.secondsLeft,
          listener: (context, state) {
            if (state.status == QuizStatus.playing && 
                state.secondsLeft <= 10 && 
                state.secondsLeft > 0) {
              _playTick();
            }
          },
        ),
      ],
      child: BlocBuilder<RecitationQuizCubit, RecitationQuizState>(
        builder: (context, state) {
          final q = state.currentQuestion;
        if (q == null) return const SizedBox.shrink();

        final required = q.answerAyahCount;
        final locked = state.choiceLocked;

        return SafeArea(
          child: Column(
            children: [
              _Header(
                secondsLeft: state.secondsLeft,
                points: state.runningPoints,
                answered: state.answeredCount,
              ),
              // Petunjuk soal (selalu terlihat).
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  children: [
                    PromptAyahCard(text: q.prompt.text),
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
              // Daftar opsi (bergulir bila panjang).
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
                      // Warnai hanya opsi yang DIPILIH saat terkunci (tanpa
                      // membocorkan jawaban benar).
                      lockedCorrect: locked && order >= 0
                          ? state.choiceCorrect
                          : null,
                      onTap: locked ? null : () => cubit.pickOption(i),
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
          ),
        );
      },
    ));
  }
}

// ─────────────────────────────────────────────────────────────── Header ──

class _Header extends StatelessWidget {
  final int secondsLeft;
  final int points;
  final int answered;

  const _Header({
    required this.secondsLeft,
    required this.points,
    required this.answered,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final urgent = secondsLeft <= 10;
    final timerColor = urgent ? QuizColors.missing : scheme.primary;
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
              const Spacer(),
              // Poin berjalan.
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: QuizColors.gold.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 16, color: QuizColors.gold),
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
                color: Colors.black45,
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
    final scheme = Theme.of(context).colorScheme;
    const base = TextStyle(fontWeight: FontWeight.w600, color: Colors.black54);
    final strong = TextStyle(fontWeight: FontWeight.w800, color: scheme.primary);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.touch_app_rounded, size: 16, color: scheme.primary),
        const SizedBox(width: 6),
        Text.rich(
          required > 1
              ? TextSpan(style: base, children: [
                  const TextSpan(text: 'Pilih '),
                  TextSpan(text: '$required ayat', style: strong),
                  const TextSpan(text: ' lanjutan sesuai urutan'),
                ])
              : const TextSpan(
                  text: 'Pilih lanjutan ayat yang benar', style: base),
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
    final scheme = Theme.of(context).colorScheme;
    final required = question.answerAyahCount;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(required, (slot) {
        final filled = slot < picks.length;
        final optionIndex = filled ? picks[slot] : -1;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: GestureDetector(
            onTap: (filled && !locked) ? () => onRemove(optionIndex) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 54,
              height: 44,
              decoration: BoxDecoration(
                color: filled
                    ? scheme.primary.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: filled ? scheme.primary : Colors.black12,
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
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: scheme.primary,
                            ),
                          ),
                          if (!locked)
                            Icon(Icons.close_rounded,
                                size: 14,
                                color: scheme.primary.withValues(alpha: 0.7)),
                        ],
                      )
                    : Text(
                        '${slot + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.black26,
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
    final scheme = Theme.of(context).colorScheme;

    Color border;
    Color bg;
    Color badge;
    if (lockedCorrect == true) {
      border = QuizColors.correct;
      bg = QuizColors.correct.withValues(alpha: 0.10);
      badge = QuizColors.correct;
    } else if (lockedCorrect == false) {
      border = QuizColors.missing;
      bg = QuizColors.missing.withValues(alpha: 0.10);
      badge = QuizColors.missing;
    } else if (selected) {
      border = scheme.primary;
      bg = scheme.primary.withValues(alpha: 0.06);
      badge = scheme.primary;
    } else {
      border = Colors.black12;
      bg = Colors.white;
      badge = scheme.primary;
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
                ayah.text,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'QuranHafs',
                  fontSize: 15,
                  height: 1.7,
                  color: Color(0xFF212121),
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
                      : Colors.black.withValues(alpha: 0.18),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: enabled ? onSubmit : null,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.check_rounded),
          label: const Text(
            'Jawab',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
