import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/features/payment/domain/repositories/payment_repository.dart';
import 'package:khoirunnasyien/features/payment/presentation/cubit/santri_payment_history_state.dart';

class SantriPaymentHistoryCubit extends Cubit<SantriPaymentHistoryState> {
  final PaymentRepository paymentRepository;

  SantriPaymentHistoryCubit(this.paymentRepository) : super(SantriPaymentHistoryInitial());

  Future<void> loadHistory(String santriId) async {
    emit(SantriPaymentHistoryLoading());

    try {
      final history = await paymentRepository.getPaymentHistoryBySantri(santriId, null);
      emit(SantriPaymentHistoryLoaded(history));
    } catch (e) {
      emit(SantriPaymentHistoryError(e.toString()));
    }
  }

  void reset() {
    emit(SantriPaymentHistoryInitial());
  }
}
