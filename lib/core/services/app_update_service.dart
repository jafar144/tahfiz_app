import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

/// Menangani in-app update Google Play (Android) dengan mode **Flexible**:
/// Play Store yang menampilkan bottom sheet konfirmasi, mengunduh di latar
/// belakang, lalu kita tawarkan restart untuk memasangnya.
///
/// UI konfirmasi & unduhan disediakan oleh Play Store; sisi kita hanya
/// memicu pengecekan. Aman dipanggil di semua platform — selain Android
/// (atau saat app tidak dari Play Store) langsung diabaikan tanpa error.
class AppUpdateService {
  AppUpdateService._();

  /// Pengecekan hanya berjalan sekali per sesi aplikasi agar tidak mengganggu
  /// setiap kali halaman Home dibuka atau di-rebuild.
  static bool _alreadyChecked = false;

  static Future<void> checkForFlexibleUpdate(BuildContext context) async {
    // In-App Update hanya tersedia di Android (Google Play Core).
    if (kIsWeb || !Platform.isAndroid) return;
    if (_alreadyChecked) return;
    _alreadyChecked = true;

    try {
      final info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability != UpdateAvailability.updateAvailable ||
          !info.flexibleUpdateAllowed) {
        return;
      }

      // Menampilkan bottom sheet konfirmasi bawaan Play Store + unduh di latar.
      final result = await InAppUpdate.startFlexibleUpdate();
      if (result != AppUpdateResult.success) return;

      // Unduhan selesai → tawarkan pemasangan (restart) lewat SnackBar agar
      // pengguna bisa memilih waktunya sendiri.
      if (!context.mounted) {
        await InAppUpdate.completeFlexibleUpdate();
        return;
      }
      _promptInstall(context);
    } catch (_) {
      // Diabaikan: app tidak dari Play Store, tidak ada update, tanpa internet,
      // atau pengguna menutup dialog. Izinkan dicoba lagi pada sesi berikutnya.
      _alreadyChecked = false;
    }
  }

  static void _promptInstall(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 10),
        content: const Text('Pembaruan telah diunduh dan siap dipasang.'),
        action: SnackBarAction(
          label: 'Pasang',
          onPressed: () => InAppUpdate.completeFlexibleUpdate(),
        ),
      ),
    );
  }
}
