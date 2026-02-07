import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_button.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_form_widgets.dart';
import 'package:khoirunnasyien/core/constants/app_constants.dart';
import 'package:khoirunnasyien/core/utils/ui_utils.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_detail.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_params.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/cubit/santri_detail_cubit.dart';

class EditSantriPage extends StatefulWidget {
  final SantriDetail santri;

  const EditSantriPage({super.key, required this.santri});

  @override
  State<EditSantriPage> createState() => _EditSantriPageState();
}

class _EditSantriPageState extends State<EditSantriPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _nisController;
  late TextEditingController _phoneController;
  late TextEditingController _birthPlaceController;
  late TextEditingController _waliNameController;
  late TextEditingController _waliPhoneController;

  late String _gender;
  DateTime? _birthDate;
  String? _selectedClass;
  String? _classType;
  late DateTime _entryDate;
  late bool _isFree;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize with existing data
    _nameController = TextEditingController(text: widget.santri.name);
    _nisController = TextEditingController(text: widget.santri.nis);
    _phoneController = TextEditingController(text: widget.santri.phone);
    _birthPlaceController =
        TextEditingController(text: widget.santri.tempatLahir);
    _waliNameController = TextEditingController(text: widget.santri.namaWali);
    _waliPhoneController = TextEditingController(text: widget.santri.nomorWali);

    _gender = widget.santri.jenisKelamin;
    _birthDate = widget.santri.tanggalLahir;
    _selectedClass = widget.santri.kelas;
    _classType = widget.santri.tipeKelas;
    _entryDate = widget.santri.tanggalMasuk ?? DateTime.now();
    _isFree = widget.santri.isFree;
  }

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

  Future<void> _selectDate(BuildContext context, bool isBirthDate) async {
    UiUtils.unfocus(context);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isBirthDate
          ? (_birthDate ?? DateTime(2010))
          : _entryDate,
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isBirthDate) {
          _birthDate = picked;
        } else {
          _entryDate = picked;
        }
      });
    }
  }

  void _showSelectionSheet(
      String title, List<String> items, Function(String) onSelected) {
    UiUtils.unfocus(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: ListView(
                controller: scrollController,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ...items.map((item) => ListTile(
                        title: Text(item, textAlign: TextAlign.center),
                        onTap: () {
                          onSelected(item);
                          Navigator.pop(context);
                        },
                      )),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
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

      setState(() => _isLoading = true);

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

      // Call Cubit to update
      // We assume this page is pushed on top of DetailPage which provides the Cubit
      // Or we can pass the Cubit context or use BlocProvider.value/listener
      context.read<SantriDetailCubit>().updateSantri(widget.santri.id, params).then((_) {
         if (mounted) {
           setState(() => _isLoading = false);
           Navigator.pop(context); // Go back to Detail
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Santri berhasil diperbarui')),
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
        title: const Text('Edit Santri'),
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
              Row(
                children: [
                  Expanded(
                    child: AiwaTextField(
                      label: 'Tempat Lahir',
                      hint: 'Kota',
                      controller: _birthPlaceController,
                      icon: Icons.location_city,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AiwaClickableInput(
                      label: 'Tanggal Lahir',
                      value: _birthDate == null
                          ? 'Pilih Tanggal'
                          : DateFormat('dd/MM/yyyy').format(_birthDate!),
                      icon: Icons.calendar_today,
                      onTap: () => _selectDate(context, true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildSectionTitle('Informasi Wali'),
              const SizedBox(height: 20),
              AiwaTextField(
                label: 'Nama Wali (Opsional)',
                hint: 'Masukkan nama wali',
                controller: _waliNameController,
                icon: Icons.family_restroom,
                isOptional: true,
              ),
              const SizedBox(height: 16),
              AiwaTextField(
                label: 'No. Telepon Wali (Opsional)',
                hint: '0812...',
                controller: _waliPhoneController,
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                isOptional: true,
              ),
              const SizedBox(height: 32),
              _buildSectionTitle('Informasi Akademik'),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: AiwaClickableInput(
                      label: 'Kelas',
                      value: _selectedClass ?? 'Pilih Kelas',
                      icon: Icons.class_outlined,
                      onTap: () => _showSelectionSheet(
                          'Pilih Kelas',
                          AppConstants.santriClasses,
                          (val) => setState(() => _selectedClass = val)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AiwaClickableInput(
                      label: 'Tipe',
                      value: _classType ?? 'Pilih Tipe',
                      icon: Icons.access_time,
                      onTap: () => _showSelectionSheet(
                          'Pilih Tipe Kelas',
                          AppConstants.classTypes,
                          (val) => setState(() => _classType = val)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AiwaClickableInput(
                label: 'Tanggal Masuk',
                value: DateFormat('dd MMMM yyyy').format(_entryDate),
                icon: Icons.login,
                onTap: () => _selectDate(context, false),
              ),
              const SizedBox(height: 16),
              const Text(
                'Status Biaya',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: AiwaSelectionCard(
                      label: 'Reguler',
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
                      label: 'Gratis',
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
