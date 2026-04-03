import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:khoirunnasyien/core/constants/app_constants.dart';
import 'package:khoirunnasyien/features/asatidz/domain/entities/active_halaqah.dart';
import 'package:khoirunnasyien/features/asatidz/domain/entities/meeting_member.dart';
import 'package:khoirunnasyien/features/asatidz/domain/repositories/asatidz_repository.dart';
import 'package:khoirunnasyien/features/asatidz/presentation/cubit/asatidz_dashboard_state.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/halaqah.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/repositories/schedule_repository.dart';
import 'package:khoirunnasyien/core/utils/error_handler.dart';

class AsatidzDashboardCubit extends Cubit<AsatidzDashboardState> {
  final AsatidzRepository asatidzRepository;
  final ScheduleRepository scheduleRepository;
  final String asatidzId;

  AsatidzDashboardCubit({
    required this.asatidzRepository,
    required this.scheduleRepository,
    required this.asatidzId,
  }) : super(AsatidzDashboardInitial());

  Future<void> loadDashboard() async {
    emit(AsatidzDashboardLoading());

    try {
      final halaqahsResult = await scheduleRepository.getHalaqahsByTeacher(asatidzId);
      
      final halaqahs = halaqahsResult.fold(
        ifLeft: (_) => <Halaqah>[],
        ifRight: (h) => h,
      );

      final totalSantri = halaqahs.fold<int>(
        0,
        (sum, halaqah) => sum + halaqah.santriCount,
      );

      final activeHalaqah = await _findActiveHalaqah(halaqahs);
      
      bool hasAttendedToday = false;
      if (activeHalaqah != null) {
        hasAttendedToday = await _checkAsatidzAttendance(
          activeHalaqah.halaqah.id,
          activeHalaqah.schedule.id,
          DateTime.now(),
        );
      }

      emit(AsatidzDashboardLoaded(
        totalSantri: totalSantri,
        activeHalaqah: activeHalaqah,
        hasAttendedToday: hasAttendedToday,
      ));
    } catch (e) {
      emit(AsatidzDashboardError(ErrorHandler.getMessage(e)));
    }
  }

  Future<ActiveHalaqah?> _findActiveHalaqah(List<Halaqah> halaqahs) async {
    final now = DateTime.now();
    final currentDay = now.weekday;

    for (final halaqah in halaqahs) {
      if (halaqah.status != 'Active') continue;

      for (final scheduleId in halaqah.scheduleIds) {
        final scheduleResult = await scheduleRepository.getScheduleById(scheduleId);
        
        final schedule = scheduleResult.fold(
          ifLeft: (_) => null,
          ifRight: (s) => s,
        );

        if (schedule == null || schedule.day != currentDay) continue;

        final sessionStart = _parseTimeToDateTime(schedule.startTime).subtract(const Duration(minutes: AppConstants.sessionBufferMinutes));
        final sessionEnd = _parseTimeToDateTime(schedule.endTime).add(const Duration(minutes: AppConstants.sessionBufferMinutes));

        if (now.isAfter(sessionStart) && now.isBefore(sessionEnd)) {
          final isCheckedIn = await _checkAsatidzAttendance(halaqah.id, scheduleId, now);
          
          return ActiveHalaqah(
            halaqah: halaqah,
            schedule: schedule,
            sessionStart: sessionStart,
            sessionEnd: sessionEnd,
            isAsatidzCheckedIn: isCheckedIn,
          );
        }
      }
    }

    return null;
  }

  DateTime _parseTimeToDateTime(String time) {
    final parts = time.split(':');
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  Future<bool> _checkAsatidzAttendance(String halaqahId, String scheduleId, DateTime date) async {
    final result = await asatidzRepository.checkAttendance(
      asatidzId: asatidzId,
      halaqahId: halaqahId,
      scheduleId: scheduleId,
      date: date,
    );

    return result.fold(
      ifLeft: (_) => false,
      ifRight: (exists) => exists,
    );
  }

  Future<void> checkInAsatidz(ActiveHalaqah activeHalaqah) async {
    if (state is! AsatidzDashboardLoaded) return;

    final currentState = state as AsatidzDashboardLoaded;
    emit(currentState.copyWith(isCheckingIn: true));

    final result = await asatidzRepository.createAttendance(
      asatidzId: asatidzId,
      halaqahId: activeHalaqah.halaqah.id,
      halaqahName: activeHalaqah.halaqah.name,
      scheduleId: activeHalaqah.schedule.id,
      date: DateTime.now(),
    );

    result.fold(
      ifLeft: (failure) {
        emit(currentState.copyWith(isCheckingIn: false));
        emit(AsatidzDashboardError(failure.message));
        emit(currentState.copyWith(isCheckingIn: false));
      },
      ifRight: (_) {
        final updatedActiveHalaqah = ActiveHalaqah(
          halaqah: activeHalaqah.halaqah,
          schedule: activeHalaqah.schedule,
          sessionStart: activeHalaqah.sessionStart,
          sessionEnd: activeHalaqah.sessionEnd,
          isAsatidzCheckedIn: true,
        );

        emit(currentState.copyWith(
          activeHalaqah: updatedActiveHalaqah,
          hasAttendedToday: true,
          isCheckingIn: false,
        ));
      },
    );
  }

  Future<Map<String, dynamic>?> getGuestSantriParams(ActiveHalaqah activeHalaqah) async {
    if (state is! AsatidzDashboardLoaded) return null;
    final currentState = state as AsatidzDashboardLoaded;
    emit(currentState.copyWith(isCheckingIn: true));

    try {
      final DateFormat formatter = DateFormat('yyyy-MM-dd');
      final String dateStr = formatter.format(DateTime.now());

      final meetingResult = await asatidzRepository.getMeeting(
        halaqahId: activeHalaqah.halaqah.id,
        scheduleId: activeHalaqah.schedule.id,
        date: dateStr,
      );

      return await meetingResult.fold(
        ifLeft: (l) {
          emit(currentState.copyWith(isCheckingIn: false));
          emit(AsatidzDashboardError(l.message));
          emit(currentState.copyWith(isCheckingIn: false));
          return null;
        },
        ifRight: (meeting) async {
          if (meeting == null) {
            emit(currentState.copyWith(isCheckingIn: false));
            emit(const AsatidzDashboardError("Meeting belum dibuat. Silakan absen terlebih dahulu."));
            emit(currentState.copyWith(isCheckingIn: false));
            return null;
          }

          final membersResult = await asatidzRepository.getMeetingMembers(meeting.id);
          final disabledIds = membersResult.fold(
            ifLeft: (_) => <String>[],
            ifRight: (members) => members.map((m) => m.santriId).toList(),
          );

          final programResult = await scheduleRepository.getProgramById(activeHalaqah.halaqah.programId);
          final gender = programResult.fold(
            ifLeft: (_) => null, 
            ifRight: (p) => p.gender
          );

          emit(currentState.copyWith(isCheckingIn: false));

          return {
            'meetingId': meeting.id,
            'disabledIds': disabledIds,
            'gender': gender,
          };
        },
      );
    } catch (e) {
      emit(currentState.copyWith(isCheckingIn: false));
      emit(AsatidzDashboardError("Gagal memuat peserta meeting."));
      emit(currentState.copyWith(isCheckingIn: false));
      return null;
    }
  }

  Future<void> addGuestSantri(String meetingId, SantriEntity santri) async {
    if (state is! AsatidzDashboardLoaded) return;
    final currentState = state as AsatidzDashboardLoaded;
    emit(currentState.copyWith(isCheckingIn: true));

    try {
      final newMember = MeetingMember(
        id: santri.id,
        santriId: santri.id,
        santriName: santri.name,
        santriNis: santri.nis,
        halaqahAsalId: santri.halaqahId ?? '',
        attendanceStatus: 'hadir',
        createdAt: DateTime.now(),
      );

      final saveResult = await asatidzRepository.saveMeetingMembers(
        meetingId: meetingId,
        members: [newMember],
      );

      saveResult.fold(
        ifLeft: (l) {
          emit(currentState.copyWith(isCheckingIn: false));
          emit(AsatidzDashboardError(l.message));
          emit(currentState.copyWith(isCheckingIn: false));
        },
        ifRight: (r) {
           emit(currentState.copyWith(isCheckingIn: false));
           emit(const AsatidzDashboardSuccess("Santri berhasil ditambahkan ke sesi ini."));
           emit(currentState.copyWith(isCheckingIn: false));
        },
      );
    } catch (e) {
      emit(currentState.copyWith(isCheckingIn: false));
      emit(AsatidzDashboardError("Gagal menambahkan santri."));
      emit(currentState.copyWith(isCheckingIn: false));
    }
  }
}
