import 'dart:convert';

import 'package:http/http.dart' as http;

/// İrsaliyeden okunan tek malzeme satırı.
class IrsaliyeMaterialLine {
  const IrsaliyeMaterialLine({
    this.name = '',
    this.quantity = '',
    this.unit = '',
    this.price = '',
  });

  final String name;
  final String quantity;
  final String unit;
  final String price;

  bool get hasName => name.trim().isNotEmpty;
}

/// İrsaliye OCR sonucu.
class IrsaliyeMaterialOcrResult {
  const IrsaliyeMaterialOcrResult({
    this.supplyDate = '',
    this.supplier = '',
    this.lines = const [],
    this.rawText = '',
    this.error,
  });

  final String supplyDate;
  final String supplier;
  final List<IrsaliyeMaterialLine> lines;
  final String rawText;
  final String? error;

  bool get hasAnyField =>
      supplyDate.isNotEmpty ||
      supplier.isNotEmpty ||
      lines.any((l) => l.hasName);
}

/// Gelen malzeme irsaliyesi — OCR.space + Türkçe alan ayrıştırma.
///
/// Beton `WaybillOcr` ile aynı servis; alanlar malzeme irsaliyesine özel.
abstract final class IrsaliyeMaterialOcr {
  static const _defaultApiKey = String.fromEnvironment(
    'OCR_SPACE_API_KEY',
    defaultValue: 'helloworld',
  );

  static Future<IrsaliyeMaterialOcrResult> fromImageBytes(
    List<int> bytes, {
    String mime = 'image/jpeg',
  }) async {
    final b64 = base64Encode(bytes);
    String raw;
    try {
      raw = await _ocrSpace(b64, mime: mime);
    } catch (_) {
      return const IrsaliyeMaterialOcrResult(
        error: 'İrsaliye okunamadı. Alanları manuel girebilirsiniz.',
      );
    }
    if (raw.trim().isEmpty) {
      return const IrsaliyeMaterialOcrResult(
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

  /// OCR metninden tedarik tarihi, firma ve ürün satırlarını çıkarır.
  static IrsaliyeMaterialOcrResult parseText(String raw) {
    final text = raw.replaceAll('\r', '\n');
    final compact = _foldTr(text.replaceAll(RegExp(r'[ \t]+'), ' '));
    final lines = text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .map(_foldTr)
        .toList();

    final supplyDate = _extractDate(compact) ?? '';
    final supplier = _extractSupplier(compact, lines) ?? '';
    final products = _extractProducts(compact, lines);

    return IrsaliyeMaterialOcrResult(
      supplyDate: supplyDate,
      supplier: supplier,
      lines: products,
      rawText: text,
    );
  }

  /// Türkçe büyük İ / I sorununu regex için sadeleştirir.
  static String _foldTr(String s) {
    return s
        .replaceAll('İ', 'i')
        .replaceAll('I', 'i')
        .replaceAll('ı', 'i')
        .replaceAll('Ğ', 'g')
        .replaceAll('ğ', 'g')
        .replaceAll('Ü', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('Ş', 's')
        .replaceAll('ş', 's')
        .replaceAll('Ö', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('Ç', 'c')
        .replaceAll('ç', 'c')
        .toLowerCase();
  }

  static String? _extractDate(String text) {
    final labeled = _firstMatch(text, [
      RegExp(
        r'(?:tedarik|sevk|düzenleme|duzenleme|irsaliye|belge)?\s*'
        r'(?:tarihi|tarih)\s*[:#]?\s*'
        r'(\d{1,2}[./-]\d{1,2}[./-]\d{2,4})',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:date)\s*[:#]?\s*(\d{1,2}[./-]\d{1,2}[./-]\d{2,4})',
        caseSensitive: false,
      ),
    ]);
    if (labeled != null) return _normalizeDate(labeled);

    final any = RegExp(r'\b(\d{1,2}[./-]\d{1,2}[./-]\d{2,4})\b').firstMatch(text);
    if (any != null) return _normalizeDate(any.group(1)!);
    return null;
  }

  static String _normalizeDate(String raw) {
    final parts = raw.split(RegExp(r'[./-]'));
    if (parts.length != 3) return raw.trim();
    final d = parts[0].padLeft(2, '0');
    final m = parts[1].padLeft(2, '0');
    var y = parts[2];
    if (y.length == 2) y = '20$y';
    return '$d.$m.$y';
  }

  static String? _extractSupplier(String compact, List<String> lines) {
    // "tedarik tarihi" ile çakışmasın — tedarikçi / firma etiketleri.
    final labeled = _firstMatch(compact, [
      RegExp(
        r'(?:tedarikci|tedarik edilen firma|satici firma|satici|'
        r'firma adi|firma|unvan|gonderen)\s*[:#]?\s*(.+?)(?:\n|$)',
        caseSensitive: false,
      ),
    ]);
    if (labeled != null) {
      final cleaned = labeled.split(RegExp(r'\s{2,}|\t')).first.trim();
      if (cleaned.length >= 3 && !cleaned.startsWith('tarih')) {
        return cleaned;
      }
    }

    for (final line in lines.take(8)) {
      if (line.contains('ltd') ||
          line.contains('a.s') ||
          line.contains('san.') ||
          line.contains('tic.')) {
        return line;
      }
    }
    return null;
  }

  static List<IrsaliyeMaterialLine> _extractProducts(
    String compact,
    List<String> lines,
  ) {
    final out = <IrsaliyeMaterialLine>[];

    // Etiketli tek ürün.
    final name = _firstMatch(compact, [
      RegExp(
        r'(?:ürün|urun|malzeme|cinsi|cins|açıklama|aciklama|stok\s*adı|stok adi)'
        r'\s*[:#]?\s*(.+?)(?:\n|miktar|birim|fiyat|$)',
        caseSensitive: false,
      ),
    ]);
    final qty = _firstMatch(compact, [
      RegExp(
        r'(?:miktar|adet|qty|quantity)\s*[:#]?\s*(\d+[.,]?\d*)',
        caseSensitive: false,
      ),
    ]);
    final unitLabeled = _firstMatch(compact, [
      RegExp(
        r'(?:birim|unit)\s*[:#]?\s*([A-Za-zÇĞİÖŞÜçğıöşü]{1,8})',
        caseSensitive: false,
      ),
    ]);
    final unitQty = RegExp(
      r'\b(\d+[.,]?\d*)\s*(kg|ton|adet|ad|m3|m³|lt|l|m2|m²|paket|çuval|cuval)\b',
      caseSensitive: false,
    ).firstMatch(compact);
    final qtyVal = qty ?? unitQty?.group(1) ?? '';
    final unitVal = unitLabeled ?? unitQty?.group(2) ?? '';

    final price = _firstMatch(compact, [
      RegExp(
        r'(?:birim\s*)?fiyat(?:ı|i)?\s*[:#]?\s*(\d+[.,]?\d*)',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:tutar|bedel)\s*[:#]?\s*(\d+[.,]?\d*)',
        caseSensitive: false,
      ),
    ]);

    if (name != null && name.trim().isNotEmpty) {
      out.add(
        IrsaliyeMaterialLine(
          name: _cleanProductName(name),
          quantity: qtyVal,
          unit: unitVal,
          price: price ?? '',
        ),
      );
    }

    // Tablo satırları: "Ürün  12  kg  100"
    final rowRe = RegExp(
      r'^(.{3,60}?)\s+(\d+[.,]?\d*)\s+'
      r'(kg|ton|adet|ad|m3|m³|lt|l|m2|m²|paket|çuval|cuval|mt|m)\b'
      r'(?:\s+(\d+[.,]?\d*))?',
      caseSensitive: false,
    );
    for (final line in lines) {
      final low = line.toLowerCase();
      if (low.contains('miktar') && low.contains('birim')) continue;
      if (low.contains('toplam')) continue;
      final m = rowRe.firstMatch(line);
      if (m == null) continue;
      final n = _cleanProductName(m.group(1)!);
      if (n.length < 3) continue;
      if (_looksLikeHeader(n)) continue;
      final candidate = IrsaliyeMaterialLine(
        name: n,
        quantity: m.group(2) ?? '',
        unit: m.group(3) ?? '',
        price: m.group(4) ?? '',
      );
      if (!out.any((e) => e.name.toLowerCase() == n.toLowerCase())) {
        out.add(candidate);
      }
    }

    if (out.isEmpty && qtyVal.isNotEmpty) {
      out.add(
        IrsaliyeMaterialLine(
          name: '',
          quantity: qtyVal,
          unit: unitVal,
          price: price ?? '',
        ),
      );
    }

    return out;
  }

  static String _cleanProductName(String s) {
    return s
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^[\d.\-\s]+'), '')
        .trim();
  }

  static bool _looksLikeHeader(String s) {
    final low = s.toLowerCase();
    return low.contains('ürün') ||
        low.contains('urun') ||
        low.contains('malzeme') ||
        low.contains('miktar') ||
        low.contains('birim') ||
        low.contains('fiyat');
  }

  static String? _firstMatch(String text, List<RegExp> patterns) {
    for (final p in patterns) {
      final m = p.firstMatch(text);
      if (m == null) continue;
      final v = m.group(1)?.trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }
}
