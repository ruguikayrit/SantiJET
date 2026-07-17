/// Günlük demirci puantaj kaydı.
class WorkforceEntry {
  const WorkforceEntry({
    required this.id,
    required this.date,
    required this.steelWorkers,
    required this.foremen,
    required this.supervisors,
    required this.hours,
    this.notes,
  });

  final String id;
  final DateTime date;
  final int steelWorkers;
  final int foremen;
  final int supervisors;
  final double hours;
  final String? notes;

  int get totalCrew => steelWorkers + foremen + supervisors;

  /// İşçi-gün eşdeğeri (demirci × saat / 8).
  double get workerDayUnits {
    if (hours <= 0 || steelWorkers <= 0) return 0;
    return steelWorkers * (hours / 8.0);
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
    String? notes,
  }) {
    return WorkforceEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      steelWorkers: steelWorkers ?? this.steelWorkers,
      foremen: foremen ?? this.foremen,
      supervisors: supervisors ?? this.supervisors,
      hours: hours ?? this.hours,
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
      notes: json['notes'] as String?,
    );
  }

  static DateTime normalizeDate(DateTime d) =>
      DateTime(d.year, d.month, d.day);
}
