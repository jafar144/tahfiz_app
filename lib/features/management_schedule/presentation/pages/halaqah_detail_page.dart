import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:khoirunnasyien/core/router/route_names.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/entities/halaqah.dart';
import 'package:khoirunnasyien/features/management_schedule/presentation/cubit/halaqah_detail_cubit.dart';
import 'package:khoirunnasyien/features/management_schedule/presentation/cubit/halaqah_detail_state.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';

class HalaqahDetailPage extends StatelessWidget {
  final String sessionName;
  final String gender;

  const HalaqahDetailPage({
    super.key,
    this.sessionName = 'Regular',
    this.gender = 'Putra',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        title: const Text(
          'Detail Jadwal',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Hapus Halaqah',
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final cubit = context.read<HalaqahDetailCubit>();
          context.pushNamed(RouteNames.editHalaqah, extra: cubit);
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      body: BlocConsumer<HalaqahDetailCubit, HalaqahDetailState>(
        listener: (context, state) {
          if (state is HalaqahDetailDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Halaqah berhasil dihapus')),
            );
            context.pop();
          } else if (state is HalaqahDetailError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is HalaqahDetailLoading ||
              state is HalaqahDetailDeleting ||
              state is HalaqahDetailDeleted) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is HalaqahDetailError) {
            return Center(child: Text(state.message));
          }

          Halaqah? halaqah;
          if (state is HalaqahDetailLoaded) {
            halaqah = state.halaqah;
          } else if (state is HalaqahDetailInitial) {
            halaqah = state.halaqah;
          }

          if (halaqah == null) return const SizedBox();

          return SafeArea(
            child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildHeaderCard(context, halaqah),
                const SizedBox(height: 24),
                _buildInfoSection(context, halaqah, state),
                const SizedBox(height: 24),
                _buildSantriSection(halaqah, state is HalaqahDetailLoaded ? state.santriList : []),
                const SizedBox(height: 80), // Space for FAB
              ],
            ),
          ),
        );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final cubit = context.read<HalaqahDetailCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Halaqah'),
        content: const Text(
          'Yakin ingin menghapus halaqah ini? Semua santri akan dilepas dari '
          'halaqah ini. Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      cubit.deleteHalaqah();
    }
  }

  Widget _buildHeaderCard(BuildContext context, Halaqah halaqah) {
    final initial = halaqah.name.isNotEmpty
        ? (halaqah.name.length >= 2
            ? halaqah.name.substring(0, 2).toUpperCase()
            : halaqah.name[0].toUpperCase())
        : '?';

    // Gender Text and Color
    final genderText = gender == 'L' ? 'Putra' : (gender == 'P' ? 'Putri' : gender);
    final genderColor = (gender == 'P' || gender == 'Putri') ? Colors.pink : Colors.blue; 

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            halaqah.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildBadge(
                icon: _getSessionIcon(sessionName),
                text: _capitalize(sessionName),
                color: _getSessionColor(sessionName),
              ),
              const SizedBox(width: 8),
              _buildBadge(
                icon: Icons.person,
                text: genderText,
                color: genderColor.withOpacity(0.1),
                textColor: genderColor == Colors.pink ? Colors.red : Colors.blue, 
                iconColor: genderColor == Colors.pink ? Colors.red : Colors.blue,
                isCustomColor: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String text,
    required Color color,
    Color? textColor,
    Color? iconColor,
    bool isCustomColor = false,
  }) {
    final bgColor = isCustomColor ? color : color.withOpacity(0.1);
    final fgColor = textColor ?? color;
    final icoColor = iconColor ?? color;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: icoColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fgColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(
      BuildContext context, Halaqah halaqah, HalaqahDetailState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'INFORMASI UMUM',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
              letterSpacing: 1.0,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Pengajar
              _buildInfoRow(
                iconWidget: _buildAvatar(halaqah.teacherName),
                title: 'Pengajar',
                content: halaqah.teacherName,
                isFirst: true,
              ),
              const Padding(
                padding: EdgeInsets.only(left: 60),
                child: Divider(height: 1),
              ),
              // Ruangan
              _buildInfoRow(
                iconWidget: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.door_sliding_outlined,
                      color: Colors.blueGrey.shade700, size: 20),
                ),
                title: 'Ruangan',
                content: 'Ruang ${halaqah.room}',
              ),
              const Padding(
                padding: EdgeInsets.only(left: 60),
                child: Divider(height: 1),
              ),
              // Jadwal
              _buildScheduleRow(halaqah, state),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required Widget iconWidget,
    required String title,
    required String content,
    bool isFirst = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          iconWidget,
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleRow(Halaqah halaqah, HalaqahDetailState state) {
    List schedules = [];
    if (state is HalaqahDetailLoaded) {
      schedules = state.schedules
          .where((s) => halaqah.scheduleIds.contains(s.id))
          .toList()
        ..sort((a, b) {
          final byDay = a.day.compareTo(b.day);
          if (byDay != 0) return byDay;
          return a.startTime.compareTo(b.startTime);
        });
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.calendar_today_rounded,
                color: Colors.blue.shade700, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jadwal Sesi',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                if (schedules.isEmpty)
                   const Text('-', style: TextStyle(fontWeight: FontWeight.bold)),
                ...schedules.map((schedule) {
                  final dayName = _dayName(schedule.day);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dayName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${schedule.startTime} - ${schedule.endTime}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.orange.shade700,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildSantriSection(Halaqah halaqah, List<SantriEntity> santriList) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Daftar Santri',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${santriList.length} Santri',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: santriList.length,
            separatorBuilder: (_, __) => const Padding(
              padding: EdgeInsets.only(left: 60),
              child: Divider(height: 1),
            ),
            itemBuilder: (context, index) {
              final santri = santriList[index];
              final initial = santri.name.isNotEmpty
                  ? (santri.name.length >= 2 
                      ? santri.name.substring(0, 2).toUpperCase() 
                      : santri.name[0].toUpperCase())
                  : '?';
              
              // Random-ish color based on index
              final colors = [
                Colors.blue, Colors.purple, Colors.teal, Colors.orange, Colors.pink
              ];
              final color = colors[index % colors.length];

              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                title: Text(
                  santri.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                subtitle: Text(
                  santri.nis.isNotEmpty ? santri.nis : "-",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey.shade400,
                ),
                onTap: () {
                   // Navigate to santri detail if needed, or ignored for now
                },
              );
            },
          ),
        ),
      ],
    );
  }
  
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Color _getSessionColor(String session) {
    switch (session.toLowerCase()) {
      case 'pagi':
        return Colors.orange.shade700;
      case 'sore':
        return Colors.deepOrange.shade700;
      case 'malam':
        return Colors.indigo.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  IconData _getSessionIcon(String session) {
    switch (session.toLowerCase()) {
      case 'pagi':
        return Icons.wb_sunny_outlined;
      case 'sore':
        return Icons.wb_twilight;
      case 'malam':
        return Icons.nights_stay_outlined;
      default:
        return Icons.schedule;
    }
  }

  String _dayName(int day) {
    if (day == 0) return 'Invalid';
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu'
    ];
    if (day >= 1 && day <= 7) return days[day - 1];
    return '';
  }
}
