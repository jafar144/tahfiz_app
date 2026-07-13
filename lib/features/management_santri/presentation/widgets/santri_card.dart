import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:khoirunnasyien/core/router/route_names.dart';
import 'package:khoirunnasyien/core/utils/ui_utils.dart'; // Added
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';

class SantriCard extends StatelessWidget {
  final SantriEntity santri;
  final VoidCallback? onReturn;
  final Map<String, dynamic>? extra;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Tampilkan nama pembimbing di footer. Dimatikan mis. pada daftar santri
  /// di dalam halaqah, di mana pembimbingnya sudah jelas (redundan).
  final bool showPembimbing;

  const SantriCard(
    this.santri, {
    super.key,
    this.onReturn,
    this.extra,
    this.trailing,
    this.onTap,
    this.showPembimbing = true,
  });

  @override
  Widget build(BuildContext context) {
    final isMale = santri.jenisKelamin == 'L';
    final primaryColor = isMale ? Colors.blue : Colors.red;
    final backgroundColor = isMale ? Colors.blue.shade50 : Colors.red.shade50;

    return Container(
      decoration: BoxDecoration(
        color: santri.isActive ? Colors.white : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          if (santri.isActive)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () async {
            await context.pushNamed(
              RouteNames.detailSantri,
              pathParameters: {'id': santri.id},
              extra: extra,
            );
            onReturn?.call();
          },
          borderRadius: BorderRadius.circular(16),
          child: Opacity(
            opacity: santri.isActive ? 1.0 : 0.6,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar Inisial (Abu-abu)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    UiUtils.getInitials(santri.name),
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                santri.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (santri.tipeKelas != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getSessionColor(santri.tipeKelas!)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getSessionIcon(santri.tipeKelas!),
                                      size: 14,
                                      color:
                                          _getSessionColor(santri.tipeKelas!),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      santri.tipeKelas!,
                                      style: TextStyle(
                                        color:
                                            _getSessionColor(santri.tipeKelas!),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (!santri.isActive) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Tidak Aktif',
                                  style: TextStyle(
                                    color: Colors.grey.shade800,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      
                      // NIS (Tanpa Label ID:)
                      Text(
                        santri.nis,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Footer: Badge Kelas & Pembimbing
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.school,
                                  size: 14,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  santri.kelas,
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          if (showPembimbing) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 14,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      santri.pembimbing ?? '-',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  Color _getSessionColor(String session) {
    switch (session.toLowerCase()) {
      case 'pagi':
        return Colors.orange.shade700;
      case 'sore':
        return Colors.deepOrange.shade700;
      case 'malam':
        return Colors.indigo.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  IconData _getSessionIcon(String session) {
    switch (session.toLowerCase()) {
      case 'pagi':
        return Icons.wb_sunny_outlined;
      case 'sore':
        return Icons.wb_twilight;
      case 'malam':
        return Icons.nights_stay_outlined;
      default:
        return Icons.schedule;
    }
  }
}
