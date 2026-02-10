import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/features/asatidz/domain/entities/active_halaqah.dart';
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

  Future<void> submitSetoran({
    required String surah,
    required int ayatAwal,
    required int ayatAkhir,
    required String kualitasHafalan,
    String catatan = '',
  }) async {
    emit(SantriSetoranLoading());

    final result = await repository.createSetoran(
      santriId: santri.id,
      santriName: santri.name,
      halaqahId: activeHalaqah.halaqah.id,
      halaqahName: activeHalaqah.halaqah.name,
      asatidzId: asatidzId,
      asatidzName: asatidzName,
      date: DateTime.now(),
      surah: surah,
      ayatAwal: ayatAwal,
      ayatAkhir: ayatAkhir,
      kualitasHafalan: kualitasHafalan,
      catatan: catatan,
    );

    result.fold(
      ifLeft: (failure) => emit(SantriSetoranError(failure.message)),
      ifRight: (_) => emit(SantriSetoranSuccess()),
    );
  }
}
