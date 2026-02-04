import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_detail.dart';

sealed class AsatidzDetailState {}

class AsatidzDetailInitial extends AsatidzDetailState {}

class AsatidzDetailLoading extends AsatidzDetailState {}

class AsatidzDetailLoaded extends AsatidzDetailState {
  final AsatidzDetail detail;

  AsatidzDetailLoaded(this.detail);
}

class AsatidzDetailError extends AsatidzDetailState {
  final String message;

  AsatidzDetailError(this.message);
}
