import 'package:flutter/material.dart';
import 'package:khoirunnasyien/core/theme/app_text_styles.dart';

class AiwaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Widget? leading;

  const AiwaAppBar({
    super.key,
    required this.title,
    this.actions,
    this.centerTitle = false,
    this.backgroundColor,
    this.foregroundColor,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: AppTextStyles.titleBlack.copyWith(
          color: foregroundColor,
        ),
      ),
      backgroundColor: backgroundColor ?? Colors.white,
      surfaceTintColor: backgroundColor ?? Colors.white,
      elevation: 0,
      centerTitle: centerTitle,
      iconTheme: IconThemeData(
        color: foregroundColor ?? Colors.black87,
      ),
      actions: actions,
      leading: leading,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
