enum SundayFajrAttendanceStatus {
  hadir('hadir', 'Hadir'),
  izin('izin', 'Izin'),
  alpha('alpha', 'Alpha');

  const SundayFajrAttendanceStatus(this.value, this.label);

  final String value;
  final String label;

  static SundayFajrAttendanceStatus fromValue(String? value) {
    return SundayFajrAttendanceStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => SundayFajrAttendanceStatus.alpha,
    );
  }
}
