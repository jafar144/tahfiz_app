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
      
      print('DEBUG: Fetching payments for $month/$year');

      // 1. Fetch Payments for Month/Year
      final payments = await paymentRepository.getPayments(month, year);
      print('DEBUG: Found ${payments.length} payments');
      
      // 2. Fetch All Active Santri
      final allSantri = await santriRepository.getSantriList(isActive: true);

      // 3. Separate Paid and Unpaid
      final paidStudents = <SantriEntity>[];
      final unpaidStudents = <SantriEntity>[];

      // Create a set of Santri IDs who hava paid
      final paidSantriIds = payments.map((e) => e.santriId).toSet();

      for (var santri in allSantri) {
        if (santri.isFree || paidSantriIds.contains(santri.id)) {
          if (santri.isFree) print('DEBUG: Santri ${santri.name} is FREE');
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
}
