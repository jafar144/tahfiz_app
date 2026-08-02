import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:khoirunnasyien/core/utils/profile_photo_picker.dart';

void main() {
  testWidgets('galeri diteruskan ke picker lalu editor foto', (tester) async {
    final pickedFile = File('picked-from-gallery.jpg');
    final editedFile = File('edited-gallery-photo.jpg');
    ImageSource? receivedSource;
    File? receivedFile;
    ProfilePhotoType? receivedType;

    final picker = ProfilePhotoPicker(
      pickImage: (source) async {
        receivedSource = source;
        return pickedFile;
      },
      editImage: (file, type) async {
        receivedFile = file;
        receivedType = type;
        return editedFile;
      },
    );

    File? result;
    await tester.pumpWidget(
      _PickerTestApp(
        onOpen: (context) async {
          result = await picker.pickAndEdit(
            context,
            type: ProfilePhotoType.santri,
          );
        },
      ),
    );

    await tester.tap(find.byKey(const Key('open_profile_photo_picker')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile_photo_source_sheet')), findsOneWidget);
    await tester.tap(find.byKey(const Key('profile_photo_source_gallery')));
    await tester.pumpAndSettle();

    expect(receivedSource, ImageSource.gallery);
    expect(receivedFile, same(pickedFile));
    expect(receivedType, ProfilePhotoType.santri);
    expect(result, same(editedFile));
    expect(find.byKey(const Key('profile_photo_source_sheet')), findsNothing);
  });

  testWidgets('kamera diteruskan ke picker lalu editor foto', (tester) async {
    final pickedFile = File('captured-with-camera.jpg');
    final editedFile = File('edited-camera-photo.jpg');
    ImageSource? receivedSource;
    File? receivedFile;
    ProfilePhotoType? receivedType;

    final picker = ProfilePhotoPicker(
      pickImage: (source) async {
        receivedSource = source;
        return pickedFile;
      },
      editImage: (file, type) async {
        receivedFile = file;
        receivedType = type;
        return editedFile;
      },
    );

    File? result;
    await tester.pumpWidget(
      _PickerTestApp(
        onOpen: (context) async {
          result = await picker.pickAndEdit(
            context,
            type: ProfilePhotoType.asatidz,
          );
        },
      ),
    );

    await tester.tap(find.byKey(const Key('open_profile_photo_picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile_photo_source_camera')));
    await tester.pumpAndSettle();

    expect(receivedSource, ImageSource.camera);
    expect(receivedFile, same(pickedFile));
    expect(receivedType, ProfilePhotoType.asatidz);
    expect(result, same(editedFile));
  });

  testWidgets('tombol tutup membatalkan tanpa memanggil picker atau editor', (
    tester,
  ) async {
    var pickerCallCount = 0;
    var editorCallCount = 0;
    var completed = false;
    File? result;

    final picker = ProfilePhotoPicker(
      pickImage: (_) async {
        pickerCallCount++;
        return File('should-not-be-picked.jpg');
      },
      editImage: (file, type) async {
        editorCallCount++;
        return file;
      },
    );

    await tester.pumpWidget(
      _PickerTestApp(
        onOpen: (context) async {
          result = await picker.pickAndEdit(
            context,
            type: ProfilePhotoType.santri,
          );
          completed = true;
        },
      ),
    );

    await tester.tap(find.byKey(const Key('open_profile_photo_picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile_photo_source_close')));
    await tester.pumpAndSettle();

    expect(completed, isTrue);
    expect(result, isNull);
    expect(pickerCallCount, 0);
    expect(editorCallCount, 0);
  });

  test('santri memakai editor 25:28 dengan judul khusus', () {
    final ratio = ProfilePhotoType.santri.aspectRatio;

    expect(ProfilePhotoType.santri.editorTitle, 'Atur Foto Santri');
    expect(ratio.ratioX, 25);
    expect(ratio.ratioY, 28);
  });

  test('asatidz memakai editor persegi dengan judul khusus', () {
    final ratio = ProfilePhotoType.asatidz.aspectRatio;

    expect(ProfilePhotoType.asatidz.editorTitle, 'Atur Foto Asatidz');
    expect(ratio.ratioX, 1);
    expect(ratio.ratioY, 1);
  });
}

class _PickerTestApp extends StatelessWidget {
  final Future<void> Function(BuildContext context) onOpen;

  const _PickerTestApp({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              key: const Key('open_profile_photo_picker'),
              onPressed: () => onOpen(context),
              child: const Text('Pilih foto'),
            ),
          ),
        ),
      ),
    );
  }
}
