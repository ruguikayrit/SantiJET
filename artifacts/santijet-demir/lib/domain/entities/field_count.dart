class ReconciliationRow {
  const ReconciliationRow({
    required this.diameter,
    required this.survey,
    required this.ordered,
    required this.delivered,
    required this.plannedUsage,
    required this.expectedStock,
    required this.counted,
    required this.used,
  });

  final int diameter;
  final double survey;
  final double ordered;
  final double delivered;

  /// Plan — ilerleme oranına göre beklenen kullanım (ana sayfa ile aynı).
  final double plannedUsage;

  /// Plan — sahada kalması beklenen stok (teslim − plan kullanım).
  final double expectedStock;

  /// Gerçek — saha sayımı.
  final double counted;

  /// Gerçek — kullanılan demir (teslim − sayım).
  final double used;

  /// Fire = gerçek kullanım − planlanan kullanım.
  /// Doğru veride pozitif çıkması beklenir (fire / hurda).
  double get fire => used - plannedUsage;

  String get status {
    if (fire < 0) {
      final abs = fire.abs();
      if (abs <= 2) return 'warning';
      return 'critical';
    }
    if (fire <= 8) return 'normal';
    return 'critical';
  }
}

class FieldCountRecord {
  const FieldCountRecord({
    required this.id,
    required this.title,
    required this.date,
    required this.personnel,
    required this.region,
    required this.expected,
    required this.actual,
    required this.status,
    this.lines = const [],
  });

  final String id;
  final String title;
  final DateTime date;
  final String personnel;
  final String region;
  final double expected;
  final double actual;
  final String status;
  final List<FieldCountLineRecord> lines;

  double get totalExpectedStock => lines.isEmpty
      ? expected
      : lines.fold(0.0, (sum, line) => sum + line.expectedStock);

  /// Sapma = beklenen stok − sayım.
  double get variance => totalExpectedStock - actual;

  double get variancePercent =>
      totalExpectedStock > 0 ? (variance / totalExpectedStock * 100) : 0;

  double get totalUsed =>
      lines.fold(0.0, (sum, line) => sum + line.actualUsed);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date.toIso8601String(),
        'personnel': personnel,
        'region': region,
        'expected': expected,
        'actual': actual,
        'status': status,
        'lines': lines.map((line) => line.toJson()).toList(),
      };

  factory FieldCountRecord.fromJson(Map<dynamic, dynamic> json) {
    final rawLines = json['lines'] as List<dynamic>? ?? const [];
    return FieldCountRecord(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      personnel: json['personnel'] as String? ?? '',
      region: json['region'] as String? ?? '',
      expected: (json['expected'] as num?)?.toDouble() ?? 0,
      actual: (json['actual'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'completed',
      lines: rawLines
          .whereType<Map>()
          .map(FieldCountLineRecord.fromJson)
          .toList(),
    );
  }
}

class FieldCountLineRecord {
  const FieldCountLineRecord({
    required this.diameter,
    required this.delivered,
    required this.plannedUsage,
    required this.expectedStock,
    required this.actual,
  });

  final int diameter;
  final double delivered;
  final double plannedUsage;
  final double expectedStock;
  final double actual;

  double get actualUsed => delivered - actual;
  double get stockVariance => actual - expectedStock;
  double get usageVariance => actualUsed - plannedUsage;

  Map<String, dynamic> toJson() => {
        'diameter': diameter,
        'delivered': delivered,
        'plannedUsage': plannedUsage,
        'expectedStock': expectedStock,
        'actual': actual,
      };

  factory FieldCountLineRecord.fromJson(Map<dynamic, dynamic> json) {
    return FieldCountLineRecord(
      diameter: (json['diameter'] as num?)?.toInt() ?? 0,
      delivered: (json['delivered'] as num?)?.toDouble() ?? 0,
      plannedUsage: (json['plannedUsage'] as num?)?.toDouble() ?? 0,
      expectedStock: (json['expectedStock'] as num?)?.toDouble() ?? 0,
      actual: (json['actual'] as num?)?.toDouble() ?? 0,
    );
  }

  factory FieldCountLineRecord.fromCountLine(CountDiameterLine line) {
    return FieldCountLineRecord(
      diameter: line.diameter,
      delivered: line.delivered,
      plannedUsage: line.plannedUsage,
      expectedStock: line.expectedStock,
      actual: line.actual,
    );
  }
}

class NewCountDraft {
  NewCountDraft({
    this.date,
    this.personnel = '',
    this.region = '',
    this.expectedByDiameter = const {},
    this.diameterEntries = const {},
  });

  final DateTime? date;
  final String personnel;
  final String region;

  /// Planlanan stok — çap bazında beklenen kalan (teslim − plan kullanım).
  final Map<int, double> expectedByDiameter;

  /// Saha sayım miktarları — kullanıcı girişi.
  final Map<int, double> diameterEntries;

  NewCountDraft copyWith({
    DateTime? date,
    String? personnel,
    String? region,
    Map<int, double>? expectedByDiameter,
    Map<int, double>? diameterEntries,
  }) {
    return NewCountDraft(
      date: date ?? this.date,
      personnel: personnel ?? this.personnel,
      region: region ?? this.region,
      expectedByDiameter: expectedByDiameter ?? this.expectedByDiameter,
      diameterEntries: diameterEntries ?? this.diameterEntries,
    );
  }
}

class CountDiameterLine {
  const CountDiameterLine({
    required this.diameter,
    required this.delivered,
    required this.plannedUsage,
    required this.expectedStock,
    required this.actual,
  });

  final int diameter;
  final double delivered;

  /// Plan — imalat ilerleme oranına göre beklenen kullanım.
  final double plannedUsage;

  /// Plan — sahada kalması beklenen stok (teslim − plan kullanım).
  final double expectedStock;

  /// Gerçek — saha sayımı.
  final double actual;

  /// Gerçek — kullanılan demir (teslim − sayım).
  double get actualUsed => delivered - actual;

  /// Stok sapması: sayım − beklenen stok.
  double get stockVariance => actual - expectedStock;

  /// Kullanım sapması: gerçek kullanım − plan kullanım.
  double get usageVariance => actualUsed - plannedUsage;
}
