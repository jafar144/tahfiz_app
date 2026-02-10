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

  const AsatidzDashboardLoaded({
    required this.totalSantri,
    this.activeHalaqah,
    this.upcomingHalaqahs = const [],
  });

  AsatidzDashboardLoaded copyWith({
    int? totalSantri,
    ActiveHalaqah? activeHalaqah,
    List<dynamic>? upcomingHalaqahs,
  }) {
    return AsatidzDashboardLoaded(
      totalSantri: totalSantri ?? this.totalSantri,
      activeHalaqah: activeHalaqah ?? this.activeHalaqah,
      upcomingHalaqahs: upcomingHalaqahs ?? this.upcomingHalaqahs,
    );
  }
}

class AsatidzDashboardError extends AsatidzDashboardState {
  final String message;
  const AsatidzDashboardError(this.message);
}
