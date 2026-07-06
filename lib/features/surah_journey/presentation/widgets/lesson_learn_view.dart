import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:khoirunnasyien/features/recitation_check/domain/entities/ayah.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_widgets.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/entities/surah_lesson.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/lesson_config.dart';
import 'package:khoirunnasyien/features/surah_journey/presentation/cubit/surah_lesson_cubit.dart';
import 'package:khoirunnasyien/features/surah_journey/presentation/cubit/surah_lesson_state.dart';

/// Halaman BELAJAR satu surah: kartu materi yang digeser seperti pelajaran
/// Duolingo — pengenalan → baca surah → asbabun nuzul → fakta menarik → ujian.
class LessonLearnView extends StatefulWidget {
  const LessonLearnView({super.key});

  @override
  State<LessonLearnView> createState() => _LessonLearnViewState();
}

class _LessonLearnViewState extends State<LessonLearnView> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SurahLessonCubit>();

    return BlocBuilder<SurahLessonCubit, SurahLessonState>(
      builder: (context, state) {
        final lesson = state.lesson;
        final pages = <Widget>[
          _CoverPage(lesson: lesson),
          _AyatPage(lesson: lesson, ayat: state.surahAyat),
          if (lesson.asbabunNuzul != null)
            _StoryPage(text: lesson.asbabunNuzul!),
          _FactsPage(facts: lesson.facts),
        ];
        final isLast = _page >= pages.length - 1;

        return SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _page = i),
                  children: pages,
                ),
              ),
              // Navigasi bawah: titik progres + tombol lanjut / mulai ujian.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < pages.length; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3.5),
                            width: i == _page ? 22 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: i == _page
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.black12,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: isLast
                          ? FilledButton.icon(
                              onPressed: cubit.startTest,
                              style: FilledButton.styleFrom(
                                backgroundColor: QuizColors.goldDark,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: const Icon(Icons.rocket_launch_rounded),
                              label: Text(
                                'Mulai Ujian • ${LessonConfig.questionCount} Soal',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : FilledButton(
                              onPressed: () => _controller.nextPage(
                                duration: const Duration(milliseconds: 320),
                                curve: Curves.easeOutCubic,
                              ),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Lanjut',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────── Halaman 1: Pengenalan ──

class _CoverPage extends StatelessWidget {
  final SurahLesson lesson;

  const _CoverPage({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Column(
        children: [
          // Badge nama Arab dalam lingkaran gradasi.
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [scheme.primary, scheme.primary.withValues(alpha: 0.7)],
              ),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.35),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text(
                lesson.nameArabic,
                style: const TextStyle(
                  fontFamily: 'QuranHafs',
                  fontSize: 34,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Surah ${lesson.nameLatin}',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            '"${lesson.meaning}"',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          // Chip info ringkas.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _infoChip(Icons.bookmark_rounded, 'Surah ke-${lesson.surahId}'),
              _infoChip(
                Icons.format_list_numbered_rounded,
                '${lesson.ayahCount} ayat',
              ),
              _infoChip(Icons.mosque_rounded, lesson.place),
              _infoChip(Icons.auto_stories_rounded, 'Juz 30'),
            ],
          ),
          const SizedBox(height: 20),
          _SectionCard(
            icon: Icons.waving_hand_rounded,
            title: 'Kenalan Dulu, Yuk!',
            color: Theme.of(context).colorScheme.primary,
            child: Text(
              lesson.intro,
              style: const TextStyle(fontSize: 14.5, height: 1.65),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: QuizColors.goldDark),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────── Halaman 2: Baca surah ──

class _AyatPage extends StatelessWidget {
  final SurahLesson lesson;
  final List<Ayah> ayat;

  const _AyatPage({required this.lesson, required this.ayat});

  @override
  Widget build(BuildContext context) {
    if (ayat.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      children: [
        const _PageHeading(
          icon: Icons.menu_book_rounded,
          title: 'Baca Surahnya Dulu',
          subtitle: 'Baca pelan-pelan sambil diingat urutan ayatnya, ya!',
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBF2),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: QuizColors.gold.withValues(alpha: 0.35)),
          ),
          child: Column(
            children: [
              for (final a in ayat)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Text(
                    a.text,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontFamily: 'QuranHafs',
                      fontSize: 21,
                      height: 1.9,
                      color: Color(0xFF212121),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────── Halaman 3: Asbabun nuzul ──

class _StoryPage extends StatelessWidget {
  final String text;

  const _StoryPage({required this.text});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Column(
        children: [
          const _PageHeading(
            icon: Icons.history_edu_rounded,
            title: 'Kisah di Balik Surah',
            subtitle: 'Simak baik-baik — nanti keluar di ujian, lho!',
          ),
          const SizedBox(height: 14),
          _SectionCard(
            icon: Icons.auto_awesome_rounded,
            title: 'Asbabun Nuzul & Kisahnya',
            color: QuizColors.goldDark,
            child: Text(
              text,
              style: const TextStyle(fontSize: 14.5, height: 1.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────── Halaman 4: Fakta menarik ──

class _FactsPage extends StatelessWidget {
  final List<String> facts;

  const _FactsPage({required this.facts});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      children: [
        const _PageHeading(
          icon: Icons.lightbulb_rounded,
          title: 'Fakta Menariknya',
          subtitle: 'Ingat-ingat fakta ini untuk menjawab soal pilihan!',
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < facts.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.primary.withValues(alpha: 0.1),
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: scheme.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    facts[i],
                    style: const TextStyle(fontSize: 13.5, height: 1.6),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────── Widget bantu ──

class _PageHeading extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PageHeading({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, size: 34, color: scheme.primary),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12.5, color: Colors.black54),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
