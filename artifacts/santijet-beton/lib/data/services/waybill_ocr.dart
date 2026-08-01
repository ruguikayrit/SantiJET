import 'dart:convert';

import 'package:http/http.dart' as http;

/// İrsaliye OCR sonucu — fotoğraftan okunan alanlar.
class WaybillOcrResult {
  const WaybillOcrResult({
    this.ticketNo = '',
    this.plate = '',
    this.volumeM3,
    this.slumpCm,
    this.concreteClass = '',
    this.rawText = '',
    this.error,
  });

  final String ticketNo;
  final String plate;
  final double? volumeM3;
  final double? slumpCm;
  final String concreteClass;
  final String rawText;
  final String? error;

  bool get hasAnyField =>
      ticketNo.isNotEmpty ||
      plate.isNotEmpty ||
      volumeM3 != null ||
      slumpCm != null ||
      concreteClass.isNotEmpty;
}

/// Beton irsaliye fotoğrafından metin okuma + alan ayrıştırma.
abstract final class WaybillOcr {
  /// OCR.space ücretsiz/demo anahtarı (staging). Prod için dart-define ile verin.
  static const _defaultApiKey = String.fromEnvironment(
    'OCR_SPACE_API_KEY',
    defaultValue: 'helloworld',
  );

  static Future<WaybillOcrResult> fromImageBytes(
    List<int> bytes, {
    String mime = 'image/jpeg',
  }) async {
    final b64 = base64Encode(bytes);
    String raw;
    try {
      raw = await _ocrSpace(b64, mime: mime);
    } catch (e) {
      return WaybillOcrResult(
        error: 'İrsaliye okunamadı. Alanları manuel girebilirsiniz.',
        rawText: '',
      );
    }
    if (raw.trim().isEmpty) {
      return const WaybillOcrResult(
        error: 'Metin bulunamadı. Alanları manuel girebilirsiniz.',
      );
    }
    return parseText(raw);
  }

  static Future<String> _ocrSpace(String base64, {required String mime}) async {
    final uri = Uri.parse('https://api.ocr.space/parse/image');
    final res = await http
        .post(
          uri,
          headers: {'apikey': _defaultApiKey},
          body: {
            'base64Image': 'data:$mime;base64,$base64',
            'language': 'tur',
            'isOverlayRequired': 'false',
            'OCREngine': '2',
            'scale': 'true',
          },
        )
        .timeout(const Duration(seconds: 45));

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

  /// OCR metninden irsaliye alanlarını çıkarır.
  static WaybillOcrResult parseText(String raw) {
    final text = raw.replaceAll('\r', '\n');
    final compact = text.replaceAll(RegExp(r'[ \t]+'), ' ');

    final ticket = _firstMatch(compact, [
      RegExp(r'(?:irsaliye|irsaliye|irs\.?|waybill|belge)\s*(?:no|numara|nr)?\s*[:#]?\s*([A-Z0-9\-\/]{4,})',
          caseSensitive: false),
      RegExp(r'\b(IR[\-\s]?\d{4,})\b', caseSensitive: false),
      RegExp(r'\b([A-Z]{1,3}[\-\/]?\d{5,})\b'),
    ]);

    final plate = _firstMatch(compact, [
      RegExp(
        r'(?:plaka|plate)\s*[:#]?\s*([0-9]{2}\s*[A-ZÇĞİÖŞÜ]{1,3}\s*[0-9]{2,4})',
        caseSensitive: false,
      ),
      RegExp(r'\b([0-9]{2}\s*[A-ZÇĞİÖŞÜ]{1,3}\s*[0-9]{2,4})\b'),
    ]);

    final volume = _firstDouble(compact, [
      RegExp(
        r'(?:miktar|hacim|m3|m³|tonaj)?\s*[:#]?\s*(\d+[.,]\d+|\d+)\s*(?:m3|m³)?',
        caseSensitive: false,
      ),
      RegExp(r'(\d+[.,]\d+|\d+)\s*(?:m3|m³)\b', caseSensitive: false),
    ]);

    final slump = _firstDouble(compact, [
      RegExp(
        r'(?:slump|çökme|cokme|slamp)\s*[:#]?\s*(\d+[.,]\d+|\d+)',
        caseSensitive: false,
      ),
      RegExp(r'\b(\d{1,2})\s*cm\b', caseSensitive: false),
    ]);

    final cls = _firstMatch(compact, [
      RegExp(r'\b(C\d{2}\s*/\s*\d{2})\b', caseSensitive: false),
      RegExp(r'\b(C\d{2}/\d{2})\b', caseSensitive: false),
    ])?.replaceAll(' ', '');

    return WaybillOcrResult(
      ticketNo: ticket?.toUpperCase() ?? '',
      plate: plate?.toUpperCase().replaceAll(RegExp(r'\s+'), ' ') ?? '',
      volumeM3: volume,
      slumpCm: slump,
      concreteClass: cls?.toUpperCase() ?? '',
      rawText: text,
    );
  }

  static String? _firstMatch(String text, List<RegExp> patterns) {
    for (final p in patterns) {
      final m = p.firstMatch(text);
      if (m != null && m.groupCount >= 1) {
        final v = m.group(1)?.trim();
        if (v != null && v.isNotEmpty) return v;
      }
    }
    return null;
  }

  static double? _firstDouble(String text, List<RegExp> patterns) {
    final s = _firstMatch(text, patterns);
    if (s == null) return null;
    return double.tryParse(s.replaceAll(',', '.'));
  }
}
