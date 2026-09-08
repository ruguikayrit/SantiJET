import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';

import '../domain/kasa_hareket.dart';
import 'kasa_table_ocr.dart';
import 'ocr_image_preprocess.dart';

/// OCR içe aktarım sonucu.
class KasaOcrImportResult {
  const KasaOcrImportResult({
    required this.hareketler,
    required this.skipped,
    required this.rawText,
    this.usedOverlay = false,
  });

  final List<KasaHareket> hareketler;
  final int skipped;
  final String rawText;
  final bool usedOverlay;
}

/// OCR.space + ön işleme + tablo hizalama.
abstract final class KasaOcrService {
  static const _apiKey = String.fromEnvironment(
    'OCR_SPACE_API_KEY',
    defaultValue: 'helloworld',
  );

  static Future<KasaOcrImportResult> importFromImage(
    List<int> bytes, {
    String mime = 'image/jpeg',
    String defaultSantiye = 'İZMİT/EFSANE',
  }) async {
    final prepared = mime.startsWith('image/')
        ? OcrImagePreprocess.prepareJpeg(bytes)
        : Uint8List.fromList(bytes);
    final ocr = await _ocrSpaceDetailed(
      base64Encode(prepared),
      mime: 'image/jpeg',
    );
    final parsed = KasaTableOcr.parse(
      rawText: ocr.text,
      words: ocr.words,
      defaultSantiye: defaultSantiye,
      sourceLabel: 'OCR JPG',
    );
    return KasaOcrImportResult(
      hareketler: parsed.hareketler,
      skipped: parsed.skipped,
      rawText: ocr.text,
      usedOverlay: ocr.words.isNotEmpty,
    );
  }

  static Future<KasaOcrImportResult> importFromPdf(
    Uint8List pdfBytes, {
    String defaultSantiye = 'İZMİT/EFSANE',
  }) async {
    try {
      final ocr = await _ocrSpaceDetailed(
        base64Encode(pdfBytes),
        mime: 'application/pdf',
        fileType: 'PDF',
      );
      if (ocr.text.trim().isNotEmpty || ocr.words.isNotEmpty) {
        final parsed = KasaTableOcr.parse(
          rawText: ocr.text,
          words: ocr.words,
          defaultSantiye: defaultSantiye,
          sourceLabel: 'OCR PDF',
        );
        if (parsed.hareketler.isNotEmpty) {
          return KasaOcrImportResult(
            hareketler: parsed.hareketler,
            skipped: parsed.skipped,
            rawText: ocr.text,
            usedOverlay: ocr.words.isNotEmpty,
          );
        }
      }
    } catch (_) {
      // raster fallback
    }

    final allWords = <OcrWord>[];
    final buf = StringBuffer();
    var pageIndex = 0;
    await for (final page in Printing.raster(pdfBytes, dpi: 160)) {
      pageIndex++;
      if (pageIndex > 3) break;
      final png = await page.toPng();
      final prepared = OcrImagePreprocess.prepareJpeg(png);
      try {
        final ocr = await _ocrSpaceDetailed(
          base64Encode(prepared),
          mime: 'image/jpeg',
        );
        if (ocr.text.trim().isNotEmpty) buf.writeln(ocr.text);
        allWords.addAll(ocr.words);
      } catch (_) {}
    }

    final parsed = KasaTableOcr.parse(
      rawText: buf.toString(),
      words: allWords,
      defaultSantiye: defaultSantiye,
      sourceLabel: 'OCR PDF',
    );
    return KasaOcrImportResult(
      hareketler: parsed.hareketler,
      skipped: parsed.skipped,
      rawText: buf.toString(),
      usedOverlay: allWords.isNotEmpty,
    );
  }

  static Future<({String text, List<OcrWord> words})> _ocrSpaceDetailed(
    String base64, {
    required String mime,
    String? fileType,
  }) async {
    final uri = Uri.parse('https://api.ocr.space/parse/image');
    final body = <String, String>{
      'base64Image': 'data:$mime;base64,$base64',
      'language': 'tur',
      'isOverlayRequired': 'true',
      'OCREngine': '2',
      'scale': 'true',
      'isTable': 'true',
      'detectOrientation': 'true',
    };
    if (fileType != null) body['filetype'] = fileType;

    final res = await http
        .post(
          uri,
          headers: {'apikey': _apiKey},
          body: body,
        )
        .timeout(const Duration(seconds: 90));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw StateError('OCR HTTP ${res.statusCode}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (json['IsErroredOnProcessing'] == true) {
      final msg = json['ErrorMessage'];
      throw StateError(msg?.toString() ?? 'OCR error');
    }
    final results = json['ParsedResults'] as List<dynamic>? ?? const [];
    if (results.isEmpty) return (text: '', words: <OcrWord>[]);

    final first = results.first as Map<String, dynamic>;
    final text = (first['ParsedText'] as String? ?? '').trim();
    final words = _extractWords(first['TextOverlay']);
    return (text: text, words: words);
  }

  static List<OcrWord> _extractWords(Object? overlay) {
    if (overlay is! Map) return const [];
    final lines = overlay['Lines'] as List<dynamic>? ?? const [];
    final out = <OcrWord>[];
    for (final line in lines) {
      if (line is! Map) continue;
      final words = line['Words'] as List<dynamic>? ?? const [];
      if (words.isNotEmpty) {
        for (final w in words) {
          if (w is! Map) continue;
          final t = (w['WordText'] as String? ?? '').trim();
          if (t.isEmpty) continue;
          out.add(
            OcrWord(
              text: t,
              left: _asInt(w['Left']),
              top: _asInt(w['Top']),
              width: _asInt(w['Width']),
              height: _asInt(w['Height']),
            ),
          );
        }
      } else {
        // Bazı yanıtlarda yalnız LineText + MaxHeight/MinTop
        final t = (line['LineText'] as String? ?? '').trim();
        if (t.isEmpty) continue;
        out.add(
          OcrWord(
            text: t,
            left: _asInt(line['MinLeft'] ?? line['Left'] ?? 0),
            top: _asInt(line['MinTop'] ?? line['Top'] ?? 0),
            width: _asInt(line['MaxWidth'] ?? line['Width'] ?? 40),
            height: _asInt(line['MaxHeight'] ?? line['Height'] ?? 14),
          ),
        );
      }
    }
    return out;
  }

  static int _asInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.round();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }
}
