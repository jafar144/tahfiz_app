import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_entity.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_page_result.dart';
import 'package:khoirunnasyien/features/management_santri/domain/repository/santri_repository.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/cubit/santri_cubit.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/pages/select_santri_page.dart';

void main() {
  testWidgets('assigned santri can be selected after transfer confirmation', (
    tester,
  ) async {
    final santri = _santri(halaqahId: 'halaqah-lama');

    await _pumpPicker(
      tester,
      santri: santri,
      disabledIds: [santri.id],
      allowHalaqahTransfer: true,
    );

    expect(find.text('Halaqah lain'), findsNothing);
    expect(_greyOpacityFor(santri), findsOneWidget);
    expect(find.text('Pilih (0)'), findsOneWidget);

    await tester.tap(find.text(santri.name));
    await tester.pumpAndSettle();

    expect(find.text('Santri sudah memiliki halaqah'), findsOneWidget);
    expect(find.text('Pilih (0)'), findsOneWidget);

    await tester.tap(find.text('Tetap pilih'));
    await tester.pumpAndSettle();

    expect(find.text('Santri sudah memiliki halaqah'), findsNothing);
    expect(find.text('Pilih (1)'), findsOneWidget);
    expect(
      tester
          .widget<Checkbox>(
            find.byKey(Key('santri_select_checkbox_${santri.id}')),
          )
          .value,
      isTrue,
    );

    // Konfirmasi hanya diperlukan pada pemilihan pertama. Setelah dilepas,
    // santri yang sama bisa dipilih kembali tanpa sheet kedua.
    await tester.tap(find.text(santri.name));
    await tester.pumpAndSettle();
    await tester.tap(find.text(santri.name));
    await tester.pumpAndSettle();

    expect(find.text('Santri sudah memiliki halaqah'), findsNothing);
    expect(find.text('Pilih (1)'), findsOneWidget);
  });

  testWidgets('default disabled card stays disabled without opening detail', (
    tester,
  ) async {
    final santri = _santri();

    await _pumpPicker(tester, santri: santri, disabledIds: [santri.id]);

    await tester.tap(find.text(santri.name), warnIfMissed: false);
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Pilih (0)'), findsOneWidget);
    expect(
      tester
          .widget<Checkbox>(
            find.byKey(Key('santri_select_checkbox_${santri.id}')),
          )
          .onChanged,
      isNull,
    );
  });

  testWidgets('member of current halaqah needs no transfer confirmation', (
    tester,
  ) async {
    final santri = _santri(halaqahId: 'halaqah-sekarang');

    await _pumpPicker(
      tester,
      santri: santri,
      allowHalaqahTransfer: true,
      currentHalaqahId: 'halaqah-sekarang',
    );

    expect(find.text('Halaqah lain'), findsNothing);
    expect(_greyOpacityFor(santri), findsNothing);

    await tester.tap(find.text(santri.name));
    await tester.pumpAndSettle();

    expect(find.text('Santri sudah memiliki halaqah'), findsNothing);
    expect(find.text('Pilih (1)'), findsOneWidget);
  });
}

Finder _greyOpacityFor(SantriEntity santri) {
  return find.ancestor(
    of: find.text(santri.name),
    matching: find.byWidgetPredicate(
      (widget) => widget is Opacity && widget.opacity == 0.5,
    ),
  );
}

Future<void> _pumpPicker(
  WidgetTester tester, {
  required SantriEntity santri,
  List<String> disabledIds = const [],
  bool allowHalaqahTransfer = false,
  String? currentHalaqahId,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider(
        create: (_) => SantriCubit(_FakeSantriRepository([santri])),
        child: SelectSantriPage(
          isMultiSelect: true,
          disabledIds: disabledIds,
          allowHalaqahTransfer: allowHalaqahTransfer,
          currentHalaqahId: currentHalaqahId,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

SantriEntity _santri({String? halaqahId}) {
  return SantriEntity(
    id: 'santri-1',
    name: 'Ahmad Fauzan',
    nis: '1001',
    kelas: 'Tahfiz 1',
    jenisKelamin: 'L',
    isActive: true,
    isFree: false,
    halaqahId: halaqahId,
  );
}

class _FakeSantriRepository implements SantriRepository {
  final List<SantriEntity> santri;

  _FakeSantriRepository(this.santri);

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
    return SantriPageResult(items: santri, totalCount: santri.length);
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
    return santri;
  }

  @override
  Future<List<AsatidzEntity>> getAsatidzList() async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
