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
      answers: answers, questionCount: count, mode: QuizMode.voice);
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
  testWidgets('Rekap suara: koreografi skor+bonus berjalan tanpa error (overcharge)',
      (tester) async {
    // reading 95 + bonus 35 = total 130 (>100 → memicu kilau overcharge).
    await tester.pumpWidget(_wrap(_voiceResult(reading: 95, bonus: 35)));

    // Melangkah menembus seluruh lini masa koreografi.
    for (final ms in [0, 500, 1000, 1650, 2150, 2450, 3150, 3400]) {
      await tester.pump(Duration(milliseconds: ms));
    }

    // Angka total akhir tampil (130 poin) & rincian muncul.
    expect(find.text('130'), findsWidgets);
    expect(find.text('Bacaan'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Rekap suara tanpa bonus: hanya cincin terisi, tanpa rincian',
      (tester) async {
    await tester.pumpWidget(_wrap(_voiceResult(reading: 88, bonus: 0)));
    for (final ms in [0, 500, 1000, 1400, 1600]) {
      await tester.pump(Duration(milliseconds: ms));
    }
    // Tanpa bonus tidak ada baris rincian "Bacaan/Bonus/Total".
    expect(find.text('Bonus'), findsNothing);
    expect(find.text('88'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
