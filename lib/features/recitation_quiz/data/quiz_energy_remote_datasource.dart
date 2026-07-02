import 'package:cloud_functions/cloud_functions.dart';

import 'package:khoirunnasyien/features/recitation_quiz/domain/entities/quiz_energy.dart';

/// Memanggil Cloud Function energi kuis (`getQuizEnergy` / `consumeQuizEnergy`).
///
/// Energi dihitung sepenuhnya di server (waktu server) agar tidak bisa diakali
/// dengan mengubah jam perangkat. Sisa pengisian dikirim sebagai detik relatif,
/// lalu diubah jadi waktu absolut lokal untuk hitung mundur di UI.
class QuizEnergyRemoteDataSource {
  final FirebaseFunctions functions;

  QuizEnergyRemoteDataSource(this.functions);

  Future<QuizEnergy> getEnergy() => _call('getQuizEnergy');

  Future<QuizEnergy> consumeEnergy() => _call('consumeQuizEnergy');

  Future<QuizEnergy> _call(String name) async {
    final callable = functions.httpsCallable(
      name,
      options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
    );
    final result = await callable.call();
    // Data callable bisa kembali sebagai Map<Object?, Object?>; normalisasi.
    final data = Map<String, dynamic>.from(result.data as Map);

    final current = (data['current'] as num?)?.toInt() ?? 0;
    final max = (data['max'] as num?)?.toInt() ?? current;
    final secs = (data['nextRefillInSeconds'] as num?)?.toInt();

    return QuizEnergy(
      current: current,
      max: max,
      nextRefillAt:
          secs == null ? null : DateTime.now().add(Duration(seconds: secs)),
    );
  }
}
