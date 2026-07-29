import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/entities/sunday_fajr_participant.dart';

enum SundayFajrSantriStatus { initial, loading, loaded, failure }

class SundayFajrSantriState {
  const SundayFajrSantriState({
    this.status = SundayFajrSantriStatus.initial,
    this.history = const [],
    this.errorMessage,
  });

  final SundayFajrSantriStatus status;
  final List<SundayFajrParticipant> history;
  final String? errorMessage;

  SundayFajrParticipant? get latest => history.firstOrNull;
}
