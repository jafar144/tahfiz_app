import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      );

      context.read<AsatidzCubit>().addAsatidz(params);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AsatidzCubit, AsatidzState>(
      listener: (context, state) {
        if (state is AsatidzLoading) {
          setState(() => _isLoading = true);
        } else if (state is AsatidzLoaded) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Asatidz berhasil ditambahkan')),
          );
          Navigator.pop(context);
        } else if (state is AsatidzError) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal: ${state.message}')),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Tambah Asatidz',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
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
                    onPressed: _submit,
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
