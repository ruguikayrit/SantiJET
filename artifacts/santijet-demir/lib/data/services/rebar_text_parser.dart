import 'package:santijet_demir/data/services/rebar_weight_calculator.dart';

/// CAD metin etiketinden okunan tek demir satırı (adet + çap + boy).
class RebarTextEntry {
  const RebarTextEntry({
    required this.sourceText,
    required this.diameter,
    required this.lengthM,
    required this.quantity,
  });

  final String sourceText;
  final int diameter;
  final double lengthM;
  final int quantity;
}

/// TEXT / MTEXT içeriğinden adet, çap (FI/Ø) ve boy birlikte geçenleri okur.
class RebarTextParser {
  const RebarTextParser();

  static final _quantityX = RegExp(
    r'(\d+)\s*[xX×]\s*(?:FI|F[Iİ]|Ø|O|D)?\s*(\d{2})\s*[/\-xX×]\s*([\d.,]+)',
    caseSensitive: false,
  );

  static final _quantityPrefix = RegExp(
    r'(\d+)\s*(?:FI|F[Iİ]|Ø|O|D)\s*(\d{2})\s*[/\-xX×\sL=]+([\d.,]+)',
    caseSensitive: false,
  );

  static final _quantityAdet = RegExp(
    r'(\d+)\s*(?:ADET|ADT|AD)\.?\s*(?:FI|F[Iİ]|Ø|O|D)\s*(\d{2})\s*[/\-xX×\sL=]+([\d.,]+)',
    caseSensitive: false,
  );

  static final _quantityAdetReverse = RegExp(
    r'(\d+)\s*(?:ADET|ADT|AD)\.?\s*(\d{2})\s*(?:FI|F[Iİ]|Ø|O|D)\s*[/\-xX×\sL=]+([\d.,]+)',
    caseSensitive: false,
  );

  /// Adet + çap + boy birlikte geçen metinleri döndürür.
  List<RebarTextEntry> parseAll(Iterable<String> texts) {
    final entries = <RebarTextEntry>[];
    for (final raw in texts) {
      final entry = parseOne(raw);
      if (entry != null) entries.add(entry);
    }
    return entries;
  }

  RebarTextEntry? parseOne(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;

    final normalized = _normalize(text);
    if (!_looksLikeRebarLabel(normalized)) return null;

    return _matchQuantity(_quantityX, normalized, text) ??
        _matchQuantity(_quantityPrefix, normalized, text) ??
        _matchQuantity(_quantityAdet, normalized, text) ??
        _matchQuantity(_quantityAdetReverse, normalized, text);
  }

  bool _looksLikeRebarLabel(String normalized) {
    final hasDiameter = RegExp(
      r'(?:FI|F[Iİ]|Ø|O|D)\s*\d{2}|\d{2}\s*(?:FI|F[Iİ]|Ø|O|D)',
      caseSensitive: false,
    ).hasMatch(normalized);
    final hasQuantity = RegExp(
      r'(?:^|\s)\d+\s*(?:[xX×]|ADET|ADT|AD\.?|\s*(?:FI|F[Iİ]|Ø|O|D))',
      caseSensitive: false,
    ).hasMatch(normalized);
    final hasLength = RegExp(
      r'[/\-xX×\sL=]+[\d.,]+|[\d.,]+\s*(?:MM|CM|M)?(?:\s|$)',
      caseSensitive: false,
    ).hasMatch(normalized);

    return hasDiameter && hasQuantity && hasLength;
  }

  RebarTextEntry? _matchQuantity(
    RegExp pattern,
    String normalized,
    String originalText,
  ) {
    final match = pattern.firstMatch(normalized);
    if (match == null) return null;

    final quantity = int.tryParse(match.group(1)!);
    final diameter = int.tryParse(match.group(2)!);
    final length = _parseLength(match.group(3)!);

    if (quantity == null ||
        quantity <= 0 ||
        !_isValidDiameter(diameter) ||
        length == null ||
        length <= 0) {
      return null;
    }

    return RebarTextEntry(
      sourceText: originalText,
      diameter: diameter!,
      lengthM: length,
      quantity: quantity,
    );
  }

  bool _isValidDiameter(int? diameter) {
    return diameter != null &&
        RebarWeightCalculator.standardDiameters.contains(diameter);
  }

  double? _parseLength(String raw) {
    final value = double.tryParse(raw.replaceAll(',', '.'));
    if (value == null || value <= 0) return null;
    return _lengthToMeters(value);
  }

  /// Türkiye'de yaygın birimler: mm (3500), cm (350), m (3.50).
  double _lengthToMeters(double value) {
    if (value >= 1000) return value / 1000;
    if (value >= 100) return value / 100;
    if (value >= 20) return value / 100;
    return value;
  }

  String _normalize(String value) {
    return value
        .toUpperCase()
        .replaceAll('İ', 'I')
        .replaceAll('Ş', 'S')
        .replaceAll('Ğ', 'G')
        .replaceAll('Ü', 'U')
        .replaceAll('Ö', 'O')
        .replaceAll('Ç', 'C');
  }
}
