import 'package:flutter_bloc/flutter_bloc.dart';
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

  Future<void> updateAsatidz(String id, AsatidzParams params) async {
    emit(AsatidzDetailLoading());
    try {
      await repository.updateAsatidz(id, params);
      final detail = await repository.getAsatidzDetail(id);
      emit(AsatidzDetailLoaded(detail));
    } catch (e) {
      emit(AsatidzDetailError(ErrorHandler.getMessage(e)));
    }
  }
}
