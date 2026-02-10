abstract class SantriAttendanceState {
  const SantriAttendanceState();
}

class SantriAttendanceInitial extends SantriAttendanceState {}

class SantriAttendanceLoading extends SantriAttendanceState {}

class SantriAttendanceLoaded extends SantriAttendanceState {
  final Map<String, String> attendanceMap;
  final bool isSubmitting;

  const SantriAttendanceLoaded({
    required this.attendanceMap,
    this.isSubmitting = false,
  });

  SantriAttendanceLoaded copyWith({
    Map<String, String>? attendanceMap,
    bool? isSubmitting,
  }) {
    return SantriAttendanceLoaded(
      attendanceMap: attendanceMap ?? this.attendanceMap,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class SantriAttendanceSuccess extends SantriAttendanceState {}

class SantriAttendanceError extends SantriAttendanceState {
  final String message;
  const SantriAttendanceError(this.message);
}
