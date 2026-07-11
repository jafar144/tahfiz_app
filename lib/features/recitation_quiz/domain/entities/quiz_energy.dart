import 'package:equatable/equatable.dart';

/// Energi main kuis ala game dengan KUOTA MINGGUAN: latihan dan Tantangan
/// masing-masing punya jatah per minggu, direset tiap Senin 00:00 WIB
/// (dihitung server — anti ubah-jam). Admin/asatidz bisa memberi tambahan
/// untuk minggu berjalan.
class QuizEnergy extends Equatable {
  /// Sisa energi LATIHAN minggu ini (0..[max]).
  final int current;

  /// Kuota latihan minggu ini (dasar + bonus pemberian).
  final int max;

  /// Sisa kuota TANTANGAN mode suara minggu ini.
  final int challengeVoiceLeft;

  /// Kuota Tantangan mode suara minggu ini.
  final int challengeVoiceMax;

  /// Sisa kuota TANTANGAN mode pilihan minggu ini.
  final int challengeChoiceLeft;

  /// Kuota Tantangan mode pilihan minggu ini.
  final int challengeChoiceMax;

  /// Waktu kuota direset (Senin 00:00 WIB berikutnya); null bila tak diketahui.
  final DateTime? resetAt;

  const QuizEnergy({
    required this.current,
    required this.max,
    this.challengeVoiceLeft = 0,
    this.challengeVoiceMax = 0,
    this.challengeChoiceLeft = 0,
    this.challengeChoiceMax = 0,
    this.resetAt,
  });

  bool get isFull => current >= max;

  /// Masih bisa memulai sesi LATIHAN.
  bool get canPlay => current > 0;

  /// Masih bisa memulai TANTANGAN mode suara / pilihan.
  bool get canChallengeVoice => challengeVoiceLeft > 0;
  bool get canChallengeChoice => challengeChoiceLeft > 0;

  @override
  List<Object?> get props => [
    current,
    max,
    challengeVoiceLeft,
    challengeVoiceMax,
    challengeChoiceLeft,
    challengeChoiceMax,
    resetAt,
  ];
}
