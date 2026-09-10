import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/session_spin/domain/session_spin.dart';

void main() {
  test('semua peserta keluar tepat satu kali', () {
    final participants = [
      _santri('a', 'Ahmad'),
      _santri('b', 'Bilal'),
      _santri('c', 'Cakra'),
      _santri('a', 'Duplikat Ahmad'),
    ];
    final session = SessionSpin(participants);
    final random = Random(42);

    while (!session.isComplete) {
      session.drawNext(random);
    }

    expect(session.participants, hasLength(3));
    expect(session.order, hasLength(3));
    expect(session.order.map((item) => item.id).toSet(), hasLength(3));
    expect(() => session.drawNext(random), throwsStateError);
  });

  test('reset mempertahankan peserta dan mengosongkan hasil', () {
    final session = SessionSpin([_santri('a', 'Ahmad'), _santri('b', 'Bilal')]);
    session.drawNext(Random(1));

    session.resetOrder();

    expect(session.order, isEmpty);
    expect(session.remaining, hasLength(2));
    expect(session.isComplete, isFalse);
  });
}

SantriEntity _santri(String id, String name) => SantriEntity(
  id: id,
  name: name,
  nis: id,
  kelas: 'Mutawassith',
  jenisKelamin: 'L',
  isActive: true,
  isFree: false,
);
