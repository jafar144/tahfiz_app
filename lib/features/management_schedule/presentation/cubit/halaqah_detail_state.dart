import 'package:khoirunnasyien/features/management_schedule/domain/entities/halaqah.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_entity.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';

abstract class HalaqahDetailState {
  const HalaqahDetailState();
}

class HalaqahDetailInitial extends HalaqahDetailState {
  final Halaqah halaqah;
  const HalaqahDetailInitial(this.halaqah);
}

class HalaqahDetailLoading extends HalaqahDetailState {}

class HalaqahDetailLoaded extends HalaqahDetailState {
  final Halaqah halaqah;
  final List<AsatidzEntity> asatidzList;
  final List<SantriEntity> santriList;
  
  const HalaqahDetailLoaded({
    required this.halaqah,
    this.asatidzList = const [],
    this.santriList = const [],
  });
}

class HalaqahDetailUpdating extends HalaqahDetailState {}

class HalaqahDetailSuccess extends HalaqahDetailState {}

class HalaqahDetailError extends HalaqahDetailState {
  final String message;
  const HalaqahDetailError(this.message);
}
