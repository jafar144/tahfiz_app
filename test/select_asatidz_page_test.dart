import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_search.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_entity.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/repository/asatidz_repository.dart';
import 'package:khoirunnasyien/features/management_asatidz/presentation/cubit/asatidz_cubit.dart';
import 'package:khoirunnasyien/features/management_asatidz/presentation/pages/select_asatidz_page.dart';
import 'package:khoirunnasyien/features/management_asatidz/presentation/widgets/asatidz_card.dart';

void main() {
  testWidgets('picker uses themed search and card then returns selection', (
    tester,
  ) async {
    final asatidz = _asatidz();
    final cubit = _loadedCubit([asatidz]);
    addTearDown(cubit.close);
    AsatidzEntity? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () async {
                  selected = await Navigator.of(context).push<AsatidzEntity>(
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: cubit,
                        child: SelectAsatidzPage(initialSelectedId: asatidz.id),
                      ),
                    ),
                  );
                },
                child: const Text('Buka picker'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Buka picker'));
    await tester.pumpAndSettle();

    expect(find.byType(AiwaSearch), findsOneWidget);
    expect(find.byType(AsatidzCard), findsOneWidget);
    expect(
      tester.widget<AsatidzCard>(find.byType(AsatidzCard)).isSelected,
      true,
    );

    await tester.tap(find.text(asatidz.name));
    await tester.pumpAndSettle();

    expect(selected?.id, asatidz.id);
    expect(find.text('Buka picker'), findsOneWidget);
  });

  testWidgets('disabled asatidz card stays visible but cannot be selected', (
    tester,
  ) async {
    final asatidz = _asatidz();
    final cubit = _loadedCubit([asatidz]);
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: SelectAsatidzPage(disabledIds: [asatidz.id]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final card = tester.widget<AsatidzCard>(find.byType(AsatidzCard));
    expect(card.isEnabled, false);
    expect(find.byIcon(Icons.block_rounded), findsOneWidget);

    await tester.tap(find.text(asatidz.name), warnIfMissed: false);
    await tester.pump();

    expect(find.text('Pilih Asatidz'), findsOneWidget);
  });
}

AsatidzCubit _loadedCubit(List<AsatidzEntity> asatidz) {
  final cubit = AsatidzCubit(_FakeAsatidzRepository(asatidz));
  cubit.loadAsatidz(isActive: true);
  return cubit;
}

AsatidzEntity _asatidz() {
  return AsatidzEntity(
    id: 'asatidz-1',
    name: 'Ustadz Ahmad',
    nis: '2001',
    jenisKelamin: 'L',
    isActive: true,
  );
}

class _FakeAsatidzRepository implements AsatidzRepository {
  final List<AsatidzEntity> asatidz;

  _FakeAsatidzRepository(this.asatidz);

  @override
  Future<List<AsatidzEntity>> getAsatidzList({
    String? keyword,
    bool? isActive,
    String? gender,
    int limit = 10,
    String? lastDocumentId,
  }) async {
    final normalizedKeyword = keyword?.trim().toLowerCase() ?? '';
    return asatidz
        .where(
          (item) =>
              (isActive == null || item.isActive == isActive) &&
              (gender == null || item.jenisKelamin == gender) &&
              (normalizedKeyword.isEmpty ||
                  item.name.toLowerCase().contains(normalizedKeyword)),
        )
        .take(limit)
        .toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
