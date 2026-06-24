import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/entities/monthly_report.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/repositories/monthly_report_repository.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/constants/monthly_report_strings.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/cubit/monthly_report_input_state.dart';

class MonthlyReportInputCubit extends Cubit<MonthlyReportInputState> {
  final MonthlyReportRepository repository;

  MonthlyReportInputCubit({required this.repository})
      : super(MonthlyReportInputInitial());

  Future<void> loadExisting(String santriId, int bulan, int tahun) async {
    emit(MonthlyReportInputLoading());

    try {
      // Satu kali ambil semua laporan santri (terurut terbaru -> terlama),
      // lalu turunkan laporan periode ini & penilaian terakhir sebelumnya.
      final result = await repository.getReportsBySantri(santriId);

      result.fold(
        ifLeft: (failure) {
          emit(const MonthlyReportInputReady());
        },
        ifRight: (reports) {
          MonthlyReport? existing;
          MonthlyReport? latestPrevious;

          for (final r in reports) {
            if (r.bulan == bulan && r.tahun == tahun) {
              existing = r;
            } else if (latestPrevious == null &&
                (r.tahun < tahun || (r.tahun == tahun && r.bulan < bulan))) {
              latestPrevious = r;
            }
          }

          emit(MonthlyReportInputReady(
            existingReport: existing,
            latestReport: latestPrevious,
          ));
        },
      );
    } catch (e) {
      emit(const MonthlyReportInputReady());
    }
  }

  Future<void> saveReport({
    required String asatidzId,
    required String asatidzName,
    required String santriId,
    required String santriName,
    required int bulan,
    required int tahun,
    required String hafalanTerakhir,
    required int nilaiPerkembangan,
    required int nilaiAkhlaq,
    String notes = '',
  }) async {
    if (state is! MonthlyReportInputReady) return;

    final currentState = state as MonthlyReportInputReady;
    emit(currentState.copyWith(isSaving: true));

    try {
      final now = DateTime.now();
      final report = MonthlyReport(
        id: currentState.existingReport?.id ?? '',
        asatidzId: asatidzId,
        asatidzName: asatidzName,
        santriId: santriId,
        santriName: santriName,
        bulan: bulan,
        tahun: tahun,
        hafalanTerakhir: hafalanTerakhir,
        nilaiPerkembangan: nilaiPerkembangan,
        nilaiAkhlaq: nilaiAkhlaq,
        notes: notes,
        createdAt: currentState.existingReport?.createdAt ?? now,
        updatedAt: now,
      );

      final result = await repository.createOrUpdateReport(report);

      result.fold(
        ifLeft: (failure) {
          emit(MonthlyReportInputError(failure.message));
          emit(currentState.copyWith(isSaving: false));
        },
        ifRight: (_) {
          emit(const MonthlyReportInputSuccess(MonthlyReportStrings.berhasilDisimpan));
        },
      );
    } catch (e) {
      emit(MonthlyReportInputError(e.toString()));
      if (state is MonthlyReportInputReady) {
        emit((state as MonthlyReportInputReady).copyWith(isSaving: false));
      }
    }
  }
}
