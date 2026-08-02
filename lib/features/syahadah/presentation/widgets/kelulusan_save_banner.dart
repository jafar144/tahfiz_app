import 'package:flutter/material.dart';

enum KelulusanSaveStatus { saving, success, failure }

class KelulusanSaveBanner extends StatelessWidget {
  final KelulusanSaveStatus status;
  final String? failureMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const KelulusanSaveBanner({
    super.key,
    required this.status,
    this.failureMessage,
    this.onRetry,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final (
      :background,
      :border,
      :foreground,
      :title,
      :message,
    ) = switch (status) {
      KelulusanSaveStatus.saving => (
        background: const Color(0xFFEFF6FF),
        border: const Color(0xFFBFDBFE),
        foreground: const Color(0xFF1D4ED8),
        title: 'Menyimpan foto kelulusan…',
        message:
            'Anda boleh membuka WhatsApp. Jangan tutup paksa Tahfiz App sampai proses selesai.',
      ),
      KelulusanSaveStatus.success => (
        background: const Color(0xFFECFDF3),
        border: const Color(0xFFA7F3D0),
        foreground: const Color(0xFF047857),
        title: 'Foto kelulusan sudah tersimpan',
        message: 'Foto sudah masuk ke daftar Kelulusan Santri.',
      ),
      KelulusanSaveStatus.failure => (
        background: const Color(0xFFFEF2F2),
        border: const Color(0xFFFECACA),
        foreground: const Color(0xFFB91C1C),
        title: 'Foto belum berhasil disimpan',
        message:
            failureMessage ??
            'Periksa koneksi internet, lalu coba simpan kembali.',
      ),
    };

    return Container(
      key: ValueKey(status),
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: foreground.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: status == KelulusanSaveStatus.saving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: foreground,
                    ),
                  )
                : Icon(
                    status == KelulusanSaveStatus.success
                        ? Icons.check_circle_rounded
                        : Icons.error_rounded,
                    size: 22,
                    color: foreground,
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: TextStyle(
                    color: foreground.withValues(alpha: 0.88),
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
                if (status == KelulusanSaveStatus.failure &&
                    onRetry != null) ...[
                  const SizedBox(height: 7),
                  TextButton.icon(
                    onPressed: onRetry,
                    style: TextButton.styleFrom(
                      foregroundColor: foreground,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: BorderSide(color: border),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text(
                      'Coba Lagi',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (status != KelulusanSaveStatus.saving && onDismiss != null)
            IconButton(
              tooltip: 'Tutup informasi',
              onPressed: onDismiss,
              visualDensity: VisualDensity.compact,
              iconSize: 18,
              color: foreground,
              icon: const Icon(Icons.close_rounded),
            ),
        ],
      ),
    );
  }
}
