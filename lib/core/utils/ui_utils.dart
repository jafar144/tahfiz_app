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
}
