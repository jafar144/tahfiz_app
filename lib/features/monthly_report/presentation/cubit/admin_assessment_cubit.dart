import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_entity.dart';
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
  _AdminAssessmentRoster? _rosterCache;
  final _reportedIdsCache = <({int bulan, int tahun}), Set<String>>{};

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
  Future<void> load({DateTime? period, bool forceRefresh = false}) async {
    if (forceRefresh) {
      _rosterCache = null;
      _reportedIdsCache.clear();
    }
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

      // Roster relatif stabil selama halaman terbuka. Pindah periode memakai
      // cache yang sama; pull-to-refresh tetap mengambil data terbaru.
      final roster = await _getRoster();
      final asatidzById = roster.asatidzById;
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
      final santriByTeacher = roster.santriByTeacher;

      // Query laporan periode terpilih dan sebelumnya secara paralel. Hasil
      // juga dicache agar navigasi antar dua periode tidak mengulang request.
      // selalu ikut dimuat agar UI dapat menampilkan penanda tunggakan.
      final reportedIdsFuture = _getReportedSantriIds(selectedPeriod);
      final previousReportedIdsFuture = selectedPeriod == activePreviousPeriod
          ? reportedIdsFuture
          : _getReportedSantriIds(activePreviousPeriod);
      final reportedResults = await Future.wait([
        reportedIdsFuture,
        previousReportedIdsFuture,
      ]);
      final reportedIds = reportedResults[0];
      final previousReportedIds = reportedResults[1];

      // Susun ringkasan per pembimbing untuk periode terpilih.
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
    final key = (bulan: period.month, tahun: period.year);
    final cached = _reportedIdsCache[key];
    if (cached != null) return cached;

    final result = await reportRepository.getReportedSantriIds(
      period.month,
      period.year,
    );
    final ids = result.fold(
      ifLeft: (failure) => throw Exception(failure.message),
      ifRight: (ids) => ids,
    );
    final immutableIds = Set<String>.unmodifiable(ids);
    _reportedIdsCache[key] = immutableIds;
    return immutableIds;
  }

  Future<_AdminAssessmentRoster> _getRoster() async {
    final cached = _rosterCache;
    if (cached != null) return cached;

    // Kedua sumber independen dimulai bersamaan. Nama pembimbing tidak perlu
    // dihidrasi ulang dari halaqah karena profil aktif sudah menjadi sumbernya.
    final asatidzFuture = asatidzRepository.getAsatidzList(
      isActive: true,
      limit: 1000,
    );
    final halaqahsFuture = scheduleRepository.getAllHalaqahs(
      hydrateTeacherNames: false,
    );
    final asatidzList = await asatidzFuture;
    final halaqahsResult = await halaqahsFuture;
    final asatidzById = {
      for (final asatidz in asatidzList) asatidz.id: asatidz,
    };

    final halaqahsByTeacher = <String, List<Halaqah>>{};
    halaqahsResult.fold(
      ifLeft: (failure) => throw Exception(failure.message),
      ifRight: (halaqahs) {
        for (final halaqah in halaqahs) {
          if (!asatidzById.containsKey(halaqah.teacherId)) continue;
          halaqahsByTeacher
              .putIfAbsent(halaqah.teacherId, () => [])
              .add(halaqah);
        }
      },
    );

    var santriByHalaqah = const <String, List<SantriEntity>>{};
    if (halaqahsByTeacher.isNotEmpty) {
      final result = await scheduleRepository.getSantrisByHalaqahIds(
        halaqahsByTeacher.values.expand(
          (halaqahs) => halaqahs.map((h) => h.id),
        ),
      );
      result.fold(
        ifLeft: (_) {},
        ifRight: (santris) => santriByHalaqah = santris,
      );
    }

    final santriByTeacher = <String, Map<String, SantriEntity>>{};
    for (final entry in halaqahsByTeacher.entries) {
      final santriById = <String, SantriEntity>{};
      for (final halaqah in entry.value) {
        for (final santri in santriByHalaqah[halaqah.id] ?? const []) {
          if (santri.isActive) santriById[santri.id] = santri;
        }
      }
      if (santriById.isNotEmpty) santriByTeacher[entry.key] = santriById;
    }

    final roster = _AdminAssessmentRoster(
      asatidzById: Map.unmodifiable(asatidzById),
      santriByTeacher: Map.unmodifiable(santriByTeacher),
    );
    _rosterCache = roster;
    return roster;
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

class _AdminAssessmentRoster {
  final Map<String, AsatidzEntity> asatidzById;
  final Map<String, Map<String, SantriEntity>> santriByTeacher;

  const _AdminAssessmentRoster({
    required this.asatidzById,
    required this.santriByTeacher,
  });
}
