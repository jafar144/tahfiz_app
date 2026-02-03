import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_button.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_form_widgets.dart';
import 'package:khoirunnasyien/core/constants/app_constants.dart';
import 'package:khoirunnasyien/core/utils/ui_utils.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_params.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/cubit/santri_cubit.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/cubit/santri_state.dart';

class AddSantriPage extends StatefulWidget {
  const AddSantriPage({super.key});

  @override
  State<AddSantriPage> createState() => _AddSantriPageState();
}

class _AddSantriPageState extends State<AddSantriPage> {
  // Config
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _nisController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthPlaceController = TextEditingController();
  final _waliNameController = TextEditingController();
  final _waliPhoneController = TextEditingController();

  // State Variables
  String _gender = 'L'; // L / P
  DateTime? _birthDate;
  DateTime _entryDate = DateTime.now();
  String? _selectedClass; // Example: 'Kelas A'
  String? _classType; // Pagi, Sore, Malam
  bool _isFree = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _nisController.dispose();
    _phoneController.dispose();
    _birthPlaceController.dispose();
    _waliNameController.dispose();
    _waliPhoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // Validate non-form fields
      if (_birthDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tanggal lahir harus diisi')),
        );
        return;
      }
      if (_selectedClass == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kelas harus dipilih')),
        );
        return;
      }
      if (_classType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tipe kelas harus dipilih')),
        );
        return;
      }

      final params = SantriParams(
        name: _nameController.text,
        nis: _nisController.text,
        phone: _phoneController.text,
        jenisKelamin: _gender,
        birthPlace: _birthPlaceController.text,
        birthDate: _birthDate!,
        waliName: _waliNameController.text,
        waliPhone: _waliPhoneController.text,
        kelas: _selectedClass!,
        tipeKelas: _classType!,
        entryDate: _entryDate,
        isFree: _isFree,
      );

      context.read<SantriCubit>().addSantri(params);
    }
  }

  Future<void> _pickDate({
    required BuildContext context,
    required DateTime initialDate,
    required Function(DateTime) onPicked,
  }) async {
    UiUtils.unfocus(context);
    await Future.delayed(Duration.zero);
    
    if (!context.mounted) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1990),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        onPicked(picked);
      });
    }
  }

  void _showClassBottomSheet() async {
    UiUtils.unfocus(context);
    await Future.delayed(Duration.zero);
    
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               const Text(
                'Pilih Kelas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...AppConstants.santriClasses.map((cls) => ListTile(
                    title: Text(cls, textAlign: TextAlign.center),
                    onTap: () {
                      setState(() {
                        _selectedClass = cls;
                      });
                      Navigator.pop(context);
                    },
                    trailing: _selectedClass == cls
                        ? const Icon(Icons.check, color: Colors.blue)
                        : null,
                  )),
            ],
          ),
        );
      },
    );
  }

  void _showClassTypeBottomSheet() async {
    UiUtils.unfocus(context);
    await Future.delayed(Duration.zero);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pilih Tipe Kelas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...AppConstants.classTypes.map((type) => ListTile(
                    title: Text(type, textAlign: TextAlign.center),
                    onTap: () {
                      setState(() {
                        _classType = type;
                      });
                      Navigator.pop(context);
                    },
                    trailing: _classType == type
                        ? const Icon(Icons.check, color: Colors.blue)
                        : null,
                  )),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SantriCubit, SantriState>(
      listener: (context, state) {
        if (state is SantriLoading) {
          setState(() => _isLoading = true);
        } else if (state is SantriLoaded) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Santri berhasil ditambahkan')),
          );
          Navigator.pop(context);
        } else if (state is SantriError) {
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
            'Tambah Santri',
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
                  Row(
                    children: [
                      Expanded(
                        child: AiwaTextField(
                          label: 'NIS',
                          hint: 'Nomor Induk',
                          controller: _nisController,
                          icon: Icons.badge_outlined,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AiwaTextField(
                          label: 'No. Telepon (Opsional)',
                          hint: '0812...',
                          controller: _phoneController,
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          isOptional: true,
                        ),
                      ),
                    ],
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
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: AiwaTextField(
                          label: 'Tempat Lahir',
                          hint: 'Kota',
                          controller: _birthPlaceController,
                          icon: Icons.location_city_outlined,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AiwaClickableInput(
                          label: 'Tanggal Lahir',
                          value: _birthDate == null
                              ? 'Pilih Tanggal'
                              : DateFormat('dd MMM yyyy').format(_birthDate!),
                          icon: Icons.calendar_today_outlined,
                          onTap: () => _pickDate(
                            context: context,
                            initialDate: _birthDate ?? DateTime(2010),
                            onPicked: (d) => _birthDate = d,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Informasi Wali'),
                  const SizedBox(height: 20),
                  AiwaTextField(
                    label: 'Nama Wali',
                    hint: 'Masukkan nama wali',
                    controller: _waliNameController,
                    icon: Icons.family_restroom,
                  ),
                  const SizedBox(height: 16),
                  AiwaTextField(
                    label: 'No. Telepon Wali',
                    hint: '0812...',
                    controller: _waliPhoneController,
                    icon: Icons.phone_in_talk_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Informasi Kelas'),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: AiwaClickableInput(
                          label: 'Kelas',
                          value: _selectedClass ?? 'Pilih Kelas',
                          icon: Icons.class_outlined,
                          onTap: _showClassBottomSheet,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AiwaClickableInput(
                          label: 'Tipe',
                          value: _classType ?? 'Pilih Tipe',
                          icon: Icons.access_time,
                          onTap: _showClassTypeBottomSheet,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AiwaClickableInput(
                    label: 'Tanggal Masuk',
                    value: DateFormat('dd MMMM yyyy').format(_entryDate),
                    icon: Icons.login,
                    onTap: () => _pickDate(
                      context: context,
                      initialDate: _entryDate,
                      onPicked: (d) => _entryDate = d,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Status Pembayaran',
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
                          label: 'Reguler (Berbayar)',
                          icon: Icons.attach_money,
                          isSelected: !_isFree,
                          onTap: () {
                            UiUtils.unfocus(context);
                            setState(() => _isFree = false);
                          },
                          activeColor: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AiwaSelectionCard(
                          label: 'Beasiswa (Gratis)',
                          icon: Icons.volunteer_activism,
                          isSelected: _isFree,
                          onTap: () {
                            UiUtils.unfocus(context);
                            setState(() => _isFree = true);
                          },
                          activeColor: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  AiwaButton(
                    text: 'Tambah Santri',
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

