import 'package:flutter/material.dart';

import 'package:khoirunnasyien/features/recitation_quiz/presentation/widgets/quiz_haptics.dart';

/// Tombol aksi bergaya Duolingo — HANYA dipakai di menu Kuis.
///
/// Punya "bibir" bawah (shadow 3D). Saat ditekan (belum dilepas), permukaan
/// tombol turun menutup bibirnya seolah benar-benar tertekan, dan getar terjadi
/// SAAT DITEKAN — bukan saat dilepas. Aksi ([onPressed]) dijalankan ketika jari
/// dilepas di atas tombol.
class QuizButton extends StatefulWidget {
  /// Teks tombol; null/kosong → tombol ikon-saja (mis. tombol gear pengaturan).
  final String? label;
  final IconData? icon;
  final double iconSize;
  final double labelFontSize;
  final double labelLetterSpacing;

  /// null → tombol nonaktif (abu-abu, tanpa getar & tanpa efek tekan).
  final VoidCallback? onPressed;

  /// Warna permukaan tombol; bibir bawah dihitung otomatis dari warna ini.
  final Color color;
  final Color foregroundColor;

  /// Padding permukaan tombol (kecilkan untuk tombol ringkas mis. di AppBar).
  final EdgeInsetsGeometry padding;

  /// Radius sudut permukaan tombol.
  final double borderRadius;

  /// Widget kecil di kanan label (mis. chip biaya energi).
  final Widget? trailing;

  const QuizButton({
    super.key,
    required this.onPressed,
    this.label,
    this.icon,
    this.iconSize = 20,
    this.labelFontSize = 15,
    this.labelLetterSpacing = 0.8,
    this.color = const Color(0xFF58CC02),
    this.foregroundColor = Colors.white,
    this.padding = const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
    this.borderRadius = 16,
    this.trailing,
  });

  @override
  State<QuizButton> createState() => _QuizButtonState();
}

class _QuizButtonState extends State<QuizButton> {
  /// Tinggi "bibir" bawah tombol saat tidak ditekan.
  static const double _lip = 5;

  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  void _down(TapDownDetails _) {
    if (!_enabled) return;
    // Getar terjadi tepat saat DITEKAN.
    QuizHaptics.tap();
    setState(() => _pressed = true);
  }

  void _release() {
    if (_pressed) setState(() => _pressed = false);
  }

  /// Bibir bawah: versi lebih gelap dari warna permukaan. Warna terang (mis.
  /// tombol netral abu) digelapkan lebih TIPIS agar bibirnya tak terlihat lebih
  /// tebal daripada tombol berwarna gelap.
  Color _lipColor(Color c) {
    final hsl = HSLColor.fromColor(c);
    final amount = hsl.lightness > 0.7 ? 0.10 : 0.18;
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _enabled;
    final faceColor = enabled ? widget.color : const Color(0xFFE3E3E3);
    final lipColor = enabled
        ? _lipColor(widget.color)
        : const Color(0xFFC8C8C8);
    final fg = enabled ? widget.foregroundColor : const Color(0xFF9E9E9E);

    // Tekan hanya menggeser saat aktif; nonaktif selalu "rata di atas".
    final down = enabled && _pressed;

    final hasLabel = widget.label != null && widget.label!.isNotEmpty;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _down,
      onTapUp: (_) => _release(),
      onTapCancel: _release,
      onTap: enabled ? widget.onPressed : null,
      // Sisakan ruang untuk bibir bawah agar tak menimpa konten di bawahnya.
      child: Padding(
        padding: const EdgeInsets.only(bottom: _lip),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 60),
          curve: Curves.easeOut,
          // Saat ditekan, permukaan turun sejauh bibirnya (menutup bibir).
          transform: Matrix4.translationValues(0, down ? _lip : 0, 0),
          width: double.infinity,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: faceColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            // Bibir 3D = bayangan keras (tanpa blur) yang bergeser ke bawah;
            // saat ditekan offset-nya 0 → tersembunyi di balik permukaan.
            // Nonaktif → tanpa bibir (rata).
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: lipColor,
                      offset: Offset(0, down ? 0 : _lip),
                      blurRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null)
                Icon(widget.icon, color: fg, size: widget.iconSize),
              if (widget.icon != null && hasLabel) const SizedBox(width: 8),
              if (hasLabel)
                Flexible(
                  child: Text(
                    // Kapital + sedikit jarak antar-huruf ala Duolingo.
                    widget.label!.toUpperCase(),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: fg,
                      fontSize: widget.labelFontSize,
                      fontWeight: FontWeight.w800,
                      letterSpacing: widget.labelLetterSpacing,
                    ),
                  ),
                ),
              if (widget.trailing != null) ...[
                const SizedBox(width: 8),
                widget.trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
