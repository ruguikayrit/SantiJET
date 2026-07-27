import 'package:equatable/equatable.dart';

/// Bir imalatın tek günlük çalışma kaydı — usta/düz ataması + o günkü gerçekleşen.
class ProductionDayEntry extends Equatable {
  const ProductionDayEntry({
    required this.id,
    required this.date,
    this.ustaCount = 0,
    this.duzIsciCount = 0,
    this.completedQty = 0,
    this.note = '',
  });

  final String id;
  final String date; // dd.MM.yyyy
  final double ustaCount;
  final double duzIsciCount;
  final double completedQty;
  final String note;

  double get laborDays => ustaCount + duzIsciCount;

  ProductionDayEntry copyWith({
    String? id,
    String? date,
    double? ustaCount,
    double? duzIsciCount,
    double? completedQty,
    String? note,
  }) {
    return ProductionDayEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      ustaCount: ustaCount ?? this.ustaCount,
      duzIsciCount: duzIsciCount ?? this.duzIsciCount,
      completedQty: completedQty ?? this.completedQty,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'ustaCount': ustaCount,
        'duzIsciCount': duzIsciCount,
        'completedQty': completedQty,
        'note': note,
      };

  factory ProductionDayEntry.fromJson(Map<String, dynamic> json) =>
      ProductionDayEntry(
        id: json['id'] as String? ?? '',
        date: json['date'] as String? ?? '',
        ustaCount: (json['ustaCount'] as num?)?.toDouble() ?? 0,
        duzIsciCount: (json['duzIsciCount'] as num?)?.toDouble() ?? 0,
        completedQty: (json['completedQty'] as num?)?.toDouble() ?? 0,
        note: json['note'] as String? ?? '',
      );

  @override
  List<Object?> get props =>
      [id, date, ustaCount, duzIsciCount, completedQty, note];
}
