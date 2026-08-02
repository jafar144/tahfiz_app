import 'dart:async';

/// Memulai penyimpanan poster tanpa menahan pembukaan share sheet.
///
/// Callback [save] wajib menangani error-nya sendiri karena proses tersebut
/// tetap berjalan di belakang layar setelah [share] dimulai.
Future<void> shareKelulusanWhileSaving({
  required Future<void> Function() save,
  required Future<void> Function() share,
}) async {
  unawaited(save());
  await share();
}
