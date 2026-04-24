import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/core/utils/image_utils.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_params.dart';
import 'package:khoirunnasyien/features/management_santri/domain/repository/santri_repository.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/cubit/santri_detail_state.dart';
import 'package:khoirunnasyien/core/utils/error_handler.dart';

class SantriDetailCubit extends Cubit<SantriDetailState> {
  final SantriRepository repository;

  SantriDetailCubit(this.repository) : super(SantriDetailInitial());

  Future<void> loadDetail(String id) async {
    emit(SantriDetailLoading());
    try {
      final detail = await repository.getSantriDetail(id);
      emit(SantriDetailLoaded(detail));
    } catch (e) {
      emit(SantriDetailError(ErrorHandler.getMessage(e)));
    }
  }

  Future<void> updateSantri(String id, SantriParams params) async {
    emit(SantriDetailLoading());
    try {
      String? finalPhotoUrl = params.photoUrl;

      if (params.localPhotoFile != null) {
        if (params.photoUrl != null && params.photoUrl!.isNotEmpty) {
          await ImageUtils.deleteImageFromFirebase(params.photoUrl!);
        }

        finalPhotoUrl = await ImageUtils.uploadImageToFirebase(
          params.localPhotoFile!,
          'santri_photos',
        );
        if (finalPhotoUrl == null) {
          emit(SantriDetailError('Gagal mengupload foto'));
          return;
        }
      }

      final finalParams = SantriParams(
        name: params.name,
        nis: params.nis,
        phone: params.phone,
        jenisKelamin: params.jenisKelamin,
        birthPlace: params.birthPlace,
        birthDate: params.birthDate,
        waliName: params.waliName,
        waliPhone: params.waliPhone,
        kelas: params.kelas,
        tipeKelas: params.tipeKelas,
        entryDate: params.entryDate,
        isFree: params.isFree,
        isActive: params.isActive,
        freeUntil: params.freeUntil,
        photoUrl: finalPhotoUrl,
      );

      await repository.updateSantri(id, finalParams);
      loadDetail(id);
    } catch (e) {
      emit(SantriDetailError(ErrorHandler.getMessage(e)));
    }
  }
}
