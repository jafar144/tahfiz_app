import 'package:flutter/material.dart';

typedef SyahadahTemplateBuilder = Widget Function(SyahadahTemplateData data);

class SyahadahTemplateData {
  final String displayName;
  final String nis;
  final String hafalan;
  final String photoUrl;
  final String kelas;
  final DateTime date;

  const SyahadahTemplateData({
    required this.displayName,
    required this.nis,
    required this.hafalan,
    required this.photoUrl,
    required this.kelas,
    required this.date,
  });
}

/// Registry presentasi yang dikonfigurasi oleh composition root flavor.
class SyahadahTemplateRegistry {
  static SyahadahTemplateBuilder? _builder;

  static void configure(SyahadahTemplateBuilder builder) {
    _builder = builder;
  }

  static Widget build(SyahadahTemplateData data) {
    final builder = _builder;
    if (builder == null) {
      throw StateError('Template syahadah flavor belum dikonfigurasi.');
    }
    return builder(data);
  }
}

/// Facade stabil yang dipakai fitur syahadah. Layout aktual berasal dari
/// flavor aktif sehingga halaman generator tetap bebas dari detail lembaga.
class SyahadahTemplate extends StatelessWidget {
  final String displayName;
  final String nis;
  final String hafalan;
  final String photoUrl;
  final String kelas;
  final DateTime date;

  const SyahadahTemplate({
    super.key,
    required this.displayName,
    required this.nis,
    required this.hafalan,
    required this.photoUrl,
    required this.kelas,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    // Poster adalah kanvas desain tetap. Pembesaran font dari pengaturan
    // aksesibilitas perangkat tetap berlaku untuk UI aplikasi, tetapi tidak
    // boleh mengubah komposisi poster maupun hasil file yang diekspor.
    return MediaQuery.withNoTextScaling(
      child: SyahadahTemplateRegistry.build(
        SyahadahTemplateData(
          displayName: displayName,
          nis: nis,
          hafalan: hafalan,
          photoUrl: photoUrl,
          kelas: kelas,
          date: date,
        ),
      ),
    );
  }
}

/// Area teks pada kanvas syahadah yang mempertahankan ukuran desain normal,
/// lalu mengecilkan keseluruhan blok hanya ketika kontennya melebihi frame.
class SyahadahFittedText extends StatelessWidget {
  final String text;
  final double width;
  final double height;
  final TextStyle style;
  final TextAlign textAlign;
  final AlignmentGeometry alignment;

  const SyahadahFittedText({
    super.key,
    required this.text,
    required this.width,
    required this.height,
    required this.style,
    this.textAlign = TextAlign.start,
    this.alignment = Alignment.topLeft,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: alignment,
        child: SizedBox(
          width: width,
          child: Text(
            text,
            textAlign: textAlign,
            textScaler: TextScaler.noScaling,
            style: style,
          ),
        ),
      ),
    );
  }
}
