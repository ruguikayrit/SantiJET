import 'package:santijet_demir/data/services/cad_text_preprocessor.dart';
import 'package:santijet_demir/data/services/rebar_weight_calculator.dart';

/// CAD metin etiketinden okunan tek demir satırı (adet + çap + boy).
class RebarTextEntry {
  const RebarTextEntry({
    required this.sourceText,
    required this.diameter,
    required this.lengthM,
    required this.quantity,
    this.spacingCm,
    this.role = RebarLabelRole.other,
  });

  final String sourceText;
  final int diameter;
  final double lengthM;
  final int quantity;
  final double? spacingCm;
  final RebarLabelRole role;
}

/// Metraj cetvelinde demir türü (Excel cetveli terminolojisi).
enum RebarLabelRole {
  longitudinal,
  bottomLongitudinal,
  topAssembly,
  stirrup,
  crosstie,
  mesh,
  other;

  String get label => switch (this) {
        RebarLabelRole.longitudinal => 'Boy donatı',
        RebarLabelRole.bottomLongitudinal => 'Alt donatı',
        RebarLabelRole.topAssembly => 'Üst montaj',
        RebarLabelRole.stirrup => 'Etriye',
        RebarLabelRole.crosstie => 'Çiroz',
        RebarLabelRole.mesh => 'Hasır / örgü',
        RebarLabelRole.other => 'Demir',
      };

  /// Excel cetvelindeki kısa başlık.
  String get shortLabel => switch (this) {
        RebarLabelRole.longitudinal => 'BOY',
        RebarLabelRole.bottomLongitudinal => 'ALT',
        RebarLabelRole.topAssembly => 'ÜST',
        RebarLabelRole.stirrup => 'ETR',
        RebarLabelRole.crosstie => 'ÇRZ',
        RebarLabelRole.mesh => 'ÖRGÜ',
        RebarLabelRole.other => 'DMR',
      };
}

/// TEXT / MTEXT içeriğinden adet, çap (FI/Ø/Φ) ve boy birlikte geçenleri okur.
///
/// Desteklenen IdeCAD / klasik pafta biçimleri (referans görseller):
/// - `42Ø28 L=280`, `12Φ18 L=270`
/// - `42Φ10/15/7/15/10 Etr. L=130`, `108Φ10 Çiroz L=53`
/// - `etr*18Ø12/10 L=510`, `Çiroz*12Ø12 L=170`
/// - `üst.334Ø22/15 l=1200`, `11Φ10/30 L=522`
/// - `5 2Φ12 L=446` (poz + adet)
/// - `1 Φ 16 L=150`, `2Φ12 L=441` (+ ilave notu)
class RebarTextParser {
  const RebarTextParser();

  /// Çap sembolü (preprocess sonrası çoğunlukla Ø).
  static const _dia = r'(?:FI|F[Iİ]|Ø|O|D|PHI)';

  /// üst.334Ø22/15 l=1200
  static final _locationLabel = RegExp(
    r'(UST|ALT)\.(\d+)' +
        _dia +
        r'(\d{1,2})\s*/\s*(\d+)\s*L\s*=\s*([\d.,]+)',
    caseSensitive: false,
  );

  /// 334Ø22/15 l=120 veya 11Ø10/30 L=522 (tek aralık)
  static final _spacingLabel = RegExp(
    r'(?:^|[^\d])(\d+)' +
        _dia +
        r'(\d{1,2})\s*/\s*(\d+)\s*L\s*=\s*([\d.,]+)',
    caseSensitive: false,
  );

  static final _spacingLabelShape = RegExp(
    r'\d+' + _dia + r'\d{1,2}\s*/\s*\d+\s*L\s*=',
    caseSensitive: false,
  );

  /// 42Ø10/15/7/15/10 ETR. L=130 · 35Ø10/15/9/10/10 ETR L=220
  static final _multiZoneRoleLength = RegExp(
    r'(\d+)\s*' +
        _dia +
        r'\s*(\d{1,2})(?:\s*/\s*\d+){1,8}\s*'
            r'(ETR|ETZ|CIROZ)\.?\s*L\s*=\s*([\d.,]+)',
    caseSensitive: false,
  );

  /// 108Ø10 CIROZ L=53 · 38Ø10 ETR. L=130 (aralıksız)
  static final _qtyDiaRoleLength = RegExp(
    r'(\d+)\s*' +
        _dia +
        r'\s*(\d{1,2})\s*(ETR|ETZ|CIROZ)\.?\s*L\s*=\s*([\d.,]+)',
    caseSensitive: false,
  );

  /// 15Ø10/25 ETR L=330 (tek aralık + rol)
  static final _spacingRoleLength = RegExp(
    r'(\d+)\s*' +
        _dia +
        r'\s*(\d{1,2})\s*/\s*(\d+)\s*(ETR|ETZ|CIROZ)\.?\s*L\s*=\s*([\d.,]+)',
    caseSensitive: false,
  );

  /// etr*18Ø12/10 L=510
  static final _stirrupLabel = RegExp(
    r'ETR\*(\d+)' + _dia + r'(\d{1,2})(?:\s*/\s*\d+)?\s*L\s*=\s*([\d.,]+)',
    caseSensitive: false,
  );

  /// Çiroz*12Ø12 L=170
  static final _crosstieLabel = RegExp(
    r'(?:CIROZ|ÇIROZ)\*(\d+)' + _dia + r'(\d{1,2})\s*L\s*=\s*([\d.,]+)',
    caseSensitive: false,
  );

  /// 5 2Ø12 L=446 (poz numarası + adet)
  static final _posQtyDiameterLength = RegExp(
    r'(?:^|[^\d])(\d{1,4})\s+(\d{1,3})\s*' +
        _dia +
        r'\s*(\d{1,2})\s*'
            r'(?:ILAVE\s*)?L\s*=\s*([\d.,]+)',
    caseSensitive: false,
  );

  /// 42Ø28 L=280 · 12Ø18 L=270 · 1Ø16 L=155 (ilave notu serbest)
  static final _qtyDiameterLength = RegExp(
    r'(?:^|[^\d])(\d+)\s*' +
        _dia +
        r'\s*(\d{1,2})\s*'
            r'(?:ILAVE\s*)?L\s*=\s*([\d.,]+)',
    caseSensitive: false,
  );

  /// 15000Ø16 l=200
  static final _quantityPrefix = RegExp(
    r'(\d+)\s*' + _dia + r'\s*(\d{1,2})\s*L\s*=\s*([\d.,]+)',
    caseSensitive: false,
  );

  static final _quantityX = RegExp(
    r'(\d+)\s*[xX×]\s*' + _dia + r'?\s*(\d{1,2})\s*[/\-xX×]\s*([\d.,]+)',
    caseSensitive: false,
  );

  static final _quantityAdet = RegExp(
    r'(\d+)\s*(?:ADET|ADT|AD)\.?\s*' +
        _dia +
        r'\s*(\d{1,2})\s*[/\-xX×\sL=]+([\d.,]+)',
    caseSensitive: false,
  );

  static final _quantityAdetReverse = RegExp(
    r'(\d+)\s*(?:ADET|ADT|AD)\.?\s*(\d{1,2})\s*' +
        _dia +
        r'\s*[/\-xX×\sL=]+([\d.,]+)',
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

  /// İki komşu CAD metnini birleştirip dener (örn. `15Ø10/25` + `Etz. L=330`).
  RebarTextEntry? parseJoined(String first, String second) {
    final a = first.trim();
    final b = second.trim();
    if (a.isEmpty || b.isEmpty) return null;
    return parseOne('$a $b') ?? parseOne('$b $a');
  }

  /// Boyu olmayan kısmi etiket mi? (birleştirme adayı)
  bool looksIncomplete(String raw) {
    final cleaned = preprocessCadText(raw);
    if (cleaned.isEmpty) return false;
    final n = _normalize(cleaned);
    final hasDia = RegExp(
      r'(?:FI|F[Iİ]|Ø|O|D|PHI)\s*\d{1,2}|\d{1,2}\s*(?:FI|F[Iİ]|Ø|O|D|PHI)',
      caseSensitive: false,
    ).hasMatch(n);
    final hasL = RegExp(r'L\s*=\s*[\d.,]+', caseSensitive: false).hasMatch(n);
    final roleOnly = RegExp(
      r'^(?:ETR|ETZ|CIROZ)\.?\s*L\s*=\s*[\d.,]+$',
      caseSensitive: false,
    ).hasMatch(n);
    if (roleOnly) return true;
    if (hasDia && !hasL) return true;
    if (hasL && !hasDia) return true;
    return false;
  }

  RebarTextEntry? parseOne(String raw) {
    final cleaned = preprocessCadText(raw);
    if (cleaned.isEmpty) return null;

    final normalized = _normalize(cleaned);
    if (!_looksLikeRebarLabel(normalized)) return null;

    return _matchRolePostfix(_multiZoneRoleLength, normalized, cleaned) ??
        _matchRolePostfix(_qtyDiaRoleLength, normalized, cleaned) ??
        _matchSpacingRole(normalized, cleaned) ??
        _matchStirrupOrCrosstie(
          _stirrupLabel,
          normalized,
          cleaned,
          RebarLabelRole.stirrup,
        ) ??
        _matchStirrupOrCrosstie(
          _crosstieLabel,
          normalized,
          cleaned,
          RebarLabelRole.crosstie,
        ) ??
        _matchPosQtyDiameterLength(normalized, cleaned) ??
        _matchQtyDiameterLength(normalized, cleaned) ??
        _matchLocationLabel(_locationLabel, normalized, cleaned) ??
        _matchLocationLabel(_spacingLabel, normalized, cleaned) ??
        _matchQuantity(_quantityX, normalized, cleaned) ??
        _matchQuantity(_quantityPrefix, normalized, cleaned) ??
        _matchQuantity(_quantityAdet, normalized, cleaned) ??
        _matchQuantity(_quantityAdetReverse, normalized, cleaned);
  }

  RebarTextEntry? _matchRolePostfix(
    RegExp pattern,
    String normalized,
    String displayText,
  ) {
    final match = pattern.firstMatch(normalized);
    if (match == null) return null;

    final quantity = int.tryParse(match.group(1)!);
    final diameter = int.tryParse(match.group(2)!);
    final roleToken = match.group(3)!.toUpperCase();
    final length = _parseSimpleLength(match.group(4)!);

    if (quantity == null ||
        quantity <= 0 ||
        !_isValidDiameter(diameter) ||
        length == null ||
        length <= 0) {
      return null;
    }

    final role = switch (roleToken) {
      'CIROZ' => RebarLabelRole.crosstie,
      'ETR' || 'ETZ' => RebarLabelRole.stirrup,
      _ => RebarLabelRole.stirrup,
    };

    return RebarTextEntry(
      sourceText: displayText,
      diameter: diameter!,
      lengthM: length,
      quantity: quantity,
      role: role,
    );
  }

  RebarTextEntry? _matchSpacingRole(String normalized, String displayText) {
    final match = _spacingRoleLength.firstMatch(normalized);
    if (match == null) return null;

    final quantity = int.tryParse(match.group(1)!);
    final diameter = int.tryParse(match.group(2)!);
    final spacing = int.tryParse(match.group(3)!);
    final roleToken = match.group(4)!.toUpperCase();
    final length = _parseSimpleLength(match.group(5)!);

    if (quantity == null ||
        quantity <= 0 ||
        !_isValidDiameter(diameter) ||
        length == null ||
        length <= 0) {
      return null;
    }

    final role = roleToken == 'CIROZ'
        ? RebarLabelRole.crosstie
        : RebarLabelRole.stirrup;

    return RebarTextEntry(
      sourceText: displayText,
      diameter: diameter!,
      lengthM: length,
      quantity: quantity,
      spacingCm: spacing?.toDouble(),
      role: role,
    );
  }

  RebarTextEntry? _matchStirrupOrCrosstie(
    RegExp pattern,
    String normalized,
    String displayText,
    RebarLabelRole role,
  ) {
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
      role: role,
    );
  }

  RebarTextEntry? _matchPosQtyDiameterLength(
    String normalized,
    String displayText,
  ) {
    final match = _posQtyDiameterLength.firstMatch(normalized);
    if (match == null) return null;

    // group1 = poz (yoksay), group2 = adet
    final quantity = int.tryParse(match.group(2)!);
    final diameter = int.tryParse(match.group(3)!);
    final length = _parseSimpleLength(match.group(4)!);

    if (quantity == null ||
        quantity <= 0 ||
        !_isValidDiameter(diameter) ||
        length == null ||
        length <= 0) {
      return null;
    }

    final pos = int.tryParse(match.group(1)!);
    if (pos == null || pos > 500) return null;

    return RebarTextEntry(
      sourceText: displayText,
      diameter: diameter!,
      lengthM: length,
      quantity: quantity,
      role: _roleFromNotes(normalized),
    );
  }

  RebarTextEntry? _matchQtyDiameterLength(
    String normalized,
    String displayText,
  ) {
    if (_posQtyDiameterLength.hasMatch(normalized) &&
        RegExp(r'\d+\s+\d+\s*(?:FI|Ø|O|D|PHI)', caseSensitive: false)
            .hasMatch(normalized)) {
      return null;
    }

    final match = _qtyDiameterLength.firstMatch(normalized);
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
      role: _roleFromNotes(normalized),
    );
  }

  RebarLabelRole _roleFromNotes(String normalized) {
    if (normalized.contains('ILAVE')) {
      return RebarLabelRole.longitudinal;
    }
    if (normalized.contains('MONTAJ') || normalized.contains('UST')) {
      return RebarLabelRole.topAssembly;
    }
    if (normalized.contains('DUZ') || normalized.contains('ALT')) {
      return RebarLabelRole.bottomLongitudinal;
    }
    return RebarLabelRole.longitudinal;
  }

  bool _looksLikeRebarLabel(String normalized) {
    if (_spacingLabelShape.hasMatch(normalized)) return true;
    if (_multiZoneRoleLength.hasMatch(normalized)) return true;
    if (_qtyDiaRoleLength.hasMatch(normalized)) return true;
    if (_spacingRoleLength.hasMatch(normalized)) return true;

    if (RegExp(
      r'\d+\s*[xX×]\s*(?:FI|F[Iİ]|Ø|O|D|PHI)?\s*\d{1,2}\s*[/\-xX×]',
      caseSensitive: false,
    ).hasMatch(normalized)) {
      return true;
    }

    if (_stirrupLabel.hasMatch(normalized) ||
        _crosstieLabel.hasMatch(normalized) ||
        _qtyDiameterLength.hasMatch(normalized) ||
        _posQtyDiameterLength.hasMatch(normalized)) {
      return true;
    }

    final hasDiameter = RegExp(
      r'(?:FI|F[Iİ]|Ø|O|D|PHI)\s*\d{1,2}|\d{1,2}\s*(?:FI|F[Iİ]|Ø|O|D|PHI)',
      caseSensitive: false,
    ).hasMatch(normalized);
    final hasQuantity = RegExp(
      r'(?:^|[^\d])\d+\s*(?:[xX×]|ADET|ADT|AD\.?|(?:FI|F[Iİ]|Ø|O|D|PHI))',
      caseSensitive: false,
    ).hasMatch(normalized);
    final hasLength = RegExp(
      r'L\s*=\s*[\d.,]+',
      caseSensitive: false,
    ).hasMatch(normalized);

    return hasDiameter && hasQuantity && hasLength;
  }

  RebarTextEntry? _matchLocationLabel(
    RegExp pattern,
    String normalized,
    String displayText,
  ) {
    final match = pattern.firstMatch(normalized);
    if (match == null) return null;

    RebarLabelRole role = RebarLabelRole.longitudinal;
    int groupOffset = 0;

    if (pattern == _locationLabel) {
      final location = match.group(1)!;
      role = location == 'UST'
          ? RebarLabelRole.topAssembly
          : RebarLabelRole.bottomLongitudinal;
      groupOffset = 1;
    }

    final quantity = int.tryParse(match.group(1 + groupOffset)!);
    final diameter = int.tryParse(match.group(2 + groupOffset)!);
    final spacing = int.tryParse(match.group(3 + groupOffset)!);
    final lengthRaw =
        double.tryParse(match.group(4 + groupOffset)!.replaceAll(',', '.'));

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
      spacingCm: spacing?.toDouble(),
      role: role,
    );
  }

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
      role: _roleFromNotes(normalized),
    );
  }

  double _parseLocationLength(double value) {
    return value / 100;
  }

  /// L= değeri: ≥20 → cm, aksi halde m.
  double? _parseSimpleLength(String raw) {
    final value = double.tryParse(raw.replaceAll(',', '.'));
    if (value == null || value <= 0) return null;
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
