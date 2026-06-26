import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:santijet_demir/core/config/dwg_converter_config.dart';
import 'package:santijet_demir/data/services/dxf_ascii_parser.dart';

import 'dwg_text_extractor_web.dart' if (dart.library.io) 'dwg_text_extractor_io.dart';

abstract final class DwgTextExtractor {
  static Future<List<String>> extract(List<int> bytes) async {
    if (kIsWeb) {
      return extractDwgTextsWeb(bytes);
    }
    return extractDwgTextsNative(bytes);
  }
}

Future<List<String>> extractDwgTextsNative(List<int> bytes) async {
  if (DwgConverterConfig.isConfigured) {
    return _extractViaHttp(bytes);
  }

  throw const FormatException(
    'DWG dosyaları bu cihazda doğrudan okunamaz. Web sürümünü kullanın veya '
    'DWG_CONVERTER_URL yapılandırın.',
  );
}

Future<List<String>> _extractViaHttp(List<int> bytes) async {
  final uri = Uri.parse('${DwgConverterConfig.url}/convert');
  final request = http.MultipartRequest('POST', uri)
    ..files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: 'upload.dwg',
      ),
    );

  final streamed = await request.send().timeout(const Duration(seconds: 120));
  final body = await streamed.stream.bytesToString();

  if (streamed.statusCode != 200) {
    throw FormatException(
      body.isNotEmpty ? body : 'DWG dönüştürme servisi hata verdi.',
    );
  }

  final decoded = jsonDecode(body) as Map<String, dynamic>;
  final rawTexts = decoded['texts'] as List<dynamic>? ?? const [];

  return rawTexts
      .map((item) => item.toString().trim())
      .where((text) => text.isNotEmpty)
      .toList(growable: false);
}
