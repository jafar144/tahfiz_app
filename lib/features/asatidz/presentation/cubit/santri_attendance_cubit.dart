import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/features/asatidz/domain/entities/active_halaqah.dart';
import 'package:khoirunnasyien/features/asatidz/domain/entities/santri_attendance.dart';
import 'package:khoirunnasyien/features/asatidz/domain/repositories/asatidz_repository.dart';
import 'package:khoirunnasyien/features/asatidz/presentation/cubit/santri_attendance_state.dart';

class SantriAttendanceCubit extends Cubit<SantriAttendanceState> {
  final AsatidzRepository repository;
  final ActiveHalaqah activeHalaqah;
  final String asatidzId;
  final String asatidzName;

  SantriAttendanceCubit({
    required this.repository,
    required this.activeHalaqah,
    required this.asatidzId,
    required this.asatidzName,
  }) : super(SantriAttendanceInitial());

  Future<void> init() async {
    emit(SantriAttendanceLoading());
    
    final result = await repository.getSantriAttendance(
      halaqahId: activeHalaqah.halaqah.id,
      date: DateTime.now(),
    );

    result.fold(
      ifLeft: (failure) => _loadDefaultAttendance(), // Fallback if error
      ifRight: (attendance) {
        if (attendance != null) {
          final attendanceMap = <String, String>{};
          
          // Map existing attendance
          for (final item in attendance.attendanceList) {
            attendanceMap[item.santriId] = item.status;
          }
          
          // Ensure all current santris are included (in case new ones added)
          for (final santri in activeHalaqah.halaqah.santris) {
            if (!attendanceMap.containsKey(santri.id)) {
              attendanceMap[santri.id] = 'hadir';
            }
          }
          
          emit(SantriAttendanceLoaded(
            attendanceMap: attendanceMap,
            isExistingData: true,
            lastUpdated: attendance.updatedAt,
          ));
        } else {
          _loadDefaultAttendance();
        }
      },
    );
  }

  void _loadDefaultAttendance() {
    final attendanceMap = <String, String>{};
    
    for (final santri in activeHalaqah.halaqah.santris) {
      attendanceMap[santri.id] = 'hadir';
    }

    emit(SantriAttendanceLoaded(attendanceMap: attendanceMap));
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

    final attendanceList = <SantriAttendanceItem>[];
    for (final entry in currentState.attendanceMap.entries) {
      final santri = activeHalaqah.halaqah.santris
          .where((s) => s.id == entry.key)
          .firstOrNull;
      if (santri == null) continue;

      attendanceList.add(SantriAttendanceItem(
        santriId: entry.key,
        santriName: santri.name,
        status: entry.value,
        notes: '',
      ));
    }

    final result = await repository.createSantriAttendance(
      halaqahId: activeHalaqah.halaqah.id,
      halaqahName: activeHalaqah.halaqah.name,
      scheduleId: activeHalaqah.schedule.id,
      date: DateTime.now(),
      asatidzId: asatidzId,
      asatidzName: asatidzName,
      attendanceList: attendanceList,
    );

    result.fold(
      ifLeft: (failure) {
        emit(SantriAttendanceError(failure.message));
        emit(currentState.copyWith(isSubmitting: false));
      },
      ifRight: (_) {
        emit(SantriAttendanceSuccess());
      },
    );
  }
}
