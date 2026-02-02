import 'package:flutter/material.dart';

class AsatidzHomePage extends StatelessWidget {
  const AsatidzHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Asatidz Home')),
      body: const Center(
        child: Text('Daftar Santri Binaan'),
      ),
    );
  }
}
