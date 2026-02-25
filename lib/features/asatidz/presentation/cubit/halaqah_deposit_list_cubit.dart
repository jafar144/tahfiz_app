import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/features/asatidz/domain/entities/active_halaqah.dart';
import 'package:khoirunnasyien/features/asatidz/domain/entities/santri_setoran.dart';
import 'package:khoirunnasyien/features/asatidz/domain/repositories/asatidz_repository.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/repositories/schedule_repository.dart';

abstract class HalaqahDepositListState {}

class HalaqahDepositListInitial extends HalaqahDepositListState {}

class HalaqahDepositListLoading extends HalaqahDepositListState {}

class HalaqahDepositListLoaded extends HalaqahDepositListState {
  final List<SantriDepositSummary> summaries;
  HalaqahDepositListLoaded(this.summaries);
}

class HalaqahDepositListError extends HalaqahDepositListState {
  final String message;
  HalaqahDepositListError(this.message);
}

class SantriDepositSummary {
  final SantriEntity santri;
  final SantriSetoran? lastDeposit;
  final SantriSetoran? todayDeposit;

  SantriDepositSummary({
    required this.santri,
    this.lastDeposit,
    this.todayDeposit,
  });
}

class HalaqahDepositListCubit extends Cubit<HalaqahDepositListState> {
  final AsatidzRepository repository;
  final ScheduleRepository scheduleRepository;
  final ActiveHalaqah activeHalaqah;

  HalaqahDepositListCubit({
    required this.repository,
    required this.scheduleRepository,
    required this.activeHalaqah,
  }) : super(HalaqahDepositListInitial());

  Future<void> loadData() async {
    emit(HalaqahDepositListLoading());
    try {
      final santrisResult = await scheduleRepository.getSantrisByHalaqahId(activeHalaqah.halaqah.id);
      final santris = santrisResult.fold(
        ifLeft: (_) => <SantriEntity>[],
        ifRight: (s) => s,
      );

      final List<SantriDepositSummary> summaries = [];
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      for (final santri in santris) {
        final result = await repository.getSetoranHistory(santriId: santri.id);

        SantriSetoran? lastDeposit;
        SantriSetoran? todayDeposit;

        result.fold(
          ifLeft: (_) {},
          ifRight: (history) {
            history.sort((a, b) => b.date.compareTo(a.date));

            try {
              todayDeposit = history.firstWhere((element) {
                final elementDate = DateTime(element.date.year, element.date.month, element.date.day);
                return elementDate.isAtSameMomentAs(today);
              });
            } catch (_) {}

            try {
              lastDeposit = history.firstWhere((element) {
                final elementDate = DateTime(element.date.year, element.date.month, element.date.day);
                return elementDate.isBefore(today);
              });
            } catch (_) {}
          },
        );

        summaries.add(SantriDepositSummary(
          santri: santri,
          lastDeposit: lastDeposit,
          todayDeposit: todayDeposit,
        ));
      }

      emit(HalaqahDepositListLoaded(summaries));
    } catch (e) {
      emit(HalaqahDepositListError(e.toString()));
    }
  }
}
