import 'package:equatable/equatable.dart';

import 'production_day_entry.dart';

/// İmalat işi — planlanan keşif miktarına %100 ulaşana kadar günlük kayıtlar.
class Production extends Equatable {
  const Production({
    required this.id,
    required this.projectId,
    required this.name,
    this.floor = '',
    this.section = '',
    this.teamName = '',
    this.unit = 'adet',
    this.plannedQty = 0,
    this.plannedDays = 0,
    this.plannedLabor = 0,
    this.note = '',
    this.dailyEntries = const [],
  });

  final String id;
  final String projectId;

  /// İmalatın adı.
  final String name;

  /// Bulunduğu kat.
  final String floor;

  /// Bulunduğu kısım / bölge / etap.
  final String section;

  /// Personel `team` (ekip) adı — listeden seçilir.
  final String teamName;

  final String unit;

  /// Planlanan keşif miktarı.
  final double plannedQty;

  /// Planlanan gün sayısı.
  final int plannedDays;

  /// Planlanan iş gücü (kişi).
  final double plannedLabor;

  final String note;

  /// %100'e kadar her gün eklenen usta/düz ve gerçekleşen miktar kayıtları.
  final List<ProductionDayEntry> dailyEntries;

  /// Kat + kısım/bölge/etap özeti (boş olanlar atlanır).
  String get locationLabel {
    final parts = <String>[
      if (floor.trim().isNotEmpty) floor.trim(),
      if (section.trim().isNotEmpty) section.trim(),
    ];
    return parts.join(' · ');
  }

  double get completedQty =>
      dailyEntries.fold<double>(0, (s, e) => s + e.completedQty);

  double get ustaCount =>
      dailyEntries.fold<double>(0, (s, e) => s + e.ustaCount);

  double get duzIsciCount =>
      dailyEntries.fold<double>(0, (s, e) => s + e.duzIsciCount);

  /// Gerçekleşen adam-gün (usta + düz işçi toplamı).
  double get actualLaborDays =>
      dailyEntries.fold<double>(0, (s, e) => s + e.laborDays);

  /// Planlanan adam-gün: iş gücü × gün (gün yoksa yalnız iş gücü).
  double get plannedWorkerDays {
    if (plannedLabor <= 0) return 0;
    if (plannedDays > 0) return plannedLabor * plannedDays;
    return plannedLabor;
  }

  /// Son günlük kayıt tarihi (sıralama için).
  String get latestDate {
    if (dailyEntries.isEmpty) return '';
    return dailyEntries
        .map((e) => e.date)
        .reduce((a, b) => a.compareTo(b) > 0 ? a : b);
  }

  double get remainingQty {
    if (plannedQty <= 0) return 0;
    return (plannedQty - completedQty).clamp(0, double.infinity);
  }

  double get progressPct {
    if (plannedQty <= 0) return completedQty > 0 ? 100 : 0;
    return ((completedQty / plannedQty) * 100).clamp(0, 100);
  }

  /// İş yapılan benzersiz gün sayısı (günlük kayıt tarihi).
  int get workedDays {
    final days = <String>{};
    for (final e in dailyEntries) {
      final d = e.date.trim();
      if (d.isEmpty) continue;
      if (e.ustaCount > 0 || e.duzIsciCount > 0 || e.completedQty > 0) {
        days.add(d);
      }
    }
    return days.length;
  }

  /// Süre bazlı ilerleme: çalışılan gün / planlanan gün.
  double get timeProgressPct {
    if (plannedDays <= 0) return workedDays > 0 ? 100 : 0;
    return ((workedDays / plannedDays) * 100).clamp(0, 100);
  }

  bool get isComplete => progressPct >= 100;

  ProductionDayEntry? entryOnDate(String date) {
    for (final e in dailyEntries) {
      if (e.date == date) return e;
    }
    return null;
  }

  List<ProductionDayEntry> entriesOnDate(String date) =>
      dailyEntries.where((e) => e.date == date).toList();

  Production copyWith({
    String? id,
    String? projectId,
    String? name,
    String? floor,
    String? section,
    String? teamName,
    String? unit,
    double? plannedQty,
    int? plannedDays,
    double? plannedLabor,
    String? note,
    List<ProductionDayEntry>? dailyEntries,
  }) {
    return Production(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      floor: floor ?? this.floor,
      section: section ?? this.section,
      teamName: teamName ?? this.teamName,
      unit: unit ?? this.unit,
      plannedQty: plannedQty ?? this.plannedQty,
      plannedDays: plannedDays ?? this.plannedDays,
      plannedLabor: plannedLabor ?? this.plannedLabor,
      note: note ?? this.note,
      dailyEntries: dailyEntries ?? this.dailyEntries,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'name': name,
        'floor': floor,
        'section': section,
        'teamName': teamName,
        'unit': unit,
        'plannedQty': plannedQty,
        'plannedDays': plannedDays,
        'plannedLabor': plannedLabor,
        'note': note,
        'dailyEntries': dailyEntries.map((e) => e.toJson()).toList(),
      };

  factory Production.fromJson(Map<String, dynamic> json) {
    final rawEntries = json['dailyEntries'];
    List<ProductionDayEntry> entries;
    if (rawEntries is List && rawEntries.isNotEmpty) {
      entries = rawEntries
          .map((e) => ProductionDayEntry.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList();
    } else {
      // Eski tek-gün formatından yükseltme.
      final date = json['date'] as String? ?? '';
      final usta = (json['ustaCount'] as num?)?.toDouble() ?? 0;
      final duz = (json['duzIsciCount'] as num?)?.toDouble() ?? 0;
      final done = (json['completedQty'] as num?)?.toDouble() ?? 0;
      if (date.isNotEmpty && (usta > 0 || duz > 0 || done > 0)) {
        entries = [
          ProductionDayEntry(
            id: '${json['id'] as String? ?? 'legacy'}_d1',
            date: date,
            ustaCount: usta,
            duzIsciCount: duz,
            completedQty: done,
            note: json['note'] as String? ?? '',
          ),
        ];
      } else {
        entries = [];
      }
    }

    return Production(
      id: json['id'] as String,
      projectId: json['projectId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      floor: json['floor'] as String? ?? '',
      section: json['section'] as String? ?? '',
      teamName: json['teamName'] as String? ?? '',
      unit: json['unit'] as String? ?? 'adet',
      plannedQty: (json['plannedQty'] as num?)?.toDouble() ?? 0,
      plannedDays: (json['plannedDays'] as num?)?.toInt() ?? 0,
      plannedLabor: (json['plannedLabor'] as num?)?.toDouble() ?? 0,
      note: json['note'] as String? ?? '',
      dailyEntries: entries,
    );
  }

  @override
  List<Object?> get props => [
        id,
        projectId,
        name,
        floor,
        section,
        teamName,
        unit,
        plannedQty,
        plannedDays,
        plannedLabor,
        note,
        dailyEntries,
      ];
}
