import 'package:flutter/material.dart';

class GenderDot extends StatelessWidget {
  final String gender;

  const GenderDot(this.gender, {super.key});

  @override
  Widget build(BuildContext context) {
    final color = gender == 'L'
        ? Colors.blue
        : Colors.pinkAccent;

    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
