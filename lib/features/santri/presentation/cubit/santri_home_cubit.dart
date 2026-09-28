import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/features/management_santri/domain/repository/santri_repository.dart';
import 'package:khoirunnasyien/features/payment/domain/repositories/payment_repository.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/repositories/schedule_repository.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/repository/asatidz_repository.dart'
    as mgmt_asatidz_domain;
import 'package:khoirunnasyien/features/santri/presentation/cubit/santri_home_state.dart';
import 'package:khoirunnasyien/features/asatidz/domain/entities/santri_setoran.dart';
import 'package:khoirunnasyien/features/asatidz/domain/repositories/asatidz_repository.dart';
import 'package:khoirunnasyien/core/utils/payment_utils.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/entities/monthly_report.dart';
import 'package:khoirunnasyien/features/monthly_report/domain/repositories/monthly_report_repository.dart';
import 'package:khoirunnasyien/features/family/data/family_repository.dart';
import 'package:khoirunnasyien/features/family/domain/entities/family_account.dart';

class SantriHomeCubit extends Cubit<SantriHomeState> {
  final SantriRepository santriRepository;
  final PaymentRepository paymentRepository;
  final ScheduleRepository scheduleRepository;
  final AsatidzRepository asatidzRepository;
  final mgmt_asatidz_domain.AsatidzRepository mgmtAsatidzRepository;
  final MonthlyReportRepository monthlyReportRepository;
  final FamilyRepository familyRepository;

  SantriHomeCubit({
    required this.santriRepository,
    required this.paymentRepository,
    required this.scheduleRepository,
    required this.asatidzRepository,
    required this.mgmtAsatidzRepository,
    required this.monthlyReportRepository,
    required this.familyRepository,
  }) : super(const SantriHomeState());

  String? _currentSantriId;
  String? _currentTeacherId;
  String? get currentSantriId => _currentSantriId;

  Future<void> loadData(String santriId) async {
    if (isClosed) return;
    _currentSantriId = santriId;
    _currentTeacherId = null;
    emit(const SantriHomeState(status: SantriHomeStatus.loading));

    try {
      // 1. Fetch Santri Profile
      final santri = await santriRepository.getSantriDetail(santriId);

      // 2. Fetch Payment Status (Full History)
      final now = DateTime.now();
      final paymentHistory = await paymentRepository.getPaymentHistoryBySantri(
        santriId,
        null,
      );

      // Calculate overdue months from startDate up to now.
      int overdueMonthsCount = 0;
      final startDate = PaymentUtils.resolveStartDate(
        freeUntil: santri.freeUntil,
        tanggalMasuk: santri.tanggalMasuk,
      );

      if (startDate != null) {
        DateTime current = DateTime(startDate.year, startDate.month);
        final end = DateTime(now.year, now.month);

        while (!current.isAfter(end)) {
          final monthStr = current.month.toString();
          final yearStr = current.year.toString();

          final isPaid = paymentHistory.any(
            (p) => p.bulan == monthStr && p.tahun == yearStr,
          );
          if (!isPaid) {
            overdueMonthsCount++;
          }

          // Move to next month
          current = DateTime(current.year, current.month + 1);
        }
      }

      // 3. Fetch Latest Setoran
      SantriSetoran? latestSetoran;

      final setoranResult = await asatidzRepository.getSetoranHistory(
        santriId: santriId,
      );

      setoranResult.fold(
        ifLeft: (l) {}, // Ignore error for now
        ifRight: (r) {
          if (r.isNotEmpty) {
            // Sort by date desc
            r.sort((a, b) => b.date.compareTo(a.date));
            latestSetoran = r.first;
          }
        },
      );

      // 4. Fetch Pembimbing (via Halaqah)
      String? pembimbingName = _usablePembimbingName(santri.pembimbing);
      String? pembimbingPhone;
      String? pembimbingGender;

      final halaqahResult = await scheduleRepository.getHalaqahBySantriId(
        santriId,
      );

      await halaqahResult.fold(
        ifLeft: (failure) async {
          debugPrint('[SantriHome] Gagal memuat halaqah: ${failure.message}');
        },
        ifRight: (r) async {
          if (r != null) {
            _currentTeacherId = r.teacherId;
            final halaqahTeacherName = _usablePembimbingName(r.teacherName);
            if (halaqahTeacherName != null) {
              pembimbingName = halaqahTeacherName;
            }
            // Fetch phone & gender from AsatidzDetail
            try {
              final asatidzDetail = await mgmtAsatidzRepository
                  .getAsatidzDetail(r.teacherId);
              final detailName = _usablePembimbingName(asatidzDetail.name);
              if (detailName != null) {
                pembimbingName = detailName;
              }
              pembimbingPhone = _normalizePhone(asatidzDetail.phone);
              pembimbingGender = _normalizeGender(asatidzDetail.jenisKelamin);
            } catch (error) {
              debugPrint('[SantriHome] Gagal memuat kontak pembimbing: $error');
              // Halaqah memasangkan pengajar dan santri dengan gender yang
              // sama. Gelar tetap bisa ditampilkan saat kontak tidak tersedia.
              pembimbingGender = _normalizeGender(santri.jenisKelamin);
            }
          }
        },
      );

      // 5. Fetch laporan bulanan. Daftar lengkap dipakai untuk memasangkan
      // target dengan periode penilaiannya; item pertama tetap yang terbaru.
      MonthlyReport? latestReport;
      List<MonthlyReport> monthlyReports = const [];
      final reportResult = await monthlyReportRepository.getReportsBySantri(
        santriId,
      );
      reportResult.fold(
        ifLeft: (_) {},
        ifRight: (reports) {
          monthlyReports = reports;
          if (reports.isNotEmpty) latestReport = reports.first;
        },
      );

      // 6. Fetch saudara (akun lain dalam satu keluarga) untuk fitur ganti akun.
      var familyMembers = const <FamilyAccount>[];
      var familyMembersLoadFailed = false;
      try {
        familyMembers = await familyRepository.getFamilyAccounts();
      } catch (error) {
        familyMembersLoadFailed = true;
        debugPrint('[SantriHome] Gagal memuat akun keluarga: $error');
      }

      if (isClosed) return;

      emit(
        SantriHomeState(
          status: SantriHomeStatus.success,
          santri: santri,
          overdueMonthsCount: overdueMonthsCount,
          paymentHistory: paymentHistory,
          latestSetoran: latestSetoran,
          pembimbingName: pembimbingName,
          pembimbingPhone: pembimbingPhone,
          pembimbingGender: pembimbingGender,
          latestReport: latestReport,
          monthlyReports: monthlyReports,
          familyMembers: familyMembers,
          familyMembersLoadFailed: familyMembersLoadFailed,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(status: SantriHomeStatus.failure, message: e.toString()),
      );
    }
  }

  Future<void> retryFamilyAccounts() async {
    final santriId = _currentSantriId;
    if (isClosed || santriId == null || state.isLoadingFamilyMembers) return;
    emit(state.copyWith(isLoadingFamilyMembers: true));
    try {
      final accounts = await familyRepository.getFamilyAccounts();
      if (isClosed || _currentSantriId != santriId) return;
      emit(
        state.copyWith(
          familyMembers: accounts,
          familyMembersLoadFailed: false,
          isLoadingFamilyMembers: false,
        ),
      );
    } catch (error) {
      debugPrint('[SantriHome] Gagal memuat ulang akun keluarga: $error');
      if (isClosed || _currentSantriId != santriId) return;
      emit(
        state.copyWith(
          familyMembersLoadFailed: true,
          isLoadingFamilyMembers: false,
        ),
      );
    }
  }

  /// Mengambil ulang kontak tanpa me-reload seluruh halaman.
  Future<String?> retryPembimbingContact() async {
    final santriId = _currentSantriId;
    if (santriId == null || isClosed) return null;

    try {
      var teacherId = _currentTeacherId;
      if (teacherId == null || teacherId.trim().isEmpty) {
        final result = await scheduleRepository.getHalaqahBySantriId(santriId);
        teacherId = result.fold(
          ifLeft: (_) => null,
          ifRight: (halaqah) => halaqah?.teacherId,
        );
        if (isClosed || _currentSantriId != santriId) return null;
        if (teacherId == null || teacherId.trim().isEmpty) return null;
        _currentTeacherId = teacherId;
      }
      final detail = await mgmtAsatidzRepository.getAsatidzDetail(teacherId);
      final phone = _normalizePhone(detail.phone);
      if (phone == null || isClosed || _currentSantriId != santriId) {
        return null;
      }

      emit(
        state.copyWith(
          pembimbingName:
              _usablePembimbingName(detail.name) ?? state.pembimbingName,
          pembimbingPhone: phone,
          pembimbingGender:
              _normalizeGender(detail.jenisKelamin) ??
              _normalizeGender(state.santri?.jenisKelamin),
        ),
      );
      return phone;
    } catch (error) {
      debugPrint('[SantriHome] Gagal memuat ulang kontak pembimbing: $error');
      return null;
    }
  }
}

String? _usablePembimbingName(String? value) {
  final name = value?.trim();
  if (name == null || name.isEmpty || name.toLowerCase() == 'belum ada') {
    return null;
  }
  return name;
}

String? _normalizePhone(String? value) {
  final phone = value?.trim();
  return phone == null || phone.isEmpty ? null : phone;
}

String? _normalizeGender(String? value) {
  return switch (value?.trim().toUpperCase()) {
    'L' => 'L',
    'P' => 'P',
    _ => null,
  };
}
