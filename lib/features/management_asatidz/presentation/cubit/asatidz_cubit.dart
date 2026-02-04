
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_params.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/repository/asatidz_repository.dart';
import 'package:khoirunnasyien/features/management_asatidz/presentation/cubit/asatidz_state.dart';

class AsatidzCubit extends Cubit<AsatidzState> {
  final AsatidzRepository repository;

  AsatidzCubit(this.repository) : super(AsatidzInitial());

  void loadAsatidz({
    String? keyword,
    bool? isActive,
  }) async {
    emit(AsatidzLoading());
    try {
      final result = await repository.getAsatidzList(
        keyword: keyword,
        isActive: isActive,
      );

      emit(AsatidzLoaded(result));
    } catch (e) {
      emit(AsatidzError(e.toString()));
    }
  }

  Future<void> addAsatidz(AsatidzParams params) async {
    emit(AsatidzLoading());
    try {
      await repository.addAsatidz(params);
      loadAsatidz();
    } catch (e) {
      emit(AsatidzError(e.toString()));
    }
  }
}
