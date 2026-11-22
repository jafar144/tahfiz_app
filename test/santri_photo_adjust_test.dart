import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khoirunnasyien/core/config/app_config.dart';
import 'package:khoirunnasyien/core/utils/profile_photo_picker.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_detail.dart';
import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_params.dart';
import 'package:khoirunnasyien/features/management_santri/domain/repository/santri_repository.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/cubit/santri_detail_cubit.dart';
import 'package:khoirunnasyien/features/management_santri/presentation/pages/edit_santri_page.dart';
import 'package:khoirunnasyien/flavors/khoirunnasyien/app_config.dart';

void main() {
  setUpAll(() => AppConfig.configure(khoirunnasyienAppConfig));

  group('ProfilePhotoPicker', () {
    testWidgets('pickAndEditWithOriginal returns original and crop', (
      tester,
    ) async {
      final picked = File('picked.jpg');
      final edited = File('edited.jpg');
      final picker = ProfilePhotoPicker(
        pickImage: (_) async => picked,
        editImage: (_, _) async => edited,
      );

      ProfilePhotoSelection? result;
      await tester.pumpWidget(
        _OpenButton(
          onOpen: (context) async {
            result = await picker.pickAndEditWithOriginal(
              context,
              type: ProfilePhotoType.santri,
            );
          },
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('profile_photo_source_gallery')));
      await tester.pumpAndSettle();

      expect(result?.original, same(picked));
      expect(result?.edited, same(edited));
    });

    testWidgets('cancelled crop returns null', (tester) async {
      final picker = ProfilePhotoPicker(
        pickImage: (_) async => File('picked.jpg'),
        editImage: (_, _) async => null,
      );

      ProfilePhotoSelection? result;
      var finished = false;
      await tester.pumpWidget(
        _OpenButton(
          onOpen: (context) async {
            result = await picker.pickAndEditWithOriginal(
              context,
              type: ProfilePhotoType.santri,
            );
            finished = true;
          },
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('profile_photo_source_camera')));
      await tester.pumpAndSettle();

      expect(finished, isTrue);
      expect(result, isNull);
    });

    test('editExisting goes straight to the editor', () async {
      final source = File('existing.jpg');
      final edited = File('recropped.jpg');
      File? received;
      ProfilePhotoType? receivedType;
      var pickerCalls = 0;
      final picker = ProfilePhotoPicker(
        pickImage: (_) async {
          pickerCalls++;
          return null;
        },
        editImage: (file, type) async {
          received = file;
          receivedType = type;
          return edited;
        },
      );

      final result = await picker.editExisting(source, ProfilePhotoType.santri);

      expect(result, same(edited));
      expect(received, same(source));
      expect(receivedType, ProfilePhotoType.santri);
      expect(pickerCalls, 0);
    });
  });

  group('SantriDetailCubit photo update', () {
    late _Storage storage;
    late _Repo repo;
    late SantriDetailCubit cubit;

    setUp(() {
      storage = _Storage();
      repo = _Repo(storage);
      cubit = SantriDetailCubit(
        repo,
        upload: storage.upload,
        delete: storage.delete,
      );
    });
    tearDown(() => cubit.close());

    test('re-crop keeps the original and replaces only the crop', () async {
      final ok = await cubit.updateSantri(
        'santri-1',
        _params(
          photoUrl: 'old-crop',
          photoOriginalUrl: 'old-original',
          localPhotoFile: File('recrop.jpg'),
        ),
      );

      expect(ok, isTrue);
      expect(storage.uploads, ['upload-1']);
      expect(repo.saved?.photoUrl, 'upload-1');
      expect(repo.saved?.photoOriginalUrl, 'old-original');
      expect(storage.deleted, ['old-crop']);
      expect(storage.deletedBeforeSave, isEmpty);
    });

    test('legacy photo becomes the original on first re-crop', () async {
      await cubit.updateSantri(
        'santri-1',
        _params(photoUrl: 'old-crop', localPhotoFile: File('recrop.jpg')),
      );

      expect(repo.saved?.photoUrl, 'upload-1');
      expect(repo.saved?.photoOriginalUrl, 'old-crop');
      expect(storage.deleted, isEmpty);
    });

    test(
      'new photo uploads original and crop, removes both old files',
      () async {
        await cubit.updateSantri(
          'santri-1',
          _params(
            photoUrl: 'old-crop',
            photoOriginalUrl: 'old-original',
            localPhotoFile: File('crop.jpg'),
            localPhotoOriginalFile: File('original.jpg'),
          ),
        );

        expect(storage.uploads, ['upload-1', 'upload-2']);
        expect(repo.saved?.photoOriginalUrl, 'upload-1');
        expect(repo.saved?.photoUrl, 'upload-2');
        expect(storage.deleted, unorderedEquals(['old-crop', 'old-original']));
      },
    );

    test('removing the photo deletes crop and original', () async {
      await cubit.updateSantri(
        'santri-1',
        _params(
          photoUrl: 'old-crop',
          photoOriginalUrl: 'old-original',
          removePhoto: true,
        ),
      );

      expect(repo.saved?.removePhoto, isTrue);
      expect(repo.saved?.photoUrl, isNull);
      expect(repo.saved?.photoOriginalUrl, isNull);
      expect(storage.deleted, unorderedEquals(['old-crop', 'old-original']));
    });

    test('failed save removes new uploads and keeps old files', () async {
      repo.fail = true;
      final ok = await cubit.updateSantri(
        'santri-1',
        _params(
          photoUrl: 'old-crop',
          photoOriginalUrl: 'old-original',
          localPhotoFile: File('crop.jpg'),
          localPhotoOriginalFile: File('original.jpg'),
        ),
      );

      expect(ok, isFalse);
      expect(storage.deleted, unorderedEquals(['upload-1', 'upload-2']));
    });

    test('failed crop upload rolls back the uploaded original', () async {
      storage.failOnUpload = 2;
      final ok = await cubit.updateSantri(
        'santri-1',
        _params(
          photoUrl: 'old-crop',
          localPhotoFile: File('crop.jpg'),
          localPhotoOriginalFile: File('original.jpg'),
        ),
      );

      expect(ok, isFalse);
      expect(repo.saved, isNull);
      expect(storage.deleted, ['upload-1']);
    });
  });

  testWidgets('pencil opens the editor with the stored original photo', (
    tester,
  ) async {
    final downloaded = File('downloaded-original.jpg');
    String? downloadedUrl;
    File? editorSource;
    final picker = ProfilePhotoPicker(
      pickImage: (_) async => fail('galeri/kamera tidak boleh dibuka'),
      download: (url) async {
        downloadedUrl = url;
        return downloaded;
      },
      editImage: (file, _) async {
        editorSource = file;
        return null; // admin membatalkan editor
      },
    );

    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => SantriDetailCubit(_Repo(_Storage())),
          child: EditSantriPage(
            santri: const SantriDetail(
              id: 'santri-1',
              name: 'Ahmad',
              nis: '1001',
              kelas: 'Mutawassith',
              jenisKelamin: 'L',
              isActive: true,
              isFree: false,
              photoUrl: 'https://example.test/crop.jpg',
              photoOriginalUrl: 'https://example.test/original.jpg',
            ),
            photoPicker: picker,
          ),
        ),
      ),
    );
    await tester.pump();
    tester.takeException(); // NetworkImage tidak bisa dimuat di test.

    await tester.tap(find.byKey(const Key('santri_photo_edit_button')));
    await tester.pump();
    await tester.pump();
    tester.takeException();

    expect(find.byKey(const Key('profile_photo_source_sheet')), findsNothing);
    expect(downloadedUrl, 'https://example.test/original.jpg');
    expect(editorSource, same(downloaded));
  });
}

SantriParams _params({
  String? photoUrl,
  String? photoOriginalUrl,
  File? localPhotoFile,
  File? localPhotoOriginalFile,
  bool removePhoto = false,
}) {
  return SantriParams(
    name: 'Ahmad',
    nis: '1001',
    phone: '0812',
    jenisKelamin: 'L',
    birthPlace: 'Jakarta',
    birthDate: DateTime(2012, 3, 9),
    waliName: 'Wali',
    waliPhone: '0813',
    kelas: 'Mutawassith',
    tipeKelas: 'Putra',
    entryDate: DateTime(2025, 7, 1),
    isFree: false,
    photoUrl: photoUrl,
    photoOriginalUrl: photoOriginalUrl,
    localPhotoFile: localPhotoFile,
    localPhotoOriginalFile: localPhotoOriginalFile,
    removePhoto: removePhoto,
  );
}

class _Storage {
  final uploads = <String>[];
  final deleted = <String>[];
  final deletedBeforeSave = <String>[];
  bool saved = false;
  int? failOnUpload;

  Future<String?> upload(File file, String path) async {
    expect(path, 'santri_photos');
    final attempt = uploads.length + 1;
    if (failOnUpload == attempt) return null;
    final url = 'upload-$attempt';
    uploads.add(url);
    return url;
  }

  Future<void> delete(String url) async {
    deleted.add(url);
    if (!saved) deletedBeforeSave.add(url);
  }
}

class _Repo implements SantriRepository {
  final _Storage storage;
  SantriParams? saved;
  bool fail = false;

  _Repo(this.storage);

  @override
  Future<void> updateSantri(String id, SantriParams params) async {
    if (fail) throw Exception('gagal simpan');
    saved = params;
    storage.saved = true;
  }

  @override
  Future<SantriDetail> getSantriDetail(String id) async => const SantriDetail(
    id: 'santri-1',
    name: 'Ahmad',
    nis: '1001',
    kelas: 'Mutawassith',
    jenisKelamin: 'L',
    isActive: true,
    isFree: false,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _OpenButton extends StatelessWidget {
  final Future<void> Function(BuildContext context) onOpen;

  const _OpenButton({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => onOpen(context),
            child: const Text('open'),
          ),
        ),
      ),
    );
  }
}
