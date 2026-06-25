import 'dart:convert';
import 'dart:js_util' as js_util;

import 'package:santijet_demir/data/services/dxf_ascii_parser.dart';
import 'package:web/web.dart' as web;

Future<List<DxfSegment>> extractDwgSegmentsWeb(List<int> bytes) async {
  final fn = js_util.getProperty(web.window, 'santijetExtractDwgSegments');
  if (fn == null) {
    throw const FormatException(
      'DWG modülü yüklenemedi. Sayfayı yenileyin (Ctrl+Shift+R).',
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
      .map(
        (item) => DxfSegment(
          layerName: (item as Map<String, dynamic>)['layerName'] as String? ?? '0',
          length: (item['length'] as num?)?.toDouble() ?? 0,
        ),
      )
      .where((segment) => segment.length > 0)
      .toList(growable: false);
}
