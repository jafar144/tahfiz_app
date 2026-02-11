import 'package:flutter/material.dart';
import 'package:khoirunnasyien/core/theme/app_text_styles.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_button.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_outline_button.dart';

class AiwaBottomSheet extends StatelessWidget {
  final String title;
  final Widget content;
  final VoidCallback onReset;
  final VoidCallback onApply;

  const AiwaBottomSheet({
    super.key,
    required this.title,
    required this.content,
    required this.onReset,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTextStyles.contentBlack
              ),
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
              Expanded(
                child: AiwaOutlineButton(
                  text: 'Reset',
                  onPressed: onReset,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AiwaButton(
                  text: 'Terapkan',
                onPressed: onApply,
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
