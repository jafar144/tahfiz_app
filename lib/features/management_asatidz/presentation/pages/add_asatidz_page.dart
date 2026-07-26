import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:khoirunnasyien/core/utils/image_utils.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_app_bar.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_button.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_form_widgets.dart';
import 'package:khoirunnasyien/core/utils/ui_utils.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_params.dart';
import 'package:khoirunnasyien/features/management_asatidz/presentation/cubit/asatidz_cubit.dart';
import 'package:khoirunnasyien/features/management_asatidz/presentation/cubit/asatidz_state.dart';

class AddAsatidzPage extends StatefulWidget {
  const AddAsatidzPage({super.key});

  @override
  State<AddAsatidzPage> createState() => _AddAsatidzPageState();
}

class _AddAsatidzPageState extends State<AddAsatidzPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _nisController = TextEditingController();
  final _phoneController = TextEditingController();

  String _gender = 'L'; // L / P
  bool _isLoading = false;
  bool _isPickingPhoto = false;
  File? _localPhotoFile;

  @override
  void dispose() {
    _nameController.dispose();
    _nisController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final params = AsatidzParams(
        name: _nameController.text,
        nis: _nisController.text,
        phone: _phoneController.text,
        jenisKelamin: _gender,
        isActive: true, // Default active
        localPhotoFile: _localPhotoFile,
      );

      context.read<AsatidzCubit>().addAsatidz(params);
    }
  }

  Future<void> _showTemporaryPassword(AsatidzCreated state) async {
    setState(() => _isLoading = false);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Akun asatidz berhasil dibuat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Simpan dan kirimkan kredensial berikut secara aman. '
              'Password hanya ditampilkan sekali.',
            ),
            const SizedBox(height: 16),
            SelectableText('NIS: ${state.nis}'),
            const SizedBox(height: 8),
            SelectableText('Password sementara: ${state.temporaryPassword}'),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(
                  text:
                      'NIS: ${state.nis}\n'
                      'Password sementara: ${state.temporaryPassword}',
                ),
              );
              if (dialogContext.mounted) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Kredensial disalin')),
                );
              }
            },
            icon: const Icon(Icons.copy_outlined),
            label: const Text('Salin'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Sudah disimpan'),
          ),
        ],
      ),
    );
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _pickImage() async {
    final file = await ImageUtils.pickImage(ImageSource.gallery);
    if (file == null) return;

    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: file.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 95,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Atur Foto Asatidz',
            toolbarColor: const Color(0xFF004AAD),
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: const Color(0xFF004AAD),
            lockAspectRatio: true,
            showCropGrid: true,
          ),
          IOSUiSettings(
            title: 'Atur Foto Asatidz',
            doneButtonTitle: 'Simpan',
            cancelButtonTitle: 'Batal',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            aspectRatioPickerButtonHidden: true,
          ),
        ],
      );
      if (croppedFile == null || !mounted) return;

      setState(() => _isPickingPhoto = true);
      final compressed = await ImageUtils.compressImage(File(croppedFile.path));
      if (!mounted) return;
      if (compressed != null) {
        setState(() => _localPhotoFile = compressed);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto gagal diproses. Silakan coba lagi.'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memilih foto: $error')));
      }
    } finally {
      if (mounted) setState(() => _isPickingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AsatidzCubit, AsatidzState>(
      listener: (context, state) {
        if (state is AsatidzLoading) {
          setState(() => _isLoading = true);
        } else if (state is AsatidzCreated) {
          _showTemporaryPassword(state);
        } else if (state is AsatidzError) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal: ${state.message}')));
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: const AiwaAppBar(title: 'Tambah Asatidz'),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: _localPhotoFile == null
                              ? null
                              : FileImage(_localPhotoFile!),
                          child: _localPhotoFile == null
                              ? Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.grey.shade500,
                                )
                              : null,
                        ),
                        if (_isPickingPhoto)
                          const Positioned.fill(
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Material(
                            color: Colors.blue,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _isPickingPhoto ? null : _pickImage,
                              child: const Padding(
                                padding: EdgeInsets.all(9),
                                child: Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      'Foto profil (opsional)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildSectionTitle('Informasi Pribadi'),
                  const SizedBox(height: 20),
                  AiwaTextField(
                    label: 'Nama Lengkap',
                    hint: 'Masukkan nama lengkap',
                    controller: _nameController,
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 16),
                  AiwaTextField(
                    label: 'NIS',
                    hint: 'Nomor Induk',
                    controller: _nisController,
                    icon: Icons.badge_outlined,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  AiwaTextField(
                    label: 'No. Telepon',
                    hint: '0812...',
                    controller: _phoneController,
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Jenis Kelamin',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: AiwaSelectionCard(
                          label: 'Laki-laki',
                          icon: Icons.male,
                          isSelected: _gender == 'L',
                          onTap: () {
                            UiUtils.unfocus(context);
                            setState(() => _gender = 'L');
                          },
                          activeColor: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AiwaSelectionCard(
                          label: 'Perempuan',
                          icon: Icons.female,
                          isSelected: _gender == 'P',
                          onTap: () {
                            UiUtils.unfocus(context);
                            setState(() => _gender = 'P');
                          },
                          activeColor: Colors.pink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  AiwaButton(
                    text: 'Tambah Asatidz',
                    onPressed: _isPickingPhoto ? null : _submit,
                    isLoading: _isLoading,
                    height: 52,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Container(
          height: 4,
          width: 40,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}
