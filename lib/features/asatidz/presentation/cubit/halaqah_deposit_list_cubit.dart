import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/features/asatidz/domain/entities/active_halaqah.dart';
import 'package:khoirunnasyien/features/asatidz/domain/entities/santri_setoran.dart';
import 'package:khoirunnasyien/features/asatidz/domain/repositories/asatidz_repository.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/halaqah_santri.dart';

// States
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

// Summary Model
class SantriDepositSummary {
  final HalaqahSantri santri;
  final SantriSetoran? lastDeposit;
  final SantriSetoran? todayDeposit;

  SantriDepositSummary({
    required this.santri,
    this.lastDeposit,
    this.todayDeposit,
  });
}

// Cubit
class HalaqahDepositListCubit extends Cubit<HalaqahDepositListState> {
  final AsatidzRepository repository;
  final ActiveHalaqah activeHalaqah;

  HalaqahDepositListCubit({
    required this.repository,
    required this.activeHalaqah,
  }) : super(HalaqahDepositListInitial());

  Future<void> loadData() async {
    emit(HalaqahDepositListLoading());
    try {
      final List<SantriDepositSummary> summaries = [];
      final now = DateTime.now();
      
      // Improve date comparison logic
      final today = DateTime(now.year, now.month, now.day);

      // Iterate over ALL santris in the halaqah
      for (var santri in activeHalaqah.halaqah.santris) {
        // Fetch history for each santri
        // Note: In a real app we might want to fetch all deposits for the halaqah in one go to optimize
        // but given the current repo method, we loop.
        final result = await repository.getSetoranHistory(santriId: santri.id);
        
        SantriSetoran? lastDeposit;
        SantriSetoran? todayDeposit;

        result.fold(
          ifLeft: (failure) {
             // If error, just leave deposits null
          },
          ifRight: (history) {
             // Sort by date desc (newest first)
            history.sort((a, b) => b.date.compareTo(a.date));
            
            // Check for today's deposit
            try {
               todayDeposit = history.firstWhere((element) {
                 final elementDate = DateTime(element.date.year, element.date.month, element.date.day);
                 return elementDate.isAtSameMomentAs(today);
               });
            } catch (_) {}

            // Check for last deposit (NOT today)
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
