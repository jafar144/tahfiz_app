import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/night_loading_page.dart';
import 'package:khoirunnasyien/features/surah_journey/presentation/cubit/surah_lesson_cubit.dart';
import 'package:khoirunnasyien/features/surah_journey/presentation/cubit/surah_lesson_state.dart';
import 'package:khoirunnasyien/features/surah_journey/presentation/widgets/journey_style.dart';
import 'package:khoirunnasyien/features/surah_journey/presentation/widgets/lesson_learn_view.dart';
import 'package:khoirunnasyien/features/surah_journey/presentation/widgets/lesson_overview_view.dart';
import 'package:khoirunnasyien/features/surah_journey/presentation/widgets/lesson_result_view.dart';
import 'package:khoirunnasyien/features/surah_journey/presentation/widgets/lesson_test_view.dart';

/// Halaman sesi satu surah bergaya journey (malam islami): daftar bagian →
/// belajar per bagian → test → hasil, dengan transisi geser berarah.
class SurahLessonPage extends StatefulWidget {
  const SurahLessonPage({super.key});

  @override
  State<SurahLessonPage> createState() => _SurahLessonPageState();
}

class _SurahLessonPageState extends State<SurahLessonPage> {
  /// Urutan alur layar untuk menentukan arah transisi.
  static const _order = {
    LessonStatus.overview: 0,
    LessonStatus.learning: 1,
    LessonStatus.loading: 2,
    LessonStatus.testing: 3,
    LessonStatus.finished: 4,
  };

  LessonStatus? _prevStatus;
  bool _advancing = true;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SurahLessonCubit, SurahLessonState>(
      listenWhen: (p, c) =>
          c.errorMessage != null && p.errorMessage != c.errorMessage,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              behavior: SnackBarBehavior.floating,
            ),
          );
      },
      builder: (context, state) {
        final status = state.status;
        if (_prevStatus != null && _prevStatus != status) {
          _advancing = (_order[status] ?? 0) >= (_order[_prevStatus] ?? 0);
        }
        _prevStatus = status;

        final testing = status == LessonStatus.testing;
        final cubit = context.read<SurahLessonCubit>();

        // Data awal (ayat + progres) belum siap → halaman loading dedicated
        // yang sama dengan seluruh Tahfiz Arena, bukan konten yang "menyusun
        // diri" sepotong-sepotong.
        if (!state.initialized) {
          return Scaffold(
            body: NightLoadingPage(
              title: 'Membuka Surah ${state.lesson.nameLatin}…',
              subtitle: 'Memuat ayat & progres belajarmu',
              showBack: true,
              onBack: () => Navigator.of(context).maybePop(),
            ),
          );
        }

        return PopScope(
          // Hanya di daftar bagian back menutup halaman; layar lain kembali
          // selangkah (saat test lewat konfirmasi karena progres hangus).
          canPop: status == LessonStatus.overview,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            if (testing) {
              final leave = await _confirmLeave(context);
              if (leave != true || !context.mounted) return;
            }
            switch (status) {
              case LessonStatus.learning:
                cubit.backToOverview();
              case LessonStatus.testing || LessonStatus.finished:
                if (state.activeSection != null && testing) {
                  cubit.backToLearning();
                } else {
                  cubit.backToOverview();
                }
              case _:
                cubit.backToOverview();
            }
          },
          child: Scaffold(
            body: JourneyBackground(
              child: SafeArea(
                child: Column(
                  children: [
                    // Bar atas disembunyikan saat test agar layar fokus.
                    if (!testing) _TopBar(state: state),
                    Expanded(
                      child: ClipRect(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 380),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
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
                            child: switch (status) {
                              LessonStatus.overview =>
                                const LessonOverviewView(),
                              LessonStatus.learning => const LessonLearnView(),
                              LessonStatus.loading => const _Loading(),
                              LessonStatus.testing => const LessonTestView(),
                              LessonStatus.finished =>
                                const LessonResultView(),
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

  Future<bool?> _confirmLeave(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari test?'),
        content: const Text('Progres test saat ini tidak akan disimpan.'),
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

/// Bar atas gelap: tombol kembali + judul sesuai layar.
class _TopBar extends StatelessWidget {
  final SurahLessonState state;

  const _TopBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final title = switch (state.status) {
      LessonStatus.overview => 'Surah ${state.lesson.nameLatin}',
      LessonStatus.learning => state.activeSection?.title ?? '',
      LessonStatus.loading => 'Menyiapkan Test…',
      LessonStatus.finished =>
        state.isExam ? 'Hasil Ujian Akhir' : 'Hasil Test',
      _ => '',
    };

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

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const NightLoadingPage(
      title: 'Menyiapkan soal…',
      subtitle: 'Test-mu segera dimulai',
      icon: Icons.menu_book_rounded,
      withBackground: false,
    );
  }
}
