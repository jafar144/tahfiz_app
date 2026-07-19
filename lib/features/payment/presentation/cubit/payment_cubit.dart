import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_santri/domain/repository/santri_repository.dart';
import 'package:khoirunnasyien/features/payment/domain/repositories/payment_repository.dart';
import 'package:khoirunnasyien/features/payment/domain/entities/payment_entity.dart';
import 'package:khoirunnasyien/features/payment/presentation/cubit/payment_state.dart';
import 'package:khoirunnasyien/core/utils/error_handler.dart';
import 'package:khoirunnasyien/core/utils/payment_utils.dart';

class PaymentCubit extends Cubit<PaymentState> {
  final PaymentRepository paymentRepository;
  final SantriRepository santriRepository;

  PaymentCubit(this.paymentRepository, this.santriRepository)
    : super(PaymentInitial());

  Future<void> loadDashboard(DateTime date) async {
    emit(PaymentLoading());
    try {
      final selectedDate = PaymentUtils.clampToSupportedPeriod(date);
      final month = selectedDate.month.toString();
      final year = selectedDate.year.toString();

      // 1. Fetch Payments for Month/Year
      final payments = await paymentRepository.getPayments(month, year);

      // 2. Fetch All Active Santri
      final allActiveSantri = await santriRepository.getSantriList(
        isActive: true,
        limit: 9999,
      );

      // Hanya hitung santri yang sudah terdaftar (tanggal_masuk) pada bulan/tahun terpilih.
      final allSantri = allActiveSantri
          .where(
            (s) => PaymentUtils.isEnrolledInMonth(
              tanggalMasuk: s.tanggalMasuk,
              month: selectedDate.month,
              year: selectedDate.year,
            ),
          )
          .toList();

      // 3. Separate Paid and Unpaid
      final paidStudents = <SantriEntity>[];
      final unpaidStudents = <SantriEntity>[];

      // Create a set of Santri IDs who hava paid
      final paidSantriIds = payments.map((e) => e.santriId).toSet();

      for (var santri in allSantri) {
        if (santri.isFree || paidSantriIds.contains(santri.id)) {
          paidStudents.add(santri);
        } else {
          unpaidStudents.add(santri);
        }
      }

      // 4. Use payments for that month as recent transactions
      final santriMap = {for (var s in allSantri) s.id: s.name};
      final recentTransactions =
          payments.map((p) {
              return PaymentEntity(
                id: p.id,
                santriId: p.santriId,
                bulan: p.bulan,
                tahun: p.tahun,
                total: p.total,
                method: p.method,
                createdAt: p.createdAt,
                createdBy: p.createdBy,
                santriName: santriMap[p.santriId],
              );
            }).toList()
            // Urutkan terbaru di atas (descending sesuai tanggal dibuat).
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      emit(
        PaymentLoaded(
          paidCount: paidStudents.length,
          unpaidCount: unpaidStudents.length,
          paidStudents: paidStudents,
          unpaidStudents: unpaidStudents,
          recentTransactions: recentTransactions,
          selectedDate: selectedDate,
        ),
      );
    } catch (e) {
      emit(PaymentError(ErrorHandler.getMessage(e)));
    }
  }

  Future<void> deletePayment(String paymentId) async {
    // Current state check to revert if necessary or keep date
    final currentState = state;
    DateTime selectedDate = DateTime.now();
    if (currentState is PaymentLoaded) {
      selectedDate = currentState.selectedDate;
    }

    try {
      await paymentRepository.deletePayment(paymentId);
      // Reload dashboard after successful deletion
      loadDashboard(selectedDate);
    } catch (e) {
      emit(PaymentError(ErrorHandler.getMessage(e)));
      // Optionally reload to restore state
      loadDashboard(selectedDate);
    }
  }
}
