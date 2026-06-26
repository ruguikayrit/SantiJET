import 'package:santijet_demir/data/services/cad_text_preprocessor.dart';
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

  /// üst.334Ø22/15 l=120  → 334 adet, Ø22, l=120 → 12 m (/15 sadece bilgi)
  static final _locationLabel = RegExp(
    r'(?:UST|ALT)\.(\d+)(?:FI|F[Iİ]|Ø|O|D)(\d{2})/(\d+)\s*L\s*=\s*([\d.,]+)',
    caseSensitive: false,
  );

  /// 334Ø22/15 l=120 (üst/alt öneki olmadan)
  static final _spacingLabel = RegExp(
    r'(?:^|[^\d])(\d+)(?:FI|F[Iİ]|Ø|O|D)(\d{2})/(\d+)\s*L\s*=\s*([\d.,]+)',
    caseSensitive: false,
  );

  static final _spacingLabelShape = RegExp(
    r'\d+(?:FI|F[Iİ]|Ø|O|D)\d{2}/\d+\s*L\s*=',
    caseSensitive: false,
  );

  /// 15000Ø16 l=200 → 15000 adet, l=200 → 2 m
  static final _quantityPrefix = RegExp(
    r'(\d+)\s*(?:FI|F[Iİ]|Ø|O|D)\s*(\d{2})\s*L\s*=\s*([\d.,]+)',
    caseSensitive: false,
  );

  static final _quantityX = RegExp(
    r'(\d+)\s*[xX×]\s*(?:FI|F[Iİ]|Ø|O|D)?\s*(\d{2})\s*[/\-xX×]\s*([\d.,]+)',
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

  List<RebarTextEntry> parseAll(Iterable<String> texts) {
    final entries = <RebarTextEntry>[];
    for (final raw in texts) {
      final entry = parseOne(raw);
      if (entry != null) entries.add(entry);
    }
    return entries;
  }

  RebarTextEntry? parseOne(String raw) {
    final cleaned = preprocessCadText(raw);
    if (cleaned.isEmpty) return null;

    final normalized = _normalize(cleaned);
    if (!_looksLikeRebarLabel(normalized)) return null;

    return _matchLocationLabel(_locationLabel, normalized, cleaned) ??
        _matchLocationLabel(_spacingLabel, normalized, cleaned) ??
        _matchQuantity(_quantityX, normalized, cleaned) ??
        _matchQuantity(_quantityPrefix, normalized, cleaned) ??
        _matchQuantity(_quantityAdet, normalized, cleaned) ??
        _matchQuantity(_quantityAdetReverse, normalized, cleaned);
  }

  bool _looksLikeRebarLabel(String normalized) {
    if (_spacingLabelShape.hasMatch(normalized)) {
      return true;
    }

    final hasDiameter = RegExp(
      r'(?:FI|F[Iİ]|Ø|O|D)\s*\d{2}|\d{2}\s*(?:FI|F[Iİ]|Ø|O|D)',
      caseSensitive: false,
    ).hasMatch(normalized);
    final hasQuantity = RegExp(
      r'(?:^|[^\d])\d+\s*(?:[xX×]|ADET|ADT|AD\.?|(?:FI|F[Iİ]|Ø|O|D))',
      caseSensitive: false,
    ).hasMatch(normalized);
    final hasLength = RegExp(
      r'L\s*=\s*[\d.,]+',
      caseSensitive: false,
    ).hasMatch(normalized);

    return hasDiameter && hasQuantity && hasLength;
  }

  /// üst./alt. veya NØcap/aralık l=boy formatı.
  /// İlk sayı = adet, /aralık sadece bilgi, l= → metre.
  RebarTextEntry? _matchLocationLabel(
    RegExp pattern,
    String normalized,
    String displayText,
  ) {
    final match = pattern.firstMatch(normalized);
    if (match == null) return null;

    final quantity = int.tryParse(match.group(1)!);
    final diameter = int.tryParse(match.group(2)!);
    final lengthRaw = double.tryParse(match.group(4)!.replaceAll(',', '.'));

    if (quantity == null ||
        quantity <= 0 ||
        lengthRaw == null ||
        lengthRaw <= 0 ||
        !_isValidDiameter(diameter)) {
      return null;
    }

    final lengthM = _parseLocationLength(lengthRaw);
    if (lengthM <= 0) return null;

    return RebarTextEntry(
      sourceText: displayText,
      diameter: diameter!,
      lengthM: lengthM,
      quantity: quantity,
    );
  }

  /// 15000Ø16 l=200 gibi doğrudan adet + l= formatı.
  RebarTextEntry? _matchQuantity(
    RegExp pattern,
    String normalized,
    String displayText,
  ) {
    if (_spacingLabelShape.hasMatch(normalized)) {
      return null;
    }

    final match = pattern.firstMatch(normalized);
    if (match == null) return null;

    final quantity = int.tryParse(match.group(1)!);
    final diameter = int.tryParse(match.group(2)!);
    final length = _parseSimpleLength(match.group(3)!);

    if (quantity == null ||
        quantity <= 0 ||
        !_isValidDiameter(diameter) ||
        length == null ||
        length <= 0) {
      return null;
    }

    return RebarTextEntry(
      sourceText: displayText,
      diameter: diameter!,
      lengthM: length,
      quantity: quantity,
    );
  }

  /// üst./alt. l= değeri: l=120 → 12 m, l=1200 → 12 m.
  double _parseLocationLength(double value) {
    if (value >= 1000) return value / 100;
    if (value >= 100) return value / 10;
    return value;
  }

  /// 15000Ø16 l=200 → l=200 cm = 2 m.
  double? _parseSimpleLength(String raw) {
    final value = double.tryParse(raw.replaceAll(',', '.'));
    if (value == null || value <= 0) return null;
    if (value >= 100) return value / 100;
    if (value >= 20) return value / 100;
    return value;
  }

  bool _isValidDiameter(int? diameter) {
    return diameter != null &&
        RebarWeightCalculator.standardDiameters.contains(diameter);
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
