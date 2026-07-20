import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/core/utils/image_utils.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_params.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/repository/asatidz_repository.dart';
import 'package:khoirunnasyien/features/management_asatidz/presentation/cubit/asatidz_detail_state.dart';
import 'package:khoirunnasyien/core/utils/error_handler.dart';

class AsatidzDetailCubit extends Cubit<AsatidzDetailState> {
  final AsatidzRepository repository;

  AsatidzDetailCubit(this.repository) : super(AsatidzDetailInitial());

  Future<void> loadDetail(String id) async {
    emit(AsatidzDetailLoading());
    try {
      final detail = await repository.getAsatidzDetail(id);
      emit(AsatidzDetailLoaded(detail));
    } catch (e) {
      emit(AsatidzDetailError(ErrorHandler.getMessage(e)));
    }
  }

  Future<bool> updateAsatidz(String id, AsatidzParams params) async {
    emit(AsatidzDetailLoading());
    String? uploadedPhotoUrl;
    try {
      String? finalPhotoUrl = params.photoUrl;
      var removePhoto = params.removePhoto && params.localPhotoFile == null;
      String? obsoletePhotoUrl;

      if (!params.isActive) {
        obsoletePhotoUrl = params.photoUrl;
        finalPhotoUrl = null;
        removePhoto = true;
      } else if (params.localPhotoFile != null) {
        uploadedPhotoUrl = await ImageUtils.uploadImageToFirebase(
          params.localPhotoFile!,
          'asatidz_photos',
        );
        if (uploadedPhotoUrl == null) {
          emit(AsatidzDetailError('Gagal mengupload foto'));
          return false;
        }
        obsoletePhotoUrl = params.photoUrl;
        finalPhotoUrl = uploadedPhotoUrl;
      } else if (params.removePhoto) {
        obsoletePhotoUrl = params.photoUrl;
        finalPhotoUrl = null;
      }

      await repository.updateAsatidz(
        id,
        AsatidzParams(
          name: params.name,
          nis: params.nis,
          phone: params.phone,
          jenisKelamin: params.jenisKelamin,
          isActive: params.isActive,
          photoUrl: finalPhotoUrl,
          removePhoto: removePhoto,
        ),
      );
      // Setelah dokumen berhasil diperbarui, foto baru sudah menjadi milik
      // profil dan tidak boleh dibersihkan bila refresh detail saja yang gagal.
      uploadedPhotoUrl = null;
      if (obsoletePhotoUrl != null && obsoletePhotoUrl.isNotEmpty) {
        await ImageUtils.deleteImageFromFirebase(obsoletePhotoUrl);
      }
      final detail = await repository.getAsatidzDetail(id);
      emit(AsatidzDetailLoaded(detail));
      return true;
    } catch (e) {
      if (uploadedPhotoUrl != null) {
        await ImageUtils.deleteImageFromFirebase(uploadedPhotoUrl);
      }
      emit(AsatidzDetailError(ErrorHandler.getMessage(e)));
      return false;
    }
  }
}
