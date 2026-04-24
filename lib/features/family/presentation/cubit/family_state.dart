import 'package:khoirunnasyien/features/family/data/family_repository.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';

sealed class FamilyState {}

class FamilyInitial extends FamilyState {}

class FamilyLoading extends FamilyState {}

class FamilyLoaded extends FamilyState {
  final List<FamilyWithMembers> families;
  FamilyLoaded(this.families);
}

class FamilyError extends FamilyState {
  final String message;
  FamilyError(this.message);
}

class FamilyWithMembers {
  final FamilyEntity family;
  final List<SantriEntity> members;

  FamilyWithMembers({required this.family, required this.members});
}
