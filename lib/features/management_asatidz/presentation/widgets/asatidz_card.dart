import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:khoirunnasyien/core/router/route_names.dart';
import 'package:khoirunnasyien/core/utils/ui_utils.dart'; // Added
import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_entity.dart';

class AsatidzCard extends StatelessWidget {
  final AsatidzEntity asatidz;
  final VoidCallback? onReturn;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool isSelected;
  final bool isEnabled;

  const AsatidzCard(
    this.asatidz, {
    super.key,
    this.onReturn,
    this.onTap,
    this.trailing,
    this.isSelected = false,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isMale = asatidz.jenisKelamin == 'L';
    final primaryColor = isMale ? Colors.blue : Colors.red;
    final backgroundColor = isMale ? Colors.blue.shade50 : Colors.red.shade50;

    return Container(
      decoration: BoxDecoration(
        color: isEnabled
            ? (isSelected ? Colors.blue.shade50 : Colors.white)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected && isEnabled
              ? Colors.blue.shade300
              : Colors.grey.shade200,
        ),
        boxShadow: [
          if (isEnabled)
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
          onTap: !isEnabled
              ? null
              : onTap ??
                    () async {
                      await context.pushNamed(
                        RouteNames.detailAsatidz,
                        pathParameters: {'id': asatidz.id},
                      );
                      onReturn?.call();
                    },
          borderRadius: BorderRadius.circular(16),
          child: Opacity(
            opacity: isEnabled ? 1 : 0.5,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar Inisial
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      shape: BoxShape.circle,
                      image:
                          asatidz.photoUrl != null &&
                              asatidz.photoUrl!.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(asatidz.photoUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    alignment: Alignment.center,
                    child:
                        asatidz.photoUrl != null && asatidz.photoUrl!.isNotEmpty
                        ? null
                        : Text(
                            UiUtils.getInitials(asatidz.name),
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
                        // Header: Name + Menu Icon
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                asatidz.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            trailing ??
                                Icon(
                                  Icons.more_vert,
                                  size: 20,
                                  color: Colors.grey.shade400,
                                ),
                          ],
                        ),

                        // NIY (Using NIS field as NIY generally)
                        Text(
                          asatidz.nis,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
