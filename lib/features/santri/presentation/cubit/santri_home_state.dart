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
  final List<MonthlyReport> monthlyReports;

  /// Saudara (akun lain dalam satu keluarga) untuk fitur ganti akun di home.
  final List<SantriDetail> familyMembers;

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
    this.monthlyReports = const [],
    this.familyMembers = const [],
  });

  /// Nama pembimbing lengkap dengan gelar, mis. "Ustadz Fulan".
  String? get pembimbingDisplayName {
    final name = pembimbingName?.trim();
    if (name == null || name.isEmpty) return null;
    final title = switch (pembimbingGender?.trim().toUpperCase()) {
      'L' => 'Ustadz',
      'P' => 'Ustadzah',
      _ => '',
    };
    return title.isEmpty ? name : '$title $name';
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
    List<MonthlyReport>? monthlyReports,
    List<SantriDetail>? familyMembers,
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
      monthlyReports: monthlyReports ?? this.monthlyReports,
      familyMembers: familyMembers ?? this.familyMembers,
    );
  }
}
