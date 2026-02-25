import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';

abstract class SantriAttendanceState {
  const SantriAttendanceState();
}

class SantriAttendanceInitial extends SantriAttendanceState {}

class SantriAttendanceLoading extends SantriAttendanceState {}

class SantriAttendanceLoaded extends SantriAttendanceState {
  final List<SantriEntity> santris;
  final Map<String, String> attendanceMap;
  final bool isSubmitting;
  final bool isExistingData;
  final DateTime? lastUpdated;

  const SantriAttendanceLoaded({
    required this.santris,
    required this.attendanceMap,
    this.isSubmitting = false,
    this.isExistingData = false,
    this.lastUpdated,
  });

  SantriAttendanceLoaded copyWith({
    List<SantriEntity>? santris,
    Map<String, String>? attendanceMap,
    bool? isSubmitting,
    bool? isExistingData,
    DateTime? lastUpdated,
  }) {
    return SantriAttendanceLoaded(
      santris: santris ?? this.santris,
      attendanceMap: attendanceMap ?? this.attendanceMap,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isExistingData: isExistingData ?? this.isExistingData,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class SantriAttendanceSuccess extends SantriAttendanceState {}

class SantriAttendanceError extends SantriAttendanceState {
  final String message;
  const SantriAttendanceError(this.message);
}
