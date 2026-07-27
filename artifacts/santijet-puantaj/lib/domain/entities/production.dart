import 'package:equatable/equatable.dart';

/// Günlük imalat kaydı — ekip + usta/düz işçi ataması + miktar.
class Production extends Equatable {
  const Production({
    required this.id,
    required this.projectId,
    required this.name,
    required this.date,
    this.teamName = '',
    this.ustaCount = 0,
    this.duzIsciCount = 0,
    this.unit = 'adet',
    this.plannedQty = 0,
    this.completedQty = 0,
    this.note = '',
  });

  final String id;
  final String projectId;
  final String name;
  final String date; // dd.MM.yyyy

  /// Personel `team` (ekip) adı — listeden seçilir.
  final String teamName;

  /// Bu imalata atanan usta (adam-gün / kişi; kullanıcı manuel girer).
  final double ustaCount;

  /// Bu imalata atanan düz işçi / çırak.
  final double duzIsciCount;

  final String unit;
  final double plannedQty;
  final double completedQty;
  final String note;

  double get progressPct {
    if (plannedQty <= 0) return completedQty > 0 ? 100 : 0;
    return ((completedQty / plannedQty) * 100).clamp(0, 999);
  }

  Production copyWith({
    String? id,
    String? projectId,
    String? name,
    String? date,
    String? teamName,
    double? ustaCount,
    double? duzIsciCount,
    String? unit,
    double? plannedQty,
    double? completedQty,
    String? note,
  }) {
    return Production(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      date: date ?? this.date,
      teamName: teamName ?? this.teamName,
      ustaCount: ustaCount ?? this.ustaCount,
      duzIsciCount: duzIsciCount ?? this.duzIsciCount,
      unit: unit ?? this.unit,
      plannedQty: plannedQty ?? this.plannedQty,
      completedQty: completedQty ?? this.completedQty,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'name': name,
        'date': date,
        'teamName': teamName,
        'ustaCount': ustaCount,
        'duzIsciCount': duzIsciCount,
        'unit': unit,
        'plannedQty': plannedQty,
        'completedQty': completedQty,
        'note': note,
      };

  factory Production.fromJson(Map<String, dynamic> json) => Production(
        id: json['id'] as String,
        projectId: json['projectId'] as String? ?? '',
        name: json['name'] as String? ?? '',
        date: json['date'] as String? ?? '',
        teamName: json['teamName'] as String? ?? '',
        ustaCount: (json['ustaCount'] as num?)?.toDouble() ?? 0,
        duzIsciCount: (json['duzIsciCount'] as num?)?.toDouble() ?? 0,
        unit: json['unit'] as String? ?? 'adet',
        plannedQty: (json['plannedQty'] as num?)?.toDouble() ?? 0,
        completedQty: (json['completedQty'] as num?)?.toDouble() ?? 0,
        note: json['note'] as String? ?? '',
      );

  @override
  List<Object?> get props => [
        id,
        projectId,
        name,
        date,
        teamName,
        ustaCount,
        duzIsciCount,
        unit,
        plannedQty,
        completedQty,
        note,
      ];
}
