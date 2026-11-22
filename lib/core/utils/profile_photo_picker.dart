import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:khoirunnasyien/core/utils/image_utils.dart';
import 'package:khoirunnasyien/core/theme/app_colors.dart';

enum ProfilePhotoType { santri, asatidz }

extension ProfilePhotoTypeSettings on ProfilePhotoType {
  String get editorTitle => switch (this) {
    ProfilePhotoType.santri => 'Atur Foto Santri',
    ProfilePhotoType.asatidz => 'Atur Foto Asatidz',
  };

  CropAspectRatio get aspectRatio => switch (this) {
    // Sama dengan rasio bidang foto pada template syahadah (500 x 560).
    ProfilePhotoType.santri => const CropAspectRatio(ratioX: 25, ratioY: 28),
    ProfilePhotoType.asatidz => const CropAspectRatio(ratioX: 1, ratioY: 1),
  };
}

typedef ProfileImagePicker = Future<File?> Function(ImageSource source);
typedef ProfileImageEditor =
    Future<File?> Function(File file, ProfilePhotoType type);
typedef ProfileImageDownloader = Future<File?> Function(String url);

/// Foto asli dari galeri/kamera beserta hasil crop-nya.
class ProfilePhotoSelection {
  final File original;
  final File edited;

  const ProfilePhotoSelection({required this.original, required this.edited});
}

/// Mengelola alur pemilihan sumber foto hingga editor crop native.
///
/// Callback dapat diganti pada test agar pilihan galeri/kamera dan penerusan
/// ke editor dapat diverifikasi tanpa membuka platform channel.
class ProfilePhotoPicker {
  final ProfileImagePicker _pickImage;
  final ProfileImageEditor _editImage;
  final ProfileImageDownloader _download;

  ProfilePhotoPicker({
    ProfileImagePicker? pickImage,
    ProfileImageEditor? editImage,
    ProfileImageDownloader? download,
  }) : _pickImage = pickImage ?? ImageUtils.pickImage,
       _editImage = editImage ?? _openEditor,
       _download = download ?? ImageUtils.downloadImageToTemp;

  static final shared = ProfilePhotoPicker();

  Future<File?> pickAndEdit(
    BuildContext context, {
    required ProfilePhotoType type,
  }) async {
    final selection = await pickAndEditWithOriginal(context, type: type);
    return selection?.edited;
  }

  /// Seperti [pickAndEdit], tetapi juga mengembalikan foto asli agar posisi
  /// foto bisa diatur ulang nanti tanpa memilih foto baru.
  Future<ProfilePhotoSelection?> pickAndEditWithOriginal(
    BuildContext context, {
    required ProfilePhotoType type,
  }) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final source = await showProfilePhotoSourceSheet(context);
    if (source == null || !context.mounted) return null;

    final pickedFile = await _pickImage(source);
    if (pickedFile == null) return null;

    final edited = await _editImage(pickedFile, type);
    if (edited == null) return null;
    return ProfilePhotoSelection(original: pickedFile, edited: edited);
  }

  /// Membuka editor langsung dengan foto yang sudah ada (tanpa pilihan
  /// galeri/kamera).
  Future<File?> editExisting(File source, ProfilePhotoType type) {
    FocusManager.instance.primaryFocus?.unfocus();
    return _editImage(source, type);
  }

  /// Mengunduh foto tersimpan agar bisa dibuka di editor.
  Future<File?> download(String url) => _download(url);

  static Future<File?> _openEditor(File file, ProfilePhotoType type) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: file.path,
      aspectRatio: type.aspectRatio,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 95,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: type.editorTitle,
          toolbarColor: (kGreenBrand
              ? const Color(0xFF1A5B30)
              : const Color(0xFF004AAD)),
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: (kGreenBrand
              ? const Color(0xFF1A5B30)
              : const Color(0xFF004AAD)),
          lockAspectRatio: true,
          showCropGrid: true,
        ),
        IOSUiSettings(
          title: type.editorTitle,
          doneButtonTitle: 'Simpan',
          cancelButtonTitle: 'Batal',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          aspectRatioPickerButtonHidden: true,
        ),
      ],
    );

    return croppedFile == null ? null : File(croppedFile.path);
  }
}

Future<ImageSource?> showProfilePhotoSourceSheet(BuildContext context) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Container(
        key: const Key('profile_photo_source_sheet'),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Pilih sumber foto',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('profile_photo_source_close'),
                  tooltip: 'Tutup',
                  onPressed: () => Navigator.pop(sheetContext),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            Text(
              'Foto yang dipilih akan dibuka di halaman edit foto.',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            _PhotoSourceTile(
              key: const Key('profile_photo_source_gallery'),
              icon: Icons.photo_library_outlined,
              title: 'Galeri',
              subtitle: 'Pilih foto yang tersimpan di HP',
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            const SizedBox(height: 10),
            _PhotoSourceTile(
              key: const Key('profile_photo_source_camera'),
              icon: Icons.photo_camera_outlined,
              title: 'Kamera',
              subtitle: 'Ambil foto baru dengan kamera HP',
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
          ],
        ),
      );
    },
  );
}

class _PhotoSourceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PhotoSourceTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: (kGreenBrand
                      ? const Color(0xFF1A5B30)
                      : const Color(0xFF004AAD)),
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}
