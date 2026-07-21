import 'package:flutter/material.dart';

class AiwaOutlineButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color color;
  final double height;

  const AiwaOutlineButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color = Colors.red,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
