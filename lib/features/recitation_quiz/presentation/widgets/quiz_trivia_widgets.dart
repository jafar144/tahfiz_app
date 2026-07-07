import 'package:flutter/material.dart';

import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_haptics.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_widgets.dart';

/// Widget bersama untuk soal trivia surah (nama+arti / urutan / jumlah ayat) —
/// dipakai Soal Bonus mode suara & Soal Bonus mode pilihan. Bernuansa emas
/// (gold) agar terasa sebagai soal spesial/bonus.

/// Kartu pertanyaan trivia: teks soal + (opsional) petunjuk & chip poin.
class TriviaQuestionCard extends StatelessWidget {
  final String text;

  /// Poin bila benar; null → chip poin disembunyikan.
  final int? points;

  /// Petunjuk tambahan (mis. surah acuan pada soal urutan); null → disembunyikan.
  final String? hint;

  const TriviaQuestionCard({
    super.key,
    required this.text,
    this.points,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            QuizColors.gold.withValues(alpha: 0.16),
            QuizColors.gold.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: QuizColors.gold.withValues(alpha: 0.45)),
      ),
      child: Column(
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              height: 1.4,
              color: Color(0xFF3A2A05),
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: QuizColors.gold.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lightbulb_rounded,
                    size: 15,
                    color: QuizColors.goldDark,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Petunjuk: $hint',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: QuizColors.goldDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (points != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
              decoration: BoxDecoration(
                color: QuizColors.gold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 15,
                    color: QuizColors.goldDark,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '+$points poin',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: QuizColors.goldDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bagian jawaban bertajuk (mis. "Nama Surah") berisi chip-chip pilihan, dibalut
/// kartu lembut. Saat [lockedCorrect] non-null, HANYA chip terpilih yang
/// diwarnai benar/salah — jawaban benar tidak dibocorkan.
class TriviaSection extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final List<String> options;

  /// Indeks opsi terpilih; null bila belum memilih.
  final int? picked;

  /// null = belum terkunci; true/false = kebenaran pilihan saat terkunci.
  final bool? lockedCorrect;

  final ValueChanged<int>? onPick;

  const TriviaSection({
    super.key,
    this.label,
    this.icon,
    required this.options,
    required this.picked,
    this.lockedCorrect,
    this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            children: [
              Icon(
                icon ?? Icons.label_important_rounded,
                size: 15,
                color: QuizColors.goldDark,
              ),
              const SizedBox(width: 6),
              Text(
                label!.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                  color: QuizColors.goldDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(options.length, (i) {
            final selected = picked == i;
            return TriviaChip(
              label: options[i],
              selected: selected,
              lockedCorrect: selected ? lockedCorrect : null,
              onTap: onPick == null
                  ? null
                  : () {
                      QuizHaptics.select();
                      onPick!(i);
                    },
            );
          }),
        ),
      ],
    );

    if (label == null) return content;
    // Bertajuk → dibalut kartu lembut agar rapi & terpisah jelas.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: QuizColors.gold.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: QuizColors.gold.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: content,
    );
  }
}

/// Chip opsi jawaban trivia (nama surah / arti surah). Terpilih → isian emas.
class TriviaChip extends StatelessWidget {
  final String label;
  final bool selected;

  /// null = tak terkunci; true = terpilih & benar; false = terpilih & salah.
  final bool? lockedCorrect;
  final VoidCallback? onTap;

  const TriviaChip({
    super.key,
    required this.label,
    required this.selected,
    this.lockedCorrect,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color border;
    Color bg;
    Color fg;
    Gradient? gradient;
    if (lockedCorrect == true) {
      border = QuizColors.correct;
      bg = QuizColors.correct;
      fg = Colors.white;
      gradient = null;
    } else if (lockedCorrect == false) {
      border = QuizColors.missing;
      bg = QuizColors.missing;
      fg = Colors.white;
      gradient = null;
    } else if (selected) {
      border = QuizColors.goldDark;
      bg = QuizColors.gold;
      fg = Colors.white;
      gradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [QuizColors.gold, QuizColors.goldDark],
      );
    } else {
      border = QuizColors.gold.withValues(alpha: 0.4);
      bg = const Color(0xFFFFFBF2);
      fg = const Color(0xFF5A4207);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
        decoration: BoxDecoration(
          color: gradient == null ? bg : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: border,
            width: (selected || lockedCorrect != null) ? 1.6 : 1.2,
          ),
          boxShadow: (selected || lockedCorrect != null)
              ? [
                  BoxShadow(
                    color: bg.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: fg,
          ),
        ),
      ),
    );
  }
}

/// Deretan opsi ANGKA (nomor urut / jumlah ayat) sebagai kotak-kotak ringkas.
class TriviaNumberOptions extends StatelessWidget {
  final List<String> options;
  final int? picked;

  /// null = belum terkunci; kebenaran pilihan saat terkunci.
  final bool? lockedCorrect;
  final ValueChanged<int>? onPick;

  const TriviaNumberOptions({
    super.key,
    required this.options,
    required this.picked,
    this.lockedCorrect,
    this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: List.generate(options.length, (i) {
        final selected = picked == i;
        return _NumberBox(
          label: options[i],
          selected: selected,
          lockedCorrect: selected ? lockedCorrect : null,
          onTap: onPick == null
              ? null
              : () {
                  QuizHaptics.select();
                  onPick!(i);
                },
        );
      }),
    );
  }
}

class _NumberBox extends StatelessWidget {
  final String label;
  final bool selected;
  final bool? lockedCorrect;
  final VoidCallback? onTap;

  const _NumberBox({
    required this.label,
    required this.selected,
    required this.lockedCorrect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color border;
    Color fg;
    Gradient? gradient;
    Color bg;
    if (lockedCorrect == true) {
      border = QuizColors.correct;
      bg = QuizColors.correct;
      fg = Colors.white;
      gradient = null;
    } else if (lockedCorrect == false) {
      border = QuizColors.missing;
      bg = QuizColors.missing;
      fg = Colors.white;
      gradient = null;
    } else if (selected) {
      border = QuizColors.goldDark;
      bg = QuizColors.gold;
      fg = Colors.white;
      gradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [QuizColors.gold, QuizColors.goldDark],
      );
    } else {
      border = QuizColors.gold.withValues(alpha: 0.45);
      bg = const Color(0xFFFFFBF2);
      fg = const Color(0xFF5A4207);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: 72,
        height: 62,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: gradient == null ? bg : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: border,
            width: (selected || lockedCorrect != null) ? 1.8 : 1.3,
          ),
          boxShadow: (selected || lockedCorrect != null)
              ? [
                  BoxShadow(
                    color: bg.withValues(alpha: 0.35),
                    blurRadius: 9,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: fg,
          ),
        ),
      ),
    );
  }
}
