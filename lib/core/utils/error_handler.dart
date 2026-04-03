import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

class ErrorHandler {
  static String getMessage(dynamic e) {
    if (e == null) return 'Terjadi kesalahan sistem yang tidak diketahui.';

    final String errorStr = e.toString();

    // Handling Firebase exceptions
    if (e is FirebaseException || errorStr.contains('FirebaseException') || errorStr.contains('cloud_firestore')) {
      if (errorStr.contains('permission-denied')) {
        return 'Anda tidak memiliki akses untuk melakukan tindakan ini.';
      } else if (errorStr.contains('not-found')) {
        return 'Data tidak ditemukan pada server.';
      } else if (errorStr.contains('unavailable') || errorStr.contains('network')) {
        return 'Server sedang tidak dapat dijangkau. Mohon periksa koneksi Anda.';
      } else if (errorStr.contains('deadline-exceeded')) {
        return 'Waktu permintaan habis, silakan coba lagi.';
      }
      return 'Maaf, terjadi kesalahan terkait basis data. Silakan coba lagi.';
    }

    // Handling Network/Socket exceptions
    if (e is SocketException || errorStr.contains('SocketException') || errorStr.toLowerCase().contains('network is unreachable')) {
      return 'Maaf, koneksi internet Anda bermasalah. Pastikan perangkat Anda terhubung ke internet.';
    }

    // Handling generic Dart Exception strings thrown manually in the app
    if (errorStr.startsWith('Exception: ')) {
      final message = errorStr.substring('Exception: '.length).trim();
      return _translateKnownMessage(message);
    }

    // If string itself contains useful standard translations but isn't explicitly an Exception block
    return _translateKnownMessage(errorStr);
  }

  static String _translateKnownMessage(String originalMsg) {
    if (originalMsg.isEmpty) {
      return 'Maaf, ada sedikit permasalahan, silakan coba lagi nanti.';
    }
    
    // In case there is an unhandled raw english sentence, we try to fallback or just return it if it seems Indonesian
    // If it's a known raw error it should be translated. For now we will allow it to display if it's already translated.
    final lowercaseMsg = originalMsg.toLowerCase();
    
    if (lowercaseMsg.contains('type \'') && lowercaseMsg.contains('is not a subtype of type')) {
      return 'Terjadi kesalahan sistem saat memproses data. Silakan coba beberapa saat lagi.';
    }

    // Return the polished/translated message 
    return originalMsg;
  }
}
