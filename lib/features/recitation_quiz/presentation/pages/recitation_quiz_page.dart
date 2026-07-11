import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_mode.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/cubit/recitation_quiz_cubit.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/cubit/recitation_quiz_state.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/night_loading_page.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_button.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_choice_play_view.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_intro_view.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_play_view.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_rank_reveal_view.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_result_view.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_widgets.dart';
import 'package:khoirunnasyien/features/surah_journey/presentation/widgets/journey_style.dart';

class RecitationQuizPage extends StatefulWidget {
  const RecitationQuizPage({super.key});

  @override
  State<RecitationQuizPage> createState() => _RecitationQuizPageState();
}

class _RecitationQuizPageState extends State<RecitationQuizPage> {
  /// Urutan alur layar. Dipakai untuk menentukan arah transisi: menuju indeks
  /// lebih besar = "maju" (halaman baru naik dari bawah), lebih kecil =
  /// "mundur" (halaman baru turun dari atas).
  static const _order = {
    QuizStatus.intro: 0,
    QuizStatus.loading: 1,
    QuizStatus.error: 1,
    QuizStatus.playing: 2,
    QuizStatus.rankReveal: 3,
    QuizStatus.finished: 4,
  };

  QuizStatus? _prevStatus;
  bool _advancing = true;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RecitationQuizCubit>();

    return BlocConsumer<RecitationQuizCubit, RecitationQuizState>(
      listenWhen: (p, c) =>
          c.startBlock != null && p.startBlock != c.startBlock,
      listener: (context, state) async {
        await showQuizBlockSheet(context, state.startBlock!);
        if (context.mounted) {
          context.read<RecitationQuizCubit>().clearStartBlock();
        }
      },
      builder: (context, state) {
        final status = state.status;
        // Perbarui arah transisi hanya ketika status benar-benar berganti,
        // agar rebuild lain (mis. pindah soal) tak mengubah arah.
        if (_prevStatus != null && _prevStatus != status) {
          _advancing = (_order[status] ?? 0) >= (_order[_prevStatus] ?? 0);
        }
        _prevStatus = status;

        final playing = status == QuizStatus.playing;
        final atIntro = status == QuizStatus.intro;
        final isChoice = state.settings.mode.isChoice;
        final challenge = state.challenge;
        // Bar atas hanya untuk layar yang butuh tombol kembali (intro latihan
        // & error). Saat bermain, loading, animasi peringkat, dan layar hasil
        // disembunyikan agar layar terasa lega.
        final showTopBar =
            (atIntro && !challenge) || status == QuizStatus.error;

        return PopScope(
          // Latihan: hanya layar intro yang boleh langsung keluar; layar lain
          // kembali ke intro. Tantangan: tanpa intro — back keluar halaman
          // (saat bermain dikonfirmasi dulu).
          canPop: challenge ? !playing : atIntro,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            if (state.status == QuizStatus.playing) {
              final leave = await _confirmLeaveSheet(
                context,
                challenge: challenge,
              );
              if (leave != true) return;
            }
            if (!context.mounted) return;
            if (challenge) {
              context.pop(); // lock dilepas oleh cubit.close()
            } else {
              context.read<RecitationQuizCubit>().backToIntro();
            }
          },
          child: Scaffold(
            // Latar malam islami — senada Petualangan Surah & Tahfiz Arena.
            body: JourneyBackground(
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    if (showTopBar)
                      _TopBar(title: challenge ? 'Tantangan' : 'Latihan Kuis'),
                    Expanded(
                      child: ClipRect(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 380),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          // Transisi horizontal berarah: saat "maju" (mis.
                          // mulai kuis) halaman baru masuk dari kanan & halaman
                          // lama geser ke kiri; saat "mundur" (mis. tekan
                          // Selesai) sebaliknya.
                          transitionBuilder: (child, animation) {
                            final incoming = child.key == ValueKey(status);
                            final Offset begin = _advancing
                                ? (incoming
                                      ? const Offset(1, 0)
                                      : const Offset(-1, 0))
                                : (incoming
                                      ? const Offset(-1, 0)
                                      : const Offset(1, 0));
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: begin,
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            );
                          },
                          // keyedFill menjaga identitas layar saat layar lama
                          // dibuang di akhir transisi — tanpanya State layar
                          // baru (mis. animasi ring hasil) tereset & mengulang.
                          layoutBuilder: (currentChild, previousChildren) =>
                              Stack(
                                children: [
                                  for (final c in previousChildren)
                                    keyedFill(c),
                                  if (currentChild != null)
                                    keyedFill(currentChild),
                                ],
                              ),
                          child: KeyedSubtree(
                            key: ValueKey(status),
                            child: switch (state.status) {
                              // Tantangan tak punya layar intro — status intro
                              // hanya sekejap sebelum sesi dimulai; tampilkan
                              // halaman loading yang sama.
                              QuizStatus.intro when challenge =>
                                const _QuizLoading(),
                              QuizStatus.intro => QuizIntroView(
                                settings: state.settings,
                                onSettingsChanged: cubit.setSettings,
                                onStart: cubit.start,
                                energy: state.energy,
                                energyLoading: state.energyLoading,
                                onRefillReady: cubit.loadEnergy,
                              ),
                              QuizStatus.loading => const _QuizLoading(),
                              QuizStatus.error => _ErrorView(
                                message:
                                    state.errorMessage ?? 'Terjadi kesalahan.',
                                onRetry: () => cubit.start(state.settings),
                              ),
                              QuizStatus.playing =>
                                isChoice
                                    ? const QuizChoicePlayView()
                                    : const QuizPlayView(),
                              // Seremoni pasca-Tantangan: loading "menghitung
                              // peringkat" → animasi menyusul → tombol
                              // Selanjutnya → layar hasil.
                              QuizStatus.rankReveal => QuizRankRevealView(
                                reveal: state.rankReveal,
                                onContinue: cubit.continueToResult,
                              ),
                              QuizStatus.finished => QuizResultView(
                                result: state.result!,
                                review: state.review,
                                isChallenge: challenge,
                                saving: state.saving,
                                saveError: state.saveError,
                                energy: state.energy,
                                onPlayAgain: cubit.playAgain,
                                onRefillReady: cubit.loadEnergy,
                                // "Selesai": latihan kembali ke layar awal;
                                // Tantangan keluar halaman (jatah terpakai).
                                onFinish: challenge
                                    ? () => context.pop()
                                    : cubit.backToIntro,
                              ),
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _confirmLeaveSheet(
    BuildContext context, {
    bool challenge = false,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LeaveQuizSheet(challenge: challenge),
    );
  }

  // ignore: unused_element
  Future<bool?> _confirmLeave(BuildContext context, {bool challenge = false}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari kuis?'),
        content: Text(
          challenge
              ? 'Jatah Tantangan hari ini sudah terpakai — bila keluar '
                    'sekarang, skormu tidak tercatat dan tidak bisa diulang '
                    'hari ini.'
              : 'Progres kuis saat ini tidak akan disimpan.',
        ),
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

/// Bar atas gelap: tombol kembali bulat + judul — gaya sama dengan halaman
/// belajar surah di Petualangan.
class _LeaveQuizSheet extends StatelessWidget {
  final bool challenge;

  const _LeaveQuizSheet({required this.challenge});

  @override
  Widget build(BuildContext context) {
    final warning = challenge
        ? 'Jatah Tantangan hari ini tetap terpakai. Skormu tidak tercatat dan '
              'kamu tidak bisa mengulang mode ini hari ini.'
        : 'Energi sudah dipakai saat sesi dimulai. Jika keluar sekarang, kamu '
              'tetap kehilangan 1 energi dan progres kuis ini tidak disimpan.';

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        decoration: BoxDecoration(
          color: const Color(0xFF102A3D),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: QuizColors.missingBright.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    color: QuizColors.missingBright,
                    size: 27,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Keluar dari kuis?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: QuizColors.missingBright.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: QuizColors.missingBright.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    challenge ? Icons.event_busy_rounded : kEnergyIcon,
                    color: QuizColors.missingBright,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      warning,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Lanjutkan kuis untuk menjaga energi dan peluang skormu.',
              style: TextStyle(color: Colors.white60, height: 1.35),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: QuizButton(
                    label: 'Lanjut Main',
                    icon: Icons.play_arrow_rounded,
                    color: QuizColors.goldDark,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: QuizButton(
                    label: 'Keluar',
                    icon: Icons.logout_rounded,
                    color: QuizColors.nightButton,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;

  const _TopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 4),
      child: Row(
        children: [
          Material(
            color: Colors.white.withValues(alpha: 0.12),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).maybePop(),
              child: const Padding(
                padding: EdgeInsets.all(9),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Loading menyiapkan sesi — halaman loading malam yang sama di seluruh Arena
/// (tanpa latar sendiri karena halaman kuis sudah bergradien malam).
class _QuizLoading extends StatelessWidget {
  const _QuizLoading();

  @override
  Widget build(BuildContext context) {
    return const NightLoadingPage(
      title: 'Menyiapkan soalmu…',
      subtitle: 'Sesi kuis segera dimulai',
      icon: Icons.videogame_asset_rounded,
      withBackground: false,
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
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: Colors.white54,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            QuizButton(
              label: 'Coba Lagi',
              icon: Icons.refresh_rounded,
              color: QuizColors.nightButton,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
