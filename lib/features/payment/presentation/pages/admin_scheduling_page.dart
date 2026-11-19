import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:khoirunnasyien/core/router/route_names.dart';
import 'package:khoirunnasyien/core/theme/app_colors.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_app_bar.dart';
import 'package:khoirunnasyien/features/home/presentation/widgets/menu_card.dart';

class AdminSchedulingPage extends StatelessWidget {
  const AdminSchedulingPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: const AiwaAppBar(title: 'Penjadwalan'),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pantau pengiriman pengingat kepada wali santri.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 120,
            height: 120,
            child: MenuCard(
              title: 'Pembayaran',
              icon: Icons.schedule_send_rounded,
              color: AppColors.primary,
              onTap: () => context.pushNamed(RouteNames.adminPaymentScheduling),
            ),
          ),
        ],
      ),
    ),
  );
}
