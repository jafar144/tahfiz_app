import 'package:equatable/equatable.dart';
import 'package:khoirunnasyien/features/payment/domain/entities/payment_entity.dart';

abstract class AdminPaymentHistoryState extends Equatable {
  const AdminPaymentHistoryState();

  @override
  List<Object?> get props => [];
}

class AdminPaymentHistoryInitial extends AdminPaymentHistoryState {}

class AdminPaymentHistoryLoading extends AdminPaymentHistoryState {}

class AdminPaymentHistoryLoaded extends AdminPaymentHistoryState {
  final List<PaymentEntity> payments;
  final bool hasReachedMax;
  final bool isFetchingMore;

  const AdminPaymentHistoryLoaded({
    required this.payments,
    this.hasReachedMax = false,
    this.isFetchingMore = false,
  });

  AdminPaymentHistoryLoaded copyWith({
    List<PaymentEntity>? payments,
    bool? hasReachedMax,
    bool? isFetchingMore,
  }) {
    return AdminPaymentHistoryLoaded(
      payments: payments ?? this.payments,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
    );
  }

  @override
  List<Object?> get props => [payments, hasReachedMax, isFetchingMore];
}

class AdminPaymentHistoryError extends AdminPaymentHistoryState {
  final String message;

  const AdminPaymentHistoryError(this.message);

  @override
  List<Object?> get props => [message];
}
