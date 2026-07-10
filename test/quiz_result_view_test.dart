import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_mode.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_result.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_result_view.dart';

/// Menyusun hasil mode SUARA: [reading] rata-rata akurasi & [bonus] total poin
/// bonus. Skor tiap soal dibuat rata agar rata-ratanya = reading.
QuizResult _voiceResult({required int reading, required int bonus}) {
  const count = 10;
  final answers = <QuizAnswer>[
    for (var i = 0; i < count; i++)
      QuizAnswer(
        questionIndex: i,
        score: reading,
        attempts: 1,
        passed: reading >= 80,
        bonusScore: i == 0 ? bonus : 0, // seluruh bonus di soal pertama
      ),
  ];
  return QuizResult(
    answers: answers,
    questionCount: count,
    mode: QuizMode.voice,
  );
}

QuizResult _choiceResult({required List<int> scores, int bonus = 0}) {
  final answers = <QuizAnswer>[
    for (var i = 0; i < scores.length; i++)
      QuizAnswer(
        questionIndex: i,
        score: scores[i],
        attempts: 1,
        passed: scores[i] > 0,
        bonusScore: i == 0 ? bonus : 0,
      ),
  ];
  return QuizResult(
    answers: answers,
    questionCount: answers.length,
    mode: QuizMode.choice,
  );
}

Widget _wrap(QuizResult result) => MaterialApp(
  home: Scaffold(
    body: QuizResultView(
      result: result,
      saving: false,
      saveError: null,
      onPlayAgain: () {},
      onFinish: () {},
    ),
  ),
);

void main() {
  testWidgets('Rekap suara: tiga tower skor menghitung poin, bonus, dan XP', (
    tester,
  ) async {
    final result = _voiceResult(reading: 95, bonus: 35);
    expect(result.earnedXp, 26); // ((95 + 35) * 2 / 10).round()
    await tester.pumpWidget(_wrap(result));

    // Melangkah menembus seluruh lini masa koreografi tower.
    for (final ms in [0, 700, 1400, 2200, 3000, 4200]) {
      await tester.pump(Duration(milliseconds: ms));
    }

    expect(find.text('TOTAL POIN'), findsOneWidget);
    expect(find.text('TOTAL BONUS'), findsOneWidget);
    expect(find.text('XP DIDAPAT'), findsOneWidget);
    expect(find.text('95'), findsWidgets);
    expect(find.text('35'), findsWidgets);
    expect(find.text('26'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Rekap pilihan: tower yang sama tampil dengan pengali XP x1', (
    tester,
  ) async {
    final result = _choiceResult(scores: [20, 20, 15, 15, 10, 0], bonus: 6);
    expect(result.totalPoints, 80);
    expect(result.totalBonus, 6);
    expect(result.earnedXp, 9); // ((80 + 6) * 1 / 10).round()
    await tester.pumpWidget(_wrap(result));

    for (final ms in [0, 700, 1400, 2200, 3000, 4200]) {
      await tester.pump(Duration(milliseconds: ms));
    }

    expect(find.text('Pilihan • XP x1'), findsOneWidget);
    expect(find.text('TOTAL POIN'), findsOneWidget);
    expect(find.text('TOTAL BONUS'), findsOneWidget);
    expect(find.text('XP DIDAPAT'), findsOneWidget);
    expect(find.text('80'), findsWidgets);
    expect(find.text('6'), findsWidgets);
    expect(find.text('9'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
