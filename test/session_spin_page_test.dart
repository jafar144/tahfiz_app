import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/halaqah.dart';
import 'package:khoirunnasyien/features/session_spin/data/session_spin_loader.dart';
import 'package:khoirunnasyien/features/session_spin/presentation/pages/session_spin_page.dart';

void main() {
  testWidgets('spin membentuk urutan unik lalu hasil dapat di-reset', (
    tester,
  ) async {
    final participants = [
      _santri('a', 'Ahmad'),
      _santri('b', 'Bilal'),
      _santri('c', 'Cakra'),
    ];
    final catalog = SessionSpinCatalog(
      teacherGender: 'L',
      halaqahs: [
        SessionSpinHalaqah(
          halaqah: _halaqah(),
          isOwn: true,
          participants: participants,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SessionSpinPage(
          teacherId: 'teacher',
          catalogLoader: (_) async => catalog,
          random: Random(7),
          spinDuration: Duration.zero,
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (var index = 0; index < participants.length; index++) {
      final spinButton = find.byKey(const ValueKey('spin-next-button'));
      await tester.ensureVisible(spinButton);
      await tester.pumpAndSettle();
      await tester.tap(spinButton);
      await tester.pumpAndSettle();
    }

    expect(find.text('Urutan Selesai'), findsOneWidget);
    for (final participant in participants) {
      expect(
        find.byKey(ValueKey('spin-result-${participant.id}')),
        findsOneWidget,
      );
    }

    final resetButton = find.byKey(const ValueKey('spin-reset-button'));
    await tester.ensureVisible(resetButton);
    await tester.pumpAndSettle();
    await tester.tap(resetButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset Hasil').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('spin-result-a')), findsNothing);
    expect(find.text('Spin Berikutnya'), findsOneWidget);
  });
}

Halaqah _halaqah() => const Halaqah(
  id: 'halaqah-a',
  programId: 'program-l',
  scheduleIds: [],
  name: 'Halaqah A',
  room: 'A',
  teacherId: 'teacher',
  teacherName: 'Ustadz',
  status: 'Active',
);

SantriEntity _santri(String id, String name) => SantriEntity(
  id: id,
  name: name,
  nis: id,
  kelas: 'Mutawassith',
  jenisKelamin: 'L',
  isActive: true,
  isFree: false,
);
