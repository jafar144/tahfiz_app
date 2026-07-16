import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khoirunnasyien/core/config/app_config.dart';
import 'package:khoirunnasyien/features/syahadah/presentation/widgets/syahadah_template.dart';

class KhoirunnasyienSyahadahTemplate extends StatelessWidget {
  final SyahadahTemplateData data;

  const KhoirunnasyienSyahadahTemplate({super.key, required this.data});

  String get displayName => data.displayName;
  String get hafalan => data.hafalan;
  String get photoUrl => data.photoUrl;
  String get kelas => data.kelas;
  DateTime get date => data.date;

  bool get _isTahsin => kelas.toLowerCase().startsWith('tahsin');

  String get _hafalanText => _isTahsin
      ? 'Selesai dan Lulus\n$hafalan'
      : 'Lancar dan Lulus\nHAFALAN AL-QUR\'AN\n$hafalan';

  String get _quoteText => _isTahsin
      ? 'Sebaik - baik kalian adalah yang belajar dan mengajarkan Alquran\n(Al Hadits)'
      : 'Semoga dengan keberkahan Alquran yg dijaga (dihafal) dapat menjaga dirimu dan keluarga dari kesulitan dunia dan akhirat, aamiin.';

  String get _formattedDate {
    const months = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${months[date.month]}  ${date.year}';
  }

  static const _bgColor = Color(0xFF004aad);
  static const _goldColor = Color(0xFFFFC550);
  static const _creamColor = Color(0xFFFFFBD5);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1080,
      height: 1350,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(color: _bgColor),
      child: Stack(
        children: [
          // ===== LAYER 1: Foto (paling belakang) =====
          Positioned(
            right: -20,
            top: 300,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Image.network(
                photoUrl,
                width: 500,
                height: 560,
                fit: BoxFit.cover,
                errorBuilder: (_, e, s) => Container(
                  width: 500,
                  height: 560,
                  color: Colors.grey.shade300,
                  child: const Icon(
                    Icons.person,
                    size: 100,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ),

          // ===== LAYER 2: Box dekoratif (menutupi sebagian foto) =====

          // Box hafalan (kiri tengah, sedikit miring)
          Positioned(
            left: -30,
            top: 475,
            child: Transform.rotate(
              angle: -0.03,
              child: Container(
                width: 670,
                height: 310,
                decoration: BoxDecoration(
                  color: _goldColor,
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(80),
                    topRight: Radius.circular(80),
                  ),
                ),
              ),
            ),
          ),

          // Box transisi / nama (tengah-kanan)
          Positioned(
            right: 0,
            top: 800,
            child: Transform.rotate(
              angle: 0.03,
              child: Container(
                width: 560,
                height: 280,
                decoration: BoxDecoration(
                  color: _creamColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(100),
                    bottomLeft: Radius.circular(100),
                  ),
                ),
              ),
            ),
          ),

          // Dekorasi kanan bawah (efek halaman tertumpuk)
          // Positioned(
          //   right: 0,
          //   bottom: 0,
          //   child: Transform.rotate(
          //     angle: 0.04,
          //     child: Container(
          //       width: 100,
          //       height: 460,
          //       decoration: BoxDecoration(
          //         color: _bgColor,
          //         borderRadius: BorderRadius.circular(10),
          //       ),
          //     ),
          //   ),
          // ),

          // Garis coral dekoratif (kanan)
          Positioned(
            right: 30,
            bottom: 30,
            child: Container(
              width: 3,
              height: 400,
              decoration: BoxDecoration(
                color: const Color(0xFFE87060),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Box quote besar (bawah)
          Positioned(
            left: -10,
            right: 50,
            bottom: -20,
            child: Transform.rotate(
              angle: -0.015,
              child: Container(
                height: 450,
                decoration: BoxDecoration(
                  color: _goldColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(50),
                  ),
                ),
              ),
            ),
          ),

          // ===== LAYER 3: Header teks dengan stroke =====

          // "Selamat"
          Positioned(
            left: 50,
            top: 70,
            child: Transform.rotate(
              angle: -0.06,
              child: _buildStrokedText(
                'Selamat',
                const TextStyle(
                  fontFamily: 'Railey',
                  fontSize: 250,
                  height: 1.0,
                ),
                _goldColor,
                17,
              ),
            ),
          ),

          // "Alhamdulillah"
          Positioned(
            left: 200,
            top: 260,
            child: Transform.rotate(
              angle: -0.06,
              child: _buildStrokedText(
                'Alhamdulillah',
                const TextStyle(
                  fontFamily: 'Railey',
                  fontSize: 90,
                  height: 1.0,
                ),
                _creamColor,
                10,
              ),
            ),
          ),

          // "Barokallahu fiik"
          Positioned(
            left: 180,
            top: 340,
            child: Transform.rotate(
              angle: -0.06,
              child: _buildStrokedText(
                'Barokallahu fiik',
                const TextStyle(
                  fontFamily: 'Railey',
                  fontSize: 90,
                  height: 1.0,
                ),
                _creamColor,
                10,
              ),
            ),
          ),

          // ===== LAYER 4: Logo =====
          Positioned(
            right: -180,
            top: -210,
            child: Image.asset(
              AppConfig.current.syahadahLogoAsset,
              width: 700,
              height: 700,
            ),
          ),

          // ===== LAYER 5: Konten teks =====

          // Teks hafalan
          Positioned(
            left: 30,
            top: _isTahsin ? 540 : 520,
            child: Transform.rotate(
              angle: -0.02,
              child: SizedBox(
                width: 500,
                child: Text(
                  _hafalanText,
                  style: GoogleFonts.breeSerif(
                    fontSize: _isTahsin ? 60 : 50,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),

          // Nama santri
          Positioned(
            left: 590,
            top: 820,
            child: SizedBox(
              width: 460,
              child: Transform.rotate(
                angle: -0.01,
                child: Text(
                  displayName,
                  style: GoogleFonts.breeSerif(
                    fontSize: 50,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),

          // Teks quote
          Positioned(
            left: 40,
            bottom: _isTahsin ? 100 : 80,
            child: SizedBox(
              width: 860,
              child: Text(
                _quoteText,
                style: GoogleFonts.arimo(
                  fontSize: _isTahsin ? 57 : 50,
                  fontWeight: FontWeight.w400,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ),
          ),

          // Bulan & Tahun
          Positioned(
            right: 150,
            bottom: 35,
            child: Text(
              _formattedDate,
              style: GoogleFonts.breeSerif(
                fontSize: 50,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrokedText(
    String text,
    TextStyle baseStyle,
    Color fillColor,
    double strokeWidth,
  ) {
    return Stack(
      children: [
        Text(
          text,
          style: baseStyle.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..color = Colors.black,
          ),
        ),
        Text(text, style: baseStyle.copyWith(color: fillColor)),
      ],
    );
  }
}
