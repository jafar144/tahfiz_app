import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/repository/asatidz_repository.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_entity.dart';
import 'package:khoirunnasyien/features/management_santri/domain/repository/santri_repository.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
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
      // Should not happen if flow is correct
      emit(const HalaqahDetailError("Data halaqah tidak ditemukan"));
      return;
    }

    emit(HalaqahDetailLoading());
    try {
      final asatidzResult = await asatidzRepository.getAsatidzList(isActive: true);
      final santriResult = await santriRepository.getSantriList(isActive: true);
      
      emit(HalaqahDetailLoaded(
        halaqah: currentHalaqah,
        asatidzList: asatidzResult,
        santriList: santriResult,
      ));
    } catch (e) {
      emit(HalaqahDetailError(e.toString()));
    }
  }

  Future<void> updateHalaqah(Halaqah updatedHalaqah) async {
    emit(HalaqahDetailUpdating());
    final result = await scheduleRepository.updateHalaqah(updatedHalaqah);
    final previousState = state;
    
    List<AsatidzEntity> asatidzList = [];
    List<SantriEntity> santriList = [];
    if (previousState is HalaqahDetailLoaded) {
      asatidzList = previousState.asatidzList;
      santriList = previousState.santriList;
    }

    result.fold(
      ifLeft: (failure) => emit(HalaqahDetailError(failure.message)),
      ifRight: (_) {
         emit(HalaqahDetailSuccess());
         emit(HalaqahDetailLoaded(
           halaqah: updatedHalaqah,
           asatidzList: asatidzList,
           santriList: santriList,
         ));
      },
    );
  }
}
