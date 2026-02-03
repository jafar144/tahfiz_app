import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/features/management_santri/domain/repository/santri_repository.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_params.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/cubit/santri_state.dart';

class SantriCubit extends Cubit<SantriState> {
  final SantriRepository repository;

  SantriCubit(this.repository) : super(SantriInitial());

  void loadSantri({
    String? keyword,
    bool? isActive,
  }) async {
    emit(SantriLoading());
    try {
      final result = await repository.getSantriList(
        keyword: keyword,
        isActive: isActive,
      );

      debugPrint(result.toString());
      emit(SantriLoaded(result));
    } catch (e) {
      emit(SantriError(e.toString()));
    }
  }

  Future<void> addSantri(SantriParams params) async {
    emit(SantriLoading());
    try {
      await repository.addSantri(params);
      loadSantri(); // Refresh list
    } catch (e) {
      emit(SantriError(e.toString()));
    }
  }
}
