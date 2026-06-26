part of 'input_payment_cubit.dart';

sealed class InputPaymentState {}

final class InputPaymentInitial extends InputPaymentState {}

final class InputPaymentLoading extends InputPaymentState {}

final class InputPaymentSuccess extends InputPaymentState {
  /// Jumlah pembayaran (bulan) yang berhasil disimpan.
  final int count;

  InputPaymentSuccess({this.count = 1});
}

final class InputPaymentAlreadyExists extends InputPaymentState {
  final PaymentEntity payment;

  InputPaymentAlreadyExists(this.payment);
}

final class InputPaymentFailure extends InputPaymentState {
  final String message;

  InputPaymentFailure(this.message);
}
