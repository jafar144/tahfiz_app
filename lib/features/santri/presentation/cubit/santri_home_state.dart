
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_detail.dart';
import 'package:khoirunnasyien/features/asatidz/domain/entities/santri_setoran.dart';
import 'package:khoirunnasyien/features/payment/domain/entities/payment_entity.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/entities/monthly_report.dart';

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

  /// Gender pembimbing ('L' / 'P') untuk gelar Ustadz/Ustadzah.
  final String? pembimbingGender;
  final MonthlyReport? latestReport;

  const SantriHomeState({
    this.status = SantriHomeStatus.initial,
    this.message,
    this.santri,
    this.overdueMonthsCount = 0,
    this.paymentHistory = const [],
    this.latestSetoran,
    this.pembimbingName,
    this.pembimbingPhone,
    this.pembimbingGender,
    this.latestReport,
  });

  /// Nama pembimbing lengkap dengan gelar, mis. "Ustadz Fulan".
  String? get pembimbingDisplayName {
    if (pembimbingName == null) return null;
    final title = switch (pembimbingGender) {
      'L' => 'Ustadz',
      'P' => 'Ustadzah',
      _ => '',
    };
    return title.isEmpty ? pembimbingName : '$title $pembimbingName';
  }

  SantriHomeState copyWith({
    SantriHomeStatus? status,
    String? message,
    SantriDetail? santri,
    int? overdueMonthsCount,
    List<PaymentEntity>? paymentHistory,
    SantriSetoran? latestSetoran,
    String? pembimbingName,
    String? pembimbingPhone,
    String? pembimbingGender,
    MonthlyReport? latestReport,
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
      pembimbingGender: pembimbingGender ?? this.pembimbingGender,
      latestReport: latestReport ?? this.latestReport,
    );
  }
}
