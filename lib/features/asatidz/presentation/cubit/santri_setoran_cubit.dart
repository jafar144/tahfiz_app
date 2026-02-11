import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/features/asatidz/domain/entities/active_halaqah.dart';
import 'package:khoirunnasyien/features/asatidz/domain/entities/santri_setoran.dart';
import 'package:khoirunnasyien/features/asatidz/domain/repositories/asatidz_repository.dart';
import 'package:khoirunnasyien/features/asatidz/presentation/cubit/santri_setoran_state.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/halaqah_santri.dart';

class SantriSetoranCubit extends Cubit<SantriSetoranState> {
  final AsatidzRepository repository;
  final ActiveHalaqah activeHalaqah;
  final HalaqahSantri santri;
  final String asatidzId;
  final String asatidzName;

  SantriSetoranCubit({
    required this.repository,
    required this.activeHalaqah,
    required this.santri,
    required this.asatidzId,
    required this.asatidzName,
  }) : super(SantriSetoranInitial());

  Future<void> loadInitialData() async {
    emit(SantriSetoranLoading());

    final result = await repository.getSetoranHistory(
      santriId: santri.id,
    );

    result.fold(
      ifLeft: (failure) => emit(SantriSetoranError(failure.message)),
      ifRight: (history) {
        // Sort by date descending if not already
        history.sort((a, b) => b.date.compareTo(a.date));
        
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        
        SantriSetoran? todaySetoran;
        SantriSetoran? lastSetoran;
        
        try {
          todaySetoran = history.firstWhere((element) {
            final elementDate = DateTime(element.date.year, element.date.month, element.date.day);
            return elementDate.isAtSameMomentAs(today);
          });
        } catch (_) {}
        
        try {
          lastSetoran = history.firstWhere((element) {
            final elementDate = DateTime(element.date.year, element.date.month, element.date.day);
             if (todaySetoran != null && element.id == todaySetoran.id) return false;
            return elementDate.isBefore(today);
          });
        } catch (_) {}

        emit(SantriSetoranDataLoaded(
          lastSetoran: lastSetoran,
          todaySetoran: todaySetoran,
        ));
      },
    );
  }

  Future<void> submitSetoran({
    required String surah,
    String catatan = '',
  }) async {
    // Preserve current data if available
    SantriSetoranDataLoaded? currentData;
    if (state is SantriSetoranDataLoaded) {
      currentData = state as SantriSetoranDataLoaded;
      emit(SantriSetoranDataLoaded(
        lastSetoran: currentData.lastSetoran,
        todaySetoran: currentData.todaySetoran,
        isSubmitting: true,
      ));
    } else {
      emit(SantriSetoranLoading());
    }

    // Check if we are updating today's setoran
    if (currentData?.todaySetoran != null) {
      final result = await repository.updateSetoran(
        setoranId: currentData!.todaySetoran!.id,
        surah: surah,
        catatan: catatan,
      );

      result.fold(
        ifLeft: (failure) {
          emit(SantriSetoranError(failure.message));
        },
        ifRight: (_) => emit(const SantriSetoranSuccess('Setoran berhasil diperbarui')),
      );
    } else {
      // Create new setoran
      final result = await repository.createSetoran(
        santriId: santri.id,
        santriName: santri.name,
        halaqahId: activeHalaqah.halaqah.id,
        halaqahName: activeHalaqah.halaqah.name,
        asatidzId: asatidzId,
        asatidzName: asatidzName,
        date: DateTime.now(),
        surah: surah,
        catatan: catatan,
      );

      result.fold(
        ifLeft: (failure) {
          emit(SantriSetoranError(failure.message));
        },
        ifRight: (_) => emit(const SantriSetoranSuccess('Setoran berhasil disimpan')),
      );
    }
  }
}
