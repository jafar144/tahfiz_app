import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_detail.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_params.dart';
import 'package:khoirunnasyien/features/management_santri/domain/repository/santri_repository.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/cubit/santri_detail_cubit.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/cubit/santri_detail_state.dart';

void main() {
  test(
    'update santri mengembalikan false dan mempertahankan pesan error',
    () async {
      final cubit = SantriDetailCubit(_SantriRepositoryFake(failUpdate: true));
      addTearDown(cubit.close);

      final updated = await cubit.updateSantri('santri-1', _params);

      expect(updated, isFalse);
      expect(cubit.state, isA<SantriDetailError>());
      expect(
        (cubit.state as SantriDetailError).message,
        contains('reset gagal'),
      );
    },
  );

  test(
    'update santri sukses memuat ulang detail sebelum melapor berhasil',
    () async {
      final cubit = SantriDetailCubit(_SantriRepositoryFake());
      addTearDown(cubit.close);

      final updated = await cubit.updateSantri('santri-1', _params);

      expect(updated, isTrue);
      expect(cubit.state, isA<SantriDetailLoaded>());
    },
  );
}

final _params = SantriParams(
  name: 'Ahmad',
  nis: '1001',
  phone: '0812',
  jenisKelamin: 'L',
  birthPlace: 'Jakarta',
  birthDate: DateTime(2012, 3, 9),
  waliName: 'Wali',
  waliPhone: '0813',
  kelas: 'Mutawassith',
  tipeKelas: 'Putra',
  entryDate: DateTime(2025, 7, 1),
  isFree: false,
);

class _SantriRepositoryFake implements SantriRepository {
  final bool failUpdate;

  _SantriRepositoryFake({this.failUpdate = false});

  @override
  Future<void> updateSantri(String id, SantriParams params) async {
    if (failUpdate) throw Exception('reset gagal');
  }

  @override
  Future<SantriDetail> getSantriDetail(String id) async => const SantriDetail(
    id: 'santri-1',
    name: 'Ahmad',
    nis: '1001',
    kelas: 'Mutawassith',
    jenisKelamin: 'L',
    isActive: true,
    isFree: false,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
