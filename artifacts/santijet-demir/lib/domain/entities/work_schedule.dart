/// Günlük iş programı — imalat bazlı planlı demir tüketimi.
class WorkActivity {
  const WorkActivity({
    required this.id,
    required this.imalatName,
    required this.plannedTonnageByDiameter,
    this.imalatId,
    this.notes,
  });

  final String id;
  final String? imalatId;
  final String imalatName;
  final Map<int, double> plannedTonnageByDiameter;
  final String? notes;

  double get totalPlannedTonnage =>
      plannedTonnageByDiameter.values.fold(0.0, (a, b) => a + b);

  WorkActivity copyWith({
    String? id,
    String? imalatId,
    String? imalatName,
    Map<int, double>? plannedTonnageByDiameter,
    String? notes,
  }) {
    return WorkActivity(
      id: id ?? this.id,
      imalatId: imalatId ?? this.imalatId,
      imalatName: imalatName ?? this.imalatName,
      plannedTonnageByDiameter:
          plannedTonnageByDiameter ?? this.plannedTonnageByDiameter,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'imalatId': imalatId,
        'imalatName': imalatName,
        'plannedTonnageByDiameter': plannedTonnageByDiameter.map(
          (k, v) => MapEntry(k.toString(), v),
        ),
        'notes': notes,
      };

  factory WorkActivity.fromJson(Map<dynamic, dynamic> json) {
    final raw = json['plannedTonnageByDiameter'];
    final map = <int, double>{};
    if (raw is Map) {
      for (final e in raw.entries) {
        final d = int.tryParse(e.key.toString());
        final t = (e.value as num?)?.toDouble();
        if (d != null && t != null) map[d] = t;
      }
    }
    return WorkActivity(
      id: json['id'] as String? ?? '',
      imalatId: json['imalatId'] as String?,
      imalatName: json['imalatName'] as String? ?? '',
      plannedTonnageByDiameter: map,
      notes: json['notes'] as String?,
    );
  }
}

class WorkScheduleDay {
  const WorkScheduleDay({
    required this.date,
    required this.activities,
  });

  /// Takvim günü (saat zerolanmış).
  final DateTime date;
  final List<WorkActivity> activities;

  double get totalPlannedTonnage =>
      activities.fold(0.0, (s, a) => s + a.totalPlannedTonnage);

  Map<int, double> get plannedTonnageByDiameter {
    final out = <int, double>{};
    for (final activity in activities) {
      activity.plannedTonnageByDiameter.forEach((d, t) {
        out[d] = (out[d] ?? 0) + t;
      });
    }
    return out;
  }

  String get dateKey =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  WorkScheduleDay copyWith({
    DateTime? date,
    List<WorkActivity>? activities,
  }) {
    return WorkScheduleDay(
      date: date ?? this.date,
      activities: activities ?? this.activities,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'activities': activities.map((a) => a.toJson()).toList(),
      };

  factory WorkScheduleDay.fromJson(Map<dynamic, dynamic> json) {
    final activitiesRaw = json['activities'];
    return WorkScheduleDay(
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      activities: activitiesRaw is List
          ? activitiesRaw
              .whereType<Map>()
              .map(WorkActivity.fromJson)
              .toList()
          : const [],
    );
  }

  static DateTime normalizeDate(DateTime d) =>
      DateTime(d.year, d.month, d.day);
}
