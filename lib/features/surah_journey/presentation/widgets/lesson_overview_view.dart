import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_widgets.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/entities/lesson_section.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/entities/lesson_question.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/lesson_config.dart';
import 'package:khoirunnasyien/features/surah_journey/domain/vocab_learning_rules.dart';
import 'package:khoirunnasyien/features/surah_journey/presentation/cubit/surah_lesson_cubit.dart';
import 'package:khoirunnasyien/features/surah_journey/presentation/cubit/surah_lesson_state.dart';
import 'package:khoirunnasyien/features/surah_journey/presentation/widgets/journey_style.dart';

/// Daftar BAGIAN sebuah surah (peta kecil di dalam surah): kartu per bagian
/// dengan status terkunci/terbuka/lulus, ditutup kartu UJIAN AKHIR.
class LessonOverviewView extends StatefulWidget {
  const LessonOverviewView({super.key});

  @override
  State<LessonOverviewView> createState() => _LessonOverviewViewState();
}

class _LessonOverviewViewState extends State<LessonOverviewView> {
  String? _expandedSectionId;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SurahLessonCubit>();

    return BlocBuilder<SurahLessonCubit, SurahLessonState>(
      builder: (context, state) {
        final lesson = state.lesson;
        final sections = lesson.sections;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            // ── Kepala surah ─────────────────────────────────────────────
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [QuizColors.gold, QuizColors.goldDark],
                ),
                boxShadow: [
                  BoxShadow(
                    color: QuizColors.gold.withValues(alpha: 0.4),
                    blurRadius: 22,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  lesson.nameArabic,
                  style: const TextStyle(
                    fontFamily: 'QuranHafs',
                    fontSize: 24,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Surah ${lesson.nameLatin}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '"${lesson.meaning}"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: QuizColors.gold,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              alignment: WrapAlignment.center,
              children: [
                _infoChip(Icons.bookmark_rounded, 'Surah ke-${lesson.surahId}'),
                _infoChip(
                  Icons.format_list_numbered_rounded,
                  '${lesson.ayahCount} ayat',
                ),
                _infoChip(Icons.mosque_rounded, lesson.place),
              ],
            ),
            const SizedBox(height: 20),

            // ── Kartu bagian ─────────────────────────────────────────────
            for (var i = 0; i < sections.length; i++) ...[
              Builder(
                builder: (context) {
                  final section = sections[i];
                  final isVocab = section.test.useVocabQuestions;
                  final expanded = _expandedSectionId == section.id;
                  return Column(
                    children: [
                      _SectionCard(
                        index: i + 1,
                        section: section,
                        state: state,
                        expanded: expanded,
                        onTap: () {
                          if (isVocab) {
                            setState(
                              () => _expandedSectionId = expanded
                                  ? null
                                  : section.id,
                            );
                          } else {
                            cubit.openSection(section);
                          }
                        },
                      ),
                      if (isVocab && expanded)
                        _VocabStages(
                          section: section,
                          state: state,
                          onLearn: () => cubit.openSection(section),
                          onQuiz: (phase) =>
                              cubit.startVocabQuiz(section, phase),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 10),
            ],

            // ── Kartu ujian akhir ────────────────────────────────────────
            const SizedBox(height: 4),
            _ExamCard(state: state, onTap: cubit.startExam),
          ],
        );
      },
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: QuizColors.gold),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu satu bagian: nomor/status di kiri, judul + subjudul, status kanan.
class _SectionCard extends StatelessWidget {
  final int index;
  final LessonSection section;
  final SurahLessonState state;
  final bool expanded;
  final VoidCallback onTap;

  const _SectionCard({
    required this.index,
    required this.section,
    required this.state,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = state.progress.of(section.id);
    final unlocked = state.sectionUnlocked(section);
    final passed = progress.passed;
    final questionCount = LessonConfig.sectionQuestionCount(section.test);
    final vocabCompleted = state.vocabCompletedCount(section);

    final Color accent = passed
        ? const Color(0xFF34D399)
        : unlocked
        ? QuizColors.gold
        : Colors.white24;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: unlocked ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: journeyCardDecoration(
            borderColor: unlocked
                ? accent.withValues(alpha: 0.45)
                : JourneyColors.cardBorder,
          ),
          child: Row(
            children: [
              // Lencana nomor / centang / gembok.
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: unlocked ? 0.18 : 0.08),
                  border: Border.all(
                    color: accent.withValues(alpha: unlocked ? 0.7 : 0.3),
                    width: 1.6,
                  ),
                ),
                child: Center(
                  child: passed
                      ? const Icon(
                          Icons.check_rounded,
                          color: Color(0xFF34D399),
                          size: 24,
                        )
                      : unlocked
                      ? Text(
                          '$index',
                          style: const TextStyle(
                            color: QuizColors.gold,
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                          ),
                        )
                      : const Icon(
                          Icons.lock_rounded,
                          color: Colors.white38,
                          size: 20,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            section.title,
                            style: TextStyle(
                              color: unlocked ? Colors.white : Colors.white38,
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                            ),
                          ),
                        ),
                        if (section.test.useVocabQuestions) ...[
                          const SizedBox(width: 7),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: QuizColors.gold.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: QuizColors.gold.withValues(alpha: 0.4),
                              ),
                            ),
                            child: const Text(
                              '3 FASE',
                              style: TextStyle(
                                color: QuizColors.gold,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      passed
                          ? section.test.useVocabQuestions
                                ? 'Lulus • Semua kuis kosa kata selesai'
                                : 'Lulus • Terbaik ${progress.bestCorrect}/'
                                      '$questionCount benar'
                          : section.test.useVocabQuestions
                          ? '$vocabCompleted dari 3 kuis selesai • '
                                '${section.vocabItems.length} kata penting'
                          : section.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: passed
                            ? const Color(0xFF34D399)
                            : unlocked
                            ? Colors.white54
                            : Colors.white24,
                        fontSize: 11.5,
                        fontWeight: passed ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (unlocked && !passed && !section.test.useVocabQuestions)
                const EnergyCostChip(),
              if (unlocked)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Icon(
                    section.test.useVocabQuestions
                        ? (expanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded)
                        : Icons.chevron_right_rounded,
                    color: Colors.white54,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VocabStages extends StatelessWidget {
  final LessonSection section;
  final SurahLessonState state;
  final VoidCallback onLearn;
  final ValueChanged<VocabLearningPhase> onQuiz;

  const _VocabStages({
    required this.section,
    required this.state,
    required this.onLearn,
    required this.onQuiz,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 2),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: QuizColors.gold.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          _VocabStageTile(
            number: 1,
            title: 'Belajar Kosa Kata',
            subtitle: '${section.vocabItems.length} kata beserta contoh ayat',
            icon: Icons.menu_book_rounded,
            unlocked: true,
            passed: false,
            onTap: onLearn,
          ),
          for (final phase in VocabLearningPhase.values) ...[
            const SizedBox(height: 7),
            _VocabStageTile(
              number: phase.number + 1,
              title: 'Kuis ${phase.number}',
              subtitle:
                  '${phase.title} • '
                  '${VocabLearningRules.questionCountFor(phase)} soal',
              icon: switch (phase) {
                VocabLearningPhase.arabicToMeaning => Icons.translate_rounded,
                VocabLearningPhase.mixedPractice => Icons.hub_rounded,
                VocabLearningPhase.meaningRecall =>
                  Icons.record_voice_over_rounded,
              },
              unlocked:
                  phase.index == 0 ||
                  state.vocabPhasePassed(
                    section,
                    VocabLearningPhase.values[phase.index - 1],
                  ),
              passed: state.vocabPhasePassed(section, phase),
              onTap: () => onQuiz(phase),
            ),
          ],
        ],
      ),
    );
  }
}

class _VocabStageTile extends StatelessWidget {
  final int number;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool unlocked;
  final bool passed;
  final VoidCallback onTap;

  const _VocabStageTile({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.unlocked,
    required this.passed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = passed
        ? const Color(0xFF34D399)
        : unlocked
        ? QuizColors.gold
        : Colors.white24;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: unlocked ? onTap : null,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: unlocked ? 0.09 : 0.035),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: color.withValues(alpha: 0.24)),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.14),
                ),
                child: Icon(
                  passed
                      ? Icons.check_rounded
                      : unlocked
                      ? icon
                      : Icons.lock_rounded,
                  size: 18,
                  color: color,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$number. $title',
                      style: TextStyle(
                        color: unlocked ? Colors.white : Colors.white30,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      passed ? 'Selesai' : subtitle,
                      style: TextStyle(
                        color: passed
                            ? const Color(0xFF34D399)
                            : unlocked
                            ? Colors.white54
                            : Colors.white24,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (unlocked && !passed && number > 1) const EnergyCostChip(),
              if (unlocked)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white38,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kartu UJIAN AKHIR surah — terkunci sampai semua bagian lulus.
class _ExamCard extends StatelessWidget {
  final SurahLessonState state;
  final VoidCallback onTap;

  const _ExamCard({required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final unlocked = state.examUnlocked;
    final passed = state.progress.examPassed;
    final best = state.progress.examBestScore;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: unlocked ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: unlocked
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      QuizColors.gold.withValues(alpha: 0.20),
                      QuizColors.gold.withValues(alpha: 0.06),
                    ],
                  )
                : null,
            color: unlocked ? null : JourneyColors.card.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: unlocked
                  ? QuizColors.gold.withValues(alpha: 0.6)
                  : JourneyColors.cardBorder,
              width: unlocked ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: unlocked
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [QuizColors.gold, QuizColors.goldDark],
                        )
                      : null,
                  color: unlocked ? null : Colors.white.withValues(alpha: 0.06),
                  border: unlocked ? null : Border.all(color: Colors.white24),
                ),
                child: Icon(
                  passed
                      ? Icons.emoji_events_rounded
                      : unlocked
                      ? Icons.rocket_launch_rounded
                      : Icons.lock_rounded,
                  color: unlocked ? Colors.white : Colors.white38,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ujian Akhir',
                      style: TextStyle(
                        color: unlocked ? Colors.white : Colors.white38,
                        fontWeight: FontWeight.w900,
                        fontSize: 15.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      passed
                          ? 'Lulus • Nilai terbaik $best'
                          : unlocked
                          ? '${LessonConfig.examQuestionCount} soal campuran '
                                'dari semua bagian'
                          : 'Lulusi semua bagian untuk membukanya',
                      style: TextStyle(
                        color: passed
                            ? const Color(0xFF34D399)
                            : unlocked
                            ? Colors.white60
                            : Colors.white24,
                        fontSize: 11.5,
                        fontWeight: passed ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (unlocked && !passed) const EnergyCostChip(),
              if (unlocked)
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white70,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
