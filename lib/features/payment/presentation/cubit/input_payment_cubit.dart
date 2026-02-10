import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/features/payment/domain/entities/payment_entity.dart';
import 'package:khoirunnasyien/features/payment/domain/repositories/payment_repository.dart';

part 'input_payment_state.dart';

class InputPaymentCubit extends Cubit<InputPaymentState> {
  final PaymentRepository paymentRepository;

  InputPaymentCubit(this.paymentRepository) : super(InputPaymentInitial());

  Future<void> validateAndSubmitPayment({
    required String santriId,
    required String month,
    required String year,
    required int total,
    required String createdBy,
    required DateTime date,
  }) async {
    emit(InputPaymentLoading());

    try {
      final existingPayments = await paymentRepository.getPaymentBySantri(
        santriId,
        month,
        year,
      );

      if (existingPayments.isNotEmpty) {
        emit(InputPaymentAlreadyExists(existingPayments.first));
        return;
      }

      final payment = PaymentEntity(
        id: '',
        santriId: santriId,
        bulan: month,
        tahun: year,
        total: total,
        method: 'Manual',
        createdAt: date,
        createdBy: createdBy,
      );

      await paymentRepository.addPayment(payment);
      emit(InputPaymentSuccess());
    } catch (e) {
      emit(InputPaymentFailure(e.toString()));
    }
  }

  void reset() {
    emit(InputPaymentInitial());
  }
}
