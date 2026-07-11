import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/vocab_match_question.dart';
import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/vocab_match_board.dart';

void main() {
  final question = VocabMatchQuestion(
    pairs: const [
      VocabMatchPair(arabic: 'أ', meaning: 'satu'),
      VocabMatchPair(arabic: 'ب', meaning: 'dua'),
    ],
  );

  Widget subject() => MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: VocabMatchBoard(question: question, onCompleted: _ignoreResult),
      ),
    ),
  );

  testWidgets('pasangan bisa dibatalkan dan nomor ikut hilang', (tester) async {
    await tester.pumpWidget(subject());

    await tester.tap(find.text('أ'));
    await tester.pump();
    await tester.tap(find.text('satu'));
    await tester.pump();

    expect(find.text('1'), findsNWidgets(2));

    await tester.tap(find.text('أ'));
    await tester.pump();

    expect(find.text('1'), findsNothing);
  });

  testWidgets('tombol Periksa berada di luar panel soal', (tester) async {
    await tester.pumpWidget(subject());

    final panel = find.byKey(const ValueKey('vocab-match-panel'));
    final button = find.byKey(const ValueKey('vocab-match-check-button'));
    expect(panel, findsOneWidget);
    expect(button, findsOneWidget);
    expect(find.descendant(of: panel, matching: button), findsNothing);
  });

  testWidgets('tombol Periksa dapat dipasang di dasar layar', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VocabMatchBoard(
            question: question,
            pinCheckButton: true,
            onCompleted: _ignoreResult,
          ),
        ),
      ),
    );

    final button = find.byKey(const ValueKey('vocab-match-check-button'));
    expect(tester.getBottomRight(button).dy, closeTo(640, 1));
    expect(tester.takeException(), isNull);
  });
}

void _ignoreResult(bool _) {}
