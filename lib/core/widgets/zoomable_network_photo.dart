import 'package:flutter/material.dart';

/// Menampilkan foto jaringan dalam dialog layar penuh yang mendukung zoom/pan.
Future<void> showZoomableNetworkPhoto(
  BuildContext context, {
  required String imageUrl,
  required String semanticLabel,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (dialogContext) => Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  semanticLabel: semanticLabel,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                tooltip: 'Tutup foto',
                onPressed: () => Navigator.of(dialogContext).pop(),
                icon: const Icon(Icons.close),
                color: Colors.white,
                style: IconButton.styleFrom(backgroundColor: Colors.black45),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
