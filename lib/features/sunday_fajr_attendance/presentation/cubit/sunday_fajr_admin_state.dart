import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/entities/sunday_fajr_attendance.dart';

enum SundayFajrAdminStatus { initial, loading, loaded, failure }

class SundayFajrAdminState {
  const SundayFajrAdminState({
    this.status = SundayFajrAdminStatus.initial,
    this.history = const [],
    this.errorMessage,
  });

  final SundayFajrAdminStatus status;
  final List<SundayFajrAttendance> history;
  final String? errorMessage;

  SundayFajrAdminState copyWith({
    SundayFajrAdminStatus? status,
    List<SundayFajrAttendance>? history,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SundayFajrAdminState(
      status: status ?? this.status,
      history: history ?? this.history,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
