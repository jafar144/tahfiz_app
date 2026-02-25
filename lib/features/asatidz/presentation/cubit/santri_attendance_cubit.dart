import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:khoirunnasyien/features/asatidz/domain/entities/active_halaqah.dart';
import 'package:khoirunnasyien/features/asatidz/domain/entities/meeting_member.dart';
import 'package:khoirunnasyien/features/asatidz/domain/repositories/asatidz_repository.dart';
import 'package:khoirunnasyien/features/asatidz/presentation/cubit/santri_attendance_state.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/repositories/schedule_repository.dart';

class SantriAttendanceCubit extends Cubit<SantriAttendanceState> {
  final AsatidzRepository repository;
  final ScheduleRepository scheduleRepository;
  final ActiveHalaqah activeHalaqah;
  final String asatidzId;
  final String asatidzName;

  SantriAttendanceCubit({
    required this.repository,
    required this.scheduleRepository,
    required this.activeHalaqah,
    required this.asatidzId,
    required this.asatidzName,
  }) : super(SantriAttendanceInitial());

  Future<void> init() async {
    emit(SantriAttendanceLoading());

    final santrisResult = await scheduleRepository.getSantrisByHalaqahId(activeHalaqah.halaqah.id);
    final santris = santrisResult.fold(
      ifLeft: (_) => <SantriEntity>[],
      ifRight: (s) => s,
    );

    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final String dateStr = formatter.format(DateTime.now());

    final meetingResult = await repository.getMeeting(
      halaqahId: activeHalaqah.halaqah.id,
      scheduleId: activeHalaqah.schedule.id,
      date: dateStr,
    );

    await meetingResult.fold(
      ifLeft: (_) async => _loadDefaultAttendance(santris),
      ifRight: (meeting) async {
        if (meeting != null) {
          final membersResult = await repository.getMeetingMembers(meeting.id);
          
          membersResult.fold(
            ifLeft: (_) => _loadDefaultAttendance(santris),
            ifRight: (members) {
              if (members.isNotEmpty) {
                final attendanceMap = <String, String>{};
                for (final item in members) {
                  attendanceMap[item.santriId] = item.attendanceStatus;
                }

                for (final santri in santris) {
                  if (!attendanceMap.containsKey(santri.id)) {
                    attendanceMap[santri.id] = 'hadir';
                  }
                }

                emit(SantriAttendanceLoaded(
                  santris: santris,
                  attendanceMap: attendanceMap,
                  isExistingData: true,
                  lastUpdated: members.first.createdAt,
                ));
              } else {
                _loadDefaultAttendance(santris);
              }
            }
          );
        } else {
          _loadDefaultAttendance(santris);
        }
      },
    );
  }

  void _loadDefaultAttendance(List<SantriEntity> santris) {
    final attendanceMap = <String, String>{};
    for (final santri in santris) {
      attendanceMap[santri.id] = 'hadir';
    }
    emit(SantriAttendanceLoaded(santris: santris, attendanceMap: attendanceMap));
  }

  void updateAttendance(String santriId, String status) {
    if (state is! SantriAttendanceLoaded) return;

    final currentState = state as SantriAttendanceLoaded;
    final updatedMap = Map<String, String>.from(currentState.attendanceMap);
    updatedMap[santriId] = status;

    emit(currentState.copyWith(attendanceMap: updatedMap));
  }

  Future<void> submitAttendance() async {
    if (state is! SantriAttendanceLoaded) return;

    final currentState = state as SantriAttendanceLoaded;
    emit(currentState.copyWith(isSubmitting: true));

    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final String dateStr = formatter.format(DateTime.now());

    final meetingResult = await repository.getMeeting(
      halaqahId: activeHalaqah.halaqah.id,
      scheduleId: activeHalaqah.schedule.id,
      date: dateStr,
    );

    await meetingResult.fold(
      ifLeft: (failure) async {
        emit(SantriAttendanceError(failure.message));
        emit(currentState.copyWith(isSubmitting: false));
      },
      ifRight: (meeting) async {
        if (meeting == null) {
          emit(SantriAttendanceError('Meeting tidak ditemukan. Harap pastikan Asatidz sudah absen terlebih dahulu.'));
          emit(currentState.copyWith(isSubmitting: false));
          return;
        }

        final membersList = <MeetingMember>[];
        for (final entry in currentState.attendanceMap.entries) {
          final santri = currentState.santris.where((s) => s.id == entry.key).firstOrNull;
          if (santri == null) continue;

          membersList.add(MeetingMember(
            id: entry.key, // Use Santri ID as document ID for members
            santriId: entry.key,
            santriName: santri.name,
            halaqahAsalId: santri.halaqahId ?? '',
            attendanceStatus: entry.value,
            createdAt: DateTime.now(),
          ));
        }

        final saveResult = await repository.saveMeetingMembers(
          meetingId: meeting.id,
          members: membersList,
        );

        saveResult.fold(
          ifLeft: (failure) {
            emit(SantriAttendanceError(failure.message));
            emit(currentState.copyWith(isSubmitting: false));
          },
          ifRight: (_) {
            emit(SantriAttendanceSuccess());
          },
        );
      },
    );
  }
}
