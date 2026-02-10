import 'package:khoirunnasyien/features/management_schedule/domain/entities/halaqah.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/program_schedule.dart';

class ActiveHalaqah {
  final Halaqah halaqah;
  final ProgramSchedule schedule;
  final DateTime sessionStart;
  final DateTime sessionEnd;
  final bool isAsatidzCheckedIn;

  ActiveHalaqah({
    required this.halaqah,
    required this.schedule,
    required this.sessionStart,
    required this.sessionEnd,
    this.isAsatidzCheckedIn = false,
  });

  bool get isWithinActiveWindow {
    final now = DateTime.now();
    return now.isAfter(sessionStart) && now.isBefore(sessionEnd);
  }

  String get timeRemaining {
    final now = DateTime.now();
    if (now.isBefore(sessionStart)) {
      final diff = sessionStart.difference(now);
      return 'Dimulai dalam ${diff.inMinutes} menit';
    } else if (now.isAfter(sessionEnd)) {
      return 'Sesi telah berakhir';
    } else {
      final diff = sessionEnd.difference(now);
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      if (hours > 0) {
        return 'Berakhir dalam $hours jam $minutes menit';
      }
      return 'Berakhir dalam $minutes menit';
    }
  }
}
