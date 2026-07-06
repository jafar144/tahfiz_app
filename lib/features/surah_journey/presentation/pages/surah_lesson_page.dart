import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:khoirunnasyien/features/surah_journey/presentation/cubit/surah_lesson_cubit.dart';
import 'package:khoirunnasyien/features/surah_journey/presentation/cubit/surah_lesson_state.dart';
import 'package:khoirunnasyien/features/surah_journey/presentation/widgets/lesson_learn_view.dart';
import 'package:khoirunnasyien/features/surah_journey/presentation/widgets/lesson_result_view.dart';
import 'package:khoirunnasyien/features/surah_journey/presentation/widgets/lesson_test_view.dart';

/// Halaman sesi satu surah: belajar → ujian → hasil, dengan transisi geser
/// horizontal berarah (maju = masuk dari kanan; mundur = masuk dari kiri).
class SurahLessonPage extends StatefulWidget {
  const SurahLessonPage({super.key});

  @override
  State<SurahLessonPage> createState() => _SurahLessonPageState();
}

class _SurahLessonPageState extends State<SurahLessonPage> {
  /// Urutan alur layar untuk menentukan arah transisi.
  static const _order = {
    LessonStatus.learning: 0,
    LessonStatus.loading: 1,
    LessonStatus.testing: 2,
    LessonStatus.finished: 3,
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
          ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      },
      builder: (context, state) {
        final status = state.status;
        if (_prevStatus != null && _prevStatus != status) {
          _advancing = (_order[status] ?? 0) >= (_order[_prevStatus] ?? 0);
        }
        _prevStatus = status;

        final testing = status == LessonStatus.testing;

        return PopScope(
          // Saat ujian, back harus lewat konfirmasi (progres ujian hangus).
          canPop: !testing,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            final leave = await _confirmLeave(context);
            if (leave == true && context.mounted) {
              context.read<SurahLessonCubit>().backToLearning();
            }
          },
          child: Scaffold(
            // Sembunyikan AppBar saat ujian agar layar lebih fokus.
            appBar: testing
                ? null
                : AppBar(
                    title: Text(
                      status == LessonStatus.finished
                          ? 'Hasil Ujian'
                          : 'Surah ${state.lesson.nameLatin}',
                    ),
                    centerTitle: true,
                  ),
            body: ClipRect(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 380),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final incoming = child.key == ValueKey(status);
                  final Offset begin = _advancing
                      ? (incoming ? const Offset(1, 0) : const Offset(-1, 0))
                      : (incoming ? const Offset(-1, 0) : const Offset(1, 0));
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: begin,
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  );
                },
                layoutBuilder: (currentChild, previousChildren) => Stack(
                  children: [
                    for (final c in previousChildren) Positioned.fill(child: c),
                    if (currentChild != null)
                      Positioned.fill(child: currentChild),
                  ],
                ),
                child: KeyedSubtree(
                  key: ValueKey(status),
                  child: switch (status) {
                    LessonStatus.learning => const LessonLearnView(),
                    LessonStatus.loading => const _Loading(),
                    LessonStatus.testing => const LessonTestView(),
                    LessonStatus.finished => const LessonResultView(),
                  },
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
        title: const Text('Keluar dari ujian?'),
        content: const Text('Progres ujian saat ini tidak akan disimpan.'),
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

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Menyiapkan ujian…', style: TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}
