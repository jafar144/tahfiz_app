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

  AdminAssessmentCubit({
    required this.scheduleRepository,
    required this.reportRepository,
    required this.asatidzRepository,
  }) : super(const AdminAssessmentInitial());

  /// Memuat status penilaian bulan berjalan untuk SEMUA pembimbing
  /// (putra & putri) sekaligus. Pemilihan tab Putra/Putri dilakukan di UI
  /// tanpa request ulang.
  Future<void> load() async {
    emit(const AdminAssessmentLoading());

    try {
      final now = DateTime.now();
      final bulan = now.month;
      final tahun = now.year;

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

      // 3. Santri yang sudah dinilai bulan ini (sekali query).
      final reportedResult = await reportRepository.getReportedSantriIds(
        bulan,
        tahun,
      );
      final reportedIds = reportedResult.fold(
        ifLeft: (_) => <String>{},
        ifRight: (ids) => ids,
      );

      // 4. Susun ringkasan per pembimbing.
      final pembimbingList = <PembimbingAssessment>[];
      for (final entry in halaqahsByTeacher.entries) {
        final teacherId = entry.key;
        final asatidz = asatidzById[teacherId]!;

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

        if (santriById.isEmpty) continue;

        final unassessed =
            santriById.values
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
            totalSantri: santriById.length,
            unassessedSantri: unassessed,
          ),
        );
      }

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
          pembimbingList: pembimbingList,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(AdminAssessmentError(e.toString()));
    }
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
