import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:khoirunnasyien/features/asatidz/domain/entities/active_halaqah.dart';
import 'package:khoirunnasyien/features/asatidz/domain/entities/santri_setoran.dart';
import 'package:khoirunnasyien/features/asatidz/domain/repositories/asatidz_repository.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/repositories/schedule_repository.dart';
import 'package:khoirunnasyien/core/utils/error_handler.dart';

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
        ifRight: (s) => List<SantriEntity>.from(s),
      );

      final DateFormat formatter = DateFormat('yyyy-MM-dd');
      final String dateStr = formatter.format(DateTime.now());

      final meetingResult = await repository.getMeeting(
        halaqahId: activeHalaqah.halaqah.id,
        scheduleId: activeHalaqah.schedule.id,
        date: dateStr,
      );

      final meeting = meetingResult.fold(ifLeft: (l) => null, ifRight: (r) => r);
      if (meeting != null) {
        final membersResult = await repository.getMeetingMembers(meeting.id);
        membersResult.fold(
          ifLeft: (l) => null,
          ifRight: (members) {
            for (final member in members) {
              final isGuest = !santris.any((s) => s.id == member.santriId);
              if (isGuest) {
                santris.add(SantriEntity(
                  id: member.santriId,
                  name: member.santriName,
                  nis: member.santriNis ?? '-',
                  kelas: '-',
                  jenisKelamin: '-',
                  isActive: true,
                  isFree: false,
                  halaqahId: member.halaqahAsalId,
                ));
              }
            }
          }
        );
      }

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
      emit(HalaqahDepositListError(ErrorHandler.getMessage(e)));
    }
  }
}
