class SundayFajrAttendancePolicy {
  SundayFajrAttendancePolicy._();

  static const wibOffset = Duration(hours: 7);
  static const maxParticipantsPerSave = 497;

  /// A date-only UTC value whose fields represent a WIB calendar date.
  ///
  /// This intentionally does not represent midnight as an instant. Keeping a
  /// UTC date sentinel prevents the selected Sunday from shifting when a user
  /// opens the app in another device timezone.
  static DateTime wibCalendarDate(DateTime instant) {
    final wib = instant.toUtc().add(wibOffset);
    return DateTime.utc(wib.year, wib.month, wib.day);
  }

  static DateTime canonicalDate(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day);

  static DateTime latestSunday({DateTime? now}) {
    final today = wibCalendarDate(now ?? DateTime.now());
    return today.subtract(Duration(days: today.weekday % DateTime.daysPerWeek));
  }

  static bool canCreate(DateTime date, {DateTime? now}) {
    final today = wibCalendarDate(now ?? DateTime.now());
    return today.weekday == DateTime.sunday && canonicalDate(date) == today;
  }

  static bool isSunday(DateTime date) =>
      canonicalDate(date).weekday == DateTime.sunday;

  static bool isEditable(DateTime date, {DateTime? now}) {
    return canCreate(date, now: now);
  }

  static bool isRosterSizeSupported(int participantCount) =>
      participantCount >= 0 && participantCount <= maxParticipantsPerSave;

  static String weekKey(DateTime date) {
    final value = canonicalDate(date);
    String two(int number) => number.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)}';
  }

  static DateTime? tryParseWeekKey(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) return null;
    final year = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final day = int.tryParse(match.group(3)!);
    if (year == null || month == null || day == null) return null;

    final parsed = DateTime.utc(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      return null;
    }
    return parsed;
  }

  static DateTime instantToWib(DateTime instant) =>
      instant.toUtc().add(wibOffset);
}
