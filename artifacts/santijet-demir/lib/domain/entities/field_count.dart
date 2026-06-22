class ReconciliationRow {
  const ReconciliationRow({
    required this.diameter,
    required this.survey,
    required this.ordered,
    required this.delivered,
    required this.used,
    required this.expected,
    required this.counted,
  });

  final int diameter;
  final double survey;
  final double ordered;
  final double delivered;
  final double used;
  final double expected;
  final double counted;

  double get variance => counted - expected;

  String get status {
    final v = variance.abs();
    if (v <= 2) return 'normal';
    if (v <= 8) return 'warning';
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
  });

  final String id;
  final String title;
  final DateTime date;
  final String personnel;
  final String region;
  final double expected;
  final double actual;
  final String status;

  double get variance => actual - expected;
  double get variancePercent =>
      expected > 0 ? (variance / expected * 100) : 0;
}

class NewCountDraft {
  NewCountDraft({
    this.date,
    this.personnel = '',
    this.region = '',
    this.diameterEntries = const {},
  });

  final DateTime? date;
  final String personnel;
  final String region;
  final Map<int, double> diameterEntries;

  NewCountDraft copyWith({
    DateTime? date,
    String? personnel,
    String? region,
    Map<int, double>? diameterEntries,
  }) {
    return NewCountDraft(
      date: date ?? this.date,
      personnel: personnel ?? this.personnel,
      region: region ?? this.region,
      diameterEntries: diameterEntries ?? this.diameterEntries,
    );
  }
}
