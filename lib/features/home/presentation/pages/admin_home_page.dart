import 'package:flutter/material.dart';
import 'package:khoirunnasyien/features/home/presentation/widgets/admin_bottom_nav.dart';
import 'package:khoirunnasyien/features/home/presentation/widgets/info_card.dart';
import 'package:khoirunnasyien/features/home/presentation/widgets/menu_card.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        elevation: 0,
      ),
      bottomNavigationBar: const AdminBottomNav(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Greeting
            const Text(
              'Welcome back 👋',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 16),

            /// INFO (Total Santri)
            const InfoCard(
              title: 'Total Santri',
              value: '150',
              subtitle: 'Active students',
              icon: Icons.groups_rounded,
            ),

            const SizedBox(height: 24),

            /// Management
            const Text(
              'Management',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: const [
                MenuCard(
                  icon: Icons.payments_rounded,
                  title: 'Payment Input',
                  subtitle: 'SPP & Infaq',
                ),
                MenuCard(
                  icon: Icons.calendar_month_rounded,
                  title: 'Schedule',
                  subtitle: 'Manage Classes',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}