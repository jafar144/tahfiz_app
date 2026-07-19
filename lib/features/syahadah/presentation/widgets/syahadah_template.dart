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
    return SyahadahTemplateRegistry.build(
      SyahadahTemplateData(
        displayName: displayName,
        nis: nis,
        hafalan: hafalan,
        photoUrl: photoUrl,
        kelas: kelas,
        date: date,
      ),
    );
  }
}
