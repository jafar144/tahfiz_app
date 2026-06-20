import 'package:khoirunnasyien/features/management_schedule/domain/entities/halaqah.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/program_schedule.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_entity.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';

abstract class HalaqahDetailState {
  const HalaqahDetailState();
}

class HalaqahDetailInitial extends HalaqahDetailState {
  final Halaqah halaqah;
  const HalaqahDetailInitial(this.halaqah);
}

class HalaqahDetailLoading extends HalaqahDetailState {}

class HalaqahDetailLoaded extends HalaqahDetailState {
  final Halaqah halaqah;
  final List<ProgramSchedule> schedules;
  final List<AsatidzEntity> asatidzList;
  final List<SantriEntity> santriList;
  final List<String> unavailableTeacherIds;
  final List<String> unavailableSantriIds;

  /// Gender halaqah ('L'/'P'), diturunkan dari program/sesi. Dipakai untuk
  /// memfilter pilihan santri agar sesuai jenis kelamin halaqah.
  final String gender;

  final bool isSubmitting;

  const HalaqahDetailLoaded({
    required this.halaqah,
    this.schedules = const [],
    this.asatidzList = const [],
    this.santriList = const [],
    this.unavailableTeacherIds = const [],
    this.unavailableSantriIds = const [],
    this.gender = '',
    this.isSubmitting = false,
  });

  HalaqahDetailLoaded copyWith({
    Halaqah? halaqah,
    List<ProgramSchedule>? schedules,
    List<AsatidzEntity>? asatidzList,
    List<SantriEntity>? santriList,
    List<String>? unavailableTeacherIds,
    List<String>? unavailableSantriIds,
    String? gender,
    bool? isSubmitting,
  }) {
    return HalaqahDetailLoaded(
      halaqah: halaqah ?? this.halaqah,
      schedules: schedules ?? this.schedules,
      asatidzList: asatidzList ?? this.asatidzList,
      santriList: santriList ?? this.santriList,
      unavailableTeacherIds: unavailableTeacherIds ?? this.unavailableTeacherIds,
      unavailableSantriIds: unavailableSantriIds ?? this.unavailableSantriIds,
      gender: gender ?? this.gender,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class HalaqahDetailUpdating extends HalaqahDetailState {}

class HalaqahDetailSuccess extends HalaqahDetailState {}

class HalaqahDetailDeleting extends HalaqahDetailState {}

class HalaqahDetailDeleted extends HalaqahDetailState {}

class HalaqahDetailError extends HalaqahDetailState {
  final String message;
  const HalaqahDetailError(this.message);
}
