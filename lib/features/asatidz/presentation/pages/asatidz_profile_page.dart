import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:khoirunnasyien/core/router/route_names.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_app_bar.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_bottom_sheet.dart';
import 'package:khoirunnasyien/features/auth/data/model/user_model.dart';
import 'package:khoirunnasyien/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:khoirunnasyien/features/auth/presentation/cubit/auth_state.dart';

class AsatidzProfilePage extends StatelessWidget {
  const AsatidzProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AiwaAppBar(title: "Profile"),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is! AuthAuthenticated) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = state.user;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildProfileHeader(user.name, user.email, user.photoUrl),
                const SizedBox(height: 24),
                _buildInfoCard(context, user),
                const SizedBox(height: 24),
                _buildMenuSection(context),
                const SizedBox(height: 24),
                _buildLogoutButton(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(String name, String email, String? photoUrl) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade600, Colors.blue.shade400],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              image: photoUrl != null && photoUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(photoUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: photoUrl != null && photoUrl.isNotEmpty
                ? null
                : Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'A',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, UserModel user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi Akun',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.badge, 'NIS', user.nis),
          const Divider(height: 24),
          _buildInfoRow(Icons.phone, 'No. Telepon', user.phone),
          const Divider(height: 24),
          _buildInfoRow(
            Icons.work,
            'Role',
            'Asatidz',
            trailing: user.isAdmin
                ? _buildSmallSwitchButton(context, isToAsatidz: false)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Widget? trailing,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: Colors.blue.shade700),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing],
      ],
    );
  }

  Widget _buildSmallSwitchButton(
    BuildContext context, {
    required bool isToAsatidz,
  }) {
    return InkWell(
      onTap: () async {
        final confirmed = await showAiwaActionSheet<bool>(
          context: context,
          title: 'Ganti Role',
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.swap_horiz, color: Colors.blue, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Apakah Anda yakin ingin beralih ke role ${isToAsatidz ? 'Asatidz' : 'Admin'}?',
                  style: const TextStyle(fontSize: 15, height: 1.4),
                ),
              ),
            ],
          ),
          confirmText: 'Ya, Ganti',
          confirmValue: true,
          cancelValue: false,
          confirmColor: Colors.blue,
        );
        if (confirmed == true && context.mounted) {
          context.read<AuthCubit>().switchRole();
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swap_horiz, size: 16, color: Colors.blue.shade700),
            const SizedBox(width: 4),
            Text(
              "Switch",
              style: TextStyle(
                color: Colors.blue.shade700,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.info,
            title: 'Tentang Aplikasi',
            subtitle: 'Versi 1.0.0',
            color: Colors.green,
            onTap: () {
              _showAboutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showLogoutDialog(context),
        icon: const Icon(Icons.logout, size: 20),
        label: const Text(
          'Keluar',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final confirmed = await showAiwaActionSheet<bool>(
      context: context,
      title: 'Konfirmasi Keluar',
      content: const Text(
        'Apakah Anda yakin ingin keluar dari aplikasi?',
        style: TextStyle(fontSize: 15),
      ),
      confirmText: 'Keluar',
      confirmValue: true,
      cancelValue: false,
      confirmColor: Colors.red,
    );
    if (confirmed == true && context.mounted) {
      await context.read<AuthCubit>().logout();
      if (context.mounted) context.goNamed(RouteNames.login);
    }
  }

  void _showAboutDialog(BuildContext context) {
    showAiwaActionSheet<void>(
      context: context,
      title: 'Tentang Aplikasi',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tahfiz App',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Versi 1.0.0',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          Text(
            'Aplikasi manajemen tahfiz untuk memudahkan pengelolaan santri, asatidz, dan kegiatan tahfiz.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
        ],
      ),
      confirmText: 'Tutup',
      showCancelAction: false,
    );
  }
}
