import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/repository/asatidz_repository.dart';
import 'package:khoirunnasyien/features/management_santri/domain/repository/santri_repository.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/halaqah.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/program_schedule.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/repositories/schedule_repository.dart';
import 'package:khoirunnasyien/features/management_schedule/presentation/cubit/halaqah_detail_state.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/core/utils/error_handler.dart';

class HalaqahDetailCubit extends Cubit<HalaqahDetailState> {
  final ScheduleRepository scheduleRepository;
  final AsatidzRepository asatidzRepository;
  final SantriRepository santriRepository;

  HalaqahDetailCubit({
    required this.scheduleRepository,
    required this.asatidzRepository,
    required this.santriRepository,
    required Halaqah halaqah,
  }) : super(HalaqahDetailInitial(halaqah));

  Future<void> init() async {
    final currentState = state;
    Halaqah? currentHalaqah;

    if (currentState is HalaqahDetailInitial) {
      currentHalaqah = currentState.halaqah;
    } else if (currentState is HalaqahDetailLoaded) {
      currentHalaqah = currentState.halaqah;
    }

    if (currentHalaqah == null) {
      emit(const HalaqahDetailError("Data halaqah tidak ditemukan"));
      return;
    }

    emit(HalaqahDetailLoading());
    try {
      final schedulesResult = await scheduleRepository.getSchedules(programId: currentHalaqah.programId);
      final santrisResult = await scheduleRepository.getSantrisByHalaqahId(currentHalaqah.id);

      final schedules = schedulesResult.fold(
        ifLeft: (_) => <ProgramSchedule>[],
        ifRight: (s) => s,
      );

      final santris = santrisResult.fold(
        ifLeft: (_) => <SantriEntity>[],
        ifRight: (s) => s,
      );

      emit(HalaqahDetailLoaded(
        halaqah: currentHalaqah,
        schedules: schedules,
        santriList: santris,
      ));

      if (currentHalaqah.scheduleIds.isNotEmpty) {
        _checkAvailability(currentHalaqah.scheduleIds.first, currentHalaqah.id);
      }
    } catch (e) {
      emit(HalaqahDetailError(ErrorHandler.getMessage(e)));
    }
  }

  Future<void> _checkAvailability(String scheduleId, String currentHalaqahId) async {
    if (state is! HalaqahDetailLoaded) return;

    final result = await scheduleRepository.getHalaqahsBySchedule(scheduleId);
    result.fold(
      ifLeft: (_) {},
      ifRight: (halaqahs) async {
        final otherHalaqahs = halaqahs.where((h) => h.id != currentHalaqahId).toList();
        final busyTeachers = otherHalaqahs.map((h) => h.teacherId).toList();

        final busySantriIds = <String>[];
        for (final h in otherHalaqahs) {
          final santrisResult = await scheduleRepository.getSantrisByHalaqahId(h.id);
          santrisResult.fold(
            ifLeft: (_) {},
            ifRight: (santris) => busySantriIds.addAll(santris.map((s) => s.id)),
          );
        }

        if (state is HalaqahDetailLoaded) {
          emit((state as HalaqahDetailLoaded).copyWith(
            unavailableTeacherIds: busyTeachers,
            unavailableSantriIds: busySantriIds,
          ));
        }
      },
    );
  }

  Future<void> deleteHalaqah() async {
    final currentState = state;
    Halaqah? currentHalaqah;

    if (currentState is HalaqahDetailInitial) {
      currentHalaqah = currentState.halaqah;
    } else if (currentState is HalaqahDetailLoaded) {
      currentHalaqah = currentState.halaqah;
    }

    if (currentHalaqah == null) {
      emit(const HalaqahDetailError("Data halaqah tidak ditemukan"));
      return;
    }

    final previousState = state;
    emit(HalaqahDetailDeleting());

    final result = await scheduleRepository.deleteHalaqah(currentHalaqah.id);

    result.fold(
      ifLeft: (failure) {
        // Tampilkan error (untuk listener/snackbar) lalu kembalikan tampilan
        // detail sebelumnya agar halaman tidak berubah menjadi layar error.
        emit(HalaqahDetailError(failure.message));
        emit(previousState);
      },
      ifRight: (_) => emit(HalaqahDetailDeleted()),
    );
  }

  Future<void> updateHalaqah(Halaqah updatedHalaqah, List<String> newSantriIds, List<String> removedSantriIds) async {
    final previousState = state;

    if (previousState is HalaqahDetailLoaded) {
      emit(previousState.copyWith(isSubmitting: true));
    } else {
      emit(HalaqahDetailUpdating());
    }

    final result = await scheduleRepository.updateHalaqah(updatedHalaqah, newSantriIds, removedSantriIds);

    result.fold(
      ifLeft: (failure) {
        emit(HalaqahDetailError(failure.message));
      },
      ifRight: (_) async {
        emit(HalaqahDetailSuccess());

        await Future.delayed(const Duration(milliseconds: 100));

        final schedulesResult = await scheduleRepository.getSchedules(programId: updatedHalaqah.programId);
        final santrisResult = await scheduleRepository.getSantrisByHalaqahId(updatedHalaqah.id);

        final schedules = schedulesResult.fold(
          ifLeft: (_) => <ProgramSchedule>[],
          ifRight: (s) => s,
        );

        final santris = santrisResult.fold(
          ifLeft: (_) => <SantriEntity>[],
          ifRight: (s) => s,
        );

        emit(HalaqahDetailLoaded(
          halaqah: updatedHalaqah,
          schedules: schedules,
          santriList: santris,
        ));

        if (updatedHalaqah.scheduleIds.isNotEmpty) {
          _checkAvailability(updatedHalaqah.scheduleIds.first, updatedHalaqah.id);
        }
      },
    );
  }
}
