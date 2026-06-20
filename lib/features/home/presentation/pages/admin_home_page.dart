import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:khoirunnasyien/core/router/route_names.dart';
import 'package:khoirunnasyien/core/theme/app_text_styles.dart';
import 'package:khoirunnasyien/features/home/presentation/cubit/admin_home_cubit.dart';
import 'package:khoirunnasyien/features/home/presentation/cubit/admin_home_state.dart';
import 'package:khoirunnasyien/features/home/presentation/widgets/info_card.dart';
import 'package:khoirunnasyien/features/home/presentation/widgets/menu_card.dart';

import 'package:khoirunnasyien/core/di/injection.dart';
import 'package:khoirunnasyien/features/home/domain/entities/admin_home_data.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/repositories/schedule_repository.dart';
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
      child: RefreshIndicator(
        onRefresh: () async {
          context.read<AdminHomeCubit>().loadHome();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BlocBuilder<AdminHomeCubit, AdminHomeState>(
                builder: (context, state) {
                  final isLoading = state is AdminHomeLoading;
                  AdminHomeData displayData;

                  if (state is AdminHomeLoaded) {
                    displayData = state.data;
                  } else if (state is AdminHomeError) {
                    displayData = AdminHomeData(
                      adminName: 'Admin',
                      totalSantriPutra: 0,
                      totalSantriPutri: 0,
                      totalAsatidzPutra: 0,
                      totalAsatidzPutri: 0,
                    );
                  } else {
                    displayData = AdminHomeData(
                      adminName: 'Admin User',
                      totalSantriPutra: 123,
                      totalSantriPutri: 123,
                      totalAsatidzPutra: 10,
                      totalAsatidzPutri: 10,
                    );
                  }

                  return Skeletonizer(
                    enabled: isLoading,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Assalamua\'laikum',
                              style: AppTextStyles.infoGrey,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              displayData.adminName,
                              style: AppTextStyles.mediumContentBlack,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              InfoCard(
                                title: 'Santri Putra',
                                value: _formatValue(displayData.totalSantriPutra),
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 12),
                              InfoCard(
                                title: 'Santri Putri',
                                value: _formatValue(displayData.totalSantriPutri),
                                color: Colors.pink,
                              ),
                              const SizedBox(width: 12),
                              InfoCard(
                                title: 'Asatidz Putra',
                                value: _formatValue(displayData.totalAsatidzPutra),
                                icon: Icons.school_rounded,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 12),
                              InfoCard(
                                title: 'Asatidz Putri',
                                value: _formatValue(displayData.totalAsatidzPutri),
                                icon: Icons.school_rounded,
                                color: Colors.red,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              const Text('Menu', style: AppTextStyles.mediumContentBlack),

              const SizedBox(height: 16),

              _menuSection('Akademik', [
                MenuCard(
                  icon: Icons.calendar_month_rounded,
                  title: 'Halaqah',
                  color: Colors.indigo,
                  onTap: () => context.pushNamed(RouteNames.adminSchedule),
                ),
                MenuCard(
                  icon: Icons.fact_check_rounded,
                  title: 'Penilaian',
                  color: Colors.teal,
                  onTap: () => context.pushNamed(RouteNames.adminAssessment),
                ),
                MenuCard(
                  icon: Icons.workspace_premium_rounded,
                  title: 'Kelulusan',
                  color: Colors.amber.shade700,
                  onTap: () => context.pushNamed(RouteNames.adminSyahadah),
                ),
              ]),

              const SizedBox(height: 20),

              _menuSection('Keuangan', [
                MenuCard(
                  icon: Icons.payments_rounded,
                  title: 'Pembayaran',
                  color: Colors.green,
                  onTap: () => context.pushNamed(RouteNames.adminPayment),
                ),
                MenuCard(
                  icon: Icons.bar_chart_rounded,
                  title: 'Laporan Keuangan',
                  color: Colors.blue,
                  onTap: () => context.pushNamed(RouteNames.financialReport),
                ),
              ]),

              const SizedBox(height: 20),

              _menuSection('Lainnya', [
                MenuCard(
                  icon: Icons.family_restroom_rounded,
                  title: 'Keluarga',
                  color: Colors.deepPurple,
                  onTap: () => context.pushNamed(RouteNames.adminFamily),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
  
  String _formatValue(int value) {
    return value.toString();
  }

  Widget _menuSection(String title, List<Widget> cards) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.infoGrey),
        const SizedBox(height: 8),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.0,
          children: cards,
        ),
      ],
    );
  }
}
