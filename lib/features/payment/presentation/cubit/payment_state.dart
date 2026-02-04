import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/payment/domain/entities/payment_entity.dart';

sealed class PaymentState {}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {}

class PaymentLoaded extends PaymentState {
  final int paidCount;
  final int unpaidCount;
  final List<SantriEntity> paidStudents;
  final List<SantriEntity> unpaidStudents;
  final List<PaymentEntity> recentTransactions;
  final DateTime selectedDate;

  PaymentLoaded({
    required this.paidCount,
    required this.unpaidCount,
    required this.paidStudents,
    required this.unpaidStudents,
    required this.recentTransactions,
    required this.selectedDate,
  });
}

class PaymentError extends PaymentState {
  final String message;

  PaymentError(this.message);
}
