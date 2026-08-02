import 'package:equatable/equatable.dart';

/// Keşif bulutundan gelen plan metraj satırı (Demir survey / keşif hizası).
///
/// Verimde planlanan miktar buradan gelir; süre ve iş gücü İş Programı’ndadır.
class KesifItem extends Equatable {
  const KesifItem({
    required this.id,
    required this.imalatName,
    this.imalatId = '',
    required this.plannedQty,
    this.unit = 'ton',
    this.notes,
  });

  final String id;
  final String imalatId;
  final String imalatName;
  final double plannedQty;
  final String unit;
  final String? notes;

  Map<String, dynamic> toJson() => {
        'id': id,
        'imalatId': imalatId,
        'imalatName': imalatName,
        'plannedQty': plannedQty,
        'unit': unit,
        if (notes != null) 'notes': notes,
      };

  factory KesifItem.fromJson(Map<String, dynamic> json) {
    return KesifItem(
      id: json['id'] as String? ?? '',
      imalatId: json['imalatId'] as String? ?? '',
      imalatName: json['imalatName'] as String? ?? '',
      plannedQty: (json['plannedQty'] as num?)?.toDouble() ?? 0,
      unit: json['unit'] as String? ?? 'ton',
      notes: json['notes'] as String?,
    );
  }

  @override
  List<Object?> get props =>
      [id, imalatId, imalatName, plannedQty, unit, notes];
}

/// Aktif proje için Keşif bulut anlık görüntüsü.
class KesifSnapshot extends Equatable {
  const KesifSnapshot({
    required this.projectId,
    required this.updatedAt,
    required this.items,
    this.source = 'kesif_cloud',
  });

  final String projectId;
  final DateTime updatedAt;
  final List<KesifItem> items;
  final String source;

  bool get isEmpty => items.isEmpty;

  Map<String, dynamic> toJson() => {
        'projectId': projectId,
        'updatedAt': updatedAt.toIso8601String(),
        'source': source,
        'items': items.map((e) => e.toJson()).toList(),
      };

  factory KesifSnapshot.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = <KesifItem>[];
    if (rawItems is List) {
      for (final e in rawItems) {
        if (e is Map) {
          items.add(KesifItem.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    return KesifSnapshot(
      projectId: json['projectId'] as String? ?? '',
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      source: json['source'] as String? ?? 'kesif_cloud',
      items: items,
    );
  }

  @override
  List<Object?> get props => [projectId, updatedAt, items, source];
}
