import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:khoirunnasyien/core/di/injection.dart';
import 'package:khoirunnasyien/core/router/route_names.dart';
import 'package:khoirunnasyien/core/utils/role.dart';
import 'package:khoirunnasyien/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:khoirunnasyien/features/auth/presentation/cubit/auth_state.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_app_bar.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_button.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_bottom_sheet.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_form_widgets.dart';
import 'package:khoirunnasyien/core/utils/image_utils.dart';
import 'package:khoirunnasyien/core/utils/ui_utils.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/syahadah/data/kelulusan_repository.dart';

import 'package:khoirunnasyien/features/syahadah/presentation/widgets/kelulusan_save_banner.dart';
import 'package:khoirunnasyien/features/syahadah/presentation/widgets/syahadah_template.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class SyahadahGeneratorPage extends StatefulWidget {
  const SyahadahGeneratorPage({super.key});

  @override
  State<SyahadahGeneratorPage> createState() => _SyahadahGeneratorPageState();
}

class _SyahadahGeneratorPageState extends State<SyahadahGeneratorPage> {
  final _formKey = GlobalKey<FormState>();
  final _hafalanController = TextEditingController();
  final _namaController = TextEditingController();
  final GlobalKey _repaintBoundaryKey = GlobalKey();

  SantriEntity? _selectedSantri;
  bool _isGenerating = false;
  KelulusanSaveStatus? _saveStatus;
  _PendingKelulusanSave? _pendingSave;
  int _saveAttempt = 0;

  @override
  void dispose() {
    _saveAttempt++;
    _hafalanController.dispose();
    _namaController.dispose();
    super.dispose();
  }

  void _selectSantri() async {
    // Asatidz (bukan admin) hanya boleh memilih santri di halaqah-nya sendiri,
    // termasuk saat pencarian. Admin tetap melihat seluruh santri.
    String? asatidzId;
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated &&
        authState.user.role == UserRole.asatidz) {
      asatidzId = authState.user.uid;
    }

    final result = await context.pushNamed(
      RouteNames.selectSantri,
      extra: asatidzId != null ? {'asatidzId': asatidzId} : null,
    );

    if (result != null) {
      final santri = result as SantriEntity;
      setState(() {
        _selectedSantri = santri;
        _namaController.text = santri.name;
      });
    }
  }

  bool get _isTahsin =>
      _selectedSantri != null &&
      _selectedSantri!.kelas.toLowerCase().startsWith('tahsin');

  Future<bool?> _showConfirmSheet() {
    return showAiwaActionSheet<bool>(
      context: context,
      title: 'Konfirmasi Kelulusan',
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                color: Colors.blue,
                size: 28,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Poster akan langsung dibagikan. Foto juga disimpan ke '
                  'daftar Kelulusan Santri secara paralel.',
                  style: TextStyle(height: 1.45),
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFFFFF7E6),
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFFB45309),
                    size: 21,
                  ),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Anda boleh melanjutkan ke WhatsApp. Jangan tutup paksa '
                      'Tahfiz App sampai banner berubah menjadi “Sudah tersimpan”.',
                      style: TextStyle(
                        color: Color(0xFF92400E),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      confirmText: 'Bagikan Sekarang',
      confirmValue: true,
      cancelValue: false,
      confirmColor: Colors.blue,
    );
  }

  void _startBackgroundSave(_PendingKelulusanSave job) {
    final attempt = ++_saveAttempt;
    setState(() {
      _pendingSave = job;
      _saveStatus = KelulusanSaveStatus.saving;
    });
    unawaited(_saveKelulusanInBackground(job, attempt));
  }

  Future<void> _saveKelulusanInBackground(
    _PendingKelulusanSave job,
    int attempt,
  ) async {
    String? uploadedUrl;
    try {
      uploadedUrl = await ImageUtils.uploadImageToFirebase(
        job.file,
        'syahadah_photos',
      );
      if (uploadedUrl == null) throw Exception('Upload foto gagal');

      await getIt<KelulusanRepository>().addKelulusan(
        santriId: job.santri.id,
        santriName: job.displayName,
        kelas: job.santri.kelas,
        hafalan: job.hafalan,
        imageUrl: uploadedUrl,
      );
      if (mounted && attempt == _saveAttempt) {
        setState(() => _saveStatus = KelulusanSaveStatus.success);
      }
    } catch (_) {
      if (uploadedUrl != null) {
        await ImageUtils.deleteImageFromFirebase(uploadedUrl);
      }
      if (mounted && attempt == _saveAttempt) {
        setState(() => _saveStatus = KelulusanSaveStatus.failure);
      }
    }
  }

  void _retryBackgroundSave() {
    final job = _pendingSave;
    if (job == null || _saveStatus == KelulusanSaveStatus.saving) return;
    _startBackgroundSave(job);
  }

  void _dismissSaveStatus() {
    if (_saveStatus == KelulusanSaveStatus.saving) return;
    setState(() => _saveStatus = null);
  }

  Future<void> _generateAndShare() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSantri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih santri terlebih dahulu')),
      );
      return;
    }
    if (_selectedSantri!.photoUrl == null ||
        _selectedSantri!.photoUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Santri ini belum memiliki foto profil, silahkan edit profil santri terlebih dahulu.',
          ),
        ),
      );
      return;
    }

    final confirmed = await _showConfirmSheet();
    if (confirmed != true) return;

    final selectedSantri = _selectedSantri!;
    final displayName = _namaController.text;
    final hafalan = _hafalanController.text;

    setState(() => _isGenerating = true);

    try {
      await Future.delayed(const Duration(milliseconds: 300));

      RenderRepaintBoundary boundary =
          _repaintBoundaryKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      // Pakai timestamp agar nama file selalu unik. Kalau nama file sama,
      // share sheet OS bisa menampilkan thumbnail lama dari cache.
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final imagePath =
          '${directory.path}/syahadah_${selectedSantri.name.replaceAll(' ', '_')}_$timestamp.png';
      final rawFile = File(imagePath);
      await rawFile.writeAsBytes(pngBytes);

      // Kompres hingga maksimal 1 MB (hemat storage & ringan dibagikan).
      final file = await ImageUtils.compressToMaxSize(rawFile) ?? rawFile;

      // Storage dan Firestore diproses paralel. Banner menjaga pengguna tetap
      // mengetahui status penyimpanan ketika kembali dari share sheet.
      _startBackgroundSave(
        _PendingKelulusanSave(
          file: file,
          santri: selectedSantri,
          displayName: displayName,
          hafalan: hafalan,
        ),
      );
      await WidgetsBinding.instance.endOfFrame;

      final xfile = XFile(file.path);
      await SharePlus.instance.share(ShareParams(files: [xfile]));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuat syahadah: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.select<AuthCubit, bool>((cubit) {
      final state = cubit.state;
      return state is AuthAuthenticated && state.user.role == UserRole.admin;
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AiwaAppBar(
        title: 'Kelulusan Santri',
        actions: [
          if (isAdmin)
            IconButton(
              tooltip: 'Kelola foto kelulusan',
              onPressed: () =>
                  context.pushNamed(RouteNames.adminSyahadahPhotos),
              icon: const Icon(Icons.photo_library_outlined),
            ),
        ],
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => UiUtils.unfocus(context),
          child: Column(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => SizeTransition(
                  sizeFactor: animation,
                  alignment: Alignment.topCenter,
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: _saveStatus == null
                    ? const SizedBox.shrink(key: ValueKey('save-status-hidden'))
                    : KelulusanSaveBanner(
                        status: _saveStatus!,
                        onRetry: _saveStatus == KelulusanSaveStatus.failure
                            ? _retryBackgroundSave
                            : null,
                        onDismiss: _dismissSaveStatus,
                      ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Pilih Santri
                        const Text(
                          'Pilih Santri',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _selectSantri,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.blue.shade100,
                                  backgroundImage:
                                      _selectedSantri?.photoUrl != null
                                      ? NetworkImage(_selectedSantri!.photoUrl!)
                                      : null,
                                  child: _selectedSantri?.photoUrl == null
                                      ? const Icon(
                                          Icons.person,
                                          color: Colors.blue,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedSantri?.name ??
                                            'Ketuk untuk memilih santri',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: _selectedSantri != null
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: _selectedSantri != null
                                              ? Colors.black87
                                              : Colors.grey,
                                        ),
                                      ),
                                      if (_selectedSantri != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'NIS: ${_selectedSantri!.nis} • Kelas: ${_selectedSantri!.kelas}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),

                        if (_selectedSantri != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _isTahsin
                                  ? Colors.orange.shade50
                                  : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isTahsin
                                      ? Icons.auto_stories
                                      : Icons.menu_book,
                                  size: 16,
                                  color: _isTahsin
                                      ? Colors.orange.shade700
                                      : Colors.blue.shade700,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Template: ${_isTahsin ? "Tahsin" : "Tahfidz"}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _isTahsin
                                        ? Colors.orange.shade700
                                        : Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),

                        // Nama tampil di syahadah
                        AiwaTextField(
                          label: 'Nama di Poster',
                          hint: 'Nama yang ditampilkan di poster',
                          controller: _namaController,
                          icon: Icons.badge_outlined,
                          textCapitalization: TextCapitalization.words,
                          enabled: _selectedSantri != null,
                          onChanged: (val) => setState(() {}),
                        ),
                        const SizedBox(height: 16),

                        // Nama Surah & Juz
                        AiwaTextField(
                          label: 'Nama Surah & Juz',
                          hint: 'Contoh: Q.s Al Muthofifin Juz 30',
                          controller: _hafalanController,
                          icon: Icons.menu_book,
                          textCapitalization: TextCapitalization.words,
                          onChanged: (val) => setState(() {}),
                        ),
                        const SizedBox(height: 24),

                        const AiwaFormSectionTitle(title: 'Preview'),
                        const SizedBox(height: 12),

                        if (_selectedSantri == null)
                          _buildEmptyPreview(
                            'Silakan pilih santri terlebih dahulu.',
                          )
                        else if (_selectedSantri!.photoUrl == null ||
                            _selectedSantri!.photoUrl!.isEmpty)
                          _buildEmptyPreview(
                            'Santri ini belum memiliki foto profil.\nSilakan edit profil santri di menu Manage Santri.',
                          )
                        else if (_hafalanController.text.isEmpty ||
                            _namaController.text.isEmpty)
                          _buildEmptyPreview(
                            'Silakan isi "Nama di Syahadah" dan\n"Nama Surah & Juz" untuk melihat preview.',
                          )
                        else
                          Center(
                            child: AspectRatio(
                              aspectRatio: 1080 / 1350,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return InteractiveViewer(
                                    child: FittedBox(
                                      alignment: Alignment.topCenter,
                                      fit: BoxFit.contain,
                                      child: RepaintBoundary(
                                        key: _repaintBoundaryKey,
                                        child: SyahadahTemplate(
                                          displayName: _namaController.text,
                                          nis: _selectedSantri!.nis,
                                          hafalan: _hafalanController.text,
                                          photoUrl: _selectedSantri!.photoUrl!,
                                          kelas: _selectedSantri!.kelas,
                                          date: DateTime.now(),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: AiwaButton(
                  text: 'Generate & Bagikan',
                  onPressed: _saveStatus == KelulusanSaveStatus.saving
                      ? null
                      : _generateAndShare,
                  isLoading: _isGenerating,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyPreview(String message) {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade300,
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, height: 1.5),
          ),
        ),
      ),
    );
  }
}

class _PendingKelulusanSave {
  final File file;
  final SantriEntity santri;
  final String displayName;
  final String hafalan;

  const _PendingKelulusanSave({
    required this.file,
    required this.santri,
    required this.displayName,
    required this.hafalan,
  });
}
