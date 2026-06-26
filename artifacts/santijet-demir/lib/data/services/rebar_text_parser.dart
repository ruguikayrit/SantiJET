import 'package:santijet_demir/data/services/rebar_weight_calculator.dart';

/// CAD metin etiketinden okunan tek demir satırı (çap + boy).
class RebarTextEntry {
  const RebarTextEntry({
    required this.sourceText,
    required this.diameter,
    required this.lengthM,
    this.quantity = 1,
  });

  final String sourceText;
  final int diameter;
  final double lengthM;
  final int quantity;
}

/// TEXT / MTEXT içeriğinden çap ve boy bilgisini çıkarır.
class RebarTextParser {
  const RebarTextParser();

  static final _quantityDiameterLength = RegExp(
    r'(\d+)\s*[xX×]\s*(?:FI|F[Iİ]|Ø|O|D)?\s*(\d{2})\s*[/\-xX×]\s*([\d.,]+)',
    caseSensitive: false,
  );

  static final _quantityPrefixDiameter = RegExp(
    r'(\d+)\s*(?:FI|F[Iİ]|Ø|O|D)\s*(\d{2})\s*[/\-xX×\sL=]+([\d.,]+)',
    caseSensitive: false,
  );

  static final _symbolDiameterLength = RegExp(
    r'(?:FI|F[Iİ]|Ø|O|D)\s*(\d{2})\s*[/\-xX×\sL=]*([\d.,]+)',
    caseSensitive: false,
  );

  static final _diameterSymbolLength = RegExp(
    r'(\d{2})\s*(?:FI|F[Iİ]|Ø|O|D)\s*[/\-xX×\sL=]*([\d.,]+)',
    caseSensitive: false,
  );

  static final _slashPair = RegExp(
    r'(?:^|[^\d])(\d{2})\s*/\s*([\d.,]+)(?:[^\d]|$)',
    caseSensitive: false,
  );

  /// Tüm metinleri tarar; çap ve boy birlikte geçenleri döndürür.
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

    RebarTextEntry? matchQuantity(
      RegExp pattern,
      List<int> groupIndexes,
    ) {
      final match = pattern.firstMatch(normalized);
      if (match == null) return null;

      final quantity = int.tryParse(match.group(groupIndexes[0])!) ?? 1;
      final diameter = int.tryParse(match.group(groupIndexes[1])!);
      final length = _parseLength(match.group(groupIndexes[2])!);
      if (!_isValidDiameter(diameter) || length == null || length <= 0) {
        return null;
      }

      return RebarTextEntry(
        sourceText: text,
        diameter: diameter!,
        lengthM: length,
        quantity: quantity > 0 ? quantity : 1,
      );
    }

    RebarTextEntry? matchPair(
      RegExp pattern,
      List<int> groupIndexes, {
      int quantity = 1,
    }) {
      final match = pattern.firstMatch(normalized);
      if (match == null) return null;

      final diameter = int.tryParse(match.group(groupIndexes[0])!);
      final length = _parseLength(match.group(groupIndexes[1])!);
      if (!_isValidDiameter(diameter) || length == null || length <= 0) {
        return null;
      }

      return RebarTextEntry(
        sourceText: text,
        diameter: diameter!,
        lengthM: length,
        quantity: quantity,
      );
    }

    return matchQuantity(_quantityDiameterLength, [1, 2, 3]) ??
        matchQuantity(_quantityPrefixDiameter, [1, 2, 3]) ??
        matchPair(_diameterSymbolLength, [1, 2]) ??
        matchPair(_symbolDiameterLength, [1, 2]) ??
        matchPair(_slashPair, [1, 2]);
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
