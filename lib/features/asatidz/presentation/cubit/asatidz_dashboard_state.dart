import 'package:khoirunnasyien/features/asatidz/domain/entities/active_halaqah.dart';

abstract class AsatidzDashboardState {
  const AsatidzDashboardState();
}

class AsatidzDashboardInitial extends AsatidzDashboardState {}

class AsatidzDashboardLoading extends AsatidzDashboardState {}

class AsatidzDashboardLoaded extends AsatidzDashboardState {
  final int totalSantri;
  final ActiveHalaqah? activeHalaqah;
  final List<dynamic> upcomingHalaqahs;
  final bool hasAttendedToday;
  final bool isCheckingIn;

  const AsatidzDashboardLoaded({
    required this.totalSantri,
    this.activeHalaqah,
    this.upcomingHalaqahs = const [],
    this.hasAttendedToday = false,
    this.isCheckingIn = false,
  });

  AsatidzDashboardLoaded copyWith({
    int? totalSantri,
    ActiveHalaqah? activeHalaqah,
    List<dynamic>? upcomingHalaqahs,
    bool? hasAttendedToday,
    bool? isCheckingIn,
  }) {
    return AsatidzDashboardLoaded(
      totalSantri: totalSantri ?? this.totalSantri,
      activeHalaqah: activeHalaqah ?? this.activeHalaqah,
      upcomingHalaqahs: upcomingHalaqahs ?? this.upcomingHalaqahs,
      hasAttendedToday: hasAttendedToday ?? this.hasAttendedToday,
      isCheckingIn: isCheckingIn ?? this.isCheckingIn,
    );
  }
}

class AsatidzDashboardError extends AsatidzDashboardState {
  final String message;
  const AsatidzDashboardError(this.message);
}

class AsatidzDashboardSuccess extends AsatidzDashboardState {
  final String message;
  const AsatidzDashboardSuccess(this.message);
}
