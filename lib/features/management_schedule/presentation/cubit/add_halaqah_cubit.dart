import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/repository/asatidz_repository.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_detail.dart';
import 'package:khoirunnasyien/features/management_santri/domain/repository/santri_repository.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/halaqah.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/repositories/schedule_repository.dart';
import 'package:khoirunnasyien/features/management_schedule/presentation/cubit/add_halaqah_state.dart';
import 'package:khoirunnasyien/core/utils/error_handler.dart';

class AddHalaqahCubit extends Cubit<AddHalaqahState> {
  final ScheduleRepository scheduleRepository;
  final AsatidzRepository asatidzRepository;
  final SantriRepository santriRepository;

  AddHalaqahCubit({
    required this.scheduleRepository,
    required this.asatidzRepository,
    required this.santriRepository,
  }) : super(AddHalaqahInitial());

  Future<AsatidzDetail> getAsatidzDetail(String id) {
    return asatidzRepository.getAsatidzDetail(id);
  }

  Future<void> loadInitialData(String gender) async {
    emit(AddHalaqahLoading());
    try {
      final sessionsResult = await scheduleRepository.getPrograms(
        gender: gender,
      );

      sessionsResult.fold(
        ifLeft: (failure) => emit(AddHalaqahError(failure.message)),
        ifRight: (sessions) async {
          emit(
            AddHalaqahLoaded(
              sessions: sessions,
              schedules: [],
              asatidzList: [],
              santriList: [],
            ),
          );
        },
      );
    } catch (e) {
      emit(AddHalaqahError(ErrorHandler.getMessage(e)));
    }
  }

  Future<void> loadSchedules(String sessionId) async {
    if (state is! AddHalaqahLoaded) {
      return;
    }

    final currentState = state as AddHalaqahLoaded;
    try {
      final schedulesResult = await scheduleRepository.getSchedules(
        programId: sessionId,
      );

      schedulesResult.fold(
        ifLeft: (failure) {
          emit(AddHalaqahError(failure.message));
        },
        ifRight: (schedules) {
          emit(currentState.copyWith(schedules: schedules));
        },
      );
    } catch (e) {
      emit(AddHalaqahError(ErrorHandler.getMessage(e)));
    }
  }

  Future<void> loadSchedulesAndPeople(String sessionId, String gender) async {
    if (state is! AddHalaqahLoaded) {
      return;
    }

    final currentState = state as AddHalaqahLoaded;
    try {
      final schedulesResult = await scheduleRepository.getSchedules(
        programId: sessionId,
      );
      final asatidzList = await asatidzRepository.getAsatidzList(
        isActive: true,
      );
      final santriList = await santriRepository.getSantriList(isActive: true);

      final filteredAsatidz = asatidzList
          .where((a) => a.jenisKelamin == gender)
          .toList();
      final filteredSantri = santriList
          .where((s) => s.jenisKelamin == gender)
          .toList();

      schedulesResult.fold(
        ifLeft: (failure) {
          emit(AddHalaqahError(failure.message));
        },
        ifRight: (schedules) {
          emit(
            currentState.copyWith(
              schedules: schedules,
              asatidzList: filteredAsatidz,
              santriList: filteredSantri,
            ),
          );
        },
      );
    } catch (e) {
      emit(AddHalaqahError(ErrorHandler.getMessage(e)));
    }
  }

  Future<void> loadAsatidzAndSantri(String gender) async {
    if (state is! AddHalaqahLoaded) return;

    final currentState = state as AddHalaqahLoaded;
    try {
      final asatidzList = await asatidzRepository.getAsatidzList(
        isActive: true,
      );
      final santriList = await santriRepository.getSantriList(isActive: true);

      final filteredAsatidz = asatidzList
          .where((a) => a.jenisKelamin == gender)
          .toList();
      final filteredSantri = santriList
          .where((s) => s.jenisKelamin == gender)
          .toList();

      emit(
        currentState.copyWith(
          asatidzList: filteredAsatidz,
          santriList: filteredSantri,
        ),
      );
    } catch (e) {
      emit(AddHalaqahError(ErrorHandler.getMessage(e)));
    }
  }

  Future<void> checkScheduleAvailability(String scheduleId) async {
    if (state is! AddHalaqahLoaded) return;
    final currentState = state as AddHalaqahLoaded;

    try {
      final result = await scheduleRepository.getHalaqahsBySchedule(scheduleId);

      result.fold(
        ifLeft: (_) {},
        ifRight: (halaqahs) async {
          final busyTeachers = halaqahs.map((h) => h.teacherId).toList();

          final busySantriIds = <String>[];
          for (final h in halaqahs) {
            final santrisResult = await scheduleRepository
                .getSantrisByHalaqahId(h.id);
            santrisResult.fold(
              ifLeft: (_) {},
              ifRight: (santris) =>
                  busySantriIds.addAll(santris.map((s) => s.id)),
            );
          }

          emit(
            currentState.copyWith(
              unavailableTeacherIds: busyTeachers,
              unavailableSantriIds: busySantriIds,
            ),
          );
        },
      );
    } catch (_) {}
  }

  Future<void> createHalaqah(Halaqah halaqah, List<String> santriIds) async {
    final previousState = state;
    emit(AddHalaqahLoading());
    try {
      final result = await scheduleRepository.createHalaqah(halaqah, santriIds);

      result.fold(
        ifLeft: (failure) {
          emit(AddHalaqahError(failure.message));
          if (previousState is AddHalaqahLoaded) emit(previousState);
        },
        ifRight: (_) => emit(AddHalaqahSuccess()),
      );
    } catch (e) {
      emit(AddHalaqahError(ErrorHandler.getMessage(e)));
      if (previousState is AddHalaqahLoaded) emit(previousState);
    }
  }
}
