import 'package:firebase_core/firebase_core.dart';
import 'package:khoirunnasyien/flavors/khoirunnasyien/firebase_options.dart';

/// Resolver Firebase untuk entry point yang dapat berjalan di isolate terpisah
/// (khususnya handler background FCM).
class FlavorFirebaseOptions {
  static const flavor = String.fromEnvironment(
    'APP_FLAVOR',
    defaultValue: 'khoirunnasyien',
  );

  static FirebaseOptions get currentPlatform => switch (flavor) {
    'khoirunnasyien' => KhoirunnasyienFirebaseOptions.currentPlatform,
    _ => throw UnsupportedError(
      'Firebase belum dikonfigurasi untuk flavor "$flavor".',
    ),
  };
}
