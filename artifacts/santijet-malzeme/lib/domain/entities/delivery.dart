import 'package:equatable/equatable.dart';

import 'delivery_line.dart';

/// Hive typeId plan: 9
class Delivery extends Equatable {
  const Delivery({
    required this.id,
    required this.projectId,
    required this.date,
    this.requestId,
    this.irsaliyeNo = '',
    this.supplierName = '',
    this.notes = '',
    this.lines = const [],
  });

  final String id;
  final String projectId;
  final DateTime date;
  final String? requestId;
  final String irsaliyeNo;
  final String supplierName;
  final String notes;
  final List<DeliveryLine> lines;

  Delivery copyWith({
    String? id,
    String? projectId,
    DateTime? date,
    String? requestId,
    String? irsaliyeNo,
    String? supplierName,
    String? notes,
    List<DeliveryLine>? lines,
  }) {
    return Delivery(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      date: date ?? this.date,
      requestId: requestId ?? this.requestId,
      irsaliyeNo: irsaliyeNo ?? this.irsaliyeNo,
      supplierName: supplierName ?? this.supplierName,
      notes: notes ?? this.notes,
      lines: lines ?? this.lines,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'date': date.toIso8601String(),
        'requestId': requestId,
        'irsaliyeNo': irsaliyeNo,
        'supplierName': supplierName,
        'notes': notes,
        'lines': lines.map((e) => e.toJson()).toList(),
      };

  factory Delivery.fromJson(Map<String, dynamic> json) => Delivery(
        id: json['id'] as String,
        projectId: json['projectId'] as String? ?? '',
        date: DateTime.tryParse(json['date'] as String? ?? '') ??
            DateTime.now(),
        requestId: json['requestId'] as String?,
        irsaliyeNo: json['irsaliyeNo'] as String? ?? '',
        supplierName: json['supplierName'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
        lines: (json['lines'] as List? ?? const [])
            .map(
              (e) =>
                  DeliveryLine.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList(),
      );

  @override
  List<Object?> get props => [
        id,
        projectId,
        date,
        requestId,
        irsaliyeNo,
        supplierName,
        notes,
        lines,
      ];
}
