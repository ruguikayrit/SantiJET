import 'package:equatable/equatable.dart';

/// İş Programı bulutundan gelen imalat satırı (Demir `WorkScheduleImalat` hizası).
class WorkScheduleItem extends Equatable {
  const WorkScheduleItem({
    required this.id,
    required this.imalatName,
    this.imalatId = '',
    this.startDate,
    this.endDate,
    this.plannedWorkerCount,
    this.plannedQty,
    this.unit,
    this.notes,
  });

  final String id;
  final String imalatId;
  final String imalatName;
  final String? startDate; // yyyy-MM-dd
  final String? endDate;
  final int? plannedWorkerCount;
  final double? plannedQty;
  final String? unit;
  final String? notes;

  /// Başlangıç–bitiş dahil planlanan takvim günü (Demir `durationDays` hizası).
  int? get durationDays {
    final start = _parseDay(startDate);
    final end = _parseDay(endDate);
    if (start == null || end == null) return null;
    final days = end.difference(start).inDays + 1;
    return days > 0 ? days : null;
  }

  static DateTime? _parseDay(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw.length >= 10 ? raw.substring(0, 10) : raw);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'imalatId': imalatId,
        'imalatName': imalatName,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
        if (plannedWorkerCount != null)
          'plannedWorkerCount': plannedWorkerCount,
        if (plannedQty != null) 'plannedQty': plannedQty,
        if (unit != null) 'unit': unit,
        if (notes != null) 'notes': notes,
      };

  factory WorkScheduleItem.fromJson(Map<String, dynamic> json) {
    String? day(dynamic v) {
      if (v == null) return null;
      final s = v.toString();
      if (s.length >= 10) return s.substring(0, 10);
      return s;
    }

    return WorkScheduleItem(
      id: json['id'] as String? ?? '',
      imalatId: json['imalatId'] as String? ?? '',
      imalatName: json['imalatName'] as String? ?? '',
      startDate: day(json['startDate']),
      endDate: day(json['endDate']),
      plannedWorkerCount: (json['plannedWorkerCount'] as num?)?.toInt(),
      plannedQty: (json['plannedQty'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      notes: json['notes'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        imalatId,
        imalatName,
        startDate,
        endDate,
        plannedWorkerCount,
        plannedQty,
        unit,
        notes,
      ];
}

/// Aktif proje için İş Programı bulut anlık görüntüsü.
class WorkScheduleSnapshot extends Equatable {
  const WorkScheduleSnapshot({
    required this.projectId,
    required this.updatedAt,
    required this.items,
    this.source = 'is_programi_cloud',
  });

  final String projectId;
  final DateTime updatedAt;
  final List<WorkScheduleItem> items;
  final String source;

  bool get isEmpty => items.isEmpty;

  Map<String, dynamic> toJson() => {
        'projectId': projectId,
        'updatedAt': updatedAt.toIso8601String(),
        'source': source,
        'items': items.map((e) => e.toJson()).toList(),
      };

  factory WorkScheduleSnapshot.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = <WorkScheduleItem>[];
    if (rawItems is List) {
      for (final e in rawItems) {
        if (e is Map) {
          items.add(WorkScheduleItem.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    return WorkScheduleSnapshot(
      projectId: json['projectId'] as String? ?? '',
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      source: json['source'] as String? ?? 'is_programi_cloud',
      items: items,
    );
  }

  @override
  List<Object?> get props => [projectId, updatedAt, items, source];
}
