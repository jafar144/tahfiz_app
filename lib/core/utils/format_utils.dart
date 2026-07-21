import 'package:intl/intl.dart';

class FormatUtils {
  static final NumberFormat _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// Format penuh, mis. 10500000 -> "Rp 10.500.000".
  static String formatRupiah(int amount) => _rupiah.format(amount);

  /// Format ringkas untuk label grafik, mis. 10500000 -> "Rp 10,5 jt".
  static String formatCompactRupiah(int amount) {
    if (amount.abs() >= 1000000000) {
      return 'Rp ${_trimZero(amount / 1000000000)} M';
    }
    if (amount.abs() >= 1000000) {
      return 'Rp ${_trimZero(amount / 1000000)} jt';
    }
    if (amount.abs() >= 1000) {
      return 'Rp ${_trimZero(amount / 1000)} rb';
    }
    return 'Rp $amount';
  }

  static String _trimZero(double value) {
    final str = value.toStringAsFixed(1);
    return str.endsWith('.0')
        ? str.substring(0, str.length - 2)
        : str.replaceAll('.', ',');
  }

  static String formatPhoneNumber(String phone) {
    var formattedPhone = phone;
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '62${formattedPhone.substring(1)}';
    }
    return formattedPhone;
  }

  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          if (word.length == 1) return word.toUpperCase();
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }
}
