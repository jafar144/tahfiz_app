import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:khoirunnasyien/core/utils/image_utils.dart';
import 'package:khoirunnasyien/core/widgets/aiwa_app_bar.dart';
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
  DateTime? _freeUntil;
  bool _isFree = false;
  bool _isLoading = false;
  bool _isUploadingPhoto = false;
  String? _photoUrl;

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
        freeUntil: _isFree ? (_freeUntil ?? DateTime(DateTime.now().year + 7)) : null,
        photoUrl: _photoUrl,
      );

      context.read<SantriCubit>().addSantri(params);
    }
  }

  Future<void> _pickDate({
    required BuildContext context,
    required DateTime initialDate,
    required Function(DateTime) onPicked,
  }) async {
    await UiUtils.dismissKeyboard(context);
    
    if (!context.mounted) return;

    final safeInitialDate = initialDate.year < 2000 
        ? DateTime(2000, 1, 1) 
        : (initialDate.year > 2050 ? DateTime(2050, 12, 31) : initialDate);

    final picked = await showDatePicker(
      context: context,
      initialDate: safeInitialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        onPicked(picked);
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    final file = await ImageUtils.pickImage(ImageSource.gallery);
    if (file == null) return;

    setState(() => _isUploadingPhoto = true);

    try {
      final compressed = await ImageUtils.compressImage(file);
      if (compressed != null) {
        final url = await ImageUtils.uploadImageToFirebase(compressed, 'santri_photos');
        if (url != null) {
          setState(() => _photoUrl = url);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mengupload foto')));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  void _showClassBottomSheet() async {
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
                   const Padding(
                     padding: EdgeInsets.only(bottom: 16),
                     child: Text(
                      'Pilih Kelas',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                     ),
                   ),
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
      },
    );
  }

  void _showClassTypeBottomSheet() async {
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
           initialChildSize: 0.4,
           minChildSize: 0.3,
           maxChildSize: 0.8,
           expand: false,
           builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: ListView(
                controller: scrollController,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Pilih Tipe Kelas',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
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
          }
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
        appBar: AiwaAppBar(
          title: 'Tambah Santri',
        ),
        body: SafeArea(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
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
                                image: _photoUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(_photoUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: _photoUrl == null
                                  ? const Icon(Icons.person, size: 50, color: Colors.grey)
                                  : null,
                            ),
                            if (_isUploadingPhoto)
                              const Positioned.fill(
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _isUploadingPhoto ? null : _pickAndUploadImage,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.blue,
                                  ),
                                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
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
                              icon: Icons.location_city_outlined,
                              textCapitalization: TextCapitalization.words,
                            ),
                          ),
                          const SizedBox(width: 12),
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
                        icon: Icons.phone_in_talk_outlined,
                        keyboardType: TextInputType.phone,
                        isOptional: true,
                      ),
                      const SizedBox(height: 24),
                      const AiwaFormSectionTitle(title: 'Informasi Kelas'),
                      const SizedBox(height: 12),
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
                          const SizedBox(width: 12),
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
                      const SizedBox(height: 12),
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
                                  _freeUntil = DateTime(DateTime.now().year + 7, DateTime.now().month, DateTime.now().day);
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
                          onTap: () => _pickDate(
                            context: context,
                            initialDate: _freeUntil ?? DateTime.now(),
                            onPicked: (d) => _freeUntil = d,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      AiwaButton(
                        text: 'Tambah Santri',
                        onPressed: _submit,
                        isLoading: _isLoading,
                        height: 48,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
        ),
      ),
    );
  }


}

