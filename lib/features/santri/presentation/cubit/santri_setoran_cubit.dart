import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/features/asatidz/domain/entities/santri_setoran.dart';
import 'package:khoirunnasyien/features/asatidz/domain/repositories/asatidz_repository.dart';

// Public enums so they can be used by both State and UI
enum SetoranFilter { bulanIni, tigaBulan, enamBulan, semua }

enum SantriSetoranStatus { initial, loading, success, failure }

class SantriSetoranState {
  final SantriSetoranStatus status;
  final List<SantriSetoran> setoranList;
  final String? errorMessage;
  final SetoranFilter filter;
  final bool hasReachedMax;

  const SantriSetoranState({
    this.status = SantriSetoranStatus.initial,
    this.setoranList = const [],
    this.errorMessage,
    this.filter = SetoranFilter.bulanIni,
    this.hasReachedMax = false,
  });

  SantriSetoranState copyWith({
    SantriSetoranStatus? status,
    List<SantriSetoran>? setoranList,
    String? errorMessage,
    SetoranFilter? filter,
    bool? hasReachedMax,
  }) {
    return SantriSetoranState(
      status: status ?? this.status,
      setoranList: setoranList ?? this.setoranList,
      errorMessage: errorMessage ?? this.errorMessage,
      filter: filter ?? this.filter,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }
}

class SantriSetoranCubit extends Cubit<SantriSetoranState> {
  final AsatidzRepository repository;
  String? _santriId;

  SantriSetoranCubit(this.repository) : super(const SantriSetoranState());

  void init(String santriId) {
    _santriId = santriId;
    loadSetoran(filter: SetoranFilter.bulanIni);
  }

  Future<void> loadSetoran({SetoranFilter? filter}) async {
    if (isClosed || _santriId == null) return;

    final currentFilter = filter ?? state.filter;

    emit(
      state.copyWith(
        status: SantriSetoranStatus.loading,
        filter: currentFilter,
      ),
    );

    final dateRange = _getDateRange(currentFilter);

    final result = await repository.getSetoranHistory(
      santriId: _santriId!,
      startDate: dateRange['start'],
      endDate: dateRange['end'],
    );

    if (isClosed) return;

    result.fold(
      ifLeft: (failure) {
        emit(
          state.copyWith(
            status: SantriSetoranStatus.failure,
            errorMessage: failure.toString(),
          ),
        );
      },
      ifRight: (data) {
        data.sort((a, b) => b.date.compareTo(a.date));
        emit(
          state.copyWith(
            status: SantriSetoranStatus.success,
            setoranList: data,
            filter: currentFilter,
          ),
        );
      },
    );
  }

  Map<String, DateTime?> _getDateRange(SetoranFilter filter) {
    final now = DateTime.now();
    DateTime? start;
    final end = now;

    switch (filter) {
      case SetoranFilter.bulanIni:
        start = DateTime(now.year, now.month, 1);
        break;
      case SetoranFilter.tigaBulan:
        start = DateTime(now.year, now.month - 3, 1);
        break;
      case SetoranFilter.enamBulan:
        start = DateTime(now.year, now.month - 6, 1);
        break;
      case SetoranFilter.semua:
        start = null;
        break;
    }
    return {'start': start, 'end': end};
  }
}
