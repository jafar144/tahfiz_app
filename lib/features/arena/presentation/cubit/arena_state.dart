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

  /// Kunci tanggal (yyyy-mm-dd, WIB) terakhir Tantangan dimainkan per mode;
  /// null bila belum pernah. Hanya untuk TAMPILAN kartu (server yang benar-
  /// benar menegakkan jatah harian).
  final String? voicePlayedDate;
  final String? choicePlayedDate;

  const ArenaState({
    this.status = ArenaStatus.loading,
    this.errorMessage,
    this.role = '',
    this.kelas,
    this.energy,
    this.energyLoading = false,
    this.voicePlayedDate,
    this.choicePlayedDate,
  });

  bool get isSantri => role == 'santri';

  /// Boleh masuk Tantangan: santri dengan kelas yang punya paket kurikulum
  /// (kelas Tahsin & admin/asatidz tidak).
  bool get canChallenge => isSantri && QuizCurriculum.canChallenge(kelas);

  /// Kunci tanggal hari ini menurut WIB (untuk membandingkan jatah harian).
  static String todayKeyWib() {
    final wib = DateTime.now().toUtc().add(const Duration(hours: 7));
    String two(int n) => n.toString().padLeft(2, '0');
    return '${wib.year}-${two(wib.month)}-${two(wib.day)}';
  }

  bool get voiceDoneToday => voicePlayedDate == todayKeyWib();
  bool get choiceDoneToday => choicePlayedDate == todayKeyWib();

  ArenaState copyWith({
    ArenaStatus? status,
    String? errorMessage,
    String? role,
    String? kelas,
    QuizEnergy? energy,
    bool? energyLoading,
    String? voicePlayedDate,
    String? choicePlayedDate,
  }) {
    return ArenaState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      role: role ?? this.role,
      kelas: kelas ?? this.kelas,
      energy: energy ?? this.energy,
      energyLoading: energyLoading ?? this.energyLoading,
      voicePlayedDate: voicePlayedDate ?? this.voicePlayedDate,
      choicePlayedDate: choicePlayedDate ?? this.choicePlayedDate,
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
    voicePlayedDate,
    choicePlayedDate,
  ];
}
