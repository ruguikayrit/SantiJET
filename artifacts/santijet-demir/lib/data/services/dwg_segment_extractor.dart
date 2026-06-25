import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:santijet_demir/core/config/dwg_converter_config.dart';
import 'package:santijet_demir/data/services/dxf_ascii_parser.dart';

import 'dwg_segment_extractor_web.dart' if (dart.library.io) 'dwg_segment_extractor_io.dart';

abstract final class DwgSegmentExtractor {
  static Future<List<DxfSegment>> extract(List<int> bytes) async {
    if (kIsWeb) {
      return extractDwgSegmentsWeb(bytes);
    }
    return extractDwgSegmentsNative(bytes);
  }
}

Future<List<DxfSegment>> extractDwgSegmentsNative(List<int> bytes) async {
  if (DwgConverterConfig.isConfigured) {
    return _extractViaHttp(bytes);
  }

  throw const FormatException(
    'DWG dosyaları bu cihazda doğrudan okunamaz. Web sürümünü kullanın veya '
    'DWG_CONVERTER_URL yapılandırın.',
  );
}

Future<List<DxfSegment>> _extractViaHttp(List<int> bytes) async {
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
  final rawSegments = decoded['segments'] as List<dynamic>? ?? const [];

  return rawSegments
      .map(
        (item) => DxfSegment(
          layerName: (item as Map<String, dynamic>)['layerName'] as String? ?? '0',
          length: (item['length'] as num?)?.toDouble() ?? 0,
        ),
      )
      .where((segment) => segment.length > 0)
      .toList(growable: false);
}
