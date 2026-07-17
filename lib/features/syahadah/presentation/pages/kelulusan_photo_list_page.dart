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
    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [SizedBox(height: 180), _EmptyView()],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        itemCount: _items.length + 1,
        separatorBuilder: (_, index) => SizedBox(height: index == 0 ? 14 : 10),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Text(
              '${_items.length} foto tersimpan',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            );
          }

          final item = _items[index - 1];
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
    final date = DateFormat('d MMMM yyyy', 'id_ID').format(item.createdAt);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              item.imageUrl,
              width: 68,
              height: 85,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (_, _, _) => Container(
                width: 68,
                height: 85,
                color: Colors.grey.shade200,
                child: const Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.santriName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
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
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 5),
                Text(
                  [if (item.kelas.isNotEmpty) item.kelas, date].join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
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
                  color: Colors.red.shade700,
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
