import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/entities/sunday_fajr_attendance.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/entities/sunday_fajr_attendance_status.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/entities/sunday_fajr_participant.dart';

enum SundayFajrEditorStatus { initial, loading, loaded, saving, saved, failure }

class SundayFajrEditorState {
  const SundayFajrEditorState({
    this.status = SundayFajrEditorStatus.initial,
    required this.eventDate,
    this.attendance,
    this.participants = const [],
    this.isEditable = false,
    this.errorMessage,
    this.hasRevisionConflict = false,
  });

  final SundayFajrEditorStatus status;
  final DateTime eventDate;
  final SundayFajrAttendance? attendance;
  final List<SundayFajrParticipantDraft> participants;
  final bool isEditable;
  final String? errorMessage;
  final bool hasRevisionConflict;

  bool get isExisting => attendance != null;
  bool get isBusy =>
      status == SundayFajrEditorStatus.loading ||
      status == SundayFajrEditorStatus.saving;
  bool get allComplete =>
      participants.isNotEmpty && participants.every((item) => item.isComplete);
  bool get canSave => isEditable && allComplete && !isBusy;
  int get totalHadir => participants
      .where((item) => item.status == SundayFajrAttendanceStatus.hadir)
      .length;
  int get totalIzin => participants
      .where((item) => item.status == SundayFajrAttendanceStatus.izin)
      .length;
  int get totalAlpha => participants
      .where((item) => item.status == SundayFajrAttendanceStatus.alpha)
      .length;
  int get totalUnmarked =>
      participants.where((item) => item.status == null).length;

  SundayFajrEditorState copyWith({
    SundayFajrEditorStatus? status,
    SundayFajrAttendance? attendance,
    List<SundayFajrParticipantDraft>? participants,
    bool? isEditable,
    String? errorMessage,
    bool? hasRevisionConflict,
    bool clearError = false,
  }) {
    return SundayFajrEditorState(
      status: status ?? this.status,
      eventDate: eventDate,
      attendance: attendance ?? this.attendance,
      participants: participants ?? this.participants,
      isEditable: isEditable ?? this.isEditable,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      hasRevisionConflict: clearError
          ? false
          : hasRevisionConflict ?? this.hasRevisionConflict,
    );
  }
}
