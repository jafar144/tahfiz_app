import 'package:cloud_functions/cloud_functions.dart';

import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_energy.dart';
import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_mode.dart';

/// Memanggil Cloud Function energi kuis (`getQuizEnergy` / `startQuizSession`).
///
/// Energi (kuota mingguan) dihitung sepenuhnya di server (waktu server) agar
/// tidak bisa diakali dengan mengubah jam perangkat. Waktu reset dikirim
/// sebagai detik relatif, lalu diubah jadi waktu absolut lokal untuk UI.
class QuizEnergyRemoteDataSource {
  final FirebaseFunctions functions;

  QuizEnergyRemoteDataSource(this.functions);

  /// Ambil energi terkini (untuk tampilan). Melempar [FirebaseFunctionsException].
  Future<QuizEnergy> getEnergy() => _callEnergy('getQuizEnergy');

  /// Mulai sesi. Server menentukan aturan dari parameter:
  ///  • latihan (practice) → potong 1 energi mingguan; Tantangan → potong
  ///    kuota mingguan mode terkait.
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

  /// Beri energi tambahan minggu berjalan ke [uid] (khusus admin/asatidz).
  /// Mengembalikan energi terbaru milik santri tersebut.
  Future<QuizEnergy> grantEnergy({
    required String uid,
    required int practice,
    required int challengeVoice,
    required int challengeChoice,
  }) async {
    final callable = functions.httpsCallable(
      'grantQuizEnergy',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
    );
    final result = await callable.call({
      'uid': uid,
      'practice': practice,
      'challengeVoice': challengeVoice,
      'challengeChoice': challengeChoice,
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    return _parseEnergy(Map<String, dynamic>.from(data['energy'] as Map));
  }

  /// Perpanjang lock; abaikan kegagalan (best-effort).
  Future<void> heartbeat() => _callVoid('heartbeatQuizSession');

  /// Lepas lock; abaikan kegagalan (best-effort).
  Future<void> endSession() => _callVoid('endQuizSession');

  Future<QuizEnergy> _callEnergy(
    String name, [
    Map<String, dynamic>? params,
  ]) async {
    final callable = functions.httpsCallable(
      name,
      options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
    );
    final result = await callable.call(params);
    // Data callable bisa kembali sebagai Map<Object?, Object?>; normalisasi.
    return _parseEnergy(Map<String, dynamic>.from(result.data as Map));
  }

  QuizEnergy _parseEnergy(Map<String, dynamic> data) {
    final current = (data['current'] as num?)?.toInt() ?? 0;
    final max = (data['max'] as num?)?.toInt() ?? current;
    final secs = (data['resetInSeconds'] as num?)?.toInt();

    (int, int) quota(dynamic raw) {
      if (raw is! Map) return (0, 0);
      final m = Map<String, dynamic>.from(raw);
      return (
        (m['left'] as num?)?.toInt() ?? 0,
        (m['max'] as num?)?.toInt() ?? 0,
      );
    }

    final challenge = data['challenge'];
    final challengeMap = challenge is Map
        ? Map<String, dynamic>.from(challenge)
        : const <String, dynamic>{};
    final voice = quota(challengeMap['voice']);
    final choice = quota(challengeMap['choice']);

    return QuizEnergy(
      current: current,
      max: max,
      challengeVoiceLeft: voice.$1,
      challengeVoiceMax: voice.$2,
      challengeChoiceLeft: choice.$1,
      challengeChoiceMax: choice.$2,
      resetAt: secs == null
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
