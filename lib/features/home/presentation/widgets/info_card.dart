import 'package:flutter/material.dart';
import 'package:khoirunnasyien/core/theme/app_colors.dart';
import 'package:khoirunnasyien/core/theme/app_text_styles.dart';

class InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;

  /// Mutasi 30 hari terakhir. Bila salah satu diisi, kartu bisa bergantian
  /// menampilkan total dan mutasi (dikendalikan [showMutasi]).
  final int? masuk;
  final int? keluar;

  /// Saat true (dan ada data mutasi), kartu menampilkan wajah mutasi.
  final bool showMutasi;

  const InfoCard({
    super.key,
    required this.title,
    required this.value,
    this.icon = Icons.groups,
    this.color,
    this.masuk,
    this.keluar,
    this.showMutasi = false,
  });

  bool get _hasMutasi => masuk != null || keluar != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.primaryColor;
    final showAlt = _hasMutasi && showMutasi;

    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: effectiveColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: effectiveColor, size: 22),
          ),
          const SizedBox(height: 10),
          // Tinggi dikunci agar kartu tidak melonjak saat wajah berganti.
          SizedBox(
            height: 48,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 900),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              // Rata kiri-atas: tanpa ini default-nya Stack center, sehingga
              // teks sempat ke tengah lalu "patah" ke kiri setelah animasi.
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  alignment: Alignment.topLeft,
                  children: <Widget>[
                    ...previousChildren,
                    ?currentChild,
                  ],
                );
              },
              transitionBuilder: (child, animation) {
                final offset = Tween<Offset>(
                  begin: const Offset(0, -0.35),
                  end: Offset.zero,
                ).animate(animation);
                return ClipRect(
                  child: FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: offset, child: child),
                  ),
                );
              },
              child: showAlt ? _mutasiFace() : _totalFace(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalFace() {
    return Column(
      key: const ValueKey('total'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: AppTextStyles.infoGrey),
        Text(value, style: AppTextStyles.titleBlack),
      ],
    );
  }

  Widget _mutasiFace() {
    return Column(
      key: const ValueKey('mutasi'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Mutasi · 30 hari', style: AppTextStyles.infoGrey),
        const SizedBox(height: 4),
        Row(
          children: [
            _delta(Icons.arrow_upward_rounded, masuk ?? 0, AppColors.success),
            const SizedBox(width: 14),
            _delta(Icons.arrow_downward_rounded, keluar ?? 0, AppColors.error),
          ],
        ),
      ],
    );
  }

  Widget _delta(IconData icon, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 1),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
