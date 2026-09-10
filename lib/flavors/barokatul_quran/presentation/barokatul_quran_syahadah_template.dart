import 'package:flutter/material.dart';
import 'package:khoirunnasyien/core/config/app_config.dart';
import 'package:khoirunnasyien/features/syahadah/presentation/widgets/syahadah_template.dart';

class BarokatulQuranSyahadahTemplate extends StatelessWidget {
  const BarokatulQuranSyahadahTemplate({super.key, required this.data});

  final SyahadahTemplateData data;

  static const _green = Color(0xFF075A3A);
  static const _gold = Color(0xFFD4AF37);
  static const _cream = Color(0xFFFFFBED);
  static const _ink = Color(0xFF17372C);

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
    return '${data.date.day} ${months[data.date.month]} ${data.date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1080,
      height: 1350,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(color: _cream),
      child: Stack(
        children: [
          const Positioned(
            top: -410,
            left: -150,
            child: _DecorativeCircle(size: 950, color: _green),
          ),
          const Positioned(
            right: -210,
            bottom: -280,
            child: _DecorativeCircle(size: 650, color: _green),
          ),
          const Positioned(
            right: -250,
            top: 250,
            child: _DecorativeCircle(size: 500, color: _gold),
          ),
          Positioned(
            left: 70,
            top: 60,
            child: Image.asset(
              AppConfig.current.syahadahLogoAsset,
              width: 185,
              height: 185,
              fit: BoxFit.contain,
            ),
          ),
          const Positioned(
            left: 285,
            top: 90,
            child: Text(
              "BAROKATUL QUR'AN",
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
                fontSize: 46,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ),
          const Positioned(
            left: 285,
            top: 150,
            child: Text(
              'SYAHADAH PENCAPAIAN',
              style: TextStyle(
                color: _gold,
                fontFamily: 'Inter',
                fontSize: 31,
                fontWeight: FontWeight.w600,
                letterSpacing: 5,
              ),
            ),
          ),
          Positioned(
            left: 110,
            top: 315,
            child: Container(
              width: 350,
              height: 350,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: _gold, width: 12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 32,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: ClipOval(child: _buildPhoto()),
            ),
          ),
          Positioned(
            left: 515,
            top: 350,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Alhamdulillah,',
                  style: TextStyle(
                    color: _green,
                    fontFamily: 'Railey',
                    fontSize: 82,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 15),
                SyahadahFittedText(
                  width: 490,
                  height: 145,
                  text: data.displayName,
                  style: const TextStyle(
                    color: _ink,
                    fontFamily: 'Inter',
                    fontSize: 68,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'NIS ${data.nis}',
                  style: const TextStyle(
                    color: _green,
                    fontFamily: 'Inter',
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 90,
            right: 90,
            top: 750,
            child: Container(
              height: 365,
              padding: const EdgeInsets.symmetric(horizontal: 55, vertical: 42),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(44),
                border: Border.all(color: const Color(0x33745D12), width: 3),
              ),
              child: Column(
                children: [
                  Text(
                    data.kelas.toUpperCase(),
                    style: const TextStyle(
                      color: _green,
                      fontFamily: 'Inter',
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'TELAH MENYELESAIKAN',
                    style: TextStyle(
                      color: Color(0xFF7C817E),
                      fontFamily: 'Inter',
                      fontSize: 26,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 22),
                  SyahadahFittedText(
                    width: 820,
                    height: 150,
                    text: data.hafalan,
                    textAlign: TextAlign.center,
                    alignment: Alignment.center,
                    style: const TextStyle(
                      color: _ink,
                      fontFamily: 'Inter',
                      fontSize: 58,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 105,
            bottom: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Semoga Allah memberkahi ilmu dan hafalannya.',
                  style: TextStyle(
                    color: _ink,
                    fontFamily: 'Inter',
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _formattedDate,
                  style: const TextStyle(
                    color: _green,
                    fontFamily: 'Inter',
                    fontSize: 31,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoto() {
    if (data.photoUrl.trim().isEmpty) {
      return const _PhotoPlaceholder();
    }

    return Image.network(
      data.photoUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const _PhotoPlaceholder(),
    );
  }
}

class _DecorativeCircle extends StatelessWidget {
  const _DecorativeCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Color(0xFFE4EAE6),
    child: Center(
      child: Icon(Icons.person_rounded, size: 150, color: Color(0xFF8CA197)),
    ),
  );
}
