import 'package:equatable/equatable.dart';

import '../enums/request_status.dart';
import 'material_request_line.dart';
import 'request_approvals.dart';

/// Hive typeId plan: 4 — Pro RN `MaterialRequest`.
class MaterialRequest extends Equatable {
  const MaterialRequest({
    required this.id,
    required this.projectId,
    required this.name,
    required this.unit,
    required this.quantity,
    this.category = '',
    this.requestDate,
    this.requestedBy = '',
    this.status = RequestStatus.pending,
    this.note = '',
    this.usageLocation = '',
    this.pozCode = '',
    this.approvals = const RequestApprovals(),
    this.receivedBy = '',
    this.kesifLineId,
    this.kesifSnapshotId,
    /// Geriye dönük PDF/çoklu satır; kart UI RN tek kalem kullanır.
    this.lines = const [],
    /// Eski alan — [name] ile senkron (JSON uyumu).
    this.title = '',
  });

  final String id;
  final String projectId;
  final String name;
  final String category;
  final String unit;
  final double quantity;
  final DateTime? requestDate;
  final String requestedBy;
  final RequestStatus status;
  final String note;
  final String usageLocation;
  final String pozCode;
  final RequestApprovals approvals;
  final String receivedBy;
  final String? kesifLineId;
  final String? kesifSnapshotId;
  final List<MaterialRequestLine> lines;
  final String title;

  String get displayName => name.isNotEmpty ? name : title;

  MaterialRequest copyWith({
    String? id,
    String? projectId,
    String? name,
    String? category,
    String? unit,
    double? quantity,
    DateTime? requestDate,
    String? requestedBy,
    RequestStatus? status,
    String? note,
    String? usageLocation,
    String? pozCode,
    RequestApprovals? approvals,
    String? receivedBy,
    String? kesifLineId,
    String? kesifSnapshotId,
    List<MaterialRequestLine>? lines,
    String? title,
  }) {
    return MaterialRequest(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      requestDate: requestDate ?? this.requestDate,
      requestedBy: requestedBy ?? this.requestedBy,
      status: status ?? this.status,
      note: note ?? this.note,
      usageLocation: usageLocation ?? this.usageLocation,
      pozCode: pozCode ?? this.pozCode,
      approvals: approvals ?? this.approvals,
      receivedBy: receivedBy ?? this.receivedBy,
      kesifLineId: kesifLineId ?? this.kesifLineId,
      kesifSnapshotId: kesifSnapshotId ?? this.kesifSnapshotId,
      lines: lines ?? this.lines,
      title: title ?? this.title,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'name': name,
        'category': category,
        'unit': unit,
        'quantity': quantity,
        'requestDate': requestDate?.toIso8601String(),
        'requestedBy': requestedBy,
        'status': status.name,
        'note': note,
        'usageLocation': usageLocation,
        'pozCode': pozCode,
        'approvals': approvals.toJson(),
        'receivedBy': receivedBy,
        'kesifLineId': kesifLineId,
        'kesifSnapshotId': kesifSnapshotId,
        'lines': lines.map((e) => e.toJson()).toList(),
        'title': title.isNotEmpty ? title : name,
      };

  factory MaterialRequest.fromJson(Map<String, dynamic> json) {
    final legacyTitle = json['title'] as String? ?? '';
    final name = (json['name'] as String?)?.trim().isNotEmpty == true
        ? json['name'] as String
        : legacyTitle;
    final lines = (json['lines'] as List? ?? const [])
        .map(
          (e) => MaterialRequestLine.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
    // Eski çoklu satır seed → ilk satırdan tek kalem türet.
    final first = lines.isNotEmpty ? lines.first : null;
    return MaterialRequest(
      id: json['id'] as String,
      projectId: json['projectId'] as String? ?? '',
      name: name.isNotEmpty ? name : (first?.materialName ?? ''),
      category: json['category'] as String? ?? '',
      unit: (json['unit'] as String?)?.isNotEmpty == true
          ? json['unit'] as String
          : (first?.birim ?? ''),
      quantity: (json['quantity'] as num?)?.toDouble() ??
          first?.miktar ??
          0,
      requestDate: json['requestDate'] != null
          ? DateTime.tryParse(json['requestDate'] as String)
          : (json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'] as String)
              : null),
      requestedBy: json['requestedBy'] as String? ?? '',
      status: RequestStatus.tryParse(json['status'] as String?) ??
          RequestStatus.pending,
      note: json['note'] as String? ?? json['notes'] as String? ?? '',
      usageLocation: json['usageLocation'] as String? ?? '',
      pozCode: json['pozCode'] as String? ?? first?.pozNo ?? '',
      approvals: RequestApprovals.fromJson(
        json['approvals'] != null
            ? Map<String, dynamic>.from(json['approvals'] as Map)
            : null,
      ),
      receivedBy: json['receivedBy'] as String? ?? '',
      kesifLineId: json['kesifLineId'] as String? ?? first?.kesifLineId,
      kesifSnapshotId: json['kesifSnapshotId'] as String?,
      lines: lines,
      title: legacyTitle,
    );
  }

  @override
  List<Object?> get props => [
        id,
        projectId,
        name,
        category,
        unit,
        quantity,
        requestDate,
        requestedBy,
        status,
        note,
        usageLocation,
        pozCode,
        approvals,
        receivedBy,
        kesifLineId,
        kesifSnapshotId,
        lines,
      ];
}
