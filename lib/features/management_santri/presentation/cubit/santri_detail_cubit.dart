import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_params.dart';
import 'package:khoirunnasyien/features/management_santri/domain/repository/santri_repository.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/cubit/santri_detail_state.dart';

class SantriDetailCubit extends Cubit<SantriDetailState> {
  final SantriRepository repository;

  SantriDetailCubit(this.repository) : super(SantriDetailInitial());

  Future<void> loadDetail(String id) async {
    emit(SantriDetailLoading());
    try {
      final detail = await repository.getSantriDetail(id);
      emit(SantriDetailLoaded(detail));
    } catch (e) {
      emit(SantriDetailError(e.toString()));
    }
  }

  Future<void> updateSantri(String id, SantriParams params) async {
    emit(SantriDetailLoading());
    try {
      await repository.updateSantri(id, params);
      loadDetail(id);
    } catch (e) {
      emit(SantriDetailError(e.toString()));
    }
  }
}
