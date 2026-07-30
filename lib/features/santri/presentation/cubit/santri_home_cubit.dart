import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/features/management_santri/domain/repository/santri_repository.dart';
import 'package:khoirunnasyien/features/payment/domain/repositories/payment_repository.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/repositories/schedule_repository.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/repository/asatidz_repository.dart'
    as mgmt_asatidz_domain;
import 'package:khoirunnasyien/features/santri/presentation/cubit/santri_home_state.dart';
import 'package:khoirunnasyien/features/asatidz/domain/entities/santri_setoran.dart';
import 'package:khoirunnasyien/features/asatidz/domain/repositories/asatidz_repository.dart';
import 'package:khoirunnasyien/core/utils/payment_utils.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/entities/monthly_report.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/repositories/monthly_report_repository.dart';
import 'package:khoirunnasyien/features/family/data/family_repository.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_detail.dart';

class SantriHomeCubit extends Cubit<SantriHomeState> {
  final SantriRepository santriRepository;
  final PaymentRepository paymentRepository;
  final ScheduleRepository scheduleRepository;
  final AsatidzRepository asatidzRepository;
  final mgmt_asatidz_domain.AsatidzRepository mgmtAsatidzRepository;
  final MonthlyReportRepository monthlyReportRepository;
  final FamilyRepository familyRepository;

  SantriHomeCubit({
    required this.santriRepository,
    required this.paymentRepository,
    required this.scheduleRepository,
    required this.asatidzRepository,
    required this.mgmtAsatidzRepository,
    required this.monthlyReportRepository,
    required this.familyRepository,
  }) : super(const SantriHomeState());

  static String? overrideSantriId;

  String? _currentSantriId;
  String? get currentSantriId => _currentSantriId;

  Future<void> loadData(String santriId) async {
    if (isClosed) return;
    _currentSantriId = santriId;
    emit(state.copyWith(status: SantriHomeStatus.loading));

    try {
      // 1. Fetch Santri Profile
      final santri = await santriRepository.getSantriDetail(santriId);

      // 2. Fetch Payment Status (Full History)
      final now = DateTime.now();
      final paymentHistory = await paymentRepository.getPaymentHistoryBySantri(
        santriId,
        null,
      );

      // Calculate overdue months from startDate up to now.
      int overdueMonthsCount = 0;
      final startDate = PaymentUtils.resolveStartDate(
        freeUntil: santri.freeUntil,
        tanggalMasuk: santri.tanggalMasuk,
      );

      if (startDate != null) {
        DateTime current = DateTime(startDate.year, startDate.month);
        final end = DateTime(now.year, now.month);

        while (!current.isAfter(end)) {
          final monthStr = current.month.toString();
          final yearStr = current.year.toString();

          final isPaid = paymentHistory.any(
            (p) => p.bulan == monthStr && p.tahun == yearStr,
          );
          if (!isPaid) {
            overdueMonthsCount++;
          }

          // Move to next month
          current = DateTime(current.year, current.month + 1);
        }
      }

      // 3. Fetch Latest Setoran
      SantriSetoran? latestSetoran;

      final setoranResult = await asatidzRepository.getSetoranHistory(
        santriId: santriId,
      );

      setoranResult.fold(
        ifLeft: (l) {}, // Ignore error for now
        ifRight: (r) {
          if (r.isNotEmpty) {
            // Sort by date desc
            r.sort((a, b) => b.date.compareTo(a.date));
            latestSetoran = r.first;
          }
        },
      );

      // 4. Fetch Pembimbing (via Halaqah)
      String? pembimbingName;
      String? pembimbingPhone;
      String? pembimbingGender;

      final halaqahResult = await scheduleRepository.getHalaqahBySantriId(
        santriId,
      );

      await halaqahResult.fold(
        ifLeft: (l) async {},
        ifRight: (r) async {
          if (r != null) {
            pembimbingName = r.teacherName;
            // Fetch phone & gender from AsatidzDetail
            try {
              final asatidzDetail = await mgmtAsatidzRepository
                  .getAsatidzDetail(r.teacherId);
              if (asatidzDetail.name.trim().isNotEmpty) {
                pembimbingName = asatidzDetail.name;
              }
              pembimbingPhone = asatidzDetail.phone;
              pembimbingGender = asatidzDetail.jenisKelamin;
            } catch (e) {
              // Could not fetch detail, use placeholder or leave null
            }
          }
        },
      );

      // 5. Fetch laporan bulanan. Daftar lengkap dipakai untuk menyusun
      // timeline target; item pertama tetap menjadi penilaian terbaru.
      MonthlyReport? latestReport;
      List<MonthlyReport> monthlyReports = const [];
      final reportResult = await monthlyReportRepository.getReportsBySantri(
        santriId,
      );
      reportResult.fold(
        ifLeft: (_) {},
        ifRight: (reports) {
          monthlyReports = reports;
          if (reports.isNotEmpty) latestReport = reports.first;
        },
      );

      // 6. Fetch saudara (akun lain dalam satu keluarga) untuk fitur ganti akun.
      final List<SantriDetail> familyMembers = [];
      try {
        final family = await familyRepository.getFamilyBySantriId(santriId);
        if (family != null && family.santriIds.length >= 2) {
          final otherIds = family.santriIds
              .where((id) => id != santriId)
              .toList();
          for (final id in otherIds) {
            try {
              familyMembers.add(await santriRepository.getSantriDetail(id));
            } catch (_) {}
          }
        }
      } catch (_) {}

      if (isClosed) return;

      emit(
        state.copyWith(
          status: SantriHomeStatus.success,
          santri: santri,
          overdueMonthsCount: overdueMonthsCount,
          paymentHistory: paymentHistory,
          latestSetoran: latestSetoran,
          pembimbingName: pembimbingName,
          pembimbingPhone: pembimbingPhone,
          pembimbingGender: pembimbingGender,
          latestReport: latestReport,
          monthlyReports: monthlyReports,
          familyMembers: familyMembers,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(status: SantriHomeStatus.failure, message: e.toString()),
      );
    }
  }
}
