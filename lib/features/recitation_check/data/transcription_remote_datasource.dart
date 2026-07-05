import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';

/// Dilempar saat transkripsi gagal, membawa pesan yang ramah pengguna.
/// [isNetwork] true bila kegagalan karena koneksi (bukan kuota/kesalahan server)
/// — dipakai UI untuk menampilkan sheet "sambungkan lagi", bukan sekadar error.
class TranscriptionException implements Exception {
  final String message;
  final bool isNetwork;
  const TranscriptionException(this.message, {this.isNetwork = false});
}

/// Memanggil Cloud Function `transcribeRecitation` (proxy Groq Whisper).
///
/// Audio dikirim sebagai base64 di payload callable (batas ~10MB). Cocok untuk
/// rekaman pendek (per ayat / beberapa ayat). Audio panjang perlu dipotong dulu.
class TranscriptionRemoteDataSource {
  final FirebaseFunctions functions;

  TranscriptionRemoteDataSource(this.functions);

  Future<String> transcribe({
    required Uint8List audioBytes,
    required String mimeType,
  }) async {
    final callable = functions.httpsCallable(
      'transcribeRecitation',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 120)),
    );
    try {
      final result = await callable.call(<String, dynamic>{
        'audioBase64': base64Encode(audioBytes),
        'mimeType': mimeType,
      });
      // Data callable bisa kembali sebagai Map<Object?, Object?>; normalisasi.
      final data = Map<String, dynamic>.from(result.data as Map);
      return (data['text'] as String?)?.trim() ?? '';
    } on FirebaseFunctionsException catch (e) {
      // Koneksi terputus → callable gagal dengan kode ini. Bedakan agar UI bisa
      // menawarkan "sambungkan lagi & kirim ulang".
      final isNetwork =
          e.code == 'unavailable' || e.code == 'deadline-exceeded';
      throw TranscriptionException(
        isNetwork
            ? 'Koneksi internet terputus.'
            : (e.message ?? 'Transkripsi gagal.'),
        isNetwork: isNetwork,
      );
    }
  }
}
