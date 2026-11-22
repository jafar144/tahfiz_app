import 'package:flutter/material.dart';

const String _appFlavor = String.fromEnvironment(
  'APP_FLAVOR',
  defaultValue: 'khoirunnasyien',
);

/// Al-Jauhar memakai brand hijau; flavor lain tetap biru Khoirunnasyien.
///
/// Dibaca dari `--dart-define=APP_FLAVOR` saat compile (wajib dan dicek oleh
/// bootstrap) agar seluruh warna tetap `const` dan dapat dipakai di widget
/// `const`. Gunakan [AppColors.brand], [AppColors.brandLight], dan
/// [AppColors.brandDeep] sebagai pengganti `Colors.blue`, `Colors.lightBlue`,
/// dan `Colors.indigo`. Warna hijau dicocokkan berdasarkan luminans sehingga
/// kontras teks sama dengan versi biru.
const bool kGreenBrand = _appFlavor == 'al_jauhar';

class AppColors {
  AppColors._();

  static const MaterialColor _alJauharGreen =
      MaterialColor(0xFF38A64A, <int, Color>{
        50: Color(0xFFE1F5E5),
        100: Color(0xFFB5E6BD),
        200: Color(0xFF85D692),
        300: Color(0xFF54C567),
        400: Color(0xFF3DB651),
        500: Color(0xFF38A64A),
        600: Color(0xFF3B964A),
        700: Color(0xFF348542),
        800: Color(0xFF2D7339),
        900: Color(0xFF1F5729),
      });

  static const MaterialColor _alJauharLightGreen =
      MaterialColor(0xFF5FB336, <int, Color>{
        50: Color(0xFFE8F5E1),
        100: Color(0xFFC7E7B6),
        200: Color(0xFFA3D888),
        300: Color(0xFF82CA5E),
        400: Color(0xFF69BF3F),
        500: Color(0xFF5FB336),
        600: Color(0xFF58A532),
        700: Color(0xFF4E922C),
        800: Color(0xFF458027),
        900: Color(0xFF33601D),
      });

  static const MaterialColor _alJauharDeepGreen =
      MaterialColor(0xFF396351, <int, Color>{
        50: Color(0xFFE2EDE9),
        100: Color(0xFFB5D2C6),
        200: Color(0xFF83B5A0),
        300: Color(0xFF5A967D),
        400: Color(0xFF4A7B67),
        500: Color(0xFF396351),
        600: Color(0xFF335A4A),
        700: Color(0xFF2C5141),
        800: Color(0xFF254638),
        900: Color(0xFF19362A),
      });

  // Brand (palet per flavor)
  static const MaterialColor brand = kGreenBrand ? _alJauharGreen : Colors.blue;
  static const MaterialColor brandLight = kGreenBrand
      ? _alJauharLightGreen
      : Colors.lightBlue;
  static const MaterialColor brandDeep = kGreenBrand
      ? _alJauharDeepGreen
      : Colors.indigo;

  static const primary = kGreenBrand
      ? Color(0xFF3B964A)
      : Color.fromRGBO(30, 136, 229, 1);
  static const secondary = kGreenBrand ? Color(0xFF44925E) : Color(0xFF268CBE);

  // Neutral
  static const background = Color(0xFFF9F9F9);
  static const surface = Colors.white;
  static const divider = Color(0xFFE0E0E0);

  // Text
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);

  // Status
  static const success = Color(0xFF2E7D32);
  static const warning = Color(0xFFFFA000);
  static const error = Color(0xFFD32F2F);
}
