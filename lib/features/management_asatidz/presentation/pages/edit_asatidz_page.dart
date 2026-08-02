import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khoirunnasyien/core/utils/image_utils.dart';
import 'package:khoirunnasyien/core/utils/profile_photo_picker.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_app_bar.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_button.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_form_widgets.dart';
import 'package:khoirunnasyien/core/utils/ui_utils.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_detail.dart';
import 'package:khoirunnasyien/features/management_asatidz/domain/entities/asatidz_params.dart';
import 'package:khoirunnasyien/features/management_asatidz/presentation/cubit/asatidz_detail_cubit.dart';

class EditAsatidzPage extends StatefulWidget {
  final AsatidzDetail asatidz;

  const EditAsatidzPage({super.key, required this.asatidz});

  @override
  State<EditAsatidzPage> createState() => _EditAsatidzPageState();
}

class _EditAsatidzPageState extends State<EditAsatidzPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _nisController;
  late TextEditingController _phoneController;

  late String _gender;
  late bool _isActive;
  bool _isLoading = false;
  bool _isPickingPhoto = false;
  String? _photoUrl;
  File? _localPhotoFile;
  bool _photoRemoved = false;

  bool get _hasPhoto =>
      _localPhotoFile != null ||
      (_photoUrl != null && _photoUrl!.isNotEmpty && !_photoRemoved);

  ImageProvider? get _photoProvider {
    if (_localPhotoFile != null) return FileImage(_localPhotoFile!);
    if (_hasPhoto) return NetworkImage(_photoUrl!);
    return null;
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.asatidz.name);
    _nisController = TextEditingController(text: widget.asatidz.nis);
    _phoneController = TextEditingController(text: widget.asatidz.phone);
    _gender = widget.asatidz.jenisKelamin;
    _isActive = widget.asatidz.isActive;
    _photoUrl = widget.asatidz.photoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nisController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final params = AsatidzParams(
        name: _nameController.text,
        nis: _nisController.text,
        phone: _phoneController.text,
        jenisKelamin: _gender,
        isActive: _isActive,
        photoUrl: _photoUrl,
        localPhotoFile: _localPhotoFile,
        removePhoto: _photoRemoved,
      );

      final success = await context.read<AsatidzDetailCubit>().updateAsatidz(
        widget.asatidz.id,
        params,
      );
      if (!mounted) return;

      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Asatidz berhasil diperbarui')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil asatidz gagal diperbarui')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    setState(() => _isPickingPhoto = true);

    try {
      final editedFile = await ProfilePhotoPicker.shared.pickAndEdit(
        context,
        type: ProfilePhotoType.asatidz,
      );
      if (editedFile == null || !mounted) return;

      final compressed = await ImageUtils.compressImage(editedFile);
      if (!mounted) return;
      if (compressed != null) {
        setState(() {
          _localPhotoFile = compressed;
          _photoRemoved = false;
        });
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

  void _removePhoto() {
    setState(() {
      _localPhotoFile = null;
      _photoRemoved = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AiwaAppBar(title: 'Edit Asatidz'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: _photoProvider,
                          child: !_hasPhoto
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
                    if (_hasPhoto) ...[
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: _isPickingPhoto ? null : _removePhoto,
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                        ),
                        label: const Text('Hapus foto'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 10),
                      Text(
                        'Foto profil (opsional)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
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
                enabled: false,
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
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
              const SizedBox(height: 16),
              const Text(
                'Status Akun',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: AiwaSelectionCard(
                      label: 'Aktif',
                      icon: Icons.check_circle_outline,
                      isSelected: _isActive,
                      onTap: () {
                        UiUtils.unfocus(context);
                        setState(() => _isActive = true);
                      },
                      activeColor: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AiwaSelectionCard(
                      label: 'Tidak Aktif',
                      icon: Icons.cancel_outlined,
                      isSelected: !_isActive,
                      onTap: () {
                        UiUtils.unfocus(context);
                        setState(() => _isActive = false);
                      },
                      activeColor: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              AiwaButton(
                text: 'Simpan Perubahan',
                onPressed: _isPickingPhoto ? null : _submit,
                isLoading: _isLoading,
                height: 52,
              ),
              const SizedBox(height: 32),
            ],
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
