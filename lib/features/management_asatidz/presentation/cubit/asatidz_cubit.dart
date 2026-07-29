import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/core/utils/image_utils.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_params.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/repository/asatidz_repository.dart';
import 'package:khoirunnasyien/features/management_asatidz/presentation/cubit/asatidz_state.dart';
import 'package:khoirunnasyien/core/utils/error_handler.dart';

class AsatidzCubit extends Cubit<AsatidzState> {
  final AsatidzRepository repository;

  // Keep track of current filters for pagination
  String? _currentKeyword;
  bool? _currentIsActive;
  String? _currentGender;
  static const int _limit = 10;

  AsatidzCubit(this.repository) : super(AsatidzInitial());

  void loadAsatidz({String? keyword, bool? isActive, String? gender}) async {
    _currentKeyword = keyword;
    _currentIsActive = isActive;
    _currentGender = gender;

    emit(AsatidzLoading());
    try {
      final result = await repository.getAsatidzList(
        keyword: keyword,
        isActive: isActive,
        gender: gender,
        limit: _limit,
      );

      final isSearching = keyword != null && keyword.isNotEmpty;

      emit(
        AsatidzLoaded(
          result,
          hasReachedMax: isSearching ? true : result.length < _limit,
        ),
      );
    } catch (e) {
      emit(AsatidzError(ErrorHandler.getMessage(e)));
    }
  }

  void loadMoreAsatidz() async {
    final currentState = state;
    if (currentState is! AsatidzLoaded) return;
    if (currentState.hasReachedMax || currentState.isFetchingMore) return;

    if (_currentKeyword != null && _currentKeyword!.isNotEmpty) return;

    emit(currentState.copyWith(isFetchingMore: true));

    try {
      final lastId = currentState.asatidz.last.id;
      final newAsatidz = await repository.getAsatidzList(
        keyword: _currentKeyword,
        isActive: _currentIsActive,
        gender: _currentGender,
        limit: _limit,
        lastDocumentId: lastId,
      );

      emit(
        currentState.copyWith(
          asatidz: List.of(currentState.asatidz)..addAll(newAsatidz),
          hasReachedMax: newAsatidz.length < _limit,
          isFetchingMore: false,
        ),
      );
    } catch (e) {
      emit(currentState.copyWith(isFetchingMore: false));
    }
  }

  Future<void> addAsatidz(AsatidzParams params) async {
    emit(AsatidzLoading());
    String? photoUrl;
    try {
      if (params.localPhotoFile != null && params.isActive) {
        photoUrl = await ImageUtils.uploadImageToFirebase(
          params.localPhotoFile!,
          'asatidz_photos',
        );
        if (photoUrl == null) {
          emit(AsatidzError('Gagal mengupload foto'));
          return;
        }
      }

      final temporaryPassword = await repository.addAsatidz(
        AsatidzParams(
          name: params.name,
          nis: params.nis,
          phone: params.phone,
          jenisKelamin: params.jenisKelamin,
          isActive: params.isActive,
          photoUrl: photoUrl,
        ),
      );
      emit(
        AsatidzCreated(nis: params.nis, temporaryPassword: temporaryPassword),
      );
    } catch (e) {
      if (photoUrl != null) {
        await ImageUtils.deleteImageFromFirebase(photoUrl);
      }
      emit(AsatidzError(ErrorHandler.getMessage(e)));
    }
  }

  Future<String> getNextNis() => repository.getNextNis();
}
