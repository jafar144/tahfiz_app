import 'package:flutter/material.dart';
import 'package:khoirunnasyien/core/theme/app_text_styles.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_button.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_outline_button.dart';

class AiwaBottomSheet extends StatelessWidget {
  final String title;
  final Widget content;
  final VoidCallback? onReset;
  final VoidCallback onApply;
  final String resetText;
  final String applyText;
  final Color resetColor;
  final Color? applyColor;

  const AiwaBottomSheet({
    super.key,
    required this.title,
    required this.content,
    this.onReset,
    required this.onApply,
    this.resetText = 'Reset',
    this.applyText = 'Terapkan',
    this.resetColor = Colors.red,
    this.applyColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.contentBlack,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          content,
          const SizedBox(height: 24),
          Row(
            children: [
              if (onReset != null) ...[
                Expanded(
                  child: AiwaOutlineButton(
                    text: resetText,
                    onPressed: onReset!,
                    color: resetColor,
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: AiwaButton(
                  text: applyText,
                  onPressed: onApply,
                  color: applyColor,
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}

/// Menampilkan action sheet standar aplikasi dan mengembalikan nilai dari
/// tombol yang dipilih. Untuk sheet informasi satu tombol, set
/// [showCancelAction] ke false.
Future<T?> showAiwaActionSheet<T>({
  required BuildContext context,
  required String title,
  required Widget content,
  String cancelText = 'Batal',
  String confirmText = 'Lanjut',
  T? cancelValue,
  T? confirmValue,
  bool showCancelAction = true,
  Color cancelColor = Colors.grey,
  Color? confirmColor,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => AiwaBottomSheet(
      title: title,
      content: content,
      onReset: showCancelAction
          ? () => Navigator.pop(sheetContext, cancelValue)
          : null,
      onApply: () => Navigator.pop(sheetContext, confirmValue),
      resetText: cancelText,
      applyText: confirmText,
      resetColor: cancelColor,
      applyColor: confirmColor,
    ),
  );
}
