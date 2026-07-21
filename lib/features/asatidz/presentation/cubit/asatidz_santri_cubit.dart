import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/features/asatidz/presentation/cubit/asatidz_santri_state.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/repositories/schedule_repository.dart';

class AsatidzSantriCubit extends Cubit<AsatidzSantriState> {
  final ScheduleRepository scheduleRepository;

  AsatidzSantriCubit({required this.scheduleRepository})
    : super(AsatidzSantriInitial());

  Future<void> loadMySantri(String teacherId) async {
    emit(AsatidzSantriLoading());

    final halaqahsResult = await scheduleRepository.getHalaqahsByTeacher(
      teacherId,
    );

    await halaqahsResult.fold(
      ifLeft: (failure) async {
        emit(AsatidzSantriError(failure.message));
      },
      ifRight: (halaqahs) async {
        if (halaqahs.isEmpty) {
          emit(AsatidzSantriLoaded([]));
          return;
        }

        final santrisById = <String, SantriEntity>{};
        for (final halaqah in halaqahs) {
          final santrisResult = await scheduleRepository.getSantrisByHalaqahId(
            halaqah.id,
          );
          santrisResult.fold(
            ifLeft: (_) {},
            ifRight: (santris) {
              for (final santri in santris) {
                santrisById[santri.id] = SantriEntity(
                  id: santri.id,
                  name: santri.name,
                  nis: santri.nis,
                  kelas: santri.kelas,
                  kelasFiqih: santri.kelasFiqih,
                  jenisKelamin: santri.jenisKelamin,
                  isActive: santri.isActive,
                  isFree: santri.isFree,
                  freeUntil: santri.freeUntil,
                  nomorWali: santri.nomorWali,
                  tipeKelas: santri.tipeKelas,
                  halaqahId: santri.halaqahId,
                  halaqahName: halaqah.name,
                  pembimbing: halaqah.teacherName,
                  tanggalMasuk: santri.tanggalMasuk,
                );
              }
            },
          );
        }

        emit(AsatidzSantriLoaded(santrisById.values.toList()));
      },
    );
  }
}
