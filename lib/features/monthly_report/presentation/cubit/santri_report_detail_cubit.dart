import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/entities/monthly_report.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/repositories/monthly_report_repository.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/cubit/monthly_report_cubit.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/cubit/santri_report_detail_state.dart';

class SantriReportDetailCubit extends Cubit<SantriReportDetailState> {
  final MonthlyReportRepository repository;

  static const int _pageSize = 10;

  /// Seluruh penilaian santri (sudah terurut terbaru ke terlama oleh datasource).
  List<MonthlyReport> _all = [];

  /// Periode susulan yang belum diisi, dipertahankan antar-paginasi.
  List<({int bulan, int tahun})> _missingPeriods = [];

  /// Apakah penilaian bulan berjalan sudah ada, dipertahankan antar-paginasi.
  bool _currentMonthFilled = false;

  /// Target bulan berjalan dan target per-laporan dihitung dari seluruh
  /// riwayat agar tidak hilang di batas halaman paginasi.
  MonthlyTargetProgress? _currentMonthTarget;
  Map<String, MonthlyTargetProgress> _periodTargetsByReportId = const {};

  SantriReportDetailCubit({required this.repository})
    : super(SantriReportDetailLoading());

  Future<void> load(String santriId, {DateTime? joinedAt}) async {
    emit(SantriReportDetailLoading());

    try {
      final result = await repository.getReportsBySantri(santriId);

      result.fold(
        ifLeft: (failure) => emit(SantriReportDetailError(failure.message)),
        ifRight: (reports) {
          _all = reports;

          final now = DateTime.now();
          final existing = {
            for (final r in _all) (bulan: r.bulan, tahun: r.tahun),
          };
          _missingPeriods = MonthlyReportCubit.backfillPeriods(
            now,
            joinedAt: joinedAt,
          ).where((p) => !existing.contains(p)).toList();
          _currentMonthFilled = existing.contains((
            bulan: now.month,
            tahun: now.year,
          ));
          _currentMonthTarget = MonthlyTargetProgress.forPeriod(
            _all,
            bulan: now.month,
            tahun: now.year,
          );
          final targetsByReportId = <String, MonthlyTargetProgress>{};
          for (final report in _all) {
            final progress = MonthlyTargetProgress.forAssessment(report, _all);
            if (progress != null) {
              targetsByReportId[report.id] = progress;
            }
          }
          _periodTargetsByReportId = targetsByReportId;

          final firstPage = _all.take(_pageSize).toList();
          emit(
            SantriReportDetailLoaded(
              reports: firstPage,
              hasMore: _all.length > firstPage.length,
              missingPeriods: _missingPeriods,
              currentMonthFilled: _currentMonthFilled,
              currentMonthTarget: _currentMonthTarget,
              periodTargetsByReportId: _periodTargetsByReportId,
            ),
          );
        },
      );
    } catch (e) {
      emit(SantriReportDetailError(e.toString()));
    }
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! SantriReportDetailLoaded) return;
    if (!current.hasMore || current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true));

    // Jeda singkat agar skeleton "load more" terlihat & transisi lebih halus.
    await Future.delayed(const Duration(milliseconds: 400));
    if (isClosed) return;

    final nextCount = (current.reports.length + _pageSize).clamp(
      0,
      _all.length,
    );
    final nextPage = _all.take(nextCount).toList();
    emit(
      SantriReportDetailLoaded(
        reports: nextPage,
        hasMore: _all.length > nextPage.length,
        isLoadingMore: false,
        missingPeriods: _missingPeriods,
        currentMonthFilled: _currentMonthFilled,
        currentMonthTarget: _currentMonthTarget,
        periodTargetsByReportId: _periodTargetsByReportId,
      ),
    );
  }
}
