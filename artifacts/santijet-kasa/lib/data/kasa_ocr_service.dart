import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';

import '../domain/kasa_ocr_parser.dart';
import '../domain/kasa_hareket.dart';

/// OCR.space üzerinden JPG/PDF metin okuma (Beton/SAHA ile aynı servis).
abstract final class KasaOcrService {
  static const _apiKey = String.fromEnvironment(
    'OCR_SPACE_API_KEY',
    defaultValue: 'helloworld',
  );

  static Future<String> recognizeImage(
    List<int> bytes, {
    String mime = 'image/jpeg',
  }) async {
    return _ocrSpace(base64Encode(bytes), mime: mime);
  }

  /// PDF: önce OCR.space PDF; olmazsa ilk sayfayı rasterize edip JPG OCR.
  static Future<String> recognizePdf(Uint8List pdfBytes) async {
    try {
      final text = await _ocrSpace(
        base64Encode(pdfBytes),
        mime: 'application/pdf',
        fileType: 'PDF',
      );
      if (text.trim().isNotEmpty) return text;
    } catch (_) {
      // raster fallback
    }

    final buf = StringBuffer();
    var pageIndex = 0;
    await for (final page in Printing.raster(pdfBytes, dpi: 150)) {
      pageIndex++;
      if (pageIndex > 3) break; // ilk 3 sayfa
      final png = await page.toPng();
      try {
        final t = await recognizeImage(png, mime: 'image/png');
        if (t.trim().isNotEmpty) {
          buf.writeln(t);
        }
      } catch (_) {
        // continue
      }
    }
    return buf.toString().trim();
  }

  static Future<({List<KasaHareket> hareketler, int skipped, String raw})>
      importFromImage(
    List<int> bytes, {
    String mime = 'image/jpeg',
    String defaultSantiye = 'İZMİT/EFSANE',
  }) async {
    final raw = await recognizeImage(bytes, mime: mime);
    final parsed = KasaOcrParser.parseText(
      raw,
      defaultSantiye: defaultSantiye,
      sourceLabel: 'OCR JPG',
    );
    return (
      hareketler: parsed.hareketler,
      skipped: parsed.skipped,
      raw: raw,
    );
  }

  static Future<({List<KasaHareket> hareketler, int skipped, String raw})>
      importFromPdf(
    Uint8List bytes, {
    String defaultSantiye = 'İZMİT/EFSANE',
  }) async {
    final raw = await recognizePdf(bytes);
    final parsed = KasaOcrParser.parseText(
      raw,
      defaultSantiye: defaultSantiye,
      sourceLabel: 'OCR PDF',
    );
    return (
      hareketler: parsed.hareketler,
      skipped: parsed.skipped,
      raw: raw,
    );
  }

  static Future<String> _ocrSpace(
    String base64, {
    required String mime,
    String? fileType,
  }) async {
    final uri = Uri.parse('https://api.ocr.space/parse/image');
    final body = <String, String>{
      'base64Image': 'data:$mime;base64,$base64',
      'language': 'tur',
      'isOverlayRequired': 'false',
      'OCREngine': '2',
      'scale': 'true',
      'isTable': 'true',
    };
    if (fileType != null) body['filetype'] = fileType;

    final res = await http
        .post(
          uri,
          headers: {'apikey': _apiKey},
          body: body,
        )
        .timeout(const Duration(seconds: 60));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw StateError('OCR HTTP ${res.statusCode}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (json['IsErroredOnProcessing'] == true) {
      final msg = json['ErrorMessage'];
      throw StateError(msg?.toString() ?? 'OCR error');
    }
    final results = json['ParsedResults'] as List<dynamic>? ?? const [];
    if (results.isEmpty) return '';
    final first = results.first as Map<String, dynamic>;
    return (first['ParsedText'] as String? ?? '').trim();
  }
}
