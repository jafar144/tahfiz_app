import 'package:url_launcher/url_launcher.dart';

enum WhatsAppLaunchResult { opened, invalidPhone, unavailable }

typedef WhatsAppUrlLauncher = Future<bool> Function(Uri uri);

class WhatsAppUtils {
  static final RegExp _indonesianMobilePattern = RegExp(
    r'^628[1-9]\d{7,10}$',
  );

  /// Menormalisasi format nomor seluler Indonesia ke bentuk wa.me (628...).
  /// Menerima awalan 0, 62, +62, 0062, nomor tanpa kode negara, spasi,
  /// tanda kurung, dan tanda hubung.
  static String? normalizePhone(String? rawPhone) {
    var digits = rawPhone?.replaceAll(RegExp(r'\D'), '') ?? '';
    if (digits.isEmpty) return null;

    if (digits.startsWith('0062')) {
      digits = digits.substring(2);
    }

    String subscriber;
    if (digits.startsWith('62')) {
      subscriber = digits.substring(2);
    } else {
      subscriber = digits;
    }

    // Beberapa data ditulis +62 (0) 812..., jadi angka trunk 0 tetap perlu
    // dibuang setelah kode negara dilepas.
    subscriber = subscriber.replaceFirst(RegExp(r'^0+'), '');
    final normalized = '62$subscriber';

    return _indonesianMobilePattern.hasMatch(normalized) ? normalized : null;
  }

  static Uri? buildUri(String? rawPhone, {String? message}) {
    final phone = normalizePhone(rawPhone);
    if (phone == null) return null;

    final trimmedMessage = message?.trim();
    return Uri.https(
      'wa.me',
      '/$phone',
      trimmedMessage == null || trimmedMessage.isEmpty
          ? null
          : {'text': trimmedMessage},
    );
  }

  static Future<WhatsAppLaunchResult> launch(
    String? rawPhone, {
    String? message,
    WhatsAppUrlLauncher? launcher,
  }) async {
    final uri = buildUri(rawPhone, message: message);
    if (uri == null) return WhatsAppLaunchResult.invalidPhone;

    try {
      final didOpen = await (launcher ?? _launchExternal)(uri);
      return didOpen
          ? WhatsAppLaunchResult.opened
          : WhatsAppLaunchResult.unavailable;
    } catch (_) {
      return WhatsAppLaunchResult.unavailable;
    }
  }

  static Future<bool> _launchExternal(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
