class Validators {
  static String? required(String? value) {
    if (value == null || value.isEmpty) {
      return 'Field tidak boleh kosong';
    }
    return null;
  }
}
