
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/features/management_santri/domain/repository/santri_repository.dart';
import 'package:khoirunnasyien/features/payment/domain/repositories/payment_repository.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/repositories/schedule_repository.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/repository/asatidz_repository.dart' as mgmt_asatidz_domain;
import 'package:khoirunnasyien/features/santri/presentation/cubit/santri_home_state.dart';
import 'package:khoirunnasyien/features/asatidz/domain/entities/santri_setoran.dart';
import 'package:khoirunnasyien/features/asatidz/domain/repositories/asatidz_repository.dart';
import 'package:khoirunnasyien/core/utils/payment_utils.dart';

class SantriHomeCubit extends Cubit<SantriHomeState> {
  final SantriRepository santriRepository;
  final PaymentRepository paymentRepository;
  final ScheduleRepository scheduleRepository;
  final AsatidzRepository asatidzRepository; // features/asatidz
  final mgmt_asatidz_domain.AsatidzRepository mgmtAsatidzRepository; // features/management_asatidz

  SantriHomeCubit({
    required this.santriRepository,
    required this.paymentRepository,
    required this.scheduleRepository,
    required this.asatidzRepository,
    required this.mgmtAsatidzRepository,
  }) : super(const SantriHomeState());

  Future<void> loadData(String santriId) async {
    if (isClosed) return;
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
          final monthName = PaymentUtils.getMonthName(current.month);
          final yearStr = current.year.toString();
          
          final isPaid = paymentHistory.any((p) => p.bulan == monthName && p.tahun == yearStr);
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

      if (isClosed) return;
      
      emit(state.copyWith(
        status: SantriHomeStatus.success,
        santri: santri,
        overdueMonthsCount: overdueMonthsCount,
        paymentHistory: paymentHistory,
        latestSetoran: latestSetoran,
        pembimbingName: pembimbingName,
        pembimbingPhone: pembimbingPhone,
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
