import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.asatidz.name);
    _nisController = TextEditingController(text: widget.asatidz.nis);
    _phoneController = TextEditingController(text: widget.asatidz.phone);
    _gender = widget.asatidz.jenisKelamin;
    _isActive = widget.asatidz.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nisController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final params = AsatidzParams(
        name: _nameController.text,
        nis: _nisController.text,
        phone: _phoneController.text,
        jenisKelamin: _gender,
        isActive: _isActive,
      );

      context.read<AsatidzDetailCubit>().updateAsatidz(widget.asatidz.id, params).then((_) {
         if (mounted) {
           setState(() => _isLoading = false);
           Navigator.pop(context);
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Asatidz berhasil diperbarui')),
           );
         }
      }).catchError((e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal: $e')),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Asatidz'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                onPressed: _submit,
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
