import 'package:flutter/material.dart';
import 'package:khoirunnasyien/core/theme/app_text_styles.dart';

class MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const MenuCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
              child: Icon(icon, color: theme.primaryColor, size: 24),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: AppTextStyles.smallContentBlack,
            ),
            const SizedBox(height: 1),
            Text(
              subtitle,
              style: AppTextStyles.infoLightGrey,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
