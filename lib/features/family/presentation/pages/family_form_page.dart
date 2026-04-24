import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:khoirunnasyien/core/router/route_names.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_app_bar.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_button.dart';
import 'package:khoirunnasyien/features/family/data/family_repository.dart';
import 'package:khoirunnasyien/features/family/presentation/cubit/family_cubit.dart';
import 'package:khoirunnasyien/features/family/presentation/cubit/family_state.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/core/di/injection.dart';

class FamilyFormPage extends StatefulWidget {
  final FamilyWithMembers? existing;

  const FamilyFormPage({super.key, this.existing});

  @override
  State<FamilyFormPage> createState() => _FamilyFormPageState();
}

class _FamilyFormPageState extends State<FamilyFormPage> {
  List<SantriEntity> _selectedSantri = [];
  bool _isLoading = false;
  Set<String> _disabledIds = {};

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _selectedSantri = List.from(widget.existing!.members);
    }
    _loadDisabledIds();
  }

  Future<void> _loadDisabledIds() async {
    final repo = getIt<FamilyRepository>();
    final allIds = await repo.getAllFamilySantriIds();

    if (_isEditing) {
      for (final id in widget.existing!.family.santriIds) {
        allIds.remove(id);
      }
    }

    if (mounted) {
      setState(() => _disabledIds = allIds);
    }
  }

  Future<void> _selectSantri() async {
    final result = await context.pushNamed<List<SantriEntity>>(
      RouteNames.selectSantri,
      extra: <String, dynamic>{
        'isMultiSelect': true,
        'initialSelection': _selectedSantri,
        'disabledIds': _disabledIds.toList(),
      },
    );

    if (result != null && mounted) {
      setState(() => _selectedSantri = result);
    }
  }

  void _removeSantri(SantriEntity santri) {
    setState(() {
      _selectedSantri.removeWhere((s) => s.id == santri.id);
    });
  }

  Future<void> _submit() async {
    if (_selectedSantri.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal 2 santri per keluarga')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final cubit = context.read<FamilyCubit>();
      final ids = _selectedSantri.map((s) => s.id).toList();

      if (_isEditing) {
        await cubit.updateFamily(widget.existing!.family.id, ids);
      } else {
        await cubit.addFamily(ids);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? 'Keluarga berhasil diperbarui'
                : 'Keluarga berhasil ditambahkan'),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e')),
        );
      }
    }
  }

  Future<void> _deleteFamily() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Hapus Keluarga'),
          ],
        ),
        content: const Text('Apakah Anda yakin ingin menghapus keluarga ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      try {
        await context.read<FamilyCubit>().deleteFamily(widget.existing!.family.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Keluarga berhasil dihapus')),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AiwaAppBar(
        title: _isEditing ? 'Edit Keluarga' : 'Tambah Keluarga',
        actions: _isEditing
            ? [
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: _deleteFamily,
                ),
              ]
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Anggota Keluarga',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Minimal 2 santri per keluarga',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 16),
                    if (_selectedSantri.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.people_outline, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text(
                              'Belum ada santri dipilih',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      )
                    else
                      ...List.generate(_selectedSantri.length, (index) {
                        final santri = _selectedSantri[index];
                        final isMale = santri.jenisKelamin == 'L';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isMale ? Colors.blue.shade50 : Colors.pink.shade50,
                                child: Text(
                                  santri.name.isNotEmpty ? santri.name[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isMale ? Colors.blue.shade700 : Colors.pink.shade700,
                                  ),
                                ),
                              ),
                              title: Text(
                                santri.name,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              subtitle: Text(
                                'NIS: ${santri.nis} • ${santri.kelas}',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.close, color: Colors.red.shade400, size: 20),
                                onPressed: () => _removeSantri(santri),
                              ),
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _selectSantri,
                        icon: const Icon(Icons.add),
                        label: const Text('Pilih Santri'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.blue.shade300),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: AiwaButton(
                text: _isEditing ? 'Simpan Perubahan' : 'Buat Keluarga',
                onPressed: _submit,
                isLoading: _isLoading,
                height: 48,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
