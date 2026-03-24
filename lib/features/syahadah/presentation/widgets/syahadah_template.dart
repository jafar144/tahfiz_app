import 'package:flutter/material.dart';

class SyahadahTemplate extends StatelessWidget {
  final String santriName;
  final String hafalan;
  final String photoUrl;
  final DateTime date;

  const SyahadahTemplate({
    super.key,
    required this.santriName,
    required this.hafalan,
    required this.photoUrl,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    // A 4:5 aspect ratio is good for Instagram/WhatsApp
    return Container(
      width: 1080,
      height: 1350,
      color: Colors.white,
      child: Stack(
        children: [
          // 1. LAPISAN BACKGROUND TEMPLATE DARI CANVA
          Positioned.fill(
            child: Image.asset(
              'assets/images/template_syahadah.png', 
              fit: BoxFit.cover,
            ),
          ),

          Positioned(
            top: 500,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 450,
                height: 800,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(200),
                    topRight: Radius.circular(200),
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                  border: Border.all(color: Colors.white, width: 10), // Bingkai Putih tebal
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                  image: DecorationImage(
                    image: NetworkImage(photoUrl),
                    fit: BoxFit.cover, 
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            left: 30,
            top: 700,
            child: SizedBox(
               width: 280,
               child: Text(
                hafalan.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.2,
                  shadows: [
                    Shadow(color: Colors.black26, offset: Offset(2, 2), blurRadius: 4),
                  ]
                ),
              ),
            ),
          ),

          Positioned(
            right: 20,
            bottom: 250,
            child: SizedBox(
               width: 300,
               child: Text(
                santriName.toUpperCase(),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.2,
                  shadows: [
                    Shadow(color: Colors.black26, offset: Offset(2, 2), blurRadius: 4),
                  ]
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
