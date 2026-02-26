import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:khoirunnasyien/core/router/route_names.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_app_bar.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_button.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_form_widgets.dart';
import 'package:khoirunnasyien/core/utils/ui_utils.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/pages/select_santri_page.dart';
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
  final GlobalKey _repaintBoundaryKey = GlobalKey();

  SantriEntity? _selectedSantri;
  bool _isGenerating = false;

  @override
  void dispose() {
    _hafalanController.dispose();
    super.dispose();
  }

  void _selectSantri() async {
    final result = await context.pushNamed(RouteNames.selectSantri);

    if (result != null) {
      setState(() {
        _selectedSantri = result as SantriEntity;
      });
    }
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

    setState(() => _isGenerating = true);

    try {
      // 1. Give it a tiny delay to ensure the UI has updated (if it was hidden)
      await Future.delayed(const Duration(milliseconds: 300));

      // 2. Capture the widget as an image
      RenderRepaintBoundary boundary =
          _repaintBoundaryKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(
        pixelRatio: 2.0,
      ); // Higher pixel ratio for better quality
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // 3. Save to temp file
      final directory = await getTemporaryDirectory();
      final imagePath =
          '${directory.path}/syahadah_${_selectedSantri!.name.replaceAll(' ', '_')}.png';
      final file = File(imagePath);
      await file.writeAsBytes(pngBytes);

      // 4. Share using share_plus
      final xfile = XFile(imagePath);
      await Share.shareXFiles(
        [xfile],
        text:
            'Syahadah Kelulusan ${_selectedSantri!.name} - ${_hafalanController.text}',
      );
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AiwaAppBar(title: 'Kelulusan Santri'),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => UiUtils.unfocus(context),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
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
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedSantri?.name ??
                                            'Ketuk untuk memilih santri',
                                        style: TextStyle(
                                          fontSize: 16,
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
                                          'NIS: ${_selectedSantri!.nis}',
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
                        const SizedBox(height: 24),

                        AiwaTextField(
                          label: 'Nama Surah & Juz',
                          hint: 'Contoh: Q.s Al Muthofifin Juz 30',
                          controller: _hafalanController,
                          icon: Icons.menu_book,
                          textCapitalization: TextCapitalization.words,
                          onChanged: (val) {
                            setState(() {}); // trigger rebuild to show preview
                          },
                        ),
                        const SizedBox(height: 32),

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
                        else if (_hafalanController.text.isEmpty)
                          _buildEmptyPreview(
                            'Silakan isi "Nama Surah & Juz"\ndi atas untuk melihat preview.',
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
                                          santriName: _selectedSantri!.name,
                                          hafalan: _hafalanController.text,
                                          photoUrl: _selectedSantri!.photoUrl!,
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

              // Bottom Button
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: AiwaButton(
                  text: 'Generate & Bagikan',
                  onPressed: _generateAndShare,
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
