import 'package:flutter/material.dart';

class UiUtils {
  static void unfocus(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  /// Memaksa menutup keyboard dengan memindahkan fokus ke node baru
  /// dan menunggu animasi selesai. Gunakan ini sebelum menampilkan dialog/bottomsheet.
  static Future<void> dismissKeyboard(BuildContext context) async {
    FocusScope.of(context).requestFocus(FocusNode());
    await Future.delayed(const Duration(milliseconds: 300));
  }

  static String getInitials(String name) {
    if (name.isEmpty) return '';
    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      if (parts[0].isEmpty) return '';
      return parts[0][0].toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
