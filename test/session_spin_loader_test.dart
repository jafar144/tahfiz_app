import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/halaqah.dart';
import 'package:khoirunnasyien/features/session_spin/data/session_spin_loader.dart';

void main() {
  test('katalog memuat halaqah sendiri dan halaqah aktif sesama gender', () {
    final own = _halaqah('own', 'program-l', 'Halaqah Saya');
    final sameGender = _halaqah('other-l', 'program-l', 'Halaqah Putra');
    final otherGender = _halaqah('other-p', 'program-p', 'Halaqah Putri');
    final inactive = _halaqah(
      'inactive',
      'program-l',
      'Halaqah Nonaktif',
      status: 'Inactive',
    );

    final result = buildSessionSpinHalaqahs(
      teacherGender: 'L',
      ownHalaqahs: [own],
      allHalaqahs: [sameGender, otherGender, inactive, own],
      sameGenderProgramIds: {'program-l'},
      participantsByHalaqah: {
        own.id: [_santri('own-a', 'Zaid', 'L')],
        sameGender.id: [
          _santri('male', 'Ahmad', 'L'),
          _santri('female', 'Aisyah', 'P'),
          _santri('inactive-santri', 'Budi', 'L', active: false),
        ],
      },
    );

    expect(result.map((item) => item.halaqah.id), ['own', 'other-l']);
    expect(result.first.isOwn, isTrue);
    expect(result.last.isOwn, isFalse);
    expect(result.last.participants.map((item) => item.id), ['male']);
  });
}

Halaqah _halaqah(
  String id,
  String programId,
  String name, {
  String status = 'Active',
}) => Halaqah(
  id: id,
  programId: programId,
  scheduleIds: const [],
  name: name,
  room: 'A',
  teacherId: 'teacher',
  teacherName: 'Ustadz',
  status: status,
);

SantriEntity _santri(
  String id,
  String name,
  String gender, {
  bool active = true,
}) => SantriEntity(
  id: id,
  name: name,
  nis: id,
  kelas: 'Mutawassith',
  jenisKelamin: gender,
  isActive: active,
  isFree: false,
);
