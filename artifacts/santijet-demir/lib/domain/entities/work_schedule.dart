import 'package:santijet_demir/domain/entities/survey.dart';

/// İmalat bazlı iş programı satırı — başlangıç/bitiş; tonaj keşiften gelir.
class WorkScheduleImalat {
  const WorkScheduleImalat({
    required this.id,
    required this.imalatId,
    required this.imalatName,
    this.startDate,
    this.endDate,
    this.plannedWorkerCount,
    this.notes,
  });

  final String id;
  final String imalatId;
  final String imalatName;
  final DateTime? startDate;
  final DateTime? endDate;

  /// Bu imalat için planlanan adam sayısı (iş gücü planı).
  final int? plannedWorkerCount;
  final String? notes;

  /// Takvim günü sayısı (başlangıç ve bitiş dahil).
  int? get durationDays {
    final start = startDate;
    final end = endDate;
    if (start == null || end == null) return null;
    final s = normalizeDate(start);
    final e = normalizeDate(end);
    if (e.isBefore(s)) return null;
    return e.difference(s).inDays + 1;
  }

  bool coversDate(DateTime date) {
    final start = startDate;
    final end = endDate;
    if (start == null || end == null) return false;
    final day = normalizeDate(date);
    final s = normalizeDate(start);
    final e = normalizeDate(end);
    if (e.isBefore(s)) return false;
    return !day.isBefore(s) && !day.isAfter(e);
  }

  WorkScheduleImalat copyWith({
    String? id,
    String? imalatId,
    String? imalatName,
    DateTime? startDate,
    DateTime? endDate,
    int? plannedWorkerCount,
    String? notes,
    bool clearStartDate = false,
    bool clearEndDate = false,
    bool clearPlannedWorkerCount = false,
    bool clearNotes = false,
  }) {
    return WorkScheduleImalat(
      id: id ?? this.id,
      imalatId: imalatId ?? this.imalatId,
      imalatName: imalatName ?? this.imalatName,
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      plannedWorkerCount: clearPlannedWorkerCount
          ? null
          : (plannedWorkerCount ?? this.plannedWorkerCount),
      notes: clearNotes ? null : (notes ?? this.notes),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'imalatId': imalatId,
        'imalatName': imalatName,
        if (startDate != null) 'startDate': startDate!.toIso8601String(),
        if (endDate != null) 'endDate': endDate!.toIso8601String(),
        if (plannedWorkerCount != null)
          'plannedWorkerCount': plannedWorkerCount,
        if (notes != null) 'notes': notes,
      };

  factory WorkScheduleImalat.fromJson(Map<dynamic, dynamic> json) {
    final rawWorkers = json['plannedWorkerCount'];
    return WorkScheduleImalat(
      id: json['id'] as String? ?? '',
      imalatId: json['imalatId'] as String? ?? '',
      imalatName: json['imalatName'] as String? ?? '',
      startDate: DateTime.tryParse(json['startDate'] as String? ?? ''),
      endDate: DateTime.tryParse(json['endDate'] as String? ?? ''),
      plannedWorkerCount: rawWorkers is num
          ? rawWorkers.toInt()
          : int.tryParse(rawWorkers?.toString() ?? ''),
      notes: json['notes'] as String?,
    );
  }

  static DateTime normalizeDate(DateTime d) =>
      DateTime(d.year, d.month, d.day);
}

/// Günlük iş programı — imalat bazlı planlı demir tüketimi (türeyen görünüm).
class WorkActivity {
  const WorkActivity({
    required this.id,
    required this.imalatName,
    required this.plannedTonnageByDiameter,
    this.imalatId,
    this.plannedWorkerCount,
    this.notes,
  });

  final String id;
  final String? imalatId;
  final String imalatName;
  final Map<int, double> plannedTonnageByDiameter;
  final int? plannedWorkerCount;
  final String? notes;

  double get totalPlannedTonnage =>
      plannedTonnageByDiameter.values.fold(0.0, (a, b) => a + b);

  WorkActivity copyWith({
    String? id,
    String? imalatId,
    String? imalatName,
    Map<int, double>? plannedTonnageByDiameter,
    int? plannedWorkerCount,
    String? notes,
    bool clearPlannedWorkerCount = false,
  }) {
    return WorkActivity(
      id: id ?? this.id,
      imalatId: imalatId ?? this.imalatId,
      imalatName: imalatName ?? this.imalatName,
      plannedTonnageByDiameter:
          plannedTonnageByDiameter ?? this.plannedTonnageByDiameter,
      plannedWorkerCount: clearPlannedWorkerCount
          ? null
          : (plannedWorkerCount ?? this.plannedWorkerCount),
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
        if (plannedWorkerCount != null)
          'plannedWorkerCount': plannedWorkerCount,
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
    final rawWorkers = json['plannedWorkerCount'];
    return WorkActivity(
      id: json['id'] as String? ?? '',
      imalatId: json['imalatId'] as String?,
      imalatName: json['imalatName'] as String? ?? '',
      plannedTonnageByDiameter: map,
      plannedWorkerCount: rawWorkers is num
          ? rawWorkers.toInt()
          : int.tryParse(rawWorkers?.toString() ?? ''),
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

/// Keşif tonajını imalat sürelerine eşit dağıtarak günlük plana dönüştürür.
List<WorkScheduleDay> expandWorkScheduleToDays({
  required List<WorkScheduleImalat> items,
  required SurveyProject survey,
}) {
  final byDate = <String, List<WorkActivity>>{};

  for (final item in items) {
    final duration = item.durationDays;
    final start = item.startDate;
    final end = item.endDate;
    if (duration == null || duration <= 0 || start == null || end == null) {
      continue;
    }

    SurveyImalat? imalat;
    for (final candidate in survey.imalats) {
      if (candidate.id == item.imalatId) {
        imalat = candidate;
        break;
      }
    }
    if (imalat == null) continue;

    final dailyByDiameter = <int, double>{};
    for (final line in imalat.diameterLines) {
      if (line.planned <= 0) continue;
      dailyByDiameter[line.diameter] = line.planned / duration;
    }
    if (dailyByDiameter.isEmpty && imalat.planned > 0) {
      // Çap satırı yoksa toplam tonajı tek kovada tut.
      dailyByDiameter[0] = imalat.planned / duration;
    }
    if (dailyByDiameter.isEmpty) continue;

    final s = WorkScheduleImalat.normalizeDate(start);
    for (var i = 0; i < duration; i++) {
      final day = s.add(Duration(days: i));
      final key = WorkScheduleDay(date: day, activities: const []).dateKey;
      byDate.putIfAbsent(key, () => []).add(
            WorkActivity(
              id: '${item.id}-$key',
              imalatId: item.imalatId,
              imalatName: imalat.name,
              plannedTonnageByDiameter: Map<int, double>.from(dailyByDiameter),
              plannedWorkerCount: item.plannedWorkerCount,
              notes: item.notes,
            ),
          );
    }
  }

  final days = byDate.entries
      .map(
        (e) => WorkScheduleDay(
          date: DateTime.tryParse(e.key) ?? DateTime.now(),
          activities: e.value,
        ),
      )
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));
  return days;
}

WorkScheduleDay? workScheduleDayFor({
  required DateTime date,
  required List<WorkScheduleImalat> items,
  required SurveyProject survey,
}) {
  final key = WorkScheduleDay.normalizeDate(date);
  final days = expandWorkScheduleToDays(items: items, survey: survey);
  for (final day in days) {
    if (WorkScheduleDay.normalizeDate(day.date) == key) return day;
  }
  return null;
}
