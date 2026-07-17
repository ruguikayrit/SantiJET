/// Kolon (S/SB/SZ), perde (P/PS), kiriş (K/KB/KZ), döşeme (D/PSB) başlıkları.
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

  /// IdeCAD önekleri: SB/SZ/S → kolon, PS/P → perde, KB/KZ/K → kiriş, PSB/D → döşeme.
  static StructuralElementType fromCodeToken(String token) {
    final t = token.toUpperCase();
    if (t.startsWith('PSB')) return StructuralElementType.slab;
    if (t.startsWith('PS')) return StructuralElementType.wall;
    if (t.startsWith('SB') || t.startsWith('SZ')) {
      return StructuralElementType.column;
    }
    if (t.startsWith('KB') || t.startsWith('KZ')) {
      return StructuralElementType.beam;
    }
    if (t.startsWith('S')) return StructuralElementType.column;
    if (t.startsWith('P')) return StructuralElementType.wall;
    if (t.startsWith('K')) return StructuralElementType.beam;
    if (t.startsWith('D')) return StructuralElementType.slab;
    return StructuralElementType.unknown;
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

  /// En uzun önek önce (PSB > PS > SB > …).
  static const _prefix = r'(?:PSB|PS|SB|SZ|KB|KZ|[SPKD])';

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

  /// SB107 (35/30) · KB101 (30/50) · PSB102 25/255 · KZ01 (30/50)
  static final _ideCadSingle = RegExp(
    r'^(' +
        _prefix +
        r')(\d+)\s*'
            r'(?:[\(\[]\s*(\d+)\s*/\s*(\d+)\s*[\)\]]|(\d+)\s*/\s*(\d+))?'
            r'(?:\s+(?:PERDE|KOLON|KIRIS|DOSEME)?\s*(?:DETAYI)?)?'
            r'\s*$',
    caseSensitive: false,
  );

  /// SB101 - SB102 (30/80) · S01-S02 KOLON DETAYI · SZ01 - SZ02 (30/80)
  static final _ideCadRange = RegExp(
    r'^(' +
        _prefix +
        r')(\d+)\s*[-–]\s*(' +
        _prefix +
        r')(\d+)\s*'
            r'(?:[\(\[]\s*(\d+)\s*/\s*(\d+)\s*[\)\]])?'
            r'(?:\s+(?:PERDE|KOLON|KIRIS|DOSEME)?\s*(?:DETAYI)?)?'
            r'\s*$',
    caseSensitive: false,
  );

  /// KB101 / 29 ADET · K101 / 28 Adet
  static final _ideCadAdet = RegExp(
    r'^(' +
        _prefix +
        r')(\d+)\s*/\s*(\d+)\s*(?:ADET|ADT|AD)\.?\s*$',
    caseSensitive: false,
  );

  /// KESIT A-A KB102-KB103-KB104
  static final _kesitMulti = RegExp(
    r'KESIT\s+[A-Z0-9\-]+\s+(' +
        _prefix +
        r'\d+(?:\s*[-–]\s*' +
        _prefix +
        r'\d+)+)',
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

    final range = _ideCadRange.firstMatch(normalized);
    if (range != null) {
      return _fromRange(range, sourceText: raw.trim());
    }

    final adet = _ideCadAdet.firstMatch(normalized);
    if (adet != null) {
      final prefix = adet.group(1)!.toUpperCase();
      final idRaw = adet.group(2)!;
      final id = int.parse(idRaw);
      final benzer = int.parse(adet.group(3)!);
      return ElementHeader(
        type: StructuralElementType.fromCodeToken('$prefix$idRaw'),
        id: id,
        code: '$prefix$idRaw',
        benzerCount: benzer,
        sourceText: raw.trim(),
      );
    }

    final kesit = _kesitMulti.firstMatch(normalized);
    if (kesit != null) {
      return _fromKesitCodes(kesit.group(1)!, sourceText: raw.trim());
    }

    final ide = _ideCadSingle.firstMatch(normalized);
    if (ide != null) {
      return _fromIdeCadSingle(ide, sourceText: raw.trim());
    }

    final combined = _combined.firstMatch(normalized);
    if (combined != null) {
      return _fromClassicMatch(
        combined,
        sourceText: raw.trim(),
        benzer: int.parse(combined.group(4)!),
      );
    }

    final codeOnly = _codeOnly.firstMatch(normalized);
    if (codeOnly != null) {
      return _fromClassicMatch(
        codeOnly,
        sourceText: raw.trim(),
        benzer: 1,
      );
    }

    final embedded = _embedded.firstMatch(normalized);
    if (embedded != null) {
      return _fromClassicMatch(
        embedded,
        sourceText: raw.trim(),
        benzer: int.parse(embedded.group(4)!),
      );
    }

    final embeddedCode = _embeddedCodeOnly.firstMatch(normalized);
    if (embeddedCode != null) {
      return _fromClassicMatch(
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

  ElementHeader _fromIdeCadSingle(RegExpMatch match, {required String sourceText}) {
    final prefix = match.group(1)!.toUpperCase();
    final idRaw = match.group(2)!;
    final id = int.parse(idRaw);
    final dims = _dimsFromGroups(
      match.group(3),
      match.group(4),
      match.group(5),
      match.group(6),
    );
    return ElementHeader(
      type: StructuralElementType.fromCodeToken('$prefix$idRaw'),
      id: id,
      code: '$prefix$idRaw',
      benzerCount: 1,
      sourceText: sourceText,
      dimensionText: dims,
    );
  }

  ElementHeader _fromRange(RegExpMatch match, {required String sourceText}) {
    final p1 = match.group(1)!.toUpperCase();
    final id1Raw = match.group(2)!;
    final id1 = int.parse(id1Raw);
    final p2 = match.group(3)!.toUpperCase();
    final id2Raw = match.group(4)!;
    final id2 = int.parse(id2Raw);
    final w = match.group(5);
    final h = match.group(6);
    final dims = (w != null && h != null) ? '$w/$h' : null;

    final benzer = _rangeBenzerCount(p1, id1, p2, id2);
    final code = '$p1$id1Raw-$p2$id2Raw';

    return ElementHeader(
      type: StructuralElementType.fromCodeToken('$p1$id1Raw'),
      id: id1,
      code: code,
      benzerCount: benzer,
      sourceText: sourceText,
      dimensionText: dims,
    );
  }

  ElementHeader? _fromKesitCodes(String codesRaw, {required String sourceText}) {
    final parts = RegExp(
      _prefix + r'\d+',
      caseSensitive: false,
    ).allMatches(codesRaw).map((m) => m.group(0)!.toUpperCase()).toList();
    if (parts.isEmpty) return null;

    final first = parts.first;
    final idMatch = RegExp(r'(\d+)$').firstMatch(first);
    final id = int.tryParse(idMatch?.group(1) ?? '') ?? 0;

    return ElementHeader(
      type: StructuralElementType.fromCodeToken(first),
      id: id,
      code: parts.join('-'),
      benzerCount: parts.length,
      sourceText: sourceText,
    );
  }

  ElementHeader _fromClassicMatch(
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
      code: '${typeLetter.toUpperCase()}$id',
      benzerCount: benzer,
      sourceText: sourceText,
      dimensionText: dims?.isEmpty ?? true ? null : dims,
    );
  }

  String? _dimsFromGroups(String? a, String? b, String? c, String? d) {
    if (a != null && b != null) return '$a/$b';
    if (c != null && d != null) return '$c/$d';
    return null;
  }

  int _rangeBenzerCount(String p1, int id1, String p2, int id2) {
    if (p1 == p2 && id2 >= id1) {
      return id2 - id1 + 1;
    }
    return 2;
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
