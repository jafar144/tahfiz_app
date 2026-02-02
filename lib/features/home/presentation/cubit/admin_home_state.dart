import '../../domain/entities/admin_home_data.dart';

abstract class AdminHomeState {}

class AdminHomeInitial extends AdminHomeState {}

class AdminHomeLoading extends AdminHomeState {}

class AdminHomeLoaded extends AdminHomeState {
  final AdminHomeData data;

  AdminHomeLoaded(this.data);
}

class AdminHomeError extends AdminHomeState {
  final String message;

  AdminHomeError(this.message);
}
