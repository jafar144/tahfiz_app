import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/features/asatidz/presentation/cubit/asatidz_santri_state.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/repositories/schedule_repository.dart';

class AsatidzSantriCubit extends Cubit<AsatidzSantriState> {
  final ScheduleRepository scheduleRepository;

  AsatidzSantriCubit({
    required this.scheduleRepository,
  }) : super(AsatidzSantriInitial());

  Future<void> loadMySantri(String teacherId) async {
    emit(AsatidzSantriLoading());

    final halaqahsResult = await scheduleRepository.getHalaqahsByTeacher(teacherId);

    await halaqahsResult.fold(
      ifLeft: (failure) async {
        emit(AsatidzSantriError(failure.message));
      },
      ifRight: (halaqahs) async {
        if (halaqahs.isEmpty) {
          emit(AsatidzSantriLoaded([]));
          return;
        }

        final allSantris = <dynamic>[];
        for (final halaqah in halaqahs) {
          final santrisResult = await scheduleRepository.getSantrisByHalaqahId(halaqah.id);
          santrisResult.fold(
            ifLeft: (_) {},
            ifRight: (santris) {
              final mapped = santris.map((s) => SantriEntity(
                id: s.id,
                name: s.name,
                nis: s.nis,
                kelas: s.kelas,
                kelasFiqih: s.kelasFiqih,
                jenisKelamin: s.jenisKelamin,
                isActive: s.isActive,
                isFree: s.isFree,
                freeUntil: s.freeUntil,
                nomorWali: s.nomorWali,
                tipeKelas: s.tipeKelas,
                halaqahId: s.halaqahId,
                halaqahName: halaqah.name,
                pembimbing: halaqah.teacherName,
                tanggalMasuk: s.tanggalMasuk,
              )).toList();
              allSantris.addAll(mapped);
            },
          );
        }

        emit(AsatidzSantriLoaded(allSantris.toSet().toList().cast()));
      },
    );
  }
}
