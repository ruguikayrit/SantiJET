import 'package:equatable/equatable.dart';

import 'quote_line.dart';

/// Hive typeId plan: 7
class SupplierQuote extends Equatable {
  const SupplierQuote({
    required this.id,
    required this.supplierName,
    this.paymentTermDays = 0,
    this.deliveryDays = 0,
    this.notes = '',
    this.lines = const [],
  });

  final String id;
  final String supplierName;
  final int paymentTermDays;
  final int deliveryDays;
  final String notes;
  final List<QuoteLine> lines;

  SupplierQuote copyWith({
    String? id,
    String? supplierName,
    int? paymentTermDays,
    int? deliveryDays,
    String? notes,
    List<QuoteLine>? lines,
  }) {
    return SupplierQuote(
      id: id ?? this.id,
      supplierName: supplierName ?? this.supplierName,
      paymentTermDays: paymentTermDays ?? this.paymentTermDays,
      deliveryDays: deliveryDays ?? this.deliveryDays,
      notes: notes ?? this.notes,
      lines: lines ?? this.lines,
    );
  }

  double get total =>
      lines.fold<double>(0, (s, l) => s + (l.unitPrice * l.quantity));

  Map<String, dynamic> toJson() => {
        'id': id,
        'supplierName': supplierName,
        'paymentTermDays': paymentTermDays,
        'deliveryDays': deliveryDays,
        'notes': notes,
        'lines': lines.map((e) => e.toJson()).toList(),
      };

  factory SupplierQuote.fromJson(Map<String, dynamic> json) => SupplierQuote(
        id: json['id'] as String,
        supplierName: json['supplierName'] as String? ?? '',
        paymentTermDays: (json['paymentTermDays'] as num?)?.toInt() ?? 0,
        deliveryDays: (json['deliveryDays'] as num?)?.toInt() ?? 0,
        notes: json['notes'] as String? ?? '',
        lines: (json['lines'] as List? ?? const [])
            .map((e) => QuoteLine.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );

  @override
  List<Object?> get props => [
        id,
        supplierName,
        paymentTermDays,
        deliveryDays,
        notes,
        lines,
      ];
}
