import 'package:equatable/equatable.dart';
import 'package:khoirunnasyien/features/payment/domain/entities/payment_entity.dart';

sealed class SantriPaymentHistoryState extends Equatable {
  const SantriPaymentHistoryState();

  @override
  List<Object> get props => [];
}

final class SantriPaymentHistoryInitial extends SantriPaymentHistoryState {}

final class SantriPaymentHistoryLoading extends SantriPaymentHistoryState {}

final class SantriPaymentHistoryLoaded extends SantriPaymentHistoryState {
  final List<PaymentEntity> payments;

  const SantriPaymentHistoryLoaded(this.payments);

  @override
  List<Object> get props => [payments];
}

final class SantriPaymentHistoryError extends SantriPaymentHistoryState {
  final String message;

  const SantriPaymentHistoryError(this.message);

  @override
  List<Object> get props => [message];
}
