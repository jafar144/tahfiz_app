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

  void init() {
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

    final attendanceList = currentState.attendanceMap.entries.map((entry) {
      final santri = activeHalaqah.halaqah.santris.firstWhere(
        (s) => s.id == entry.key,
      );
      
      return SantriAttendanceItem(
        santriId: entry.key,
        santriName: santri.name,
        status: entry.value,
        notes: '',
      );
    }).toList();

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
