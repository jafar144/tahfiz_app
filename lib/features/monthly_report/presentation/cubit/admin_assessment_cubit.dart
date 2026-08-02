import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/repository/asatidz_repository.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/halaqah.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/repositories/schedule_repository.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/entities/pembimbing_assessment.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/repositories/monthly_report_repository.dart';
import 'package:khoirunnasyien/features/monthly_report/presentation/cubit/admin_assessment_state.dart';

class AdminAssessmentCubit extends Cubit<AdminAssessmentState> {
  final ScheduleRepository scheduleRepository;
  final MonthlyReportRepository reportRepository;
  final AsatidzRepository asatidzRepository;
  final DateTime Function() _now;

  AdminAssessmentCubit({
    required this.scheduleRepository,
    required this.reportRepository,
    required this.asatidzRepository,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       super(const AdminAssessmentInitial());

  DateTime get currentPeriod {
    final now = _now();
    return DateTime(now.year, now.month);
  }

  DateTime get previousPeriod {
    final current = currentPeriod;
    return DateTime(current.year, current.month - 1);
  }

  bool isAvailablePeriod(DateTime period) {
    final normalized = DateTime(period.year, period.month);
    final current = currentPeriod;
    final previous = DateTime(current.year, current.month - 1);
    return normalized == current || normalized == previous;
  }

  /// Memuat status penilaian [period] untuk SEMUA pembimbing
  /// (putra & putri) sekaligus. Pemilihan tab Putra/Putri dilakukan di UI
  /// tanpa request ulang. Periode dibatasi ke bulan berjalan dan satu bulan
  /// sebelumnya; tanpa [period], bulan berjalan yang dimuat.
  Future<void> load({DateTime? period}) async {
    emit(const AdminAssessmentLoading());

    try {
      // Tangkap batas periode sekali agar hasil tetap konsisten, termasuk bila
      // pemuatan kebetulan berlangsung saat pergantian bulan.
      final activeCurrentPeriod = currentPeriod;
      final activePreviousPeriod = DateTime(
        activeCurrentPeriod.year,
        activeCurrentPeriod.month - 1,
      );
      final selectedPeriod = period == null
          ? activeCurrentPeriod
          : DateTime(period.year, period.month);
      if (selectedPeriod != activeCurrentPeriod &&
          selectedPeriod != activePreviousPeriod) {
        throw ArgumentError.value(
          period,
          'period',
          'Hanya bulan berjalan dan satu bulan sebelumnya yang tersedia',
        );
      }

      final bulan = selectedPeriod.month;
      final tahun = selectedPeriod.year;

      // 1. Daftar asatidz aktif (semua gender) → untuk filter & gelar.
      final asatidzList = await asatidzRepository.getAsatidzList(
        isActive: true,
        limit: 1000,
      );
      final asatidzById = {for (final a in asatidzList) a.id: a};
      if (asatidzById.isEmpty) {
        emit(
          AdminAssessmentLoaded(
            bulan: bulan,
            tahun: tahun,
            previousMonthHasIncompleteAssessment: false,
            pembimbingList: const [],
          ),
        );
        return;
      }

      // 2. Semua halaqah, dikelompokkan per pembimbing.
      final halaqahsResult = await scheduleRepository.getAllHalaqahs();
      final halaqahsByTeacher = <String, List<Halaqah>>{};
      halaqahsResult.fold(
        ifLeft: (failure) => throw Exception(failure.message),
        ifRight: (halaqahs) {
          for (final h in halaqahs) {
            if (!asatidzById.containsKey(h.teacherId)) continue;
            halaqahsByTeacher.putIfAbsent(h.teacherId, () => []).add(h);
          }
        },
      );

      // 3. Ambil santri aktif per pembimbing sekali, kemudian iriskan dengan
      // bulan masuk santri untuk masing-masing periode.
      final santriByTeacher = <String, Map<String, SantriEntity>>{};
      for (final entry in halaqahsByTeacher.entries) {
        final teacherId = entry.key;
        final santriById = <String, SantriEntity>{};
        for (final halaqah in entry.value) {
          final santrisResult = await scheduleRepository.getSantrisByHalaqahId(
            halaqah.id,
          );
          santrisResult.fold(
            ifLeft: (_) {},
            ifRight: (santris) {
              for (final s in santris) {
                if (s.isActive) santriById[s.id] = s;
              }
            },
          );
        }

        if (santriById.isNotEmpty) {
          santriByTeacher[teacherId] = santriById;
        }
      }

      // 4. Query laporan untuk periode terpilih. Status bulan sebelumnya
      // selalu ikut dimuat agar UI dapat menampilkan penanda tunggakan.
      final reportedIds = await _getReportedSantriIds(selectedPeriod);
      final previousReportedIds = selectedPeriod == activePreviousPeriod
          ? reportedIds
          : await _getReportedSantriIds(activePreviousPeriod);

      // 5. Susun ringkasan per pembimbing untuk periode terpilih.
      final pembimbingList = <PembimbingAssessment>[];
      for (final entry in santriByTeacher.entries) {
        final teacherId = entry.key;
        final asatidz = asatidzById[teacherId]!;
        final eligibleSantri = entry.value.values
            .where((santri) => _wasEnrolledIn(santri, selectedPeriod))
            .toList();

        if (eligibleSantri.isEmpty) continue;

        final unassessed =
            eligibleSantri
                .where((s) => !reportedIds.contains(s.id))
                .map(
                  (s) => UnassessedSantri(id: s.id, name: s.name, nis: s.nis),
                )
                .toList()
              ..sort(
                (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
              );

        pembimbingList.add(
          PembimbingAssessment(
            asatidzId: teacherId,
            asatidzName: asatidz.name,
            gender: asatidz.jenisKelamin,
            totalSantri: eligibleSantri.length,
            unassessedSantri: unassessed,
          ),
        );
      }

      final previousMonthHasIncompleteAssessment = santriByTeacher.values
          .expand((santriById) => santriById.values)
          .where((santri) => _wasEnrolledIn(santri, activePreviousPeriod))
          .any((santri) => !previousReportedIds.contains(santri.id));

      // Yang belum lengkap tampil di atas, lalu urut nama.
      pembimbingList.sort((a, b) {
        if (a.isComplete != b.isComplete) return a.isComplete ? 1 : -1;
        return a.asatidzName.toLowerCase().compareTo(
          b.asatidzName.toLowerCase(),
        );
      });

      if (isClosed) return;
      emit(
        AdminAssessmentLoaded(
          bulan: bulan,
          tahun: tahun,
          previousMonthHasIncompleteAssessment:
              previousMonthHasIncompleteAssessment,
          pembimbingList: pembimbingList,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(AdminAssessmentError(e.toString()));
    }
  }

  Future<Set<String>> _getReportedSantriIds(DateTime period) async {
    final result = await reportRepository.getReportedSantriIds(
      period.month,
      period.year,
    );
    return result.fold(
      ifLeft: (failure) => throw Exception(failure.message),
      ifRight: (ids) => ids,
    );
  }

  bool _wasEnrolledIn(SantriEntity santri, DateTime period) {
    final joinedAt = santri.tanggalMasuk;
    if (joinedAt == null) return true;
    final joinedPeriod = DateTime(joinedAt.year, joinedAt.month);
    return !joinedPeriod.isAfter(period);
  }

  /// Mengambil nomor WhatsApp pembimbing (dari profil user) saat akan
  /// mengirim pengingat. Mengembalikan null bila tidak tersedia.
  Future<String?> getPembimbingPhone(String asatidzId) async {
    try {
      final detail = await asatidzRepository.getAsatidzDetail(asatidzId);
      final phone = detail.phone.trim();
      return phone.isEmpty ? null : phone;
    } catch (_) {
      return null;
    }
  }
}
