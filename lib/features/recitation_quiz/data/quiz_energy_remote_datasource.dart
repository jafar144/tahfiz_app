import 'package:cloud_functions/cloud_functions.dart';

import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_energy.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_mode.dart';

/// Memanggil Cloud Function energi kuis (`getQuizEnergy` / `consumeQuizEnergy`).
///
/// Energi dihitung sepenuhnya di server (waktu server) agar tidak bisa diakali
/// dengan mengubah jam perangkat. Sisa pengisian dikirim sebagai detik relatif,
/// lalu diubah jadi waktu absolut lokal untuk hitung mundur di UI.
class QuizEnergyRemoteDataSource {
  final FirebaseFunctions functions;

  QuizEnergyRemoteDataSource(this.functions);

  /// Ambil energi terkini (untuk tampilan). Melempar [FirebaseFunctionsException].
  Future<QuizEnergy> getEnergy() => _callEnergy('getQuizEnergy');

  /// Mulai sesi. Server menentukan aturan dari parameter:
  ///  • latihan (practice) → potong 1 energi; Tantangan → cek jatah harian.
  ///  • mode suara → ambil lock 1-user (jaga kuota Whisper); pilihan tidak.
  /// Melempar [FirebaseFunctionsException] dengan `details['reason']` bila
  /// terblokir.
  Future<QuizEnergy> startSession({
    required QuizMode mode,
    bool challenge = false,
  }) => _callEnergy('startQuizSession', {
    'kind': challenge ? 'challenge' : 'practice',
    'mode': mode.key,
  });

  /// Perpanjang lock; abaikan kegagalan (best-effort).
  Future<void> heartbeat() => _callVoid('heartbeatQuizSession');

  /// Lepas lock; abaikan kegagalan (best-effort).
  Future<void> endSession() => _callVoid('endQuizSession');

  Future<QuizEnergy> _callEnergy(String name, [Map<String, dynamic>? params]) async {
    final callable = functions.httpsCallable(
      name,
      options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
    );
    final result = await callable.call(params);
    // Data callable bisa kembali sebagai Map<Object?, Object?>; normalisasi.
    final data = Map<String, dynamic>.from(result.data as Map);

    final current = (data['current'] as num?)?.toInt() ?? 0;
    final max = (data['max'] as num?)?.toInt() ?? current;
    final secs = (data['nextRefillInSeconds'] as num?)?.toInt();

    return QuizEnergy(
      current: current,
      max: max,
      nextRefillAt: secs == null
          ? null
          : DateTime.now().add(Duration(seconds: secs)),
    );
  }

  Future<void> _callVoid(String name) async {
    try {
      final callable = functions.httpsCallable(
        name,
        options: HttpsCallableOptions(timeout: const Duration(seconds: 15)),
      );
      await callable.call();
    } catch (_) {
      // best-effort: heartbeat/endSession tak boleh mengganggu alur main.
    }
  }
}
