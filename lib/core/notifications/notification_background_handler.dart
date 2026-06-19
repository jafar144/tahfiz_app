import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:khoirunnasyien/firebase_options.dart';

/// Handler pesan FCM saat aplikasi di background/terminated.
///
/// Harus berupa fungsi top-level (`vm:entry-point`) karena dijalankan di
/// isolate terpisah. Pesan yang membawa payload `notification` sudah otomatis
/// ditampilkan oleh sistem di status bar, jadi di sini tidak perlu menampilkan
/// notifikasi manual. Fungsi disiapkan sebagai titik ekstensi untuk pemrosesan
/// data di masa depan (mis. memperbarui badge / cache lokal).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}
