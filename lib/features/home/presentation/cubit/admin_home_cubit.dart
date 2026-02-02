import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/features/auth/domain/auth_repository.dart';
import '../../domain/repositories/admin_home_repository.dart';
import 'admin_home_state.dart';

class AdminHomeCubit extends Cubit<AdminHomeState> {
  final AdminHomeRepository repository;
  final AuthRepository authRepository;

  AdminHomeCubit(
    this.repository,
    this.authRepository,
  ) : super(AdminHomeInitial());

  Future<void> loadHome() async {
    try {
      emit(AdminHomeLoading());

      final firebaseUser = authRepository.currentUser();
      if (firebaseUser == null) {
        throw Exception('User not logged in');
      }

      final data = await repository.getHomeData(
        adminUid: firebaseUser.uid,
      );

      emit(AdminHomeLoaded(data));
    } catch (e) {
      emit(AdminHomeError(e.toString()));
    }
  }
}
