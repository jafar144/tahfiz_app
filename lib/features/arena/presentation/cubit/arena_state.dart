import 'package:equatable/equatable.dart';

import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_energy.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/quiz_curriculum.dart';

enum ArenaStatus { loading, ready, error }

/// State shell Tahfiz Arena: profil ringkas user (role + kelas), energi untuk
/// top bar, dan status jatah Tantangan harian per mode.
class ArenaState extends Equatable {
  final ArenaStatus status;
  final String? errorMessage;

  /// Role user: 'admin' / 'asatidz' / 'santri' / '' (belum termuat).
  final String role;

  /// Kelas santri (null untuk admin/asatidz atau belum termuat).
  final String? kelas;

  /// Energi kuis terkini; null bila belum dimuat.
  final QuizEnergy? energy;

  /// True selama energi sedang dimuat (tampilkan skeleton di top bar).
  final bool energyLoading;

  const ArenaState({
    this.status = ArenaStatus.loading,
    this.errorMessage,
    this.role = '',
    this.kelas,
    this.energy,
    this.energyLoading = false,
  });

  bool get isSantri => role == 'santri';

  /// Boleh masuk Tantangan: santri dengan kelas yang punya paket kurikulum
  /// (kelas Tahsin & admin/asatidz tidak).
  bool get canChallenge => isSantri && QuizCurriculum.canChallenge(kelas);

  /// Sisa kuota Tantangan minggu ini per mode; null bila energi belum termuat.
  int? get voiceChallengeLeft => energy?.challengeVoiceLeft;
  int? get choiceChallengeLeft => energy?.challengeChoiceLeft;

  /// True bila kuota mode tsb PASTI habis (energi termuat & sisa 0). Selama
  /// energi belum termuat, kartu tetap bisa diketuk — server penegak aslinya.
  bool get voiceQuotaEmpty => (energy?.challengeVoiceLeft ?? 1) <= 0;
  bool get choiceQuotaEmpty => (energy?.challengeChoiceLeft ?? 1) <= 0;

  ArenaState copyWith({
    ArenaStatus? status,
    String? errorMessage,
    String? role,
    String? kelas,
    QuizEnergy? energy,
    bool? energyLoading,
  }) {
    return ArenaState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      role: role ?? this.role,
      kelas: kelas ?? this.kelas,
      energy: energy ?? this.energy,
      energyLoading: energyLoading ?? this.energyLoading,
    );
  }

  @override
  List<Object?> get props => [
    status,
    errorMessage,
    role,
    kelas,
    energy,
    energyLoading,
  ];
}
