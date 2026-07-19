/// Günlük demirci puantaj kaydı.
class WorkforceEntry {
  const WorkforceEntry({
    required this.id,
    required this.date,
    required this.steelWorkers,
    required this.foremen,
    required this.supervisors,
    required this.hours,
    this.overtimeHours = 0,
    this.notes,
  });

  final String id;
  final DateTime date;
  final int steelWorkers;
  final int foremen;
  final int supervisors;
  /// Normal çalışma saati (varsayılan 8).
  final double hours;
  /// Mesai saati (fazla çalışma).
  final double overtimeHours;
  final String? notes;

  int get totalCrew => steelWorkers + foremen + supervisors;

  double get totalHours => hours + overtimeHours;

  /// İşçi-gün eşdeğeri (demirci × (saat+mesai) / 8).
  double get workerDayUnits {
    if (totalHours <= 0 || steelWorkers <= 0) return 0;
    return steelWorkers * (totalHours / 8.0);
  }

  String get dateKey =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  WorkforceEntry copyWith({
    String? id,
    DateTime? date,
    int? steelWorkers,
    int? foremen,
    int? supervisors,
    double? hours,
    double? overtimeHours,
    String? notes,
  }) {
    return WorkforceEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      steelWorkers: steelWorkers ?? this.steelWorkers,
      foremen: foremen ?? this.foremen,
      supervisors: supervisors ?? this.supervisors,
      hours: hours ?? this.hours,
      overtimeHours: overtimeHours ?? this.overtimeHours,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'steelWorkers': steelWorkers,
        'foremen': foremen,
        'supervisors': supervisors,
        'hours': hours,
        'overtimeHours': overtimeHours,
        'notes': notes,
      };

  factory WorkforceEntry.fromJson(Map<dynamic, dynamic> json) {
    return WorkforceEntry(
      id: json['id'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      steelWorkers: (json['steelWorkers'] as num?)?.toInt() ?? 0,
      foremen: (json['foremen'] as num?)?.toInt() ?? 0,
      supervisors: (json['supervisors'] as num?)?.toInt() ?? 0,
      hours: (json['hours'] as num?)?.toDouble() ?? 8,
      overtimeHours: (json['overtimeHours'] as num?)?.toDouble() ?? 0,
      notes: json['notes'] as String?,
    );
  }

  static DateTime normalizeDate(DateTime d) =>
      DateTime(d.year, d.month, d.day);
}
