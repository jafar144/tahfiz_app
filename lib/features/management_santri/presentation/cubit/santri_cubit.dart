import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/core/utils/image_utils.dart';
import 'package:khoirunnasyien/features/management_santri/domain/repository/santri_repository.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_params.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/cubit/santri_state.dart';

import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_entity.dart';
import 'package:khoirunnasyien/core/utils/error_handler.dart';

class SantriCubit extends Cubit<SantriState> {
  final SantriRepository repository;

  // Keep track of current filters for pagination
  String? _currentKeyword;
  bool? _currentIsActive;
  String? _currentGender;
  String? _currentSession;
  String? _currentClass;
  String? _currentAsatidzId;
  bool? _currentIsFree;
  bool? _currentHasPhoto;
  bool? _currentHasHalaqah;
  SantriSortBy _currentSortBy = SantriSortBy.name;
  static const int _limit = 10;

  SantriCubit(this.repository) : super(SantriInitial());

  Future<void> loadSantri({
    String? keyword,
    bool? isActive,
    String? gender,
    String? session,
    String? kelas,
    String? asatidzId,
    bool? isFree,
    bool? hasPhoto,
    bool? hasHalaqah,
    SantriSortBy sortBy = SantriSortBy.name,
  }) async {
    _currentKeyword = keyword;
    _currentIsActive = isActive;
    _currentGender = gender;
    _currentSession = session;
    _currentClass = kelas;
    _currentAsatidzId = asatidzId;
    _currentIsFree = isFree;
    _currentHasPhoto = hasPhoto;
    _currentHasHalaqah = hasHalaqah;
    _currentSortBy = sortBy;

    emit(SantriLoading());
    try {
      final result = await repository.getSantriList(
        keyword: keyword,
        isActive: isActive,
        gender: gender,
        session: session,
        kelas: kelas,
        asatidzId: asatidzId,
        isFree: isFree,
        hasPhoto: hasPhoto,
        hasHalaqah: hasHalaqah,
        sortBy: sortBy,
        limit: _limit,
      );

      // Filter asatidz dan pencarian mengambil seluruh hasil sekaligus, jadi
      // keduanya tidak memakai cursor pagination.
      final hasReachedMax =
          asatidzId != null ||
          (keyword?.trim().isNotEmpty ?? false) ||
          result.length < _limit;

      emit(SantriLoaded(result, hasReachedMax: hasReachedMax));
    } catch (e) {
      emit(SantriError(ErrorHandler.getMessage(e)));
    }
  }

  void loadMoreSantri() async {
    final currentState = state;
    if (currentState is! SantriLoaded) return;
    if (currentState.hasReachedMax || currentState.isFetchingMore) return;

    // Already loading more
    emit(currentState.copyWith(isFetchingMore: true));

    try {
      final lastId = currentState.santri.last.id;
      final newSantri = await repository.getSantriList(
        keyword: _currentKeyword,
        isActive: _currentIsActive,
        gender: _currentGender,
        session: _currentSession,
        kelas: _currentClass,
        asatidzId: _currentAsatidzId,
        isFree: _currentIsFree,
        hasPhoto: _currentHasPhoto,
        hasHalaqah: _currentHasHalaqah,
        sortBy: _currentSortBy,
        limit: _limit,
        lastDocumentId: lastId,
      );

      emit(
        currentState.copyWith(
          santri: List.of(currentState.santri)..addAll(newSantri),
          hasReachedMax: newSantri.length < _limit,
          isFetchingMore: false,
        ),
      );
    } catch (e) {
      // On error, keep the current data but stop loading
      emit(currentState.copyWith(isFetchingMore: false));
      // Optionally emit a side-effect or different error state
    }
  }

  /// NIS otomatis berikutnya untuk form tambah santri.
  Future<String> getNextNis() => repository.getNextNis();

  Future<void> addSantri(SantriParams params) async {
    emit(SantriLoading());
    try {
      // Pastikan NIS unik (field boleh diedit admin) sebelum membuat akun.
      if (await repository.isNisTaken(params.nis)) {
        emit(SantriError('NIS ${params.nis} sudah dipakai. Gunakan NIS lain.'));
        return;
      }

      String? finalPhotoUrl = params.photoUrl;

      // Santri non-aktif tidak menyimpan foto agar tidak membebani Storage.
      if (params.isActive && params.localPhotoFile != null) {
        finalPhotoUrl = await ImageUtils.uploadImageToFirebase(
          params.localPhotoFile!,
          'santri_photos',
        );
        if (finalPhotoUrl == null) {
          emit(SantriError('Gagal mengupload foto'));
          return;
        }
      } else if (!params.isActive) {
        finalPhotoUrl = null;
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
        photoUrl: finalPhotoUrl,
      );

      final temporaryPassword = await repository.addSantri(finalParams);
      emit(
        SantriCreated(nis: params.nis, temporaryPassword: temporaryPassword),
      );
    } catch (e) {
      emit(SantriError(ErrorHandler.getMessage(e)));
    }
  }

  Future<List<AsatidzEntity>> fetchAsatidzList() {
    return repository.getAsatidzList();
  }
}
