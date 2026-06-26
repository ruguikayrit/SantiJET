import 'dart:math';

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

  /// üst.1670Ø22/15 l=1200  ·  alt.12Ø22/15 l=640
  static final _locationSpacingLength = RegExp(
    r'(?:UST|ALT)\.(\d+)(?:FI|F[Iİ]|Ø|O|D)(\d{2})/(\d+)\s*L\s*=\s*([\d.,]+)',
    caseSensitive: false,
  );

  /// 1670Ø22/15 l=1200  (üst/alt öneki olmadan)
  static final _spacingLength = RegExp(
    r'(?:^|[^\d])(\d+)(?:FI|F[Iİ]|Ø|O|D)(\d{2})/(\d+)\s*L\s*=\s*([\d.,]+)',
    caseSensitive: false,
  );

  static final _spacingDistributionLabel = RegExp(
    r'\d+(?:FI|F[Iİ]|Ø|O|D)\d{2}/\d+\s*L\s*=',
    caseSensitive: false,
  );

  static final _quantityX = RegExp(
    r'(\d+)\s*[xX×]\s*(?:FI|F[Iİ]|Ø|O|D)?\s*(\d{2})\s*[/\-xX×]\s*([\d.,]+)',
    caseSensitive: false,
  );

  static final _quantityPrefix = RegExp(
    r'(\d+)\s*(?:FI|F[Iİ]|Ø|O|D)\s*(\d{2})\s*L\s*=\s*([\d.,]+)',
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

  /// 100'den küçük sayı doğrudan adet; büyükse dağıtım uzunluğu (mm) kabul edilir.
  static const explicitQuantityThreshold = 100;

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
    final cleaned = preprocessCadText(raw);
    if (cleaned.isEmpty) return null;

    final normalized = _normalize(cleaned);
    if (!_looksLikeRebarLabel(normalized)) return null;

    return _matchSpacingLength(_locationSpacingLength, normalized, cleaned) ??
        _matchSpacingLength(_spacingLength, normalized, cleaned) ??
        _matchQuantity(_quantityX, normalized, cleaned) ??
        _matchQuantity(_quantityPrefix, normalized, cleaned) ??
        _matchQuantity(_quantityAdet, normalized, cleaned) ??
        _matchQuantity(_quantityAdetReverse, normalized, cleaned);
  }

  bool _looksLikeRebarLabel(String normalized) {
    if (_spacingDistributionLabel.hasMatch(normalized)) {
      return true;
    }

    final hasDiameter = RegExp(
      r'(?:FI|F[Iİ]|Ø|O|D)\s*\d{2}|\d{2}\s*((?:FI|F[Iİ]|Ø|O|D))',
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

  RebarTextEntry? _matchSpacingLength(
    RegExp pattern,
    String normalized,
    String displayText,
  ) {
    final match = pattern.firstMatch(normalized);
    if (match == null) return null;

    final firstNumber = int.tryParse(match.group(1)!);
    final diameter = int.tryParse(match.group(2)!);
    final spacingCm = int.tryParse(match.group(3)!);
    final lengthMm = double.tryParse(match.group(4)!.replaceAll(',', '.'));

    if (firstNumber == null ||
        spacingCm == null ||
        spacingCm <= 0 ||
        lengthMm == null ||
        lengthMm <= 0 ||
        !_isValidDiameter(diameter)) {
      return null;
    }

    final quantity = _resolveDistributionQuantity(firstNumber, spacingCm);
    if (quantity <= 0) return null;

    // üst./alt. formatında l= değeri mm cinsindendir (l=1200 → 1,20 m).
    final lengthM = lengthMm / 1000.0;

    return RebarTextEntry(
      sourceText: displayText,
      diameter: diameter!,
      lengthM: lengthM,
      quantity: quantity,
    );
  }

  RebarTextEntry? _matchQuantity(
    RegExp pattern,
    String normalized,
    String displayText,
  ) {
    if (_spacingDistributionLabel.hasMatch(normalized)) {
      return null;
    }

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
      sourceText: displayText,
      diameter: diameter!,
      lengthM: length,
      quantity: quantity,
    );
  }

  /// [distributionOrCountMm]: üst./alt. sonrası sayı.
  /// <100 → doğrudan adet (alt.12), >=100 → dağıtım uzunluğu mm (üst.1670).
  int _resolveDistributionQuantity(int distributionOrCountMm, int spacingCm) {
    if (distributionOrCountMm < explicitQuantityThreshold) {
      return distributionOrCountMm;
    }

    final spacingMm = spacingCm * 10.0;
    return max(1, (distributionOrCountMm / spacingMm).ceil());
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
