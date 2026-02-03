import 'package:flutter/material.dart';

class UiUtils {
  static void unfocus(BuildContext context) {
    FocusScope.of(context).unfocus();
  }
}
