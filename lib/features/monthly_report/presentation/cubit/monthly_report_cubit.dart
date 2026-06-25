import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/repositories/schedule_repository.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/entities/monthly_report.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/repositories/monthly_report_repository.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/cubit/monthly_report_state.dart';

class MonthlyReportCubit extends Cubit<MonthlyReportState> {
  final MonthlyReportRepository reportRepository;
  final ScheduleRepository scheduleRepository;

  MonthlyReportCubit({
    required this.reportRepository,
    required this.scheduleRepository,
  }) : super(MonthlyReportInitial());

  static bool checkIsInWindow(DateTime now) {
    final lastDay = DateTime(now.year, now.month + 1, 0);
    final windowStart = lastDay.subtract(const Duration(days: 6));
    return !now.isBefore(windowStart);
  }

  static int getTargetBulan(DateTime now) => now.month;
  static int getTargetTahun(DateTime now) => now.year;

  static int getDaysRemaining(DateTime now) {
    final lastDay = DateTime(now.year, now.month + 1, 0);
    return lastDay.difference(now).inDays;
  }

  /// Bulan pertama fitur penilaian aktif. Tidak ada susulan sebelum periode ini.
  static const int epochBulan = 6;
  static const int epochTahun = 2026;

  /// Maksimal jumlah bulan lampau yang boleh diisi susulan (rolling).
  static const int maxBackfillMonths = 2;

  /// Periode (bulan, tahun) lampau yang masih boleh diisi susulan, dibatasi
  /// rolling [maxBackfillMonths] bulan, epoch fitur, dan (opsional) bulan masuk
  /// santri. Terurut terbaru -> terlama. Tidak termasuk bulan berjalan.
  static List<({int bulan, int tahun})> backfillPeriods(
    DateTime now, {
    DateTime? joinedAt,
  }) {
    final epoch = DateTime(epochTahun, epochBulan);
    final periods = <({int bulan, int tahun})>[];
    for (var i = 1; i <= maxBackfillMonths; i++) {
      final d = DateTime(now.year, now.month - i);
      if (d.isBefore(epoch)) break;
      if (joinedAt != null &&
          d.isBefore(DateTime(joinedAt.year, joinedAt.month))) {
        continue;
      }
      periods.add((bulan: d.month, tahun: d.year));
    }
    return periods;
  }

  Future<void> loadData(String asatidzId) async {
    emit(MonthlyReportLoading());

    try {
      final now = DateTime.now();
      final isInWindow = checkIsInWindow(now);
      final targetBulan = getTargetBulan(now);
      final targetTahun = getTargetTahun(now);
      final daysRemaining = getDaysRemaining(now);

      final halaqahsResult = await scheduleRepository.getHalaqahsByTeacher(asatidzId);

      final allSantris = <SantriEntity>[];

      await halaqahsResult.fold(
        ifLeft: (failure) async {
          emit(MonthlyReportError(failure.message));
        },
        ifRight: (halaqahs) async {
          for (final halaqah in halaqahs) {
            final santrisResult = await scheduleRepository.getSantrisByHalaqahId(halaqah.id);
            santrisResult.fold(
              ifLeft: (_) {},
              ifRight: (santris) {
                final mapped = santris.map((s) => SantriEntity(
                  id: s.id,
                  name: s.name,
                  nis: s.nis,
                  kelas: s.kelas,
                  jenisKelamin: s.jenisKelamin,
                  isActive: s.isActive,
                  isFree: s.isFree,
                  freeUntil: s.freeUntil,
                  nomorWali: s.nomorWali,
                  tipeKelas: s.tipeKelas,
                  halaqahId: s.halaqahId,
                  halaqahName: halaqah.name,
                  pembimbing: halaqah.teacherName,
                  tanggalMasuk: s.tanggalMasuk,
                )).toList();
                allSantris.addAll(mapped);
              },
            );
          }
        },
      );

      if (state is MonthlyReportError) return;

      final uniqueSantris = {for (var s in allSantris) s.id: s}
          .values
          .where((s) => s.isActive)
          .toList();

      final reportsResult = await reportRepository.getReportsByAsatidz(
        asatidzId,
        targetBulan,
        targetTahun,
      );

      final reportMap = <String, MonthlyReport>{};
      reportsResult.fold(
        ifLeft: (_) {},
        ifRight: (reports) {
          for (final report in reports) {
            reportMap[report.santriId] = report;
          }
        },
      );

      // Hitung penilaian tertunggak (bulan lampau yang belum diisi) per santri.
      // Cukup 1 query per periode susulan, lalu diiriskan dengan santri ini.
      final periods = backfillPeriods(now);
      final reportedByPeriod = <({int bulan, int tahun}), Set<String>>{};
      for (final p in periods) {
        final res = await reportRepository.getReportedSantriIds(p.bulan, p.tahun);
        res.fold(
          ifLeft: (_) {},
          ifRight: (ids) => reportedByPeriod[p] = ids,
        );
      }

      final tertunggakBySantri = <String, int>{};
      for (final s in uniqueSantris) {
        var count = 0;
        for (final p in periods) {
          final pd = DateTime(p.tahun, p.bulan);
          final joined = s.tanggalMasuk;
          if (joined != null && pd.isBefore(DateTime(joined.year, joined.month))) {
            continue;
          }
          final reported = reportedByPeriod[p] ?? const <String>{};
          if (!reported.contains(s.id)) count++;
        }
        if (count > 0) tertunggakBySantri[s.id] = count;
      }

      if (isClosed) return;

      emit(MonthlyReportLoaded(
        santriList: uniqueSantris,
        reportMap: reportMap,
        isInWindow: isInWindow,
        targetBulan: targetBulan,
        targetTahun: targetTahun,
        daysRemaining: daysRemaining,
        tertunggakBySantri: tertunggakBySantri,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(MonthlyReportError(e.toString()));
    }
  }
}
