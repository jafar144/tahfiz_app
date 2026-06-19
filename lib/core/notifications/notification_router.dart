import 'package:firebase_auth/firebase_auth.dart';
import 'package:khoirunnasyien/core/router/app_router.dart';
import 'package:khoirunnasyien/core/router/route_paths.dart';

/// Titik ekstensi navigasi saat notifikasi di-tap.
///
/// Memetakan `data['type']` dari payload FCM ke rute aplikasi. Tambahkan
/// `case` baru di sini untuk setiap jenis notifikasi mendatang.
void handleNotificationTap(Map<String, dynamic> data) {
  // Notifikasi ini hanya menyasar akun yang sudah login. Bila belum login
  // (mis. cold start belum selesai), biarkan alur splash menentukan tujuan.
  if (FirebaseAuth.instance.currentUser == null) return;

  switch (data['type']) {
    case 'monthly_assessment_open':
    case 'monthly_assessment_reminder':
      AppRouter.router.push(RoutePaths.monthlyReport);
      break;
    case 'payment_due':
    case 'payment_arrears':
      // Beranda santri menampilkan ringkasan tunggakan + akses data pembayaran.
      AppRouter.router.push(RoutePaths.home);
      break;
    default:
      break;
  }
}
