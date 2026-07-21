import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/features/payment/domain/repositories/payment_repository.dart';
import 'package:khoirunnasyien/features/payment/presentation/cubit/admin_payment_history_state.dart';
import 'package:khoirunnasyien/core/utils/error_handler.dart';

class AdminPaymentHistoryCubit extends Cubit<AdminPaymentHistoryState> {
  final PaymentRepository repository;
  static const int _limit = 15;

  AdminPaymentHistoryCubit(this.repository)
    : super(AdminPaymentHistoryInitial());

  Future<void> loadHistory() async {
    try {
      emit(AdminPaymentHistoryLoading());
      final payments = await repository.getPaymentHistory(limit: _limit);

      emit(
        AdminPaymentHistoryLoaded(
          payments: payments,
          hasReachedMax: payments.length < _limit,
        ),
      );
    } catch (e) {
      emit(AdminPaymentHistoryError(ErrorHandler.getMessage(e)));
    }
  }

  Future<void> loadMore() async {
    final currentState = state;
    if (currentState is AdminPaymentHistoryLoaded &&
        !currentState.hasReachedMax &&
        !currentState.isFetchingMore) {
      try {
        emit(currentState.copyWith(isFetchingMore: true));

        final lastPayment = currentState.payments.last;
        final newPayments = await repository.getPaymentHistory(
          limit: _limit,
          lastDocumentId: lastPayment.id,
        );

        emit(
          currentState.copyWith(
            payments: currentState.payments + newPayments,
            hasReachedMax: newPayments.length < _limit,
            isFetchingMore: false,
          ),
        );
      } catch (e) {
        // On error during pagination, just stop fetching more but keep list
        emit(currentState.copyWith(isFetchingMore: false));
      }
    }
  }

  Future<void> deletePayment(String paymentId) async {
    final currentState = state;
    if (currentState is AdminPaymentHistoryLoaded) {
      try {
        await repository.deletePayment(paymentId);

        // Optimistically remove from list
        final updatedList = List.of(currentState.payments)
          ..removeWhere((p) => p.id == paymentId);
        emit(currentState.copyWith(payments: updatedList));
      } catch (e) {
        // Just reload in case of error mismatch
        loadHistory();
      }
    }
  }
}
