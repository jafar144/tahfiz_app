import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/repository/asatidz_repository.dart';
import 'package:khoirunnasyien/features/management_santri/domain/repository/santri_repository.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/halaqah.dart';
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
      emit(HalaqahDetailLoaded(
        halaqah: currentHalaqah,
      ));
      
      _checkAvailability(currentHalaqah.scheduleId, currentHalaqah.id);
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
      ifRight: (_) {
         emit(HalaqahDetailSuccess());
      },
    );
  }
}
