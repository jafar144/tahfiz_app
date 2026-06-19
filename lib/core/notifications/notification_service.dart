import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:khoirunnasyien/core/notifications/fcm_token_datasource.dart';
import 'package:khoirunnasyien/core/notifications/notification_router.dart';

/// Inti pengelolaan notifikasi (FCM + tampilan lokal).
///
/// Tanggung jawab:
/// - meminta izin & membuat channel notifikasi Android,
/// - menampilkan notifikasi saat aplikasi foreground,
/// - menangani tap notifikasi (deep-link via [handleNotificationTap]),
/// - mendaftarkan/menghapus token perangkat sesuai siklus login.
///
/// Didesain generik agar fitur notifikasi berikutnya cukup menambah handler/
/// rute baru tanpa mengubah kelas ini.
class NotificationService {
  final FirebaseMessaging _messaging;
  final FcmTokenDataSource _tokenDataSource;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  NotificationService(this._messaging, this._tokenDataSource);

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'Notifikasi',
    description: 'Saluran notifikasi utama aplikasi.',
    importance: Importance.high,
  );

  static const String _icon = '@mipmap/launcher_icon';

  bool _initialized = false;
  String? _uid;
  String? _role;

  /// Dipanggil sekali saat aplikasi start (lihat main.dart).
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await _messaging.requestPermission();

    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(_icon),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          handleNotificationTap(_decodePayload(payload));
        }
      },
    );

    final android =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(_channel);
    await android?.requestNotificationsPermission();

    // Foreground → tampilkan manual lewat local notifications.
    FirebaseMessaging.onMessage.listen(_showForeground);
    // Tap notifikasi saat app di background.
    FirebaseMessaging.onMessageOpenedApp
        .listen((message) => handleNotificationTap(message.data));
    // Tap notifikasi yang membuka app dari keadaan terminated.
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      handleNotificationTap(initialMessage.data);
    }
    // Token bisa berganti sewaktu-waktu → daftarkan ulang.
    _messaging.onTokenRefresh.listen(_handleTokenRefresh);
  }

  /// Daftarkan token perangkat untuk user yang sedang login.
  Future<void> registerForUser({
    required String uid,
    required String role,
  }) async {
    _uid = uid;
    _role = role;
    try {
      final token = await _messaging.getToken();
      if (token == null) return;
      await _tokenDataSource.saveToken(token: token, uid: uid, role: role);
    } catch (_) {
      // Jangan ganggu alur login bila pendaftaran token gagal.
    }
  }

  /// Hapus token saat logout (dipanggil sebelum sign-out agar lolos rules).
  Future<void> clear() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) await _tokenDataSource.deleteToken(token);
    } catch (_) {
      // Abaikan kegagalan (mis. offline saat logout).
    }
    _uid = null;
    _role = null;
  }

  Future<void> _handleTokenRefresh(String token) async {
    final uid = _uid;
    final role = _role;
    if (uid == null || role == null) return;
    await _tokenDataSource.saveToken(token: token, uid: uid, role: role);
  }

  Future<void> _showForeground(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: _icon,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  Map<String, dynamic> _decodePayload(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      // payload bukan JSON valid → kembalikan map kosong.
    }
    return <String, dynamic>{};
  }
}
