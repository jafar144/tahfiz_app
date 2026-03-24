
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_detail.dart';
import 'package:khoirunnasyien/features/asatidz/domain/entities/santri_setoran.dart';
import 'package:khoirunnasyien/features/payment/domain/entities/payment_entity.dart';

enum SantriHomeStatus { initial, loading, success, failure }

class SantriHomeState {
  final SantriHomeStatus status;
  final String? message;
  final SantriDetail? santri;
  final int overdueMonthsCount;
  final List<PaymentEntity> paymentHistory;
  final SantriSetoran? latestSetoran;
  final String? pembimbingName;
  final String? pembimbingPhone;

  const SantriHomeState({
    this.status = SantriHomeStatus.initial,
    this.message,
    this.santri,
    this.overdueMonthsCount = 0,
    this.paymentHistory = const [],
    this.latestSetoran,
    this.pembimbingName,
    this.pembimbingPhone,
  });

  SantriHomeState copyWith({
    SantriHomeStatus? status,
    String? message,
    SantriDetail? santri,
    int? overdueMonthsCount,
    List<PaymentEntity>? paymentHistory,
    SantriSetoran? latestSetoran,
    String? pembimbingName,
    String? pembimbingPhone,
  }) {
    return SantriHomeState(
      status: status ?? this.status,
      message: message ?? this.message,
      santri: santri ?? this.santri,
      overdueMonthsCount: overdueMonthsCount ?? this.overdueMonthsCount,
      paymentHistory: paymentHistory ?? this.paymentHistory,
      latestSetoran: latestSetoran ?? this.latestSetoran,
      pembimbingName: pembimbingName ?? this.pembimbingName,
      pembimbingPhone: pembimbingPhone ?? this.pembimbingPhone,
    );
  }
}
