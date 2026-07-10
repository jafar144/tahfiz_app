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
    QuizStatus.finished: 3,
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

        return PopScope(
          // Latihan: hanya layar intro yang boleh langsung keluar; layar lain
          // kembali ke intro. Tantangan: tanpa intro — back keluar halaman
          // (saat bermain dikonfirmasi dulu).
          canPop: challenge ? !playing : atIntro,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            if (state.status == QuizStatus.playing) {
              final leave = await _confirmLeave(context, challenge: challenge);
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
                    // Bar atas disembunyikan saat bermain agar layar lega.
                    if (!playing)
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
                          layoutBuilder: (currentChild, previousChildren) =>
                              Stack(
                                children: [
                                  for (final c in previousChildren)
                                    Positioned.fill(child: c),
                                  if (currentChild != null)
                                    Positioned.fill(child: currentChild),
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
