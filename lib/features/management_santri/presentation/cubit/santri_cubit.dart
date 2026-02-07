import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/features/management_santri/domain/repository/santri_repository.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_params.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/cubit/santri_state.dart';

class SantriCubit extends Cubit<SantriState> {
  final SantriRepository repository;

  // Keep track of current filters for pagination
  String? _currentKeyword;
  bool? _currentIsActive;
  String? _currentGender;
  static const int _limit = 10;

  SantriCubit(this.repository) : super(SantriInitial());

  void loadSantri({
    String? keyword,
    bool? isActive,
    String? gender,
  }) async {
    _currentKeyword = keyword;
    _currentIsActive = isActive;
    _currentGender = gender;
    
    emit(SantriLoading());
    try {
      final result = await repository.getSantriList(
        keyword: keyword,
        isActive: isActive,
        gender: gender,
        limit: _limit,
      );

      // If filtering by keyword, pagination is disabled (all data returned)
      // So hasReachedMax is effectively true
      final isSearching = keyword != null && keyword.isNotEmpty;
      
      emit(SantriLoaded(
        result,
        hasReachedMax: isSearching ? true : result.length < _limit,
      ));
    } catch (e) {
      emit(SantriError(e.toString()));
    }
  }

  void loadMoreSantri() async {
    final currentState = state;
    if (currentState is! SantriLoaded) return;
    if (currentState.hasReachedMax || currentState.isFetchingMore) return;

    // Search logic fetches all data at once, so no "load more" needed
    if (_currentKeyword != null && _currentKeyword!.isNotEmpty) return;

    // Already loading more
    emit(currentState.copyWith(isFetchingMore: true));

    try {
      final lastId = currentState.santri.last.id;
      final newSantri = await repository.getSantriList(
        keyword: _currentKeyword,
        isActive: _currentIsActive,
        gender: _currentGender,
        limit: _limit,
        lastDocumentId: lastId,
      );

      emit(currentState.copyWith(
        santri: List.of(currentState.santri)..addAll(newSantri),
        hasReachedMax: newSantri.length < _limit,
        isFetchingMore: false,
      ));
    } catch (e) {
      // On error, keep the current data but stop loading
      emit(currentState.copyWith(isFetchingMore: false));
      // Optionally emit a side-effect or different error state
    }
  }

  Future<void> addSantri(SantriParams params) async {
    // We emit specific loading state if needed, or stick to SantriLoading which clears list
    // Or better: keep list but show overlay loading. For now, following existing pattern:
    emit(SantriLoading());
    try {
      await repository.addSantri(params);
      loadSantri(keyword: _currentKeyword, isActive: _currentIsActive);
    } catch (e) {
      emit(SantriError(e.toString()));
    }
  }
}
