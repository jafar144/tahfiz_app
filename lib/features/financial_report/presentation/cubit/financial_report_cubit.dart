import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/core/utils/error_handler.dart';
import 'package:khoirunnasyien/core/utils/payment_utils.dart';
import 'package:khoirunnasyien/features/financial_report/domain/entities/financial_report_data.dart';
import 'package:khoirunnasyien/features/financial_report/presentation/cubit/financial_report_state.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_santri/domain/repository/santri_repository.dart';
import 'package:khoirunnasyien/features/payment/domain/entities/payment_entity.dart';
import 'package:khoirunnasyien/features/payment/domain/repositories/payment_repository.dart';

class FinancialReportCubit extends Cubit<FinancialReportState> {
  final PaymentRepository paymentRepository;
  final SantriRepository santriRepository;

  FinancialReportCubit(this.paymentRepository, this.santriRepository)
      : super(FinancialReportInitial());

  Future<void> loadReport(DateTime date) async {
    emit(FinancialReportLoading());
    try {
      // Bulan terpilih (normalisasi ke awal bulan) dan bulan sebelumnya.
      final selected = DateTime(date.year, date.month);
      final previous = DateTime(selected.year, selected.month - 1);

      // Ambil pembayaran bulan terpilih & bulan lalu secara paralel.
      final results = await Future.wait([
        paymentRepository.getPayments(
            selected.month.toString(), selected.year.toString()),
        paymentRepository.getPayments(
            previous.month.toString(), previous.year.toString()),
      ]);
      final currentPayments = results[0];
      final previousPayments = results[1];

      // Ambil seluruh santri aktif sekali saja.
      final allActiveSantri =
          await santriRepository.getSantriList(isActive: true, limit: 9999);
      final santriMap = {for (final s in allActiveSantri) s.id: s};

      // Hanya hitung santri yang sudah terdaftar (tanggal_masuk) pada bulan terpilih.
      final allSantri = allActiveSantri
          .where((s) => PaymentUtils.isEnrolledInMonth(
                tanggalMasuk: s.tanggalMasuk,
                month: selected.month,
                year: selected.year,
              ))
          .toList();

      final totalRevenue =
          currentPayments.fold<int>(0, (sum, p) => sum + p.total);
      final previousMonthRevenue =
          previousPayments.fold<int>(0, (sum, p) => sum + p.total);

      // Rincian pendapatan per kelompok (gender x sesi kelas).
      final groups = _buildGroups(currentPayments, santriMap);

      // Status pembayaran santri bulan terpilih.
      final paidIds = currentPayments.map((p) => p.santriId).toSet();
      final unpaidStudents = <SantriEntity>[];
      var billableCount = 0;
      var paidCount = 0;
      for (final s in allSantri) {
        if (s.isFree) {
          paidCount++;
          continue;
        }
        billableCount++;
        if (paidIds.contains(s.id)) {
          paidCount++;
        } else {
          unpaidStudents.add(s);
        }
      }

      emit(FinancialReportLoaded(
        FinancialReportData(
          selectedDate: selected,
          totalRevenue: totalRevenue,
          previousMonthRevenue: previousMonthRevenue,
          transactionCount: currentPayments.length,
          billableCount: billableCount,
          paidCount: paidCount,
          unpaidStudents: unpaidStudents,
          groups: groups,
        ),
      ));
    } catch (e) {
      emit(FinancialReportError(ErrorHandler.getMessage(e)));
    }
  }

  List<RevenueGroup> _buildGroups(
    List<PaymentEntity> payments,
    Map<String, SantriEntity> santriMap,
  ) {
    final revenueByKey = <String, int>{};
    final countByKey = <String, int>{};
    final genderByKey = <String, String>{};
    final sessionByKey = <String, String>{};

    for (final p in payments) {
      final santri = santriMap[p.santriId];
      final gender = santri?.jenisKelamin ?? '';
      final session = (santri?.tipeKelas?.trim().isNotEmpty ?? false)
          ? santri!.tipeKelas!.trim()
          : 'Lainnya';
      final label = _groupLabel(gender, session);

      revenueByKey[label] = (revenueByKey[label] ?? 0) + p.total;
      countByKey[label] = (countByKey[label] ?? 0) + 1;
      genderByKey[label] = gender;
      sessionByKey[label] = session;
    }

    final groups = revenueByKey.keys
        .map((label) => RevenueGroup(
              label: label,
              gender: genderByKey[label] ?? '',
              session: sessionByKey[label] ?? 'Lainnya',
              revenue: revenueByKey[label] ?? 0,
              paymentCount: countByKey[label] ?? 0,
            ))
        .toList();

    groups.sort((a, b) => b.revenue.compareTo(a.revenue));
    return groups;
  }

  String _groupLabel(String gender, String session) {
    final genderLabel = switch (gender) {
      'L' => 'Putra',
      'P' => 'Putri',
      _ => 'Lainnya',
    };
    if (genderLabel == 'Lainnya') return 'Lainnya';
    return '$genderLabel $session';
  }
}
