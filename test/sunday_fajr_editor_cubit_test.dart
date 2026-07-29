import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/entities/sunday_fajr_attendance_status.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/entities/sunday_fajr_participant.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/repositories/sunday_fajr_attendance_repository.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/presentation/cubit/sunday_fajr_editor_cubit.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/presentation/cubit/sunday_fajr_editor_state.dart';

import 'helpers/sunday_fajr_fake_repository.dart';

void main() {
  const actorId = 'admin-1';
  final now = DateTime.utc(2026, 7, 29);
  final creationNow = DateTime.utc(2026, 7, 26, 5);
  final latestSunday = DateTime.utc(2026, 7, 26);

  test('membuat snapshot roster dan mewajibkan alasan izin', () async {
    final repository = SundayFajrFakeRepository()
      ..eligibleSantri = [
        sundayFajrTestSantri(id: 's1', name: 'Ahmad', nis: '101'),
        sundayFajrTestSantri(id: 's2', name: 'Bilal', nis: '102'),
      ];
    final cubit = SundayFajrEditorCubit(
      repository: repository,
      actorId: actorId,
      eventDate: latestSunday,
      now: creationNow,
    );
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.status, SundayFajrEditorStatus.loaded);
    expect(cubit.state.isEditable, isTrue);
    expect(cubit.state.participants, hasLength(2));
    expect(cubit.state.canSave, isFalse);

    cubit.markAllPresent();
    expect(cubit.state.totalHadir, 2);
    expect(cubit.state.canSave, isTrue);

    cubit.updateStatus('s1', SundayFajrAttendanceStatus.izin);
    expect(cubit.state.canSave, isFalse);
    cubit.updateReason('s1', 'Sedang sakit');
    expect(cubit.state.canSave, isTrue);

    await cubit.save();

    expect(cubit.state.status, SundayFajrEditorStatus.saved);
    expect(repository.saveCallCount, 1);
    expect(repository.lastExpectedRevision, 0);
    expect(
      repository.lastSavedParticipants!
          .singleWhere((item) => item.santriId == 's1')
          .izinReason,
      'Sedang sakit',
    );
  });

  test('record lama memakai roster snapshot dan bersifat read-only', () async {
    final oldSunday = DateTime.utc(2026, 7, 12);
    final attendance = sundayFajrTestAttendance(eventDate: oldSunday);
    final storedParticipant = _participant(
      eventDate: oldSunday,
      name: 'Nama Lama',
    );
    final repository = SundayFajrFakeRepository()
      ..attendanceByWeek[attendance.weekKey] = attendance
      ..participantsByWeek[attendance.weekKey] = [storedParticipant]
      ..eligibleSantri = [sundayFajrTestSantri(id: 'new', name: 'Santri Baru')];
    final cubit = SundayFajrEditorCubit(
      repository: repository,
      actorId: actorId,
      eventDate: oldSunday,
      now: now,
    );
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.isEditable, isFalse);
    expect(cubit.state.participants.single.santriName, 'Nama Lama');
    cubit.markAllPresent();
    expect(
      cubit.state.participants.single.status,
      SundayFajrAttendanceStatus.alpha,
    );
    expect(cubit.state.canSave, isFalse);
  });

  test('konflik revisi ditampilkan tanpa membuang input admin', () async {
    final repository = SundayFajrFakeRepository()
      ..eligibleSantri = [sundayFajrTestSantri(id: 's1', name: 'Ahmad')]
      ..saveError = const SundayFajrRevisionConflictException();
    final cubit = SundayFajrEditorCubit(
      repository: repository,
      actorId: actorId,
      eventDate: latestSunday,
      now: creationNow,
    );
    addTearDown(cubit.close);

    await cubit.load();
    cubit.markAllPresent();
    await cubit.save();

    expect(cubit.state.status, SundayFajrEditorStatus.loaded);
    expect(cubit.state.totalHadir, 1);
    expect(cubit.state.errorMessage, contains('diperbarui admin lain'));
    expect(cubit.state.hasRevisionConflict, isTrue);

    await cubit.load();
    expect(cubit.state.hasRevisionConflict, isFalse);
    expect(cubit.state.errorMessage, isNull);
  });

  test('record baru tidak dapat dibuat pada hari Senin', () async {
    final repository = SundayFajrFakeRepository()
      ..eligibleSantri = [sundayFajrTestSantri(id: 's1', name: 'Ahmad')];
    final cubit = SundayFajrEditorCubit(
      repository: repository,
      actorId: actorId,
      eventDate: latestSunday,
      now: DateTime.utc(2026, 7, 27, 5),
    );
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.isEditable, isFalse);
    expect(cubit.state.participants, isEmpty);
    expect(cubit.state.canSave, isFalse);
  });
}

SundayFajrParticipant _participant({
  required DateTime eventDate,
  required String name,
}) {
  return SundayFajrParticipant(
    id: 's1',
    santriId: 's1',
    santriName: name,
    santriNis: '101',
    kelas: 'Tahfiz 1',
    weekKey:
        '${eventDate.year}-${eventDate.month.toString().padLeft(2, '0')}-${eventDate.day.toString().padLeft(2, '0')}',
    eventDate: eventDate,
    status: SundayFajrAttendanceStatus.alpha,
    createdAt: eventDate,
    updatedAt: eventDate,
  );
}
