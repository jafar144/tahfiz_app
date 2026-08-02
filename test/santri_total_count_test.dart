import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_entity.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_page_result.dart';
import 'package:khoirunnasyien/features/management_santri/domain/repository/santri_repository.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/cubit/santri_cubit.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/cubit/santri_state.dart';

void main() {
  test('preserves exact total while loading subsequent pages', () async {
    final repository = _PagingSantriRepository(
      firstPage: List.generate(10, _santri),
      nextPage: List.generate(10, (index) => _santri(index + 10)),
      totalCount: 20,
    );
    final cubit = SantriCubit(repository);
    addTearDown(cubit.close);

    await cubit.loadSantri(isActive: true, sortBy: SantriSortBy.nis);

    var state = cubit.state as SantriLoaded;
    expect(state.santri, hasLength(10));
    expect(state.totalCount, 20);
    expect(state.hasReachedMax, isFalse);

    await cubit.loadMoreSantri();

    state = cubit.state as SantriLoaded;
    expect(state.santri, hasLength(20));
    expect(state.totalCount, 20);
    expect(state.hasReachedMax, isTrue);
    expect(repository.loadMoreCalls, 1);

    await cubit.loadMoreSantri();
    expect(repository.loadMoreCalls, 1);
  });

  test('client-evaluated complete result does not paginate again', () async {
    final matches = List.generate(3, _santri);
    final repository = _PagingSantriRepository(
      firstPage: matches,
      nextPage: const <SantriEntity>[],
      totalCount: matches.length,
    );
    final cubit = SantriCubit(repository);
    addTearDown(cubit.close);

    await cubit.loadSantri(hasPhoto: false);

    final state = cubit.state as SantriLoaded;
    expect(state.totalCount, 3);
    expect(state.hasReachedMax, isTrue);

    await cubit.loadMoreSantri();
    expect(repository.loadMoreCalls, 0);
  });
}

SantriEntity _santri(int index) {
  return SantriEntity(
    id: 'santri-$index',
    name: 'Santri $index',
    nis: '${1000 + index}',
    kelas: 'Tahfiz 1',
    jenisKelamin: 'L',
    isActive: true,
    isFree: false,
  );
}

class _PagingSantriRepository implements SantriRepository {
  final List<SantriEntity> firstPage;
  final List<SantriEntity> nextPage;
  final int totalCount;

  int loadMoreCalls = 0;

  _PagingSantriRepository({
    required this.firstPage,
    required this.nextPage,
    required this.totalCount,
  });

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
    return SantriPageResult(items: firstPage, totalCount: totalCount);
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
    loadMoreCalls++;
    return nextPage;
  }

  @override
  Future<List<AsatidzEntity>> getAsatidzList() async {
    return const <AsatidzEntity>[];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
