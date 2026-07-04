import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:khoirunnasyien/features/recitation_check/domain/entities/ayah.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_question.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/quiz_config.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/cubit/recitation_quiz_cubit.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/cubit/recitation_quiz_state.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_trivia_widgets.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_widgets.dart';

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

          // Soal BONUS (trivia): layar khusus bernuansa emas + gelombang tepi.
          if (q.isTrivia) {
            return _ChoiceTriviaScreen(state: state, cubit: cubit);
          }

          final required = q.answerAyahCount;
          final locked = state.choiceLocked;

          return SafeArea(
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
                          // Key per-soal: cegah warna slot beranimasi "nyambung"
                          // dari soal sebelumnya saat pindah soal.
                          key: ValueKey('order_${state.currentIndex}'),
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
                    // Key per-soal: kartu opsi selalu segar saat pindah soal,
                    // agar warna hijau/merah tak "nyambung" ke soal berikutnya.
                    key: ValueKey('opts_${state.currentIndex}'),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    itemCount: q.options.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final order = state.picks.indexOf(i);
                      return _OptionCard(
                        ayah: q.options[i],
                        orderLabel: order >= 0 ? '${order + 1}' : null,
                        selected: order >= 0,
                        // Warnai hanya opsi yang DIPILIH saat terkunci
                        // (tanpa membocorkan jawaban benar).
                        lockedCorrect:
                            locked && order >= 0 ? state.choiceCorrect : null,
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
      ),
    );
  }
}

// ───────────────────────────────────────────── Layar Soal Bonus (trivia) ──

/// Layar Soal Bonus mode pilihan: latar krem + gelombang emas di tepi, timer
/// sesi utama tampil "dijeda", hitung mundur sendiri, dan soal trivia surah.
class _ChoiceTriviaScreen extends StatelessWidget {
  final RecitationQuizState state;
  final RecitationQuizCubit cubit;

  const _ChoiceTriviaScreen({required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final t = state.currentQuestion!.trivia!;
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
                      ? const _TriviaIntroSplash()
                      : _TriviaContent(state: state, cubit: cubit),
                ),
              ),
              // Tombol "Jawab" untuk soal nama+arti (dua bagian).
              if (!intro && t.needsSubmit && !state.choiceBonusRewardStage)
                _GoldSubmitBar(
                  enabled: state.choiceComplete && !state.choiceLocked,
                  onSubmit: cubit.submitChoice,
                ),
            ],
          ),
        ),
        // Gelombang emas tipis bergerak di tepi layar.
        const Positioned.fill(child: IgnorePointer(child: _GoldEdgeGlow())),
        // Hadiah: poin & waktu gratis beranimasi terbang ke HUD.
        if (state.choiceBonusRewardStage)
          Positioned.fill(
            child: IgnorePointer(
              child: _BonusRewardOverlay(
                key: ValueKey(state.currentIndex),
                seconds: state.lastTimeBonus,
                points:
                    state.answers.isNotEmpty ? state.answers.last.score : 0,
                full: (state.answers.isNotEmpty
                        ? state.answers.last.score
                        : 0) >=
                    QuizConfig.choiceTriviaPoints,
              ),
            ),
          ),
      ],
    );
  }
}

/// Overlay hadiah Soal Bonus: sekilas "Benar!" lalu pill "+poin" & "+detik"
/// terbang cepat ke arah HUD (poin di kanan atas, timer yang dijeda di kiri
/// atas) sambil memudar — nuansa reward permainan.
class _BonusRewardOverlay extends StatefulWidget {
  final int seconds;
  final int points;
  final bool full;

  const _BonusRewardOverlay({
    super.key,
    required this.seconds,
    required this.points,
    required this.full,
  });

  @override
  State<_BonusRewardOverlay> createState() => _BonusRewardOverlayState();
}

class _BonusRewardOverlayState extends State<_BonusRewardOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        // Muncul (pop) → tahan → terbang ke HUD.
        final introT = Curves.easeOutBack.transform((t / 0.30).clamp(0.0, 1.0));
        const flyStart = 0.52;
        final flyT = ((t - flyStart) / (1 - flyStart)).clamp(0.0, 1.0);
        final flyE = Curves.easeInCubic.transform(flyT);

        // Kartu teks: tampil solid & jelas saat reveal; memudar + sedikit
        // menyusut begitu pill mulai terbang.
        final cardOpacity =
            (introT * (1 - (flyT / 0.3).clamp(0.0, 1.0))).clamp(0.0, 1.0);
        final cardScale = (0.75 + 0.25 * introT) * (1 - 0.08 * flyE);

        // Pill: "docked" di bawah kartu saat reveal, lalu terbang ke HUD &
        // memudar di ujung perjalanan.
        final flyOut = ((flyE - 0.62) / 0.38).clamp(0.0, 1.0);
        final pillOpacity = (introT * (1 - flyOut)).clamp(0.0, 1.0);
        final pillScale = (0.75 + 0.25 * introT) * (1 - 0.45 * flyE);

        // Scrim gelap lembut agar reveal terbaca jelas; memudar saat terbang
        // supaya HUD terlihat ketika pill "mendarat".
        final scrimAlpha = 0.38 * introT * (1 - flyT);

        Widget flyingPill(Alignment start, Alignment target, Widget child) {
          return Align(
            alignment: Alignment.lerp(start, target, flyE)!,
            child: Opacity(
              opacity: pillOpacity,
              child: Transform.scale(scale: pillScale, child: child),
            ),
          );
        }

        return Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: scrimAlpha),
              ),
            ),
            // Kartu hadiah — latar solid agar teks jelas terpisah dari soal.
            Align(
              alignment: const Alignment(0, -0.18),
              child: Opacity(
                opacity: cardOpacity,
                child: Transform.scale(
                  scale: cardScale,
                  child: _RewardCard(full: widget.full),
                ),
              ),
            ),
            // Pill waktu → dari bawah kartu terbang ke timer (kiri atas).
            flyingPill(
              const Alignment(-0.28, 0.14),
              const Alignment(-0.72, -0.86),
              _RewardPill(
                icon: Icons.more_time_rounded,
                label: '+${widget.seconds} dtk',
                color: QuizColors.correct,
              ),
            ),
            // Pill poin → dari bawah kartu terbang ke poin (kanan atas).
            flyingPill(
              const Alignment(0.28, 0.14),
              const Alignment(0.78, -0.86),
              _RewardPill(
                icon: Icons.star_rounded,
                label: '+${widget.points}',
                color: QuizColors.goldDark,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Kartu hadiah bertekstur solid (ikon + headline + subteks) sebagai latar
/// jelas saat reveal Soal Bonus.
class _RewardCard extends StatelessWidget {
  final bool full;

  const _RewardCard({required this.full});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: QuizColors.gold, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: QuizColors.gold.withValues(alpha: 0.35),
            blurRadius: 22,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [QuizColors.gold, QuizColors.goldDark],
              ),
            ),
            child: const Icon(Icons.celebration_rounded,
                color: Colors.white, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            full ? 'Benar! 🎉' : 'Benar sebagian! 👍',
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: QuizColors.goldDark),
          ),
          const SizedBox(height: 4),
          const Text('Hadiah untukmu…',
              style: TextStyle(fontSize: 13, color: Colors.black54)),
        ],
      ),
    );
  }
}

/// Pill hadiah kecil (ikon + angka) yang terbang ke HUD.
class _RewardPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _RewardPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color, width: 1.6),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
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
                const Icon(Icons.pause_rounded,
                    size: 15, color: Colors.black45),
                const SizedBox(width: 4),
                Text('$mainSeconds dtk',
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.black45)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Text('waktu dijeda',
              style: TextStyle(fontSize: 11.5, color: Colors.black38)),
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
                const Icon(Icons.star_rounded,
                    size: 16, color: QuizColors.gold),
                const SizedBox(width: 4),
                Text('$points',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: QuizColors.goldDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Splash "SOAL BONUS" sesaat sebelum soal trivia muncul.
class _TriviaIntroSplash extends StatelessWidget {
  const _TriviaIntroSplash();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutBack,
        builder: (context, v, child) => Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.scale(scale: 0.7 + 0.3 * v, child: child),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 94,
              height: 94,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [QuizColors.gold, QuizColors.goldDark],
                ),
                boxShadow: [
                  BoxShadow(
                    color: QuizColors.gold.withValues(alpha: 0.5),
                    blurRadius: 26,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.bolt_rounded,
                  color: Colors.white, size: 52),
            ),
            const SizedBox(height: 18),
            const Text('SOAL BONUS',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: QuizColors.goldDark)),
            const SizedBox(height: 6),
            const Text('Waktu permainan dijeda • poin lebih besar',
                style: TextStyle(fontSize: 13, color: Colors.black54)),
          ],
        ),
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
              lockedCorrect:
                  locked ? t.meaningCorrect(state.meaningPick) : null,
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
                  Text('$secondsLeft',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: color,
                          height: 1.0)),
                  Text('dtk',
                      style: TextStyle(
                          fontSize: 11,
                          color: color.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600)),
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
            Text('Soal Bonus',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: QuizColors.goldDark)),
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
        child: FilledButton.icon(
          onPressed: enabled ? onSubmit : null,
          style: FilledButton.styleFrom(
            backgroundColor: QuizColors.goldDark,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.check_rounded),
          label: const Text('Jawab',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

/// Gelombang emas tipis yang bergerak halus di sepanjang tepi layar bonus.
class _GoldEdgeGlow extends StatefulWidget {
  const _GoldEdgeGlow();

  @override
  State<_GoldEdgeGlow> createState() => _GoldEdgeGlowState();
}

class _GoldEdgeGlowState extends State<_GoldEdgeGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => CustomPaint(
        size: Size.infinite,
        painter: _GoldEdgeGlowPainter(_c.value),
      ),
    );
  }
}

class _GoldEdgeGlowPainter extends CustomPainter {
  /// Fase animasi 0..1.
  final double t;

  _GoldEdgeGlowPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Vignette emas lembut di tepi (pusat transparan).
    final vignette = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.15,
        colors: [
          Colors.transparent,
          QuizColors.gold.withValues(alpha: 0.0),
          QuizColors.gold.withValues(alpha: 0.14),
        ],
        stops: const [0.55, 0.82, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, vignette);

    // Gelombang berjalan: sweep gradient berputar sepanjang bingkai.
    final rrect =
        RRect.fromRectAndRadius(rect.deflate(3), const Radius.circular(30));
    final glowOpacity = 0.4 + 0.2 * (0.5 + 0.5 * sin(2 * pi * t));
    final sweep = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..shader = SweepGradient(
        transform: GradientRotation(2 * pi * t),
        colors: [
          QuizColors.gold.withValues(alpha: 0.0),
          QuizColors.gold.withValues(alpha: glowOpacity),
          QuizColors.goldDark.withValues(alpha: 0.12),
          QuizColors.gold.withValues(alpha: glowOpacity),
          QuizColors.gold.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(rect);
    canvas.drawRRect(rrect, sweep);
  }

  @override
  bool shouldRepaint(_GoldEdgeGlowPainter old) => old.t != t;
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
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: QuizColors.correct.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '+$timeBonus dtk',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: QuizColors.correct,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
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
    super.key,
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
                _stripAyahNumber(ayah.text),
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'QuranHafs',
                  fontSize: 18,
                  height: 1.8,
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
