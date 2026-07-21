import 'package:equatable/equatable.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/entities/ayah.dart';
import 'package:khoirunnasyien/features/recitation_check/domain/entities/recitation_result.dart';

enum RecitationStatus {
  initial,
  loadingSurah,
  ready,
  recording,
  processing,
  done,
  error,
}

class RecitationCheckState extends Equatable {
  final RecitationStatus status;
  final List<SurahInfo> surahs;
  final SurahInfo? selectedSurah;
  final int fromAyah;
  final int toAyah;
  final RecitationResult? result;

  /// Ayat target yang sedang dipilih — dipakai sebagai referensi pemeriksaan
  /// bacaan, dan diberi warna per kata setelah [result] tersedia.
  final List<Ayah> targetAyat;

  /// Semua ayat pada halaman mushaf yang memuat target (termasuk surah
  /// tetangga) — ditampilkan sebagai halaman penuh.
  final List<Ayah> pageAyat;
  final String? errorMessage;

  const RecitationCheckState({
    this.status = RecitationStatus.initial,
    this.surahs = const [],
    this.selectedSurah,
    this.fromAyah = 1,
    this.toAyah = 1,
    this.result,
    this.targetAyat = const [],
    this.pageAyat = const [],
    this.errorMessage,
  });

  bool get isBusy =>
      status == RecitationStatus.processing ||
      status == RecitationStatus.loadingSurah;

  RecitationCheckState copyWith({
    RecitationStatus? status,
    List<SurahInfo>? surahs,
    SurahInfo? selectedSurah,
    int? fromAyah,
    int? toAyah,
    RecitationResult? result,
    List<Ayah>? targetAyat,
    List<Ayah>? pageAyat,
    String? errorMessage,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return RecitationCheckState(
      status: status ?? this.status,
      surahs: surahs ?? this.surahs,
      selectedSurah: selectedSurah ?? this.selectedSurah,
      fromAyah: fromAyah ?? this.fromAyah,
      toAyah: toAyah ?? this.toAyah,
      result: clearResult ? null : (result ?? this.result),
      targetAyat: targetAyat ?? this.targetAyat,
      pageAyat: pageAyat ?? this.pageAyat,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    surahs,
    selectedSurah,
    fromAyah,
    toAyah,
    result,
    targetAyat,
    pageAyat,
    errorMessage,
  ];
}
