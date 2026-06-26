import 'dart:convert';
import 'dart:js_util' as js_util;

import 'package:santijet_demir/data/services/cad_text_entity.dart';
import 'package:web/web.dart' as web;

Future<List<CadTextEntity>> extractDwgTextsWeb(List<int> bytes) async {
  final fn = await _waitForDwgBridge();
  if (fn == null) {
    final status = js_util.getProperty(web.window, '__SANTIJET_DWG_MODULE__');
    final statusText = status?.toString() ?? 'unknown';
    throw FormatException(
      statusText == 'error'
          ? 'DWG modülü başlatılamadı. Sayfayı yenileyin (Ctrl+Shift+R).'
          : 'DWG modülü henüz yüklenmedi. Birkaç saniye bekleyip tekrar deneyin.',
    );
  }

  final promise = js_util.callMethod(fn, 'call', [
    web.window,
    js_util.jsify(bytes),
  ]);
  final result = await js_util.promiseToFuture<Object?>(promise);

  if (result == null) {
    throw const FormatException('DWG dosyası işlenemedi.');
  }

  final jsonText = jsonEncode(js_util.dartify(result));
  final decoded = jsonDecode(jsonText) as List<dynamic>;

  return decoded
      .map((item) {
        if (item is Map<String, dynamic>) {
          final text = (item['text'] ?? '').toString().trim();
          if (text.isEmpty) return null;
          return CadTextEntity(
            entityType: (item['entityType'] ?? 'TEXT').toString(),
            text: text,
          );
        }
        final text = item.toString().trim();
        if (text.isEmpty) return null;
        return CadTextEntity(entityType: 'TEXT', text: text);
      })
      .whereType<CadTextEntity>()
      .toList(growable: false);
}

Future<Object?> _waitForDwgBridge({
  Duration timeout = const Duration(seconds: 15),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    final fn = js_util.getProperty(web.window, 'santijetExtractDwgTexts');
    if (fn != null) return fn;

    final status = js_util.getProperty(web.window, '__SANTIJET_DWG_MODULE__');
    if (status?.toString() == 'error') return null;

    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  return null;
}
