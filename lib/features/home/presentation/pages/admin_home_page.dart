import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:khoirunnasyien/core/router/route_names.dart';
import 'package:khoirunnasyien/features/home/presentation/cubit/admin_home_cubit.dart';
import 'package:khoirunnasyien/features/home/presentation/cubit/admin_home_state.dart';
import 'package:khoirunnasyien/features/home/presentation/widgets/info_card.dart';
import 'package:khoirunnasyien/features/home/presentation/widgets/menu_card.dart';

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
                if (state is AdminHomeLoading) {
                  return const CircularProgressIndicator();
                }
      
                if (state is AdminHomeLoaded) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, ${state.data.adminName}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      InfoCard(
                        title: 'Total Santri',
                        value: state.data.totalSantri.toString(),
                        subtitle: 'Active students',
                        icon: Icons.groups_rounded,
                      ),
                    ],
                  );
                }
      
                if (state is AdminHomeError) {
                  return Text(state.message);
                }
      
                return const SizedBox();
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
