/// Günlük demirci puantaj kaydı.
class WorkforceEntry {
  const WorkforceEntry({
    required this.id,
    required this.date,
    required this.kalfa,
    required this.usta,
    required this.duzIsci,
    required this.tamGun,
    required this.yarimGun,
    this.mesaiSaati = 0,
    this.notes,
  });

  final String id;
  final DateTime date;
  final int kalfa;
  final int usta;
  final int duzIsci;
  final int tamGun;
  final int yarimGun;
  /// Mesai saati (fazla çalışma).
  final double mesaiSaati;
  final String? notes;

  int get totalCrew => kalfa + usta + duzIsci;

  /// İşçi-gün eşdeğeri (tam gün + yarım gün/2 + mesai/8).
  double get workerDayUnits {
    final base = tamGun + (yarimGun * 0.5);
    final overtime = mesaiSaati > 0 ? mesaiSaati / 8.0 : 0.0;
    return base + overtime;
  }

  String get dateKey =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  WorkforceEntry copyWith({
    String? id,
    DateTime? date,
    int? kalfa,
    int? usta,
    int? duzIsci,
    int? tamGun,
    int? yarimGun,
    double? mesaiSaati,
    String? notes,
  }) {
    return WorkforceEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      kalfa: kalfa ?? this.kalfa,
      usta: usta ?? this.usta,
      duzIsci: duzIsci ?? this.duzIsci,
      tamGun: tamGun ?? this.tamGun,
      yarimGun: yarimGun ?? this.yarimGun,
      mesaiSaati: mesaiSaati ?? this.mesaiSaati,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'kalfa': kalfa,
        'usta': usta,
        'duzIsci': duzIsci,
        'tamGun': tamGun,
        'yarimGun': yarimGun,
        'mesaiSaati': mesaiSaati,
        'notes': notes,
      };

  factory WorkforceEntry.fromJson(Map<dynamic, dynamic> json) {
    return WorkforceEntry(
      id: json['id'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      kalfa: (json['kalfa'] as num?)?.toInt() ??
          (json['steelWorkers'] as num?)?.toInt() ??
          0,
      usta: (json['usta'] as num?)?.toInt() ??
          (json['foremen'] as num?)?.toInt() ??
          0,
      duzIsci: (json['duzIsci'] as num?)?.toInt() ?? 0,
      tamGun: (json['tamGun'] as num?)?.toInt() ?? 0,
      yarimGun: (json['yarimGun'] as num?)?.toInt() ?? 0,
      mesaiSaati: (json['mesaiSaati'] as num?)?.toDouble() ??
          (json['overtimeHours'] as num?)?.toDouble() ??
          0,
      notes: json['notes'] as String?,
    );
  }

  static DateTime normalizeDate(DateTime d) =>
      DateTime(d.year, d.month, d.day);
}
