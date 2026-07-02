import 'package:equatable/equatable.dart';

/// Energi main kuis ala game: dibatasi agar pemakaian transkripsi (Whisper)
/// tidak jebol. 1 sesi kuis memakai 1 energi; energi terisi otomatis seiring
/// waktu.
class QuizEnergy extends Equatable {
  /// Energi saat ini (0..[max]).
  final int current;

  /// Kapasitas maksimum.
  final int max;

  /// Waktu ketika +1 energi berikutnya tersedia; null bila sudah penuh.
  final DateTime? nextRefillAt;

  const QuizEnergy({
    required this.current,
    required this.max,
    this.nextRefillAt,
  });

  bool get isFull => current >= max;

  /// Masih bisa memulai sesi kuis.
  bool get canPlay => current > 0;

  @override
  List<Object?> get props => [current, max, nextRefillAt];
}
