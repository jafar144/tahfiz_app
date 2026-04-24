
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/features/management_santri/domain/repository/santri_repository.dart';
import 'package:khoirunnasyien/features/payment/domain/repositories/payment_repository.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/repositories/schedule_repository.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/repository/asatidz_repository.dart' as mgmt_asatidz_domain;
import 'package:khoirunnasyien/features/santri/presentation/cubit/santri_home_state.dart';
import 'package:khoirunnasyien/features/asatidz/domain/entities/santri_setoran.dart';
import 'package:khoirunnasyien/features/asatidz/domain/repositories/asatidz_repository.dart';
import 'package:khoirunnasyien/core/utils/payment_utils.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/entities/monthly_report.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/repositories/monthly_report_repository.dart';

class SantriHomeCubit extends Cubit<SantriHomeState> {
  final SantriRepository santriRepository;
  final PaymentRepository paymentRepository;
  final ScheduleRepository scheduleRepository;
  final AsatidzRepository asatidzRepository;
  final mgmt_asatidz_domain.AsatidzRepository mgmtAsatidzRepository;
  final MonthlyReportRepository monthlyReportRepository;

  SantriHomeCubit({
    required this.santriRepository,
    required this.paymentRepository,
    required this.scheduleRepository,
    required this.asatidzRepository,
    required this.mgmtAsatidzRepository,
    required this.monthlyReportRepository,
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
      final paymentHistory = await paymentRepository.getPaymentHistoryBySantri(santriId, null);
      
      // Calculate overdue months from startDate up to now.
      int overdueMonthsCount = 0;
      final startDate = PaymentUtils.resolveStartDate(santri);
      
      if (startDate != null) {
        DateTime current = DateTime(startDate.year, startDate.month);
        final end = DateTime(now.year, now.month);
        
        while (!current.isAfter(end)) {
          final monthStr = current.month.toString();
          final yearStr = current.year.toString();
          
          final isPaid = paymentHistory.any((p) => p.bulan == monthStr && p.tahun == yearStr);
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

      final halaqahResult = await scheduleRepository.getHalaqahBySantriId(santriId);
      
      await halaqahResult.fold(
        ifLeft: (l) async {}, 
        ifRight: (r) async {
          if (r != null) {
            pembimbingName = r.teacherName;
            // Fetch phone from AsatidzDetail
            try {
              final asatidzDetail = await mgmtAsatidzRepository.getAsatidzDetail(r.teacherId);
              pembimbingPhone = asatidzDetail.phone;
            } catch (e) {
              // Could not fetch phone, use placeholder or leave null
            }
          }
        },
      );

      // 5. Fetch Latest Monthly Report
      MonthlyReport? latestReport;
      final reportResult = await monthlyReportRepository.getLatestReportBySantri(santriId);
      reportResult.fold(
        ifLeft: (_) {},
        ifRight: (r) => latestReport = r,
      );

      if (isClosed) return;
      
      emit(state.copyWith(
        status: SantriHomeStatus.success,
        santri: santri,
        overdueMonthsCount: overdueMonthsCount,
        paymentHistory: paymentHistory,
        latestSetoran: latestSetoran,
        pembimbingName: pembimbingName,
        pembimbingPhone: pembimbingPhone,
        latestReport: latestReport,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        status: SantriHomeStatus.failure,
        message: e.toString(),
      ));
    }
  }

}
