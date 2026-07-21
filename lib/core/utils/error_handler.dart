import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';

class ErrorHandler {
  static String getMessage(dynamic e) {
    if (e == null) return 'Terjadi kesalahan sistem yang tidak diketahui.';

    final String errorStr = e.toString();

    // Handling Firebase Auth exceptions (login/registrasi).
    // Harus dicek sebelum FirebaseException karena FirebaseAuthException
    // adalah turunannya — jika tidak, error login jatuh ke pesan generik.
    if (e is FirebaseAuthException) {
      return _authMessage(e.code);
    }

    // Handling Firebase exceptions
    if (e is FirebaseException ||
        errorStr.contains('FirebaseException') ||
        errorStr.contains('cloud_firestore')) {
      if (errorStr.contains('permission-denied')) {
        return 'Anda tidak memiliki akses untuk melakukan tindakan ini.';
      } else if (errorStr.contains('not-found')) {
        return 'Data tidak ditemukan pada server.';
      } else if (errorStr.contains('unavailable') ||
          errorStr.contains('network')) {
        return 'Server sedang tidak dapat dijangkau. Mohon periksa koneksi Anda.';
      } else if (errorStr.contains('deadline-exceeded')) {
        return 'Waktu permintaan habis, silakan coba lagi.';
      }
      return 'Maaf, terjadi kesalahan terkait basis data. Silakan coba lagi.';
    }

    // Handling Network/Socket exceptions
    if (e is SocketException ||
        errorStr.contains('SocketException') ||
        errorStr.toLowerCase().contains('network is unreachable')) {
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

  static String _authMessage(String code) {
    switch (code) {
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'NIS atau password salah. Silakan periksa kembali.';
      case 'wrong-password':
        return 'Password salah. Silakan coba lagi.';
      case 'user-not-found':
        return 'NIS tidak terdaftar. Periksa kembali NIS Anda.';
      case 'invalid-email':
        return 'Format NIS tidak valid.';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan. Silakan hubungi admin.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan gagal. Coba lagi beberapa saat.';
      case 'network-request-failed':
        return 'Koneksi internet bermasalah. Periksa jaringan Anda.';
      default:
        return 'Gagal masuk. Pastikan NIS dan password Anda benar.';
    }
  }

  static String _translateKnownMessage(String originalMsg) {
    if (originalMsg.isEmpty) {
      return 'Maaf, ada sedikit permasalahan, silakan coba lagi nanti.';
    }

    // In case there is an unhandled raw english sentence, we try to fallback or just return it if it seems Indonesian
    // If it's a known raw error it should be translated. For now we will allow it to display if it's already translated.
    final lowercaseMsg = originalMsg.toLowerCase();

    if (lowercaseMsg.contains('type \'') &&
        lowercaseMsg.contains('is not a subtype of type')) {
      return 'Terjadi kesalahan sistem saat memproses data. Silakan coba beberapa saat lagi.';
    }

    // Return the polished/translated message
    return originalMsg;
  }
}
