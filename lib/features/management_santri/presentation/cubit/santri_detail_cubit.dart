import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/core/utils/image_utils.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_params.dart';
import 'package:khoirunnasyien/features/management_santri/domain/repository/santri_repository.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/cubit/santri_detail_state.dart';
import 'package:khoirunnasyien/core/utils/error_handler.dart';

typedef SantriPhotoUploader = Future<String?> Function(File file, String path);
typedef SantriPhotoDeleter = Future<void> Function(String url);

class SantriDetailCubit extends Cubit<SantriDetailState> {
  static const _photoFolder = 'santri_photos';

  final SantriRepository repository;
  final SantriPhotoUploader _upload;
  final SantriPhotoDeleter _delete;

  SantriDetailCubit(
    this.repository, {
    SantriPhotoUploader? upload,
    SantriPhotoDeleter? delete,
  }) : _upload = upload ?? ImageUtils.uploadImageToFirebase,
       _delete = delete ?? ImageUtils.deleteImageFromFirebase,
       super(SantriDetailInitial());

  Future<void> loadDetail(String id) async {
    emit(SantriDetailLoading());
    try {
      final detail = await repository.getSantriDetail(id);
      emit(SantriDetailLoaded(detail));
    } catch (e) {
      emit(SantriDetailError(ErrorHandler.getMessage(e)));
    }
  }

  Future<bool> updateSantri(String id, SantriParams params) async {
    emit(SantriDetailLoading());
    final uploaded = <String>[];
    try {
      final photos = await _resolvePhotos(params, uploaded);
      if (photos == null) {
        await _deleteAll(uploaded);
        emit(SantriDetailError('Gagal mengupload foto'));
        return false;
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
        kelasFiqih: params.kelasFiqih,
        tipeKelas: params.tipeKelas,
        entryDate: params.entryDate,
        isFree: params.isFree,
        isActive: params.isActive,
        freeUntil: params.freeUntil,
        photoUrl: photos.photoUrl,
        photoOriginalUrl: photos.originalUrl,
        removePhoto: photos.remove,
      );

      await repository.updateSantri(id, finalParams);
      // File lama baru dihapus setelah profil menunjuk ke file baru.
      await _deleteAll(photos.obsolete);
      await loadDetail(id);
      return true;
    } catch (e) {
      await _deleteAll(uploaded);
      emit(SantriDetailError(ErrorHandler.getMessage(e)));
      return false;
    }
  }

  /// Menentukan URL foto (crop) dan foto asli setelah disimpan.
  ///
  /// - Foto baru dari galeri/kamera: unggah foto asli dan hasil crop, buang
  ///   keduanya yang lama.
  /// - Atur ulang posisi: unggah hasil crop baru, foto asli tetap.
  /// - Foto lama tanpa versi asli: foto crop lama dijadikan foto asli agar
  ///   pengaturan berikutnya tidak memotong dari hasil potongan.
  ///
  /// Mengembalikan null bila unggahan gagal. URL yang sempat terunggah dicatat
  /// di [uploaded] agar bisa dibersihkan.
  Future<_SantriPhotoUpdate?> _resolvePhotos(
    SantriParams params,
    List<String> uploaded,
  ) async {
    final oldPhoto = _nonEmpty(params.photoUrl);
    final oldOriginal = _nonEmpty(params.photoOriginalUrl);
    final newPhotoFile = params.localPhotoFile;

    // Santri non-aktif tidak menyimpan foto agar tidak membebani Storage.
    if (!params.isActive || (params.removePhoto && newPhotoFile == null)) {
      return _SantriPhotoUpdate(
        photoUrl: null,
        originalUrl: null,
        remove: true,
        obsolete: {?oldPhoto, ?oldOriginal},
      );
    }
    if (newPhotoFile == null) {
      return _SantriPhotoUpdate(
        photoUrl: oldPhoto,
        originalUrl: oldOriginal,
        remove: false,
        obsolete: const {},
      );
    }

    final obsolete = <String>{};
    String? newOriginal;
    final newOriginalFile = params.localPhotoOriginalFile;
    if (newOriginalFile != null) {
      newOriginal = await _upload(newOriginalFile, _photoFolder);
      if (newOriginal == null) return null;
      uploaded.add(newOriginal);
      obsolete.addAll({?oldPhoto, ?oldOriginal});
    } else if (oldOriginal != null) {
      newOriginal = oldOriginal;
      obsolete.addAll({?oldPhoto});
    } else {
      newOriginal = oldPhoto;
    }

    final newPhoto = await _upload(newPhotoFile, _photoFolder);
    if (newPhoto == null) return null;
    uploaded.add(newPhoto);

    obsolete.removeAll({newPhoto, ?newOriginal});
    return _SantriPhotoUpdate(
      photoUrl: newPhoto,
      originalUrl: newOriginal,
      remove: false,
      obsolete: obsolete,
    );
  }

  Future<void> _deleteAll(Iterable<String> urls) async {
    for (final url in urls) {
      await _delete(url);
    }
  }

  static String? _nonEmpty(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _SantriPhotoUpdate {
  final String? photoUrl;
  final String? originalUrl;
  final bool remove;
  final Set<String> obsolete;

  const _SantriPhotoUpdate({
    required this.photoUrl,
    required this.originalUrl,
    required this.remove,
    required this.obsolete,
  });
}
