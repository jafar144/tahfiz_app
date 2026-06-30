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

  /// Ayat target yang diperiksa pada hasil terakhir (untuk ditampilkan).
  final List<Ayah> checkedAyat;
  final String? errorMessage;

  const RecitationCheckState({
    this.status = RecitationStatus.initial,
    this.surahs = const [],
    this.selectedSurah,
    this.fromAyah = 1,
    this.toAyah = 1,
    this.result,
    this.checkedAyat = const [],
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
    List<Ayah>? checkedAyat,
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
      checkedAyat: checkedAyat ?? this.checkedAyat,
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
        checkedAyat,
        errorMessage,
      ];
}
