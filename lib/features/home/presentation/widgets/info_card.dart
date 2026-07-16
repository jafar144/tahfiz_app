import 'package:flutter/material.dart';
import 'package:khoirunnasyien/core/theme/app_colors.dart';
import 'package:khoirunnasyien/core/theme/app_text_styles.dart';

class InfoCardDetail {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const InfoCardDetail({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;

  /// Ringkasan dua sesi berbentuk badge ikon pada wajah kedua.
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
      width: 140,
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
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: effectiveColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: effectiveColor, size: 20),
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
                const SizedBox(height: 20),
                // Tinggi dikunci agar card tidak berubah ukuran antartampilan.
                SizedBox(
                  height: 60,
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
                    child: _face(activeFace),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _face(String face) {
    return switch (face) {
      'details' => _detailsFace(),
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
        const SizedBox(height: 3),
        Text(value, style: AppTextStyles.titleBlack.copyWith(height: 1.05)),
      ],
    );
  }

  Widget _detailsFace() {
    final visibleDetails = details.take(2).toList(growable: false);
    return Align(
      key: const ValueKey('details'),
      alignment: Alignment.centerLeft,
      child: Transform.translate(
        offset: const Offset(0, -5),
        child: Row(
          children: [
            for (var index = 0; index < visibleDetails.length; index++) ...[
              if (index > 0) const SizedBox(width: 6),
              Expanded(child: _SessionMetric(detail: visibleDetails[index])),
            ],
          ],
        ),
      ),
    );
  }

  Widget _mutasiFace() {
    return Semantics(
      key: const ValueKey('mutasi'),
      label: 'Mutasi 30 hari terakhir',
      container: true,
      child: SizedBox.expand(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: _MutationMetric(
                        label: 'Masuk',
                        count: masuk ?? 0,
                        icon: Icons.person_add_alt_1_rounded,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _MutationMetric(
                        label: 'Keluar',
                        count: keluar ?? 0,
                        icon: Icons.person_remove_alt_1_rounded,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Positioned(
              right: 0,
              bottom: 0,
              child: Text(
                '30 hari',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 8,
                  height: 1,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MutationMetric extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  const _MutationMetric({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $count santri',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(height: 1),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 17,
              height: 1,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionMetric extends StatelessWidget {
  final InfoCardDetail detail;

  const _SessionMetric({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: detail.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(detail.icon, size: 14, color: detail.color),
                const SizedBox(width: 4),
                Text(
                  detail.label,
                  style: TextStyle(
                    color: detail.color,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${detail.value}',
          style: const TextStyle(
            fontSize: 17,
            height: 1,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
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
    return Column(
      key: const ValueKey('info-card-face-indicator'),
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < count; index++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 4,
            height: index == activeIndex ? 10 : 4,
            margin: EdgeInsets.only(top: index == 0 ? 0 : 3),
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
