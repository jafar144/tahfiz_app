import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/repository/asatidz_repository.dart';
import 'package:khoirunnasyien/features/management_santri/domain/repository/santri_repository.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/halaqah.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/repositories/schedule_repository.dart';
import 'package:khoirunnasyien/features/management_schedule/presentation/cubit/add_halaqah_state.dart';

class AddHalaqahCubit extends Cubit<AddHalaqahState> {
  final ScheduleRepository scheduleRepository;
  final AsatidzRepository asatidzRepository;
  final SantriRepository santriRepository;

  AddHalaqahCubit({
    required this.scheduleRepository,
    required this.asatidzRepository,
    required this.santriRepository,
  }) : super(AddHalaqahInitial());

  Future<void> loadInitialData(String gender) async {
    emit(AddHalaqahLoading());
    try {
      final sessionsResult = await scheduleRepository.getPrograms(gender: gender);
      
      sessionsResult.fold(
        ifLeft: (failure) => emit(AddHalaqahError(failure.message)),
        ifRight: (sessions) async {
          emit(AddHalaqahLoaded(
            sessions: sessions,
            schedules: [],
            asatidzList: [],
            santriList: [],
          ));
        },
      );
    } catch (e) {
      emit(AddHalaqahError(e.toString()));
    }
  }

  Future<void> loadSchedules(String sessionId) async {
    print('DEBUG: loadSchedules called with sessionId: $sessionId');
    if (state is! AddHalaqahLoaded) {
      print('DEBUG: State is not AddHalaqahLoaded, returning');
      return;
    }
    
    final currentState = state as AddHalaqahLoaded;
    try {
      final schedulesResult = await scheduleRepository.getSchedules(programId: sessionId);
      
      schedulesResult.fold(
        ifLeft: (failure) {
          print('DEBUG: loadSchedules FAILED: ${failure.message}');
          emit(AddHalaqahError(failure.message));
        },
        ifRight: (schedules) {
          print('DEBUG: loadSchedules SUCCESS: ${schedules.length} schedules loaded');
          emit(currentState.copyWith(schedules: schedules));
        },
      );
    } catch (e) {
      print('DEBUG: loadSchedules ERROR: $e');
      emit(AddHalaqahError(e.toString()));
    }
  }

  Future<void> loadSchedulesAndPeople(String sessionId, String gender) async {
    print('DEBUG: loadSchedulesAndPeople called with sessionId: $sessionId, gender: $gender');
    if (state is! AddHalaqahLoaded) {
      print('DEBUG: State is not AddHalaqahLoaded, returning');
      return;
    }
    
    final currentState = state as AddHalaqahLoaded;
    try {
      final schedulesResult = await scheduleRepository.getSchedules(programId: sessionId);
      final asatidzList = await asatidzRepository.getAsatidzList(isActive: true);
      final santriList = await santriRepository.getSantriList(isActive: true);
      
      print('DEBUG: Total Asatidz: ${asatidzList.length}');
      print('DEBUG: Total Santri: ${santriList.length}');
      
      final filteredAsatidz = asatidzList.where((a) => a.jenisKelamin == gender).toList();
      final filteredSantri = santriList.where((s) => s.jenisKelamin == gender).toList();
      
      print('DEBUG: Filtered Asatidz ($gender): ${filteredAsatidz.length}');
      print('DEBUG: Filtered Santri ($gender): ${filteredSantri.length}');
      
      schedulesResult.fold(
        ifLeft: (failure) {
          print('DEBUG: loadSchedules FAILED: ${failure.message}');
          emit(AddHalaqahError(failure.message));
        },
        ifRight: (schedules) {
          print('DEBUG: loadSchedules SUCCESS: ${schedules.length} schedules loaded');
          emit(currentState.copyWith(
            schedules: schedules,
            asatidzList: filteredAsatidz,
            santriList: filteredSantri,
          ));
        },
      );
    } catch (e) {
      print('DEBUG: loadSchedulesAndPeople ERROR: $e');
      emit(AddHalaqahError(e.toString()));
    }
  }

  Future<void> loadAsatidzAndSantri(String gender) async {
    if (state is! AddHalaqahLoaded) return;
    
    final currentState = state as AddHalaqahLoaded;
    try {
      final asatidzList = await asatidzRepository.getAsatidzList(isActive: true);
      final santriList = await santriRepository.getSantriList(isActive: true);
      
      print('DEBUG: Total Asatidz: ${asatidzList.length}');
      print('DEBUG: Total Santri: ${santriList.length}');
      
      final filteredAsatidz = asatidzList.where((a) => a.jenisKelamin == gender).toList();
      final filteredSantri = santriList.where((s) => s.jenisKelamin == gender).toList();
      
      print('DEBUG: Filtered Asatidz ($gender): ${filteredAsatidz.length}');
      print('DEBUG: Filtered Santri ($gender): ${filteredSantri.length}');
      
      emit(currentState.copyWith(
        asatidzList: filteredAsatidz,
        santriList: filteredSantri,
      ));
    } catch (e) {
      print('DEBUG ERROR loadAsatidzAndSantri: $e');
      emit(AddHalaqahError(e.toString()));
    }
  }

  Future<void> checkScheduleAvailability(String scheduleId) async {
    if (state is! AddHalaqahLoaded) return;
    final currentState = state as AddHalaqahLoaded;

    try {
      final result = await scheduleRepository.getHalaqahsBySchedule(scheduleId);
      
      result.fold(
        ifLeft: (failure) {
          print('Availability check failed: ${failure.message}');
        },
        ifRight: (halaqahs) {
          final busyTeachers = halaqahs.map((h) => h.teacherId).toList();
          final busySantris = halaqahs.expand((h) => h.santris.map((s) => s.id)).toList();
          
          emit(currentState.copyWith(
            unavailableTeacherIds: busyTeachers,
            unavailableSantriIds: busySantris,
          ));
        },
      );
    } catch (e) {
      print('Availability check error: $e');
    }
  }

  Future<void> createHalaqah(Halaqah halaqah) async {
    emit(AddHalaqahLoading());
    try {
      final result = await scheduleRepository.createHalaqah(halaqah);
      
      result.fold(
        ifLeft: (failure) => emit(AddHalaqahError(failure.message)),
        ifRight: (_) => emit(AddHalaqahSuccess()),
      );
    } catch (e) {
      emit(AddHalaqahError(e.toString()));
    }
  }
}
