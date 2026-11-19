// Nilai dari aplikasi Android resmi Firebase project al-jauhar-app.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class AlJauharFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'AlJauharFirebaseOptions belum dikonfigurasi untuk web.',
      );
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      _ => throw UnsupportedError(
        'AlJauharFirebaseOptions baru dikonfigurasi untuk Android.',
      ),
    };
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDLCUOfyyMfWQ6dyM1nvaCXoaDYYXJprzQ',
    appId: '1:469727255045:android:0f24a420b6a4d50bea5a6c',
    messagingSenderId: '469727255045',
    projectId: 'al-jauhar-app',
    storageBucket: 'al-jauhar-app.firebasestorage.app',
  );
}
