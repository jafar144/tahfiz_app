import 'package:flutter/material.dart';

class SantriHomePage extends StatelessWidget {
  const SantriHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Santri Home')),
      body: const Center(
        child: Text('Progress Hafalan Santri'),
      ),
    );
  }
}
