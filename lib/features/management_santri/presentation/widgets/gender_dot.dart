import 'package:flutter/material.dart';
import 'package:khoirunnasyien/core/theme/app_colors.dart';

class GenderDot extends StatelessWidget {
  final String gender;

  const GenderDot(this.gender, {super.key});

  @override
  Widget build(BuildContext context) {
    final color = gender == 'L' ? AppColors.brand : Colors.pinkAccent;

    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
