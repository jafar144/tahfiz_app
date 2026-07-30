import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/core/utils/error_handler.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/entities/sunday_fajr_attendance_status.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/entities/sunday_fajr_participant.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/repositories/sunday_fajr_attendance_repository.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/domain/sunday_fajr_attendance_policy.dart';
import 'package:khoirunnasyien/features/sunday_fajr_attendance/presentation/cubit/sunday_fajr_editor_state.dart';

class SundayFajrEditorCubit extends Cubit<SundayFajrEditorState> {
  SundayFajrEditorCubit({
    required this.repository,
    required this.actorId,
    required DateTime eventDate,
    DateTime? now,
  }) : _now = now,
       super(
         SundayFajrEditorState(
           eventDate: SundayFajrAttendancePolicy.canonicalDate(eventDate),
         ),
       );

  final SundayFajrAttendanceRepository repository;
  final String actorId;
  final DateTime? _now;

  Future<void> load() async {
    emit(
      state.copyWith(status: SundayFajrEditorStatus.loading, clearError: true),
    );
    try {
      final weekKey = SundayFajrAttendancePolicy.weekKey(state.eventDate);
      final attendance = await repository.getAttendance(weekKey);
      final editable = attendance == null
          ? SundayFajrAttendancePolicy.canCreate(state.eventDate, now: _now)
          : SundayFajrAttendancePolicy.isEditable(state.eventDate, now: _now);

      final List<SundayFajrParticipantDraft> participants;
      if (attendance != null) {
        final stored = await repository.getParticipants(weekKey);
        participants = stored
            .map(
              (item) => SundayFajrParticipantDraft(
                santriId: item.santriId,
                santriName: item.santriName,
                santriNis: item.santriNis,
                kelas: item.kelas,
                status: item.status,
                izinReason: item.izinReason,
                createdAt: item.createdAt,
              ),
            )
            .toList();
      } else if (editable) {
        final eligible = await repository.getEligibleSantri();
        participants = eligible
            .map(
              (santri) => SundayFajrParticipantDraft(
                santriId: santri.id,
                santriName: santri.name,
                santriNis: santri.nis,
                kelas: santri.kelas,
              ),
            )
            .toList();
      } else {
        participants = const [];
      }

      if (isClosed) return;
      emit(
        SundayFajrEditorState(
          status: SundayFajrEditorStatus.loaded,
          eventDate: state.eventDate,
          attendance: attendance,
          participants: participants,
          isEditable: editable,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: SundayFajrEditorStatus.failure,
          errorMessage: ErrorHandler.getMessage(error),
        ),
      );
    }
  }

  void updateStatus(String santriId, SundayFajrAttendanceStatus status) {
    if (!state.isEditable || state.isBusy) return;
    final updated = state.participants.map((item) {
      if (item.santriId != santriId) return item;
      return item.copyWith(status: status, izinReason: '');
    }).toList();
    emit(state.copyWith(participants: updated, clearError: true));
  }

  Future<void> save() async {
    if (!state.canSave) return;
    final beforeSave = state;
    emit(
      state.copyWith(status: SundayFajrEditorStatus.saving, clearError: true),
    );
    try {
      final now = DateTime.now();
      final weekKey = SundayFajrAttendancePolicy.weekKey(state.eventDate);
      final participants = state.participants
          .map(
            (item) => SundayFajrParticipant(
              id: item.santriId,
              santriId: item.santriId,
              santriName: item.santriName,
              santriNis: item.santriNis,
              kelas: item.kelas,
              weekKey: weekKey,
              eventDate: state.eventDate,
              status: item.status!,
              izinReason: '',
              createdAt: item.createdAt ?? now,
              updatedAt: now,
            ),
          )
          .toList();

      final saved = await repository.saveAttendance(
        eventDate: state.eventDate,
        participants: participants,
        actorId: actorId,
        expectedRevision: state.attendance?.revision ?? 0,
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          status: SundayFajrEditorStatus.saved,
          attendance: saved,
          clearError: true,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        beforeSave.copyWith(
          status: SundayFajrEditorStatus.loaded,
          errorMessage: ErrorHandler.getMessage(error),
          hasRevisionConflict: error is SundayFajrRevisionConflictException,
        ),
      );
    }
  }
}
