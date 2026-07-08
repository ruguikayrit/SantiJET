import 'dart:js_util' as js_util;

import 'package:web/web.dart' as web;

double? readWebSafeAreaBottomInset() {
  try {
    final value = js_util.getProperty(web.window, '__SANTIJET_SAFE_AREA_BOTTOM__');
    if (value is num && value > 0) return value.toDouble();
  } catch (_) {
    // JS henüz hazır değil.
  }
  return null;
}
