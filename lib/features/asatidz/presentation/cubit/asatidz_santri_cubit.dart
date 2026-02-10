import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/features/asatidz/presentation/cubit/asatidz_santri_state.dart';
import 'package:khoirunnasyien/features/management_santri/domain/repository/santri_repository.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/repositories/schedule_repository.dart';

class AsatidzSantriCubit extends Cubit<AsatidzSantriState> {
  final ScheduleRepository scheduleRepository;
  final SantriRepository santriRepository;

  AsatidzSantriCubit({
    required this.scheduleRepository,
    required this.santriRepository,
  }) : super(AsatidzSantriInitial());

  Future<void> loadMySantri(String teacherId) async {
    emit(AsatidzSantriLoading());
    
    // 1. Get Teacher's Halaqahs
    final halaqahsResult = await scheduleRepository.getHalaqahsByTeacher(teacherId);
    
    await halaqahsResult.fold(
      ifLeft: (failure) async {
        emit(AsatidzSantriError(failure.message));
      },
      ifRight: (halaqahs) async {
        // 2. Collect unique Santri IDs
        final santriIds = halaqahs
            .expand((h) => h.santris.map((s) => s.id))
            .toSet() 
            .toList();

        if (santriIds.isEmpty) {
          emit(AsatidzSantriLoaded([]));
          return;
        }

        try {
          // 3. Fetch Santri Details
          final santris = await santriRepository.getSantriByIds(santriIds);
           emit(AsatidzSantriLoaded(santris));
        } catch (e) {
          emit(AsatidzSantriError("Failed to load santri details: ${e.toString()}"));
        }
      },
    );
  }
}
