import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/core/utils/error_handler.dart';
import 'package:khoirunnasyien/features/family/data/family_repository.dart';
import 'package:khoirunnasyien/features/family/presentation/cubit/family_state.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_santri/domain/repository/santri_repository.dart';

class FamilyCubit extends Cubit<FamilyState> {
  final FamilyRepository familyRepository;
  final SantriRepository santriRepository;

  FamilyCubit({required this.familyRepository, required this.santriRepository})
    : super(FamilyInitial());

  Future<void> loadFamilies() async {
    emit(FamilyLoading());
    try {
      final families = await familyRepository.getFamilies();

      final allSantriIds = <String>{};
      for (final f in families) {
        allSantriIds.addAll(f.santriIds);
      }

      final santriList = allSantriIds.isNotEmpty
          ? await santriRepository.getSantriByIds(allSantriIds.toList())
          : <SantriEntity>[];

      final santriMap = {for (final s in santriList) s.id: s};

      final result = families.map((f) {
        final members = f.santriIds
            .where((id) => santriMap.containsKey(id))
            .map((id) => santriMap[id]!)
            .toList();
        return FamilyWithMembers(family: f, members: members);
      }).toList();

      emit(FamilyLoaded(result));
    } catch (e) {
      emit(FamilyError(ErrorHandler.getMessage(e)));
    }
  }

  Future<void> addFamily(List<String> santriIds) async {
    try {
      await familyRepository.addFamily(santriIds);
      loadFamilies();
    } catch (e) {
      emit(FamilyError(ErrorHandler.getMessage(e)));
    }
  }

  Future<void> updateFamily(String id, List<String> santriIds) async {
    try {
      await familyRepository.updateFamily(id, santriIds);
      loadFamilies();
    } catch (e) {
      emit(FamilyError(ErrorHandler.getMessage(e)));
    }
  }

  Future<void> deleteFamily(String id) async {
    try {
      await familyRepository.deleteFamily(id);
      loadFamilies();
    } catch (e) {
      emit(FamilyError(ErrorHandler.getMessage(e)));
    }
  }
}
