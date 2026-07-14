import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:khoirunnasyien/features/recitation_check/domain/entities/ayah.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_widgets.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/entities/lesson_section.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/lesson_config.dart';
import 'package:khoirunnasyien/features/surah_journey/presentation/cubit/surah_lesson_cubit.dart';
import 'package:khoirunnasyien/features/surah_journey/presentation/cubit/surah_lesson_state.dart';
import 'package:khoirunnasyien/features/surah_journey/presentation/widgets/journey_style.dart';

/// Halaman BELAJAR satu bagian surah: blok-blok konten modular digeser
/// seperti pelajaran Duolingo, ditutup tombol mulai test bagian tersebut.
///
/// Menambah jenis blok baru: tambahkan subclass di `lesson_section.dart`
/// lalu petakan cara menggambarnya di [_blockPage].
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
        final section = state.activeSection;
        if (section == null) return const SizedBox.shrink();

        final pages = [
          for (final block in section.blocks)
            _blockPage(block, state.surahAyat),
        ];
        final isLast = _page >= pages.length - 1;
        final needEnergy = !state.progress.of(section.id).passed;
        final questionCount = LessonConfig.sectionQuestionCount(section.test);

        return Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: pages,
              ),
            ),
            // Navigasi bawah: titik progres + tombol lanjut / mulai test.
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
                                ? QuizColors.gold
                                : Colors.white24,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  isLast
                      ? JourneyPrimaryButton(
                          onPressed: cubit.startSectionTest,
                          icon: Icons.rocket_launch_rounded,
                          label: section.test.useVocabQuestions
                              ? 'Mulai 3 Fase • $questionCount Latihan'
                              : 'Mulai Test • $questionCount Soal',
                          showEnergyCost: needEnergy,
                        )
                      : JourneyPrimaryButton(
                          onPressed: () => _controller.nextPage(
                            duration: const Duration(milliseconds: 320),
                            curve: Curves.easeOutCubic,
                          ),
                          label: 'Lanjut',
                        ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Petakan satu blok konten → halaman geser.
  Widget _blockPage(LessonBlock block, List<Ayah> ayat) {
    return switch (block) {
      ParagraphBlock() => _ParagraphPage(block: block),
      FactListBlock() => _FactsPage(facts: block.facts),
      FullSurahBlock() => _FullSurahPage(ayat: ayat),
      VocabListBlock() => _VocabPage(items: block.items, ayat: ayat),
    };
  }
}

// ─────────────────────────────────────────────────────── Blok: paragraf ──

class _ParagraphPage extends StatelessWidget {
  final ParagraphBlock block;

  const _ParagraphPage({required this.block});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Column(
        children: [
          if (block.title != null) ...[
            const Icon(
              Icons.auto_awesome_rounded,
              size: 32,
              color: QuizColors.gold,
            ),
            const SizedBox(height: 8),
            Text(
              block.title!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
          ],
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: journeyCardDecoration(),
            child: Text(
              block.body,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                height: 1.7,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────── Blok: fakta ──

class _FactsPage extends StatelessWidget {
  final List<String> facts;

  const _FactsPage({required this.facts});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      children: [
        const Icon(Icons.lightbulb_rounded, size: 32, color: QuizColors.gold),
        const SizedBox(height: 8),
        const Text(
          'Fakta Menariknya',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Ingat-ingat fakta ini untuk menjawab soal, ya!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 12.5),
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < facts.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: journeyCardDecoration(radius: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: QuizColors.gold.withValues(alpha: 0.16),
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: QuizColors.gold,
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      height: 1.6,
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

// ─────────────────────────────────────────────────── Blok: surah lengkap ──

class _FullSurahPage extends StatelessWidget {
  final List<Ayah> ayat;

  const _FullSurahPage({required this.ayat});

  @override
  Widget build(BuildContext context) {
    if (ayat.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white70),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      children: [
        const Icon(Icons.menu_book_rounded, size: 32, color: QuizColors.gold),
        const SizedBox(height: 8),
        const Text(
          'Baca Surahnya',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
          decoration: journeyCardDecoration(
            borderColor: QuizColors.gold.withValues(alpha: 0.35),
          ),
          child: Column(
            children: [
              for (final a in ayat)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    a.text,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontFamily: 'QuranHafs',
                      fontSize: 21,
                      height: 1.9,
                      color: Colors.white,
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

// ─────────────────────────────────────────────────── Blok: kosa kata ──

class _VocabPage extends StatelessWidget {
  final List<VocabItem> items;
  final List<Ayah> ayat;

  const _VocabPage({required this.items, required this.ayat});

  @override
  Widget build(BuildContext context) {
    final textOf = {for (final a in ayat) a.number: a.text};

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      children: [
        const Icon(Icons.translate_rounded, size: 32, color: QuizColors.gold),
        const SizedBox(height: 8),
        const Text(
          'Kosa Kata Penting',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Perhatikan kata yang disorot beserta artinya, ya!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 12.5),
        ),
        const SizedBox(height: 14),
        for (final item in items)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: journeyCardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Ayat penuh dengan kata disorot.
                HighlightedAyahText(
                  text: textOf[item.ayahNumber] ?? item.word,
                  highlight: item.word,
                  fontSize: 20,
                ),
                const SizedBox(height: 10),
                Divider(height: 1, color: Colors.white.withValues(alpha: 0.1)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: QuizColors.gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.latin,
                        style: const TextStyle(
                          color: QuizColors.gold,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '= ${item.displayMeaning}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (item.note != null) ...[
                  const SizedBox(height: 7),
                  Text(
                    item.note!,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
