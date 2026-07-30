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

          MonthlyReport? targetToEvaluate;
          for (final r in reports) {
            if (r.id == existing?.id) continue;
            if (r.target?.appliesTo(bulan, tahun) ?? false) {
              targetToEvaluate = r;
              break;
            }
          }

          emit(
            MonthlyReportInputReady(
              existingReport: existing,
              latestReport: latestPrevious,
              targetToEvaluate: targetToEvaluate,
            ),
          );
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
    required String targetMinimum,
    required String targetOptimum,
    MonthlyTargetResult targetResult = MonthlyTargetResult.notAssessed,
    String notes = '',
  }) async {
    if (state is! MonthlyReportInputReady) return;

    final currentState = state as MonthlyReportInputReady;
    final normalizedMinimum = targetMinimum.trim();
    final normalizedOptimum = targetOptimum.trim();
    if (normalizedMinimum.isEmpty || normalizedOptimum.isEmpty) {
      emit(
        const MonthlyReportInputError('Target minimum dan optimum wajib diisi'),
      );
      emit(currentState);
      return;
    }
    if (currentState.targetToEvaluate != null &&
        targetResult == MonthlyTargetResult.notAssessed) {
      emit(
        const MonthlyReportInputError('Hasil target bulan ini wajib dipilih'),
      );
      emit(currentState);
      return;
    }
    emit(currentState.copyWith(isSaving: true));

    try {
      final now = DateTime.now();
      final targetPeriod = DateTime(tahun, bulan + 1);
      final targetToEvaluate = currentState.targetToEvaluate;
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
        target: MonthlyTarget(
          bulan: targetPeriod.month,
          tahun: targetPeriod.year,
          minimum: normalizedMinimum,
          optimum: normalizedOptimum,
        ),
        targetEvaluation: targetToEvaluate == null
            ? null
            : MonthlyTargetEvaluation(
                sourceReportId: targetToEvaluate.id,
                targetBulan: targetToEvaluate.target!.bulan,
                targetTahun: targetToEvaluate.target!.tahun,
                result: targetResult,
                evaluatedAt: now,
              ),
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
          emit(
            const MonthlyReportInputSuccess(
              MonthlyReportStrings.berhasilDisimpan,
            ),
          );
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
