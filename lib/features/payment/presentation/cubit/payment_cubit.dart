import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_santri/domain/repository/santri_repository.dart';
import 'package:khoirunnasyien/features/payment/domain/repositories/payment_repository.dart';
import 'package:khoirunnasyien/features/payment/presentation/cubit/payment_state.dart';

class PaymentCubit extends Cubit<PaymentState> {
  final PaymentRepository paymentRepository;
  final SantriRepository santriRepository;

  PaymentCubit(this.paymentRepository, this.santriRepository)
      : super(PaymentInitial());

  Future<void> loadDashboard(DateTime date) async {
    emit(PaymentLoading());
    try {
      final month = date.month.toString();
      final year = date.year.toString();
      
      // 1. Fetch Payments for Month/Year
      final payments = await paymentRepository.getPayments(month, year);
      
      // 2. Fetch All Active Santri
      final allSantri = await santriRepository.getSantriList(isActive: true, limit: 9999);

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

      // 4. Fetch Recent Transactions
      final recentTransactions = await paymentRepository.getRecentPayments(5);

      emit(PaymentLoaded(
        paidCount: paidStudents.length,
        unpaidCount: unpaidStudents.length,
        paidStudents: paidStudents,
        unpaidStudents: unpaidStudents,
        recentTransactions: recentTransactions,
        selectedDate: date,
      ));
    } catch (e) {
      emit(PaymentError(e.toString()));
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
      emit(PaymentError(e.toString()));
      // Optionally reload to restore state
      loadDashboard(selectedDate);
    }
  }
}
