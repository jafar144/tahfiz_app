// File generated from the Firebase Android app configuration.
// ignore_for_file: type=lint

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class BarokatulQuranFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'BarokatulQuranFirebaseOptions belum dikonfigurasi untuk web.',
      );
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      _ => throw UnsupportedError(
        'BarokatulQuranFirebaseOptions baru dikonfigurasi untuk Android.',
      ),
    };
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBUCNJa5Tc0NHFi_wC2hNVvJWD_99VBIrw',
    appId: '1:406302789936:android:55bdab2b4cd5201d80f8f5',
    messagingSenderId: '406302789936',
    projectId: 'barokatul-apps',
    storageBucket: 'barokatul-apps.firebasestorage.app',
  );
}
