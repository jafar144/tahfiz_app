import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/repository/asatidz_repository.dart';
import 'package:khoirunnasyien/features/management_santri/domain/repository/santri_repository.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/halaqah.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/program_schedule.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/repositories/schedule_repository.dart';
import 'package:khoirunnasyien/features/management_schedule/presentation/cubit/halaqah_detail_state.dart';

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
      
      final schedules = schedulesResult.fold(
        ifLeft: (_) => <ProgramSchedule>[],
        ifRight: (s) => s,
      );

      emit(HalaqahDetailLoaded(
        halaqah: currentHalaqah,
        schedules: schedules,
      ));
      
      if (currentHalaqah.scheduleIds.isNotEmpty) {
        _checkAvailability(currentHalaqah.scheduleIds.first, currentHalaqah.id);
      }
    } catch (e) {
      emit(HalaqahDetailError(e.toString()));
    }
  }

  Future<void> _checkAvailability(String scheduleId, String currentHalaqahId) async {
    if (state is! HalaqahDetailLoaded) return;
    
    final result = await scheduleRepository.getHalaqahsBySchedule(scheduleId);
    result.fold(
      ifLeft: (_) {}, 
      ifRight: (halaqahs) {
        final otherHalaqahs = halaqahs.where((h) => h.id != currentHalaqahId).toList();
        
        final busyTeachers = otherHalaqahs.map((h) => h.teacherId).toList();
        final busySantris = otherHalaqahs.expand((h) => h.santris.map((s) => s.id)).toList();
        
        if (state is HalaqahDetailLoaded) {
          emit((state as HalaqahDetailLoaded).copyWith(
            unavailableTeacherIds: busyTeachers,
            unavailableSantriIds: busySantris,
          ));
        }
      }
    );
  }

  Future<void> updateHalaqah(Halaqah updatedHalaqah) async {
    final previousState = state;
    
    if (previousState is HalaqahDetailLoaded) {
      emit(previousState.copyWith(isSubmitting: true));
    } else {
      emit(HalaqahDetailUpdating());
    }

    final result = await scheduleRepository.updateHalaqah(updatedHalaqah);
    
    result.fold(
      ifLeft: (failure) {
          emit(HalaqahDetailError(failure.message));
      },
      ifRight: (_) async {
         emit(HalaqahDetailSuccess());
         
         await Future.delayed(const Duration(milliseconds: 100));
         
         final schedulesResult = await scheduleRepository.getSchedules(programId: updatedHalaqah.programId);
         
         final schedules = schedulesResult.fold(
           ifLeft: (_) => <ProgramSchedule>[],
           ifRight: (s) => s,
         );

         emit(HalaqahDetailLoaded(
           halaqah: updatedHalaqah,
           schedules: schedules,
         ));
         
         if (updatedHalaqah.scheduleIds.isNotEmpty) {
           _checkAvailability(updatedHalaqah.scheduleIds.first, updatedHalaqah.id);
         }
      },
    );
  }
}
