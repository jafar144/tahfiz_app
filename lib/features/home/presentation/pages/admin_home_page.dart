import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:khoirunnasyien/core/router/route_names.dart';
import 'package:khoirunnasyien/features/home/presentation/cubit/admin_home_cubit.dart';
import 'package:khoirunnasyien/features/home/presentation/cubit/admin_home_state.dart';
import 'package:khoirunnasyien/features/home/presentation/widgets/info_card.dart';
import 'package:khoirunnasyien/features/home/presentation/widgets/menu_card.dart';

import 'package:khoirunnasyien/features/home/domain/entities/admin_home_data.dart';
import 'package:skeletonizer/skeletonizer.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  @override
  void initState() {
    super.initState();
    context.read<AdminHomeCubit>().loadHome();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BlocBuilder<AdminHomeCubit, AdminHomeState>(
              builder: (context, state) {
                final isLoading = state is AdminHomeLoading;
                final AdminHomeData displayData;

                if (state is AdminHomeLoaded) {
                  displayData = state.data;
                } else if (state is AdminHomeError) {
                  displayData = AdminHomeData(
                    adminName: 'Admin',
                    totalSantriPutra: 0,
                    totalSantriPutri: 0,
                  );
                } else {
                  displayData = AdminHomeData(
                    adminName: 'Admin User',
                    totalSantriPutra: 123,
                    totalSantriPutri: 123,
                  );
                }

                return Skeletonizer(
                  enabled: isLoading,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, ${displayData.adminName}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InfoCard(
                              title: 'Santri Putra',
                              value: displayData.totalSantriPutra.toString(),
                              icon: Icons.face,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InfoCard(
                              title: 'Santri Putri',
                              value: displayData.totalSantriPutri.toString(),
                              icon: Icons.face_3,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
      
            const SizedBox(height: 24),
      
            /// Management
            const Text(
              'Management',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
      
            const SizedBox(height: 12),
      
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                MenuCard(
                  icon: Icons.payments_rounded,
                  title: 'Payment Input',
                  subtitle: 'SPP',
                  onTap: () => context.pushNamed(RouteNames.adminPayment),
                ),
                MenuCard(
                  icon: Icons.calendar_month_rounded,
                  title: 'Schedule',
                  subtitle: 'Manage Classes',
                  onTap: () => context.pushNamed(RouteNames.adminSchedule),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
