import 'dart:js_util' as js_util;

import 'package:web/web.dart' as web;

void syncPageBackgroundColor(int argbColor) {
  final hex =
      '#${(argbColor & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  try {
    final root = web.document.documentElement;
    if (root != null) {
      js_util.callMethod(js_util.getProperty(root, 'style'), 'setProperty', [
        'background-color',
        hex,
      ]);
    }
    final body = web.document.body;
    if (body != null) {
      js_util.callMethod(js_util.getProperty(body, 'style'), 'setProperty', [
        'background-color',
        hex,
      ]);
    }
  } catch (_) {
    // Web API henüz hazır değil.
  }
}
