import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/features/management_santri/domain/repository/santri_repository.dart';
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
      emit(SantriLoaded(result));
    } catch (e) {
      emit(SantriError(e.toString()));
    }
  }
}
