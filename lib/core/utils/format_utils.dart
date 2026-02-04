class FormatUtils {
  static String formatPhoneNumber(String phone) {
    var formattedPhone = phone;
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '62${formattedPhone.substring(1)}';
    }
    return formattedPhone;
  }
}
