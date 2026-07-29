import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/core/config/app_config.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_entity.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_page_result.dart';
import 'package:khoirunnasyien/features/management_santri/domain/repository/santri_repository.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/cubit/santri_cubit.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/pages/admin_santri_page.dart';
import 'package:khoirunnasyien/flavors/khoirunnasyien/app_config.dart';

void main() {
  setUpAll(() => AppConfig.configure(khoirunnasyienAppConfig));

  test('presence helpers treat null and blank profile fields as missing', () {
    final incomplete = _santri(photoUrl: '  ', halaqahId: null);
    final complete = _santri(
      photoUrl: 'https://example.com/photo.jpg',
      halaqahId: 'halaqah-1',
    );

    expect(incomplete.hasProfilePhoto, isFalse);
    expect(incomplete.hasHalaqah, isFalse);
    expect(complete.hasProfilePhoto, isTrue);
    expect(complete.hasHalaqah, isTrue);
  });

  testWidgets('admin list exposes scalable filter and sorting controls', (
    tester,
  ) async {
    final repository = _FakeSantriRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => SantriCubit(repository),
          child: const AdminSantriPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.lastSortBy, SantriSortBy.nis);
    expect(find.byKey(const Key('santri_filter_button')), findsOneWidget);
    expect(find.text('Urutkan: NIS'), findsOneWidget);

    await tester.tap(find.byKey(const Key('santri_filter_button')));
    await tester.pumpAndSettle();

    final missingPhoto = find.text('Belum ada foto');
    await tester.ensureVisible(missingPhoto);
    await tester.tap(missingPhoto);
    await tester.tap(find.text('Terapkan'));
    await tester.pumpAndSettle();

    expect(repository.lastHasPhoto, isFalse);
    expect(
      find.descendant(
        of: find.byKey(const Key('santri_filter_button')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('santri_filter_button')));
    await tester.pumpAndSettle();
    final missingHalaqah = find.text('Belum ada halaqah');
    await tester.ensureVisible(missingHalaqah);
    await tester.tap(missingHalaqah);
    await tester.tap(find.text('Terapkan'));
    await tester.pumpAndSettle();

    expect(repository.lastHasPhoto, isFalse);
    expect(repository.lastHasHalaqah, isFalse);

    await tester.tap(find.byKey(const Key('santri_sort_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nama santri'));
    await tester.tap(find.text('Terapkan'));
    await tester.pumpAndSettle();

    expect(repository.lastSortBy, SantriSortBy.name);
    expect(find.text('Urutkan: Nama'), findsOneWidget);
  });

  testWidgets(
    'admin list shows exact result total with compact footer padding',
    (tester) async {
      final repository = _FakeSantriRepository(
        result: [_santri()],
        totalCount: 37,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) => SantriCubit(repository),
            child: const AdminSantriPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('santri_result_count')), findsOneWidget);
      expect(find.text('37 santri ditemukan'), findsOneWidget);

      final listView = tester.widget<ListView>(find.byType(ListView).first);
      expect(listView.padding, const EdgeInsets.all(16));
    },
  );
}

SantriEntity _santri({String? photoUrl, String? halaqahId}) {
  return SantriEntity(
    id: 'santri-1',
    name: 'Ahmad',
    nis: '1001',
    kelas: 'Tahsin Awwal',
    jenisKelamin: 'L',
    isActive: true,
    isFree: false,
    photoUrl: photoUrl,
    halaqahId: halaqahId,
  );
}

class _FakeSantriRepository implements SantriRepository {
  final List<SantriEntity> result;
  final int totalCount;

  bool? lastHasPhoto;
  bool? lastHasHalaqah;
  SantriSortBy? lastSortBy;

  _FakeSantriRepository({this.result = const <SantriEntity>[], int? totalCount})
    : totalCount = totalCount ?? result.length;

  void _record({
    required bool? hasPhoto,
    required bool? hasHalaqah,
    required SantriSortBy sortBy,
  }) {
    lastHasPhoto = hasPhoto;
    lastHasHalaqah = hasHalaqah;
    lastSortBy = sortBy;
  }

  @override
  Future<SantriPageResult> getSantriPage({
    String? keyword,
    bool? isActive,
    String? gender,
    String? session,
    String? kelas,
    String? asatidzId,
    bool? isFree,
    bool? hasPhoto,
    bool? hasHalaqah,
    SantriSortBy sortBy = SantriSortBy.name,
    int limit = 10,
  }) async {
    _record(hasPhoto: hasPhoto, hasHalaqah: hasHalaqah, sortBy: sortBy);
    return SantriPageResult(items: result, totalCount: totalCount);
  }

  @override
  Future<List<SantriEntity>> getSantriList({
    String? keyword,
    bool? isActive,
    String? gender,
    String? session,
    String? kelas,
    String? asatidzId,
    bool? isFree,
    bool? hasPhoto,
    bool? hasHalaqah,
    SantriSortBy sortBy = SantriSortBy.name,
    int limit = 10,
    String? lastDocumentId,
  }) async {
    _record(hasPhoto: hasPhoto, hasHalaqah: hasHalaqah, sortBy: sortBy);
    return result;
  }

  @override
  Future<List<AsatidzEntity>> getAsatidzList() async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
