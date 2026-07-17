import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:khoirunnasyien/core/di/injection.dart';
import 'package:khoirunnasyien/core/utils/role.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_app_bar.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_bottom_sheet.dart';
import 'package:khoirunnasyien/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:khoirunnasyien/features/auth/presentation/cubit/auth_state.dart';
import 'package:khoirunnasyien/features/syahadah/data/kelulusan_repository.dart';
import 'package:khoirunnasyien/features/syahadah/data/syahadah_retention.dart';

class KelulusanPhotoListPage extends StatefulWidget {
  const KelulusanPhotoListPage({super.key});

  @override
  State<KelulusanPhotoListPage> createState() => _KelulusanPhotoListPageState();
}

class _KelulusanPhotoListPageState extends State<KelulusanPhotoListPage> {
  List<KelulusanEntity> _items = const [];
  final Set<String> _deletingIds = {};
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final items = await getIt<KelulusanRepository>().getKelulusan(
        limit: 100,
        activeOnly: false,
      );
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Gagal memuat foto kelulusan: $error';
      });
    }
  }

  Future<void> _confirmDelete(KelulusanEntity item) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => AiwaBottomSheet(
        title: 'Hapus Foto Kelulusan?',
        resetText: 'Batal',
        applyText: 'Hapus',
        resetColor: Colors.grey.shade700,
        applyColor: Colors.red,
        onReset: () => Navigator.pop(sheetContext, false),
        onApply: () => Navigator.pop(sheetContext, true),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Foto ${item.santriName} akan dihapus dari Home Santri dan '
                'penyimpanan. Tindakan ini tidak dapat dibatalkan.',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deletingIds.add(item.id));
    try {
      await getIt<KelulusanRepository>().deleteKelulusan(item.id);
      if (!mounted) return;
      setState(
        () => _items = _items.where((entry) => entry.id != item.id).toList(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto kelulusan berhasil dihapus.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus foto kelulusan: $error')),
      );
    } finally {
      if (mounted) setState(() => _deletingIds.remove(item.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final isAdmin =
        authState is AuthAuthenticated &&
        (authState.user.role == UserRole.admin || authState.user.isAdmin);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: const AiwaAppBar(title: 'Foto Kelulusan'),
      body: isAdmin ? _buildBody() : const _AccessDenied(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return _ErrorView(message: _errorMessage!, onRetry: _load);
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _items.length + 2,
        separatorBuilder: (_, index) => SizedBox(height: index == 0 ? 14 : 10),
        itemBuilder: (context, index) {
          if (index == 0) {
            return const _RetentionNotice();
          }

          if (index == 1) {
            if (_items.isEmpty) return const _EmptyView();
            return Text(
              '${_items.length} foto tersimpan',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            );
          }

          final item = _items[index - 2];
          return _KelulusanPhotoCard(
            item: item,
            deleting: _deletingIds.contains(item.id),
            onDelete: () => _confirmDelete(item),
          );
        },
      ),
    );
  }
}

class _KelulusanPhotoCard extends StatelessWidget {
  final KelulusanEntity item;
  final bool deleting;
  final VoidCallback onDelete;

  const _KelulusanPhotoCard({
    required this.item,
    required this.deleting,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isActive = isSyahadahPhotoActive(item.createdAt, now: now);
    final date = DateFormat('d MMMM yyyy', 'id_ID').format(item.createdAt);
    final deletionAtWib = syahadahUtcToWib(
      syahadahScheduledDeletionAtUtc(item.createdAt, now: now),
    );
    final deletionDate = DateFormat(
      'EEEE, d MMMM yyyy',
      'id_ID',
    ).format(deletionAtWib);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? Colors.grey.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                isActive ? Colors.transparent : Colors.grey,
                isActive ? BlendMode.dst : BlendMode.saturation,
              ),
              child: Opacity(
                opacity: isActive ? 1 : 0.58,
                child: Image.network(
                  item.imageUrl,
                  width: 68,
                  height: 98,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (_, _, _) => Container(
                    width: 68,
                    height: 98,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusBadge(isActive: isActive),
                const SizedBox(height: 6),
                Text(
                  item.santriName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isActive
                        ? Colors.grey.shade900
                        : Colors.grey.shade600,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (item.hafalan.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    item.hafalan,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isActive
                          ? Colors.grey.shade700
                          : Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 5),
                Text(
                  [if (item.kelas.isNotEmpty) item.kelas, date].join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
                const SizedBox(height: 7),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 13,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Dihapus otomatis $deletionDate, 03.00 WIB',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 10.5,
                          height: 1.3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 2),
          deleting
              ? const SizedBox(
                  width: 40,
                  height: 40,
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  tooltip: 'Hapus foto',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: isActive ? Colors.red.shade700 : Colors.red.shade400,
                ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;

  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.green.shade700 : Colors.grey.shade600;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade50 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? 'Tampil di Home' : 'Tidak tampil di Home',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RetentionNotice extends StatelessWidget {
  const _RetentionNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.info_outline_rounded,
              size: 20,
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tentang foto kelulusan',
                  style: TextStyle(
                    color: Colors.blue.shade900,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Daftar ini memuat semua foto yang tersimpan. Foto tampil '
                  'di Home Santri selama 7 hari, lalu dihapus otomatis setiap '
                  'Senin pukul 03.00 WIB.',
                  style: TextStyle(
                    color: Colors.blue.shade800,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.photo_library_outlined,
          size: 52,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 12),
        const Text(
          'Belum ada foto kelulusan.',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccessDenied extends StatelessWidget {
  const _AccessDenied();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Halaman ini hanya tersedia untuk admin.'));
  }
}
