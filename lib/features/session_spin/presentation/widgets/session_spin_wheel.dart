import 'package:flutter/material.dart';

class SessionSpinWheel extends StatelessWidget {
  final double turns;
  final Duration duration;
  final bool isSpinning;
  final String? winnerName;
  final int remainingCount;

  const SessionSpinWheel({
    super.key,
    required this.turns,
    required this.duration,
    required this.isSpinning,
    required this.winnerName,
    required this.remainingCount,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: isSpinning
          ? 'Roda sedang mengacak urutan'
          : winnerName == null
          ? '$remainingCount peserta siap diacak'
          : 'Urutan terbaru $winnerName',
      child: SizedBox(
        width: 246,
        height: 266,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 0,
              child: Icon(
                Icons.arrow_drop_down_rounded,
                size: 52,
                color: Colors.orange.shade700,
              ),
            ),
            Positioned(
              top: 30,
              child: AnimatedRotation(
                key: const ValueKey('session-spin-wheel'),
                turns: turns,
                duration: duration,
                curve: Curves.easeOutCubic,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        Colors.blue.shade600,
                        Colors.lightBlue.shade300,
                        Colors.orange.shade400,
                        Colors.blue.shade700,
                        Colors.teal.shade300,
                        Colors.amber.shade400,
                        Colors.blue.shade600,
                      ],
                    ),
                    border: Border.all(color: Colors.white, width: 5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.2),
                        blurRadius: 22,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 74,
              child: Container(
                width: 132,
                height: 132,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blue.shade50, width: 5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: Text(
                      isSpinning
                          ? 'Mengacak…'
                          : winnerName ?? '$remainingCount\npeserta',
                      key: ValueKey('$isSpinning-$winnerName-$remainingCount'),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.w800,
                        fontSize: winnerName == null ? 18 : 15,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
