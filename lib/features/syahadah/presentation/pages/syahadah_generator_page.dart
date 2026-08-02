import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:firebase_core/firebase_core.dart';
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

import 'package:khoirunnasyien/features/syahadah/presentation/utils/kelulusan_share_flow.dart';
import 'package:khoirunnasyien/features/syahadah/presentation/widgets/kelulusan_save_banner.dart';
import 'package:khoirunnasyien/features/syahadah/presentation/widgets/syahadah_template.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

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
  String? _saveErrorMessage;
  bool _requiresReplaceConfirmation = false;
  bool _canRetrySave = true;

  @override
  void dispose() {
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
                      'Tahfiz App sampai banner menyatakan proses selesai.',
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

  Future<bool?> _showReplaceConfirmSheet({
    required String santriName,
    required int existingCount,
  }) {
    final countText = existingCount > 1
        ? 'Ditemukan $existingCount foto kelulusan'
        : 'Foto kelulusan';
    return showAiwaActionSheet<bool>(
      context: context,
      title: 'Foto Kelulusan Sudah Ada',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.photo_library_rounded,
                color: Color(0xFFB45309),
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$countText untuk $santriName pada hari ini.',
                  style: const TextStyle(height: 1.45),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFFFEF2F2),
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFB91C1C),
                    size: 21,
                  ),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Jika tetap dilanjutkan, seluruh foto sebelumnya untuk '
                      'santri ini pada hari yang sama akan dihapus dan diganti '
                      'dengan satu foto baru.',
                      style: TextStyle(
                        color: Color(0xFF991B1B),
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
      confirmText: 'Ganti & Bagikan',
      confirmValue: true,
      cancelValue: false,
      confirmColor: const Color(0xFFB91C1C),
    );
  }

  Future<void> _savePendingKelulusan(_PendingKelulusanSave job) async {
    var currentJob = job;
    if (mounted) {
      setState(() {
        _pendingSave = currentJob;
        _saveStatus = KelulusanSaveStatus.saving;
        _saveErrorMessage = null;
        _requiresReplaceConfirmation = false;
        _canRetrySave = true;
      });
    }

    try {
      // Reservasi dibuat sedekat mungkin dengan upload. Server mengikatnya
      // ke hasil preflight yang sudah dikonfirmasi agar retry lama tidak dapat
      // menimpa foto yang lebih baru.
      await getIt<KelulusanRepository>().reserveUpload(
        santriId: currentJob.santri.id,
        dateKey: currentJob.dateKey,
        operationId: currentJob.operationId,
        expectedRevision: currentJob.expectedRevision,
        replaceExisting: currentJob.replaceExisting,
      );

      var uploadedUrl = currentJob.uploadedUrl;
      if (uploadedUrl == null) {
        try {
          uploadedUrl = await ImageUtils.uploadImageToFirebaseOrThrow(
            currentJob.file,
            'syahadah_photos/${currentJob.uploaderUid}',
            fileName: kelulusanUploadFileName(
              santriId: currentJob.santri.id,
              dateKey: currentJob.dateKey,
              operationId: currentJob.operationId,
            ),
            uploaderUid: currentJob.uploaderUid,
          ).timeout(const Duration(seconds: 30));
        } catch (error) {
          if (_looksLikeNetworkFailure(error)) {
            throw const KelulusanNetworkException();
          }
          rethrow;
        }

        currentJob = currentJob.copyWith(uploadedUrl: uploadedUrl);
        if (mounted) {
          setState(() => _pendingSave = currentJob);
        }
      }

      await getIt<KelulusanRepository>().saveKelulusan(
        santriId: currentJob.santri.id,
        santriName: currentJob.displayName,
        kelas: currentJob.santri.kelas,
        hafalan: currentJob.hafalan,
        imageUrl: uploadedUrl,
        dateKey: currentJob.dateKey,
        operationId: currentJob.operationId,
        replaceExisting: currentJob.replaceExisting,
      );
      if (mounted) {
        setState(() {
          _pendingSave = currentJob;
          _saveStatus = KelulusanSaveStatus.success;
          _saveErrorMessage = null;
        });
      }
      return;
    } on KelulusanAlreadyExistsException {
      if (mounted) {
        setState(() {
          // State server berubah sejak konfirmasi. URL lama dibuang dan retry
          // berikutnya memakai preflight serta UUID baru.
          _pendingSave = currentJob.copyWith(clearUploadedUrl: true);
          _saveStatus = KelulusanSaveStatus.failure;
          _saveErrorMessage =
              'Foto kelulusan santri ini sudah ada hari ini. '
              'Ketuk Coba Lagi untuk mengonfirmasi penggantian.';
          _requiresReplaceConfirmation = true;
          _canRetrySave = true;
        });
      }
      return;
    } on KelulusanNetworkException catch (error) {
      _showSaveFailure(error.message);
      return;
    } on KelulusanRemoteException catch (error) {
      _showSaveFailure(
        error.message,
        canRetry: !const {
          'failed-precondition',
          'invalid-argument',
          'not-found',
          'permission-denied',
          'unauthenticated',
        }.contains(error.code),
      );
      return;
    } catch (error) {
      if (_looksLikeNetworkFailure(error)) {
        _showSaveFailure(kelulusanNetworkErrorMessage);
      } else {
        _showSaveFailure(
          'Foto kelulusan belum berhasil disimpan. Silakan coba lagi.',
        );
      }
      return;
    }
  }

  void _showSaveFailure(String message, {bool canRetry = true}) {
    if (!mounted) return;
    setState(() {
      _saveStatus = KelulusanSaveStatus.failure;
      _saveErrorMessage = message;
      _canRetrySave = canRetry;
    });
  }

  Future<void> _retryPendingSave() async {
    var job = _pendingSave;
    if (job == null ||
        _saveStatus == KelulusanSaveStatus.saving ||
        _isGenerating) {
      return;
    }

    setState(() => _isGenerating = true);
    try {
      if (_requiresReplaceConfirmation) {
        final replacementOperationId = const Uuid().v4();
        final status = await getIt<KelulusanRepository>().checkToday(
          santriId: job.santri.id,
        );
        if (!mounted) return;
        if (status.dateKey != job.dateKey) {
          const message =
              'Tanggal sudah berubah. Silakan generate ulang foto kelulusan.';
          _showSaveFailure(message, canRetry: false);
          _showSnackBar(message);
          return;
        }
        if (status.exists) {
          final confirmed = await _showReplaceConfirmSheet(
            santriName: job.displayName,
            existingCount: status.existingCount,
          );
          if (confirmed != true) return;
        }
        // Jangan gunakan ulang path yang pernah masuk antrean cleanup akibat
        // conflict. UUID baru memastikan worker tidak dapat menghapus foto
        // pengganti yang sudah aktif.
        job = job.copyWith(
          dateKey: status.dateKey,
          operationId: replacementOperationId,
          expectedRevision: status.revision,
          replaceExisting: status.exists,
          clearUploadedUrl: true,
        );
        setState(() {
          _pendingSave = job;
          _requiresReplaceConfirmation = false;
        });
      }

      unawaited(_savePendingKelulusan(job));
    } on KelulusanNetworkException catch (error) {
      _showSaveFailure(error.message);
      _showSnackBar(error.message);
    } catch (error) {
      final message = _looksLikeNetworkFailure(error)
          ? kelulusanNetworkErrorMessage
          : 'Belum dapat mencoba kembali. Silakan ulangi beberapa saat lagi.';
      _showSaveFailure(message);
      _showSnackBar(message);
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _dismissSaveStatus() {
    if (_saveStatus == KelulusanSaveStatus.saving) return;
    setState(() => _saveStatus = null);
  }

  Future<void> _generateAndShare() async {
    if (_isGenerating || _saveStatus == KelulusanSaveStatus.saving) return;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSantri == null) {
      _showSnackBar('Pilih santri terlebih dahulu');
      return;
    }
    if (_selectedSantri!.photoUrl == null ||
        _selectedSantri!.photoUrl!.isEmpty) {
      _showSnackBar(
        'Santri ini belum memiliki foto profil, silahkan edit profil santri '
        'terlebih dahulu.',
      );
      return;
    }

    final selectedSantri = _selectedSantri!;
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      _showSnackBar('Sesi login berakhir. Silakan login kembali.');
      return;
    }
    UiUtils.unfocus(context);
    final displayName = _namaController.text;
    final hafalan = _hafalanController.text;
    final operationId = const Uuid().v4();

    setState(() => _isGenerating = true);

    try {
      // Callable ini sekaligus menjadi pemeriksaan koneksi. Proses berhenti
      // sebelum render/upload/share ketika server tidak dapat dijangkau.
      final dailyStatus = await getIt<KelulusanRepository>().checkToday(
        santriId: selectedSantri.id,
      );
      if (!mounted) return;

      final confirmed = dailyStatus.exists
          ? await _showReplaceConfirmSheet(
              santriName: displayName,
              existingCount: dailyStatus.existingCount,
            )
          : await _showConfirmSheet();
      if (confirmed != true) return;

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

      final job = _PendingKelulusanSave(
        file: file,
        santri: selectedSantri,
        displayName: displayName,
        hafalan: hafalan,
        dateKey: dailyStatus.dateKey,
        operationId: operationId,
        expectedRevision: dailyStatus.revision,
        uploaderUid: authState.user.uid,
        replaceExisting: dailyStatus.exists,
      );
      await shareKelulusanWhileSaving(
        save: () => _savePendingKelulusan(job),
        share: () => _shareFile(file),
      );
    } on KelulusanNetworkException catch (error) {
      _showSnackBar(error.message);
    } on KelulusanRemoteException catch (error) {
      _showSnackBar(error.message);
    } catch (e) {
      final message = _looksLikeNetworkFailure(e)
          ? kelulusanNetworkErrorMessage
          : 'Gagal membuat syahadah: $e';
      _showSnackBar(message);
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _shareFile(File file) async {
    if (!mounted) return;
    try {
      await WidgetsBinding.instance.endOfFrame;
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    } catch (_) {
      _showSnackBar(
        'Menu bagikan belum dapat dibuka. Status penyimpanan foto tetap dapat '
        'dilihat pada banner.',
      );
    }
  }

  bool _looksLikeNetworkFailure(Object error) {
    if (error is KelulusanNetworkException ||
        error is TimeoutException ||
        error is SocketException) {
      return true;
    }
    if (error is FirebaseException) {
      return const {
        'cancelled',
        'deadline-exceeded',
        'network-request-failed',
        'retry-limit-exceeded',
        'unavailable',
      }.contains(error.code);
    }
    final text = error.toString().toLowerCase();
    return text.contains('network') ||
        text.contains('socket') ||
        text.contains('host lookup');
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.select<AuthCubit, bool>((cubit) {
      final state = cubit.state;
      return state is AuthAuthenticated && state.user.role == UserRole.admin;
    });
    final isBusy = _isGenerating || _saveStatus == KelulusanSaveStatus.saving;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AiwaAppBar(
        title: 'Kelulusan Santri',
        actions: [
          if (isAdmin)
            IconButton(
              tooltip: 'Kelola foto kelulusan',
              onPressed: isBusy
                  ? null
                  : () => context.pushNamed(RouteNames.adminSyahadahPhotos),
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
                        failureMessage: _saveErrorMessage,
                        onRetry:
                            _saveStatus == KelulusanSaveStatus.failure &&
                                _canRetrySave
                            ? _retryPendingSave
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
                          onTap: isBusy ? null : _selectSantri,
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
                          enabled: _selectedSantri != null && !isBusy,
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
                          enabled: !isBusy,
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
                  onPressed:
                      _isGenerating || _saveStatus == KelulusanSaveStatus.saving
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
  final String dateKey;
  final String operationId;
  final String expectedRevision;
  final String uploaderUid;
  final bool replaceExisting;
  final String? uploadedUrl;

  const _PendingKelulusanSave({
    required this.file,
    required this.santri,
    required this.displayName,
    required this.hafalan,
    required this.dateKey,
    required this.operationId,
    required this.expectedRevision,
    required this.uploaderUid,
    required this.replaceExisting,
    this.uploadedUrl,
  });

  _PendingKelulusanSave copyWith({
    String? dateKey,
    String? operationId,
    String? expectedRevision,
    bool? replaceExisting,
    String? uploadedUrl,
    bool clearUploadedUrl = false,
  }) {
    return _PendingKelulusanSave(
      file: file,
      santri: santri,
      displayName: displayName,
      hafalan: hafalan,
      dateKey: dateKey ?? this.dateKey,
      operationId: operationId ?? this.operationId,
      expectedRevision: expectedRevision ?? this.expectedRevision,
      uploaderUid: uploaderUid,
      replaceExisting: replaceExisting ?? this.replaceExisting,
      uploadedUrl: clearUploadedUrl ? null : uploadedUrl ?? this.uploadedUrl,
    );
  }
}
