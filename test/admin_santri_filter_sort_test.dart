import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/core/config/app_config.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_bottom_sheet.dart';
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
    final incomplete = _santri(photoUrl: '  ', halaqahId: null, nomorWali: ' ');
    final complete = _santri(
      photoUrl: 'https://example.com/photo.jpg',
      halaqahId: 'halaqah-1',
      nomorWali: '08123456789',
    );

    expect(incomplete.hasProfilePhoto, isFalse);
    expect(incomplete.hasHalaqah, isFalse);
    expect(incomplete.hasGuardianPhone, isFalse);
    expect(complete.hasProfilePhoto, isTrue);
    expect(complete.hasHalaqah, isTrue);
    expect(complete.hasGuardianPhone, isTrue);
  });

  testWidgets('admin list exposes scalable filter and sorting controls', (
    tester,
  ) async {
    final repository = _FakeSantriRepository(
      asatidz: [
        AsatidzEntity(
          id: 'asatidz-1',
          name: 'Ustadz Ahmad',
          nis: '2001',
          jenisKelamin: 'L',
          isActive: true,
        ),
      ],
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

    expect(repository.lastSortBy, SantriSortBy.nis);
    expect(find.byKey(const Key('santri_filter_button')), findsOneWidget);
    expect(find.text('Urutkan: NIS'), findsOneWidget);

    await tester.tap(find.byKey(const Key('santri_filter_button')));
    await tester.pumpAndSettle();

    final sheetSize = tester.getSize(find.byType(AiwaBottomSheet));
    final screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    expect(sheetSize.height, greaterThan(screenHeight * 0.9));

    final genderTop = tester
        .getTopLeft(find.byKey(const Key('santri_gender_filter')))
        .dy;
    final sessionTop = tester
        .getTopLeft(find.byKey(const Key('santri_session_filter')))
        .dy;
    expect(genderTop, sessionTop);
    expect(find.byKey(const Key('santri_class_filter')), findsOneWidget);
    expect(find.byKey(const Key('santri_asatidz_filter')), findsOneWidget);
    expect(find.text('Ada'), findsNWidgets(3));
    expect(find.text('Tidak Ada'), findsNWidgets(3));
    expect(find.text('Belum ada foto'), findsNothing);
    expect(find.text('Belum ada halaqah'), findsNothing);

    await tester.tap(find.byKey(const Key('santri_class_filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tahsin Awwal').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('santri_asatidz_filter')));
    await tester.tap(find.byKey(const Key('santri_asatidz_filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ustadz Ahmad').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('santri_no_photo_filter')));
    await tester.tap(find.byKey(const Key('santri_no_photo_filter')));
    await tester.ensureVisible(
      find.byKey(const Key('santri_no_guardian_phone_filter')),
    );
    await tester.tap(find.byKey(const Key('santri_no_guardian_phone_filter')));
    await tester.ensureVisible(
      find.byKey(const Key('santri_active_status_section')),
    );
    expect(
      tester
          .getTopLeft(find.byKey(const Key('santri_active_status_section')))
          .dy,
      greaterThan(tester.getTopLeft(find.text('Status pembayaran')).dy),
    );
    await tester.tap(find.text('Terapkan'));
    await tester.pumpAndSettle();

    expect(repository.lastHasPhoto, isFalse);
    expect(repository.lastHasGuardianPhone, isFalse);
    expect(repository.lastClass, 'Tahsin Awwal');
    expect(repository.lastAsatidzId, 'asatidz-1');
    expect(
      find.descendant(
        of: find.byKey(const Key('santri_filter_button')),
        matching: find.text('4'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('santri_filter_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset'));
    await tester.tap(find.text('Terapkan'));
    await tester.pumpAndSettle();

    expect(repository.lastHasPhoto, isNull);
    expect(repository.lastHasGuardianPhone, isNull);
    expect(repository.lastClass, isNull);
    expect(repository.lastAsatidzId, isNull);

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

SantriEntity _santri({String? photoUrl, String? halaqahId, String? nomorWali}) {
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
    nomorWali: nomorWali,
  );
}

class _FakeSantriRepository implements SantriRepository {
  final List<SantriEntity> result;
  final int totalCount;
  final List<AsatidzEntity> asatidz;

  bool? lastHasPhoto;
  bool? lastHasHalaqah;
  bool? lastHasGuardianPhone;
  String? lastClass;
  String? lastAsatidzId;
  SantriSortBy? lastSortBy;

  _FakeSantriRepository({
    this.result = const <SantriEntity>[],
    this.asatidz = const <AsatidzEntity>[],
    int? totalCount,
  }) : totalCount = totalCount ?? result.length;

  void _record({
    required bool? hasPhoto,
    required bool? hasHalaqah,
    required bool? hasGuardianPhone,
    required String? kelas,
    required String? asatidzId,
    required SantriSortBy sortBy,
  }) {
    lastHasPhoto = hasPhoto;
    lastHasHalaqah = hasHalaqah;
    lastHasGuardianPhone = hasGuardianPhone;
    lastClass = kelas;
    lastAsatidzId = asatidzId;
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
    bool? hasGuardianPhone,
    SantriSortBy sortBy = SantriSortBy.name,
    int limit = 10,
  }) async {
    _record(
      hasPhoto: hasPhoto,
      hasHalaqah: hasHalaqah,
      hasGuardianPhone: hasGuardianPhone,
      kelas: kelas,
      asatidzId: asatidzId,
      sortBy: sortBy,
    );
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
    bool? hasGuardianPhone,
    SantriSortBy sortBy = SantriSortBy.name,
    int limit = 10,
    String? lastDocumentId,
  }) async {
    _record(
      hasPhoto: hasPhoto,
      hasHalaqah: hasHalaqah,
      hasGuardianPhone: hasGuardianPhone,
      kelas: kelas,
      asatidzId: asatidzId,
      sortBy: sortBy,
    );
    return result;
  }

  @override
  Future<List<AsatidzEntity>> getAsatidzList() async => asatidz;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
