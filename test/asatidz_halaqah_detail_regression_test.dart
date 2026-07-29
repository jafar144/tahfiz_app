import 'package:dart_either/dart_either.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/core/error/failure.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_detail.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/repository/asatidz_repository.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/halaqah.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/program_schedule.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/schedule_program.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/repositories/schedule_repository.dart';
import 'package:khoirunnasyien/features/management_schedule/presentation/pages/asatidz_halaqah_detail_page.dart';

void main() {
  testWidgets(
    'detail pengajar tetap menampilkan halaqah saat daftar sesi gagal dimuat',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AsatidzHalaqahDetailPage(
            teacherId: 'teacher-1',
            teacherName: 'Nama Lama',
            gender: 'L',
            scheduleRepository: _DetailScheduleRepository(),
            asatidzRepository: _DetailAsatidzRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ustadz Canonical'), findsOneWidget);
      expect(find.text('Sesi Sore'), findsOneWidget);
      expect(find.text('Ruang A-1'), findsOneWidget);
      expect(find.text('Rabu • 16:00–17:30'), findsOneWidget);
      expect(find.text('Belum ada sesi'), findsNothing);
    },
  );
}

class _DetailScheduleRepository implements ScheduleRepository {
  @override
  Future<Either<Failure, List<ScheduleProgram>>> getPrograms({
    required String gender,
  }) async {
    return const Left(ServerFailure('Daftar sesi sementara tidak tersedia'));
  }

  @override
  Future<Either<Failure, List<Halaqah>>> getHalaqahsByTeacher(
    String teacherId,
  ) async {
    return const Right([
      Halaqah(
        id: 'halaqah-1',
        programId: 'sore-l',
        scheduleIds: ['rabu-sore'],
        name: '',
        room: 'A-1',
        teacherId: 'teacher-1',
        teacherName: 'Ustadz Canonical',
        status: 'Active',
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
  Future<Either<Failure, List<ProgramSchedule>>> getSchedules({
    required String programId,
  }) async {
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
  Future<Either<Failure, List<SantriEntity>>> getSantrisByHalaqahId(
    String halaqahId,
  ) async {
    return const Right([]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DetailAsatidzRepository implements AsatidzRepository {
  @override
  Future<AsatidzDetail> getAsatidzDetail(String id) async {
    return AsatidzDetail(
      id: id,
      name: 'Ustadz Canonical',
      nis: '2001',
      phone: '',
      jenisKelamin: 'L',
      isActive: true,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
