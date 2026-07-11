/// Kolon (S), perde (P), kiriş (K), döşeme (D) başlık satırlarını okur.
enum StructuralElementType {
  column,
  wall,
  beam,
  slab,
  unknown;

  String get codeLetter => switch (this) {
        StructuralElementType.column => 'S',
        StructuralElementType.wall => 'P',
        StructuralElementType.beam => 'K',
        StructuralElementType.slab => 'D',
        StructuralElementType.unknown => '?',
      };

  String get label => switch (this) {
        StructuralElementType.column => 'Kolon',
        StructuralElementType.wall => 'Perde',
        StructuralElementType.beam => 'Kiriş',
        StructuralElementType.slab => 'Döşeme',
        StructuralElementType.unknown => 'Eleman',
      };

  static StructuralElementType fromLetter(String? letter) {
    return switch (letter?.toUpperCase()) {
      'S' => StructuralElementType.column,
      'P' => StructuralElementType.wall,
      'K' => StructuralElementType.beam,
      'D' => StructuralElementType.slab,
      _ => StructuralElementType.unknown,
    };
  }
}

class ElementHeader {
  const ElementHeader({
    required this.type,
    required this.id,
    required this.code,
    required this.benzerCount,
    required this.sourceText,
    this.dimensionText,
  });

  final StructuralElementType type;
  final int id;
  final String code;
  final int benzerCount;
  final String sourceText;
  final String? dimensionText;

  String get title {
    final dims = dimensionText?.trim();
    if (dims != null && dims.isNotEmpty) {
      return '$code - $dims';
    }
    return code;
  }

  String get subtitle => 'Benzer × ${benzerCount} adet';
}

class ElementHeaderParser {
  const ElementHeaderParser();

  /// S1[100/160] 182 ADET
  static final _combined = RegExp(
    r'^([SPKD])\s*(\d+)\s*(?:[\[(]([^\])]+)[\])])?\s*(\d+)\s*(?:ADET|ADT|AD)\.?\s*$',
    caseSensitive: false,
  );

  /// S1[100/160]
  static final _codeOnly = RegExp(
    r'^([SPKD])\s*(\d+)\s*(?:[\[(]([^\])]+)[\])])?\s*$',
    caseSensitive: false,
  );

  /// Satır içinde: P1[40/240] 36 ADET
  static final _embedded = RegExp(
    r'([SPKD])\s*(\d+)\s*(?:[\[(]([^\])]+)[\])])?\s*(\d+)\s*(?:ADET|ADT|AD)\.?\b',
    caseSensitive: false,
  );

  /// Satır içinde: P1[40/240]
  static final _embeddedCodeOnly = RegExp(
    r'([SPKD])\s*(\d+)\s*(?:[\[(]([^\])]+)[\])])\b',
    caseSensitive: false,
  );

  /// 182 ADET
  static final _benzerOnly = RegExp(
    r'^(\d+)\s*(?:ADET|ADT|AD)\.?\s*$',
    caseSensitive: false,
  );

  ElementHeader? tryParse(String raw) {
    final normalized = _normalize(raw);
    if (normalized.isEmpty) return null;

    final combined = _combined.firstMatch(normalized);
    if (combined != null) {
      return _fromMatch(
        combined,
        sourceText: raw.trim(),
        benzer: int.parse(combined.group(4)!),
      );
    }

    final codeOnly = _codeOnly.firstMatch(normalized);
    if (codeOnly != null) {
      return _fromMatch(
        codeOnly,
        sourceText: raw.trim(),
        benzer: 1,
      );
    }

    final embedded = _embedded.firstMatch(normalized);
    if (embedded != null) {
      return _fromMatch(
        embedded,
        sourceText: raw.trim(),
        benzer: int.parse(embedded.group(4)!),
      );
    }

    final embeddedCode = _embeddedCodeOnly.firstMatch(normalized);
    if (embeddedCode != null) {
      return _fromMatch(
        embeddedCode,
        sourceText: raw.trim(),
        benzer: 1,
      );
    }

    return null;
  }

  int? tryParseBenzerOnly(String raw) {
    final normalized = _normalize(raw);
    final match = _benzerOnly.firstMatch(normalized);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  ElementHeader _fromMatch(
    RegExpMatch match, {
    required String sourceText,
    required int benzer,
  }) {
    final typeLetter = match.group(1)!;
    final id = int.parse(match.group(2)!);
    final dims = match.group(3)?.trim();
    final type = StructuralElementType.fromLetter(typeLetter);
    return ElementHeader(
      type: type,
      id: id,
      code: '$typeLetter$id',
      benzerCount: benzer,
      sourceText: sourceText,
      dimensionText: dims?.isEmpty ?? true ? null : dims,
    );
  }

  String _normalize(String value) {
    return value
        .trim()
        .toUpperCase()
        .replaceAll('İ', 'I')
        .replaceAll('Ş', 'S')
        .replaceAll('Ğ', 'G')
        .replaceAll('Ü', 'U')
        .replaceAll('Ö', 'O')
        .replaceAll('Ç', 'C')
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}
