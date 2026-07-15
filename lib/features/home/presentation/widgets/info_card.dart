import 'package:flutter/material.dart';
import 'package:khoirunnasyien/core/theme/app_colors.dart';
import 'package:khoirunnasyien/core/theme/app_text_styles.dart';

class InfoCardDetail {
  final String label;
  final int value;

  const InfoCardDetail({required this.label, required this.value});
}

class InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;

  /// Rincian dua sesi yang ditampilkan pada wajah kedua.
  final List<InfoCardDetail> details;

  /// Mutasi 30 hari terakhir. Bila salah satu diisi, kartu bisa bergantian
  /// menampilkan total, rincian sesi, dan mutasi.
  final int? masuk;
  final int? keluar;

  /// Indeks informasi aktif. Nilai dinormalisasi terhadap jumlah wajah card.
  final int displayIndex;
  final VoidCallback? onTap;

  const InfoCard({
    super.key,
    required this.title,
    required this.value,
    this.icon = Icons.groups,
    this.color,
    this.details = const [],
    this.masuk,
    this.keluar,
    this.displayIndex = 0,
    this.onTap,
  });

  bool get _hasMutasi => masuk != null || keluar != null;
  bool get _hasDetails => details.isNotEmpty;

  List<String> get _faces => [
    'total',
    if (_hasDetails) 'details',
    if (_hasMutasi) 'mutasi',
  ];

  int get _activeIndex => displayIndex % _faces.length;
  String get _activeFace => _faces[_activeIndex];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.primaryColor;
    final activeFace = _activeFace;

    return Container(
      width: 152,
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: _faces.length > 1 ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: effectiveColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: effectiveColor, size: 22),
                    ),
                    const Spacer(),
                    if (_faces.length > 1)
                      _FaceIndicator(
                        count: _faces.length,
                        activeIndex: _activeIndex,
                        color: effectiveColor,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                // Tinggi dikunci agar card tidak berubah ukuran antartampilan.
                SizedBox(
                  height: 56,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 520),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    layoutBuilder: (currentChild, previousChildren) {
                      return Stack(
                        alignment: Alignment.topLeft,
                        children: <Widget>[...previousChildren, ?currentChild],
                      );
                    },
                    transitionBuilder: (child, animation) {
                      // Satu transition harus membedakan animasi maju dan
                      // reverse. Saat masuk, posisi bergerak dari atas ke
                      // tengah; saat keluar, dari tengah ke bawah.
                      return AnimatedBuilder(
                        animation: animation,
                        child: child,
                        builder: (context, transitionChild) {
                          final isLeaving =
                              animation.status == AnimationStatus.reverse;
                          final direction = isLeaving ? 1.0 : -1.0;
                          final offset = Offset(
                            0,
                            (1 - animation.value) * 0.42 * direction,
                          );
                          return ClipRect(
                            child: FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: AlwaysStoppedAnimation(offset),
                                child: transitionChild,
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: _face(activeFace, effectiveColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _face(String face, Color color) {
    return switch (face) {
      'details' => _detailsFace(color),
      'mutasi' => _mutasiFace(),
      _ => _totalFace(),
    };
  }

  Widget _totalFace() {
    return Column(
      key: const ValueKey('total'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: AppTextStyles.infoGrey.copyWith(height: 1)),
        Text(value, style: AppTextStyles.titleBlack.copyWith(height: 1.05)),
      ],
    );
  }

  Widget _detailsFace(Color color) {
    final visibleDetails = details.take(2).toList(growable: false);
    return Column(
      key: const ValueKey('details'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Rincian Sesi', style: AppTextStyles.infoGrey.copyWith(height: 1)),
        const SizedBox(height: 3),
        Row(
          children: [
            for (var index = 0; index < visibleDetails.length; index++) ...[
              if (index > 0) const SizedBox(width: 10),
              Expanded(
                child: _SessionMetric(
                  detail: visibleDetails[index],
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _mutasiFace() {
    return Column(
      key: const ValueKey('mutasi'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Mutasi · 30 hari',
          style: AppTextStyles.infoGrey.copyWith(height: 1),
        ),
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

class _SessionMetric extends StatelessWidget {
  final InfoCardDetail detail;
  final Color color;

  const _SessionMetric({required this.detail, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            detail.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Colors.black45,
            ),
          ),
        ),
        const SizedBox(width: 3),
        Text(
          '${detail.value}',
          style: TextStyle(
            fontSize: 17,
            height: 1,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _FaceIndicator extends StatelessWidget {
  final int count;
  final int activeIndex;
  final Color color;

  const _FaceIndicator({
    required this.count,
    required this.activeIndex,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < count; index++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: index == activeIndex ? 10 : 4,
            height: 4,
            margin: const EdgeInsets.only(left: 3),
            decoration: BoxDecoration(
              color: color.withValues(
                alpha: index == activeIndex ? 0.85 : 0.18,
              ),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
      ],
    );
  }
}
