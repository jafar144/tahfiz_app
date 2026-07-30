import 'package:dart_either/dart_either.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/core/error/failure.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/repository/asatidz_repository.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_santri/domain/repository/santri_repository.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/halaqah.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/program_schedule.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/schedule_program.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/repositories/schedule_repository.dart';
import 'package:khoirunnasyien/features/management_schedule/presentation/cubit/add_halaqah_cubit.dart';
import 'package:khoirunnasyien/features/management_schedule/presentation/cubit/halaqah_detail_cubit.dart';
import 'package:khoirunnasyien/features/management_schedule/presentation/pages/add_halaqah_page.dart';
import 'package:khoirunnasyien/features/management_schedule/presentation/pages/edit_halaqah_page.dart';

void main() {
  testWidgets(
    'memilih sesi lalu menerapkan jadwal menutup masing-masing bottom sheet',
    (tester) async {
      final scheduleRepository = _FakeScheduleRepository();
      final cubit = AddHalaqahCubit(
        scheduleRepository: scheduleRepository,
        asatidzRepository: _UnusedAsatidzRepository(),
        santriRepository: _UnusedSantriRepository(),
      );
      addTearDown(cubit.close);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: cubit,
            child: const AddHalaqahPage(initialGender: 'L'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pilih Sesi'));
      await tester.pumpAndSettle();
      expect(
        find.text('Pilih program waktu untuk halaqah baru.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Sesi Sore'));
      await tester.pumpAndSettle();

      expect(
        find.text('Pilih program waktu untuk halaqah baru.'),
        findsNothing,
      );
      expect(scheduleRepository.scheduleLoadCount, 1);
      expect(find.text('Sore'), findsOneWidget);

      await tester.tap(find.text('Pilih jadwal'));
      await tester.pumpAndSettle();

      expect(find.text('Pilih Jadwal'), findsOneWidget);
      expect(find.text('Rabu'), findsOneWidget);
      expect(find.text('16:00 – 17:30'), findsOneWidget);

      await tester.tap(find.text('Rabu'));
      await tester.pump();
      await tester.tap(find.text('Terapkan (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Pilih Jadwal'), findsNothing);
      expect(find.text('1 jadwal dipilih'), findsOneWidget);
    },
  );

  testWidgets('menerapkan jadwal saat edit menutup bottom sheet', (
    tester,
  ) async {
    final scheduleRepository = _FakeScheduleRepository();
    final cubit = HalaqahDetailCubit(
      scheduleRepository: scheduleRepository,
      asatidzRepository: _UnusedAsatidzRepository(),
      santriRepository: _UnusedSantriRepository(),
      halaqah: const Halaqah(
        id: 'halaqah-1',
        programId: 'sore-l',
        scheduleIds: [],
        name: 'Halaqah Sore',
        room: 'Aula',
        teacherId: 'asatidz-1',
        teacherName: 'Ustadz Ahmad',
        status: 'Active',
      ),
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(value: cubit, child: const EditHalaqahPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pilih jadwal'));
    await tester.pumpAndSettle();
    expect(find.text('Pilih Jadwal'), findsOneWidget);

    await tester.tap(find.text('Rabu'));
    await tester.pump();
    await tester.tap(find.text('Terapkan (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Pilih Jadwal'), findsNothing);
    expect(find.text('1 jadwal dipilih'), findsOneWidget);
  });
}

class _FakeScheduleRepository implements ScheduleRepository {
  int scheduleLoadCount = 0;

  @override
  Future<Either<Failure, List<ScheduleProgram>>> getPrograms({
    required String gender,
  }) async {
    return const Right([
      ScheduleProgram(id: 'sore-l', name: 'sore', gender: 'L'),
    ]);
  }

  @override
  Future<Either<Failure, List<ProgramSchedule>>> getSchedules({
    required String programId,
  }) async {
    scheduleLoadCount++;
    return const Right([
      ProgramSchedule(
        id: 'rabu-sore',
        programId: 'sore-l',
        day: 3,
        startTime: '16:00',
        endTime: '17:30',
      ),
    ]);
  }

  @override
  Future<Either<Failure, ScheduleProgram>> getProgramById(
    String programId,
  ) async {
    return const Right(
      ScheduleProgram(id: 'sore-l', name: 'sore', gender: 'L'),
    );
  }

  @override
  Future<Either<Failure, List<Halaqah>>> getHalaqahsBySchedule(
    String scheduleId,
  ) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, List<SantriEntity>>> getSantrisByHalaqahId(
    String halaqahId,
  ) async {
    return const Right([]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedAsatidzRepository implements AsatidzRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedSantriRepository implements SantriRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
