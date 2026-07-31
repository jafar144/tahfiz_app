import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_either/dart_either.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/core/error/failure.dart';
import 'package:khoirunnasyien/features/asatidz/domain/entities/santri_setoran.dart';
import 'package:khoirunnasyien/features/asatidz/domain/repositories/asatidz_repository.dart'
    as learning;
import 'package:khoirunnasyien/features/family/data/family_repository.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_detail.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/repository/asatidz_repository.dart'
    as management;
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_detail.dart';
import 'package:khoirunnasyien/features/management_santri/domain/repository/santri_repository.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/halaqah.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/repositories/schedule_repository.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/entities/monthly_report.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/repositories/monthly_report_repository.dart';
import 'package:khoirunnasyien/features/payment/domain/entities/payment_entity.dart';
import 'package:khoirunnasyien/features/payment/domain/repositories/payment_repository.dart';
import 'package:khoirunnasyien/features/santri/presentation/cubit/santri_home_cubit.dart';
import 'package:khoirunnasyien/features/santri/presentation/cubit/santri_home_state.dart';

void main() {
  test('detail pengajar sukses mengisi nama, kontak, dan gelar', () async {
    final harness = _Harness()
      ..santriRepository.details['santri-a'] = _santri(
        id: 'santri-a',
        gender: 'L',
        pembimbing: 'Nama Fallback',
      )
      ..scheduleRepository.halaqahs['santri-a'] = _halaqah(
        santriId: 'santri-a',
        teacherId: 'teacher-a',
        teacherName: 'Nama Halaqah',
      )
      ..teacherRepository.details['teacher-a'] = _teacher(
        id: 'teacher-a',
        name: 'Ahmad',
        phone: '08123456789',
        gender: 'L',
      );
    addTearDown(harness.cubit.close);

    await harness.cubit.loadData('santri-a');

    expect(harness.cubit.state.status, SantriHomeStatus.success);
    expect(harness.cubit.state.pembimbingName, 'Ahmad');
    expect(harness.cubit.state.pembimbingPhone, '08123456789');
    expect(harness.cubit.state.pembimbingGender, 'L');
    expect(harness.cubit.state.pembimbingDisplayName, 'Ustadz Ahmad');
  });

  test('ganti santri tidak membawa nomor pembimbing sebelumnya', () async {
    final harness = _Harness()
      ..santriRepository.details.addAll({
        'santri-a': _santri(
          id: 'santri-a',
          gender: 'L',
          pembimbing: 'Guru Lama',
        ),
        'santri-b': _santri(id: 'santri-b', gender: 'P', pembimbing: 'Fatimah'),
      })
      ..scheduleRepository.halaqahs.addAll({
        'santri-a': _halaqah(
          santriId: 'santri-a',
          teacherId: 'teacher-a',
          teacherName: 'Guru Lama',
        ),
        'santri-b': _halaqah(
          santriId: 'santri-b',
          teacherId: 'teacher-b',
          teacherName: '   ',
        ),
      })
      ..teacherRepository.details['teacher-a'] = _teacher(
        id: 'teacher-a',
        name: 'Ahmad',
        phone: '081200000001',
        gender: 'L',
      )
      ..teacherRepository.deniedIds.add('teacher-b');
    addTearDown(harness.cubit.close);

    await harness.cubit.loadData('santri-a');
    expect(harness.cubit.state.pembimbingPhone, '081200000001');

    await harness.cubit.loadData('santri-b');

    expect(harness.cubit.state.status, SantriHomeStatus.success);
    expect(harness.cubit.currentSantriId, 'santri-b');
    expect(harness.cubit.state.pembimbingName, 'Fatimah');
    expect(harness.cubit.state.pembimbingPhone, isNull);
    expect(harness.cubit.state.pembimbingGender, 'P');
    expect(harness.cubit.state.pembimbingDisplayName, 'Ustadzah Fatimah');
  });

  test('detail kontak gagal tetap mempertahankan gelar yang benar', () async {
    final harness = _Harness()
      ..santriRepository.details['santri-a'] = _santri(
        id: 'santri-a',
        gender: 'L',
        pembimbing: 'Nama Fallback',
      )
      ..scheduleRepository.halaqahs['santri-a'] = _halaqah(
        santriId: 'santri-a',
        teacherId: 'teacher-a',
        teacherName: 'Ahmad',
      )
      ..teacherRepository.deniedIds.add('teacher-a');
    addTearDown(harness.cubit.close);

    await harness.cubit.loadData('santri-a');

    expect(harness.cubit.state.pembimbingName, 'Ahmad');
    expect(harness.cubit.state.pembimbingPhone, isNull);
    expect(harness.cubit.state.pembimbingGender, 'L');
    expect(harness.cubit.state.pembimbingDisplayName, 'Ustadz Ahmad');
  });

  test('retry memulihkan nomor WhatsApp tanpa me-reload halaman', () async {
    final harness = _Harness()
      ..santriRepository.details['santri-a'] = _santri(
        id: 'santri-a',
        gender: 'L',
        pembimbing: 'Nama Fallback',
      )
      ..scheduleRepository.halaqahs['santri-a'] = _halaqah(
        santriId: 'santri-a',
        teacherId: 'teacher-a',
        teacherName: 'Ahmad',
      )
      ..teacherRepository.deniedIds.add('teacher-a');
    addTearDown(harness.cubit.close);

    await harness.cubit.loadData('santri-a');
    expect(harness.cubit.state.pembimbingPhone, isNull);

    harness.teacherRepository.deniedIds.remove('teacher-a');
    harness.teacherRepository.details['teacher-a'] = _teacher(
      id: 'teacher-a',
      name: 'Ahmad',
      phone: '08123456789',
      gender: 'L',
    );

    final phone = await harness.cubit.retryPembimbingContact();

    expect(phone, '08123456789');
    expect(harness.cubit.state.status, SantriHomeStatus.success);
    expect(harness.cubit.state.pembimbingPhone, '08123456789');
    expect(harness.cubit.state.pembimbingDisplayName, 'Ustadz Ahmad');
  });

  test(
    'nomor kosong dinormalisasi menjadi null tanpa menghilangkan gelar',
    () async {
      final harness = _Harness()
        ..santriRepository.details['santri-a'] = _santri(
          id: 'santri-a',
          gender: 'P',
          pembimbing: 'Nama Fallback',
        )
        ..scheduleRepository.halaqahs['santri-a'] = _halaqah(
          santriId: 'santri-a',
          teacherId: 'teacher-a',
          teacherName: 'Nama Halaqah',
        )
        ..teacherRepository.details['teacher-a'] = _teacher(
          id: 'teacher-a',
          name: 'Aisyah',
          phone: '   ',
          gender: 'P',
        );
      addTearDown(harness.cubit.close);

      await harness.cubit.loadData('santri-a');

      expect(harness.cubit.state.pembimbingPhone, isNull);
      expect(harness.cubit.state.pembimbingGender, 'P');
      expect(harness.cubit.state.pembimbingDisplayName, 'Ustadzah Aisyah');
    },
  );

  test('nama, nomor, dan gender pengajar dinormalisasi', () async {
    final harness = _Harness()
      ..santriRepository.details['santri-a'] = _santri(
        id: 'santri-a',
        gender: 'P',
        pembimbing: 'Nama Fallback',
      )
      ..scheduleRepository.halaqahs['santri-a'] = _halaqah(
        santriId: 'santri-a',
        teacherId: 'teacher-a',
        teacherName: 'Nama Halaqah',
      )
      ..teacherRepository.details['teacher-a'] = _teacher(
        id: 'teacher-a',
        name: '  Khadijah  ',
        phone: '  081200000002  ',
        gender: ' p ',
      );
    addTearDown(harness.cubit.close);

    await harness.cubit.loadData('santri-a');

    expect(harness.cubit.state.pembimbingName, 'Khadijah');
    expect(harness.cubit.state.pembimbingPhone, '081200000002');
    expect(harness.cubit.state.pembimbingGender, 'P');
    expect(harness.cubit.state.pembimbingDisplayName, 'Ustadzah Khadijah');
  });
}

class _Harness {
  final _FakeSantriRepository santriRepository = _FakeSantriRepository();
  final _FakePaymentRepository paymentRepository = _FakePaymentRepository();
  final _FakeScheduleRepository scheduleRepository = _FakeScheduleRepository();
  final _FakeLearningRepository learningRepository = _FakeLearningRepository();
  final _FakeTeacherRepository teacherRepository = _FakeTeacherRepository();
  final _FakeMonthlyReportRepository monthlyReportRepository =
      _FakeMonthlyReportRepository();
  final _FakeFamilyRepository familyRepository = _FakeFamilyRepository();
  late final SantriHomeCubit cubit = SantriHomeCubit(
    santriRepository: santriRepository,
    paymentRepository: paymentRepository,
    scheduleRepository: scheduleRepository,
    asatidzRepository: learningRepository,
    mgmtAsatidzRepository: teacherRepository,
    monthlyReportRepository: monthlyReportRepository,
    familyRepository: familyRepository,
  );
}

class _FakeSantriRepository implements SantriRepository {
  final Map<String, SantriDetail> details = {};

  @override
  Future<SantriDetail> getSantriDetail(String id) async => details[id]!;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePaymentRepository implements PaymentRepository {
  @override
  Future<List<PaymentEntity>> getPaymentHistoryBySantri(
    String santriId,
    int? limit,
  ) async {
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeScheduleRepository implements ScheduleRepository {
  final Map<String, Halaqah> halaqahs = {};

  @override
  Future<Either<Failure, Halaqah?>> getHalaqahBySantriId(
    String santriId,
  ) async {
    return Right(halaqahs[santriId]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLearningRepository implements learning.AsatidzRepository {
  @override
  Future<Either<Failure, List<SantriSetoran>>> getSetoranHistory({
    required String santriId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return const Right([]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTeacherRepository implements management.AsatidzRepository {
  final Map<String, AsatidzDetail> details = {};
  final Set<String> deniedIds = {};

  @override
  Future<AsatidzDetail> getAsatidzDetail(String id) async {
    if (deniedIds.contains(id)) {
      throw Exception('permission-denied');
    }
    return details[id]!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMonthlyReportRepository implements MonthlyReportRepository {
  @override
  Future<Either<Failure, List<MonthlyReport>>> getReportsBySantri(
    String santriId, {
    int? bulan,
    int? tahun,
  }) async {
    return const Right([]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFamilyRepository extends FamilyRepository {
  _FakeFamilyRepository() : super(_UnusedFirestore());

  @override
  Future<FamilyEntity?> getFamilyBySantriId(String santriId) async => null;
}

class _UnusedFirestore implements FirebaseFirestore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

SantriDetail _santri({
  required String id,
  required String gender,
  required String pembimbing,
}) {
  return SantriDetail(
    id: id,
    name: 'Santri $id',
    nis: id,
    kelas: 'Tahfidz',
    jenisKelamin: gender,
    isActive: true,
    isFree: false,
    pembimbing: pembimbing,
  );
}

Halaqah _halaqah({
  required String santriId,
  required String teacherId,
  required String teacherName,
}) {
  return Halaqah(
    id: 'halaqah-$santriId',
    programId: 'program',
    scheduleIds: const [],
    name: 'Halaqah $santriId',
    room: 'Ruang 1',
    teacherId: teacherId,
    teacherName: teacherName,
    status: 'active',
  );
}

AsatidzDetail _teacher({
  required String id,
  required String name,
  required String phone,
  required String gender,
}) {
  return AsatidzDetail(
    id: id,
    name: name,
    nis: id,
    phone: phone,
    jenisKelamin: gender,
    isActive: true,
  );
}
