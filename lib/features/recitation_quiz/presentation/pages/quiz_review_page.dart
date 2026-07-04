import 'package:flutter/material.dart';

import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_mode.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_review.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_widgets.dart';

/// Layar REVIEW pasca-sesi: menampilkan tiap soal, jawaban santri, dan jawaban
/// benar (saat salah). Data hanya dari memori sesi — tidak diambil dari server.
class QuizReviewPage extends StatelessWidget {
  final List<QuizReviewItem> items;
  final QuizMode mode;

  const QuizReviewPage({super.key, required this.items, required this.mode});

  @override
  Widget build(BuildContext context) {
    final benar = items.where((e) => e.correct).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Soal'),
        centerTitle: true,
      ),
      body: items.isEmpty
          ? const Center(
              child: Text('Belum ada soal untuk ditinjau.',
                  style: TextStyle(color: Colors.black54)),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              itemCount: items.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '$benar benar dari ${items.length} soal',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54),
                    ),
                  );
                }
                return _ReviewCard(number: i, item: items[i - 1]);
              },
            ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final int number;
  final QuizReviewItem item;

  const _ReviewCard({required this.number, required this.item});

  @override
  Widget build(BuildContext context) {
    final color = item.correct ? QuizColors.correct : QuizColors.missing;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: nomor soal + status benar/salah.
          Row(
            children: [
              Text('Soal $number',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                        item.correct
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        size: 15,
                        color: color),
                    const SizedBox(width: 4),
                    Text(item.correct ? 'Benar' : 'Salah',
                        style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(width: 6),
                    Text('${item.score}',
                        style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(item.question,
              style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87)),
          if (item.promptArabic != null) ...[
            const SizedBox(height: 10),
            _arabic(item.promptArabic!, const Color(0xFF212121), 20),
          ],
          const SizedBox(height: 12),
          _answerBlock('Jawabanmu', item.yourAnswer, item.yourAnswerArabic,
              item.correct ? QuizColors.correct : QuizColors.missing),
          if (!item.correct) ...[
            const SizedBox(height: 8),
            _answerBlock('Jawaban benar', item.correctAnswer,
                item.correctAnswerArabic, QuizColors.correct),
          ],
        ],
      ),
    );
  }

  Widget _answerBlock(String label, String value, bool arabic, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: color)),
          const SizedBox(height: 5),
          arabic
              ? _arabic(value, const Color(0xFF212121), 19)
              : Text(value,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _arabic(String text, Color color, double size) {
    return Text(
      text,
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      style: TextStyle(
        fontFamily: 'QuranHafs',
        fontSize: size,
        height: 1.9,
        color: color,
      ),
    );
  }
}
