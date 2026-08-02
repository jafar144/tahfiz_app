import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:khoirunnasyien/core/utils/image_utils.dart';
import 'package:khoirunnasyien/core/utils/profile_photo_picker.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_app_bar.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_bottom_sheet.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_button.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_form_widgets.dart';
import 'package:khoirunnasyien/core/constants/app_constants.dart';
import 'package:khoirunnasyien/core/di/injection.dart';
import 'package:khoirunnasyien/core/utils/ui_utils.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_detail.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_params.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/cubit/santri_detail_cubit.dart';
import 'package:khoirunnasyien/features/management_schedule/domain/repositories/schedule_repository.dart';

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
  String? _selectedFiqihClass;
  String? _classType;
  late DateTime _entryDate;
  late bool _isFree;
  DateTime? _freeUntil;
  bool _isLoading = false;
  bool _isPickingPhoto = false;
  String? _photoUrl;
  File? _localPhotoFile;
  bool _photoRemoved = false;
  late bool _isActive;

  /// Ada foto yang sedang ditampilkan di preview (lokal baru atau url lama).
  bool get _hasPhoto =>
      _localPhotoFile != null || (_photoUrl != null && !_photoRemoved);

  @override
  void initState() {
    super.initState();
    // Initialize with existing data
    _nameController = TextEditingController(text: widget.santri.name);
    _nisController = TextEditingController(text: widget.santri.nis);
    _phoneController = TextEditingController(text: widget.santri.phone);
    _birthPlaceController = TextEditingController(
      text: widget.santri.tempatLahir,
    );
    _waliNameController = TextEditingController(text: widget.santri.namaWali);
    _waliPhoneController = TextEditingController(text: widget.santri.nomorWali);

    _gender = widget.santri.jenisKelamin;
    _birthDate = widget.santri.tanggalLahir;
    _selectedClass = widget.santri.kelas;
    _selectedFiqihClass = widget.santri.kelasFiqih;
    _classType = widget.santri.tipeKelas;
    _entryDate = widget.santri.tanggalMasuk ?? DateTime.now();
    _isFree = widget.santri.isFree;
    _freeUntil = widget.santri.freeUntil;
    _photoUrl = widget.santri.photoUrl;
    _isActive = widget.santri.isActive;
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

  Future<void> _selectDate(
    BuildContext context,
    bool isBirthDate, {
    bool isFreeUntil = false,
  }) async {
    await UiUtils.dismissKeyboard(context);

    if (!context.mounted) return;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFreeUntil
          ? (_freeUntil ?? DateTime.now())
          : (isBirthDate ? (_birthDate ?? DateTime(2010)) : _entryDate),
      firstDate: DateTime(1990),
      lastDate: isFreeUntil ? DateTime(2050) : DateTime.now(),
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
        if (isFreeUntil) {
          _freeUntil = picked;
        } else if (isBirthDate) {
          _birthDate = picked;
        } else {
          _entryDate = picked;
        }
      });
    }
  }

  void _showSelectionSheet(
    String title,
    List<String> items,
    Function(String) onSelected,
  ) async {
    await UiUtils.dismissKeyboard(context);

    if (!mounted) return;

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
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...items.map(
                    (item) => ListTile(
                      title: Text(item, textAlign: TextAlign.center),
                      onTap: () {
                        onSelected(item);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickImage() async {
    setState(() => _isPickingPhoto = true);

    try {
      final file = await ProfilePhotoPicker.shared.pickAndEdit(
        context,
        type: ProfilePhotoType.santri,
      );
      if (file == null || !mounted) return;

      final compressed = await ImageUtils.compressImage(file);
      if (!mounted) return;

      if (compressed != null) {
        setState(() {
          _localPhotoFile = compressed;
          _photoRemoved = false;
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto gagal diproses. Silakan coba lagi.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingPhoto = false);
      }
    }
  }

  void _removePhoto() {
    UiUtils.unfocus(context);
    setState(() {
      _localPhotoFile = null;
      _photoRemoved = true;
    });
  }

  /// Konfirmasi mengeluarkan santri dari halaqah saat status diubah ke
  /// Tidak Aktif. Mengembalikan true bila admin menyetujui.
  Future<bool?> _confirmLeaveHalaqah(String halaqahName) {
    return showAiwaActionSheet<bool>(
      context: context,
      title: 'Keluarkan dari Halaqah?',
      content: Text(
        'Santri ini masih terhubung dengan halaqah "$halaqahName". '
        'Karena status diubah menjadi Tidak Aktif, santri akan dikeluarkan '
        'dari halaqah tersebut. Lanjutkan?',
      ),
      confirmText: 'Keluarkan',
      confirmValue: true,
      cancelValue: false,
      confirmColor: Colors.red,
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_birthDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tanggal lahir harus diisi')),
        );
        return;
      }
      if (_selectedClass == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Kelas harus dipilih')));
        return;
      }
      if (_classType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tipe kelas harus dipilih')),
        );
        return;
      }

      // Bila status diubah ke Tidak Aktif & santri masih terhubung ke halaqah,
      // minta konfirmasi untuk mengeluarkannya terlebih dahulu.
      final scheduleRepo = getIt<ScheduleRepository>();
      bool leaveHalaqah = false;
      if (!_isActive) {
        final halaqahResult = await scheduleRepo.getHalaqahBySantriId(
          widget.santri.id,
        );
        if (!mounted) return;
        final halaqah = halaqahResult.fold(
          ifLeft: (_) => null,
          ifRight: (h) => h,
        );
        if (halaqah != null) {
          final confirmed = await _confirmLeaveHalaqah(halaqah.name);
          if (!mounted || confirmed != true) return;
          leaveHalaqah = true;
        }
      }

      setState(() => _isLoading = true);

      // Keluarkan santri dari halaqah lebih dulu (bila dikonfirmasi).
      if (leaveHalaqah) {
        final removeResult = await scheduleRepo.removeSantriFromHalaqah(
          widget.santri.id,
        );
        if (!mounted) return;
        final failure = removeResult.fold(
          ifLeft: (f) => f,
          ifRight: (_) => null,
        );
        if (failure != null) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Gagal mengeluarkan dari halaqah: ${failure.message}',
              ),
            ),
          );
          return;
        }
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
        kelasFiqih: _selectedFiqihClass,
        tipeKelas: _classType!,
        entryDate: _entryDate,
        isFree: _isFree,
        isActive: _isActive,
        freeUntil: _isFree
            ? (_freeUntil ?? DateTime(DateTime.now().year + 7))
            : null,
        localPhotoFile: _localPhotoFile,
        photoUrl: _photoUrl,
        removePhoto: _photoRemoved,
      );

      // Call Cubit to update
      // We assume this page is pushed on top of DetailPage which provides the Cubit
      // Or we can pass the Cubit context or use BlocProvider.value/listener
      context
          .read<SantriDetailCubit>()
          .updateSantri(widget.santri.id, params)
          .then((_) {
            if (mounted) {
              setState(() => _isLoading = false);
              Navigator.pop(context); // Go back to Detail
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Santri berhasil diperbarui')),
              );
            }
          })
          .catchError((e) {
            if (mounted) {
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
            }
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AiwaAppBar(title: 'Edit Santri'),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.shade200,
                            image: _localPhotoFile != null
                                ? DecorationImage(
                                    image: FileImage(_localPhotoFile!),
                                    fit: BoxFit.cover,
                                  )
                                : (_photoUrl != null && !_photoRemoved)
                                ? DecorationImage(
                                    image: NetworkImage(_photoUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: !_hasPhoto
                              ? const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                        if (_isPickingPhoto)
                          const Positioned.fill(
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _isPickingPhoto ? null : _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue,
                              ),
                              child: Icon(
                                _hasPhoto ? Icons.edit : Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        if (_hasPhoto)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _isPickingPhoto ? null : _removePhoto,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.red.shade400,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const AiwaFormSectionTitle(title: 'Informasi Pribadi'),
                  const SizedBox(height: 12),
                  AiwaTextField(
                    label: 'Nama Lengkap',
                    hint: 'Masukkan nama lengkap',
                    controller: _nameController,
                    icon: Icons.person_outline,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AiwaTextField(
                          label: 'NIS',
                          hint: 'Nomor Induk',
                          controller: _nisController,
                          icon: Icons.badge_outlined,
                          keyboardType: TextInputType.number,
                          enabled: false,
                        ),
                      ),
                      const SizedBox(width: 12),
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
                  const SizedBox(height: 12),
                  const Text(
                    'Jenis Kelamin',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
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
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AiwaTextField(
                          label: 'Tempat Lahir',
                          hint: 'Kota',
                          controller: _birthPlaceController,
                          icon: Icons.location_city,
                          textCapitalization: TextCapitalization.words,
                        ),
                      ),
                      const SizedBox(width: 12),
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
                  const SizedBox(height: 24),
                  const AiwaFormSectionTitle(title: 'Informasi Wali'),
                  const SizedBox(height: 12),
                  AiwaTextField(
                    label: 'Nama Wali (Opsional)',
                    hint: 'Masukkan nama wali',
                    controller: _waliNameController,
                    icon: Icons.family_restroom,
                    isOptional: true,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  AiwaTextField(
                    label: 'No. Telepon Wali (Opsional)',
                    hint: '0812...',
                    controller: _waliPhoneController,
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    isOptional: true,
                  ),
                  const SizedBox(height: 24),
                  const AiwaFormSectionTitle(title: 'Informasi Akademik'),
                  const SizedBox(height: 12),
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
                            (val) => setState(() {
                              _selectedClass = val;
                              if (!AppConstants.isFiqihEligible(val)) {
                                _selectedFiqihClass = null;
                              }
                            }),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AiwaClickableInput(
                          label: 'Tipe',
                          value: _classType ?? 'Pilih Tipe',
                          icon: Icons.access_time,
                          onTap: () => _showSelectionSheet(
                            'Pilih Tipe Kelas',
                            AppConstants.classTypes,
                            (val) => setState(() => _classType = val),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (AppConstants.isFiqihEligible(_selectedClass)) ...[
                    const SizedBox(height: 12),
                    AiwaClickableInput(
                      label: 'Kelas Fiqih (Opsional)',
                      value: _selectedFiqihClass ?? 'Belum ditentukan',
                      icon: Icons.menu_book_outlined,
                      onTap: () => _showSelectionSheet(
                        'Pilih Kelas Fiqih',
                        ['Belum ditentukan', ...AppConstants.fiqihClasses],
                        (val) => setState(() {
                          _selectedFiqihClass = val == 'Belum ditentukan'
                              ? null
                              : val;
                        }),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  AiwaClickableInput(
                    label: 'Tanggal Masuk',
                    value: DateFormat('dd MMMM yyyy').format(_entryDate),
                    icon: Icons.login,
                    onTap: () => _selectDate(context, false),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Status Akun',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
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
                  const SizedBox(height: 12),
                  const Text(
                    'Status Pembayaran',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: AiwaSelectionCard(
                          label: 'Reguler',
                          icon: Icons.attach_money,
                          isSelected: !_isFree,
                          onTap: () {
                            UiUtils.unfocus(context);
                            setState(() {
                              _isFree = false;
                              _freeUntil = null;
                            });
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
                            setState(() {
                              _isFree = true;
                              // Only set default if null
                              _freeUntil ??= DateTime(
                                DateTime.now().year + 7,
                                DateTime.now().month,
                                DateTime.now().day,
                              );
                            });
                          },
                          activeColor: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  if (_isFree) ...[
                    const SizedBox(height: 12),
                    AiwaClickableInput(
                      label: 'Gratis Sampai',
                      value: _freeUntil == null
                          ? 'Pilih Tanggal'
                          : DateFormat('dd MMMM yyyy').format(_freeUntil!),
                      icon: Icons.event,
                      onTap: () =>
                          _selectDate(context, false, isFreeUntil: true),
                    ),
                  ],
                  const SizedBox(height: 24),
                  AiwaButton(
                    text: 'Simpan Perubahan',
                    onPressed: _isPickingPhoto ? null : _submit,
                    isLoading: _isLoading || _isPickingPhoto,
                    height: 48,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
