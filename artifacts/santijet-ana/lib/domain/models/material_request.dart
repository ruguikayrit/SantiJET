import 'package:equatable/equatable.dart';

class MaterialRequestApprovals extends Equatable {
  const MaterialRequestApprovals({
    this.sef,
    this.mudur,
    this.satinAlma,
  });

  final bool? sef;
  final bool? mudur;
  final bool? satinAlma;

  MaterialRequestApprovals copyWith({
    bool? sef,
    bool? mudur,
    bool? satinAlma,
  }) {
    return MaterialRequestApprovals(
      sef: sef ?? this.sef,
      mudur: mudur ?? this.mudur,
      satinAlma: satinAlma ?? this.satinAlma,
    );
  }

  Map<String, dynamic> toJson() => {
        if (sef != null) 'sef': sef,
        if (mudur != null) 'mudur': mudur,
        if (satinAlma != null) 'satinAlma': satinAlma,
      };

  factory MaterialRequestApprovals.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MaterialRequestApprovals();
    return MaterialRequestApprovals(
      sef: json['sef'] as bool?,
      mudur: json['mudur'] as bool?,
      satinAlma: json['satinAlma'] as bool?,
    );
  }

  @override
  List<Object?> get props => [sef, mudur, satinAlma];
}

class MaterialRequest extends Equatable {
  const MaterialRequest({
    required this.id,
    required this.projectId,
    required this.name,
    required this.unit,
    required this.quantity,
    required this.requestDate,
    required this.requestedBy,
    required this.status,
    required this.note,
    this.category,
    this.usageLocation,
    this.pozCode,
    this.pozCategory,
    this.approvals,
    this.receivedBy,
  });

  final String id;
  final String projectId;
  final String name;
  final String? category;
  final String unit;
  final double quantity;
  final String requestDate;
  final String requestedBy;
  final String status; // pending | approved | delivered | rejected
  final String note;
  final String? usageLocation;
  final String? pozCode;
  final String? pozCategory;
  final MaterialRequestApprovals? approvals;
  final String? receivedBy;

  MaterialRequest copyWith({
    String? id,
    String? projectId,
    String? name,
    String? category,
    String? unit,
    double? quantity,
    String? requestDate,
    String? requestedBy,
    String? status,
    String? note,
    String? usageLocation,
    String? pozCode,
    String? pozCategory,
    MaterialRequestApprovals? approvals,
    String? receivedBy,
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
      pozCategory: pozCategory ?? this.pozCategory,
      approvals: approvals ?? this.approvals,
      receivedBy: receivedBy ?? this.receivedBy,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'name': name,
        if (category != null) 'category': category,
        'unit': unit,
        'quantity': quantity,
        'requestDate': requestDate,
        'requestedBy': requestedBy,
        'status': status,
        'note': note,
        if (usageLocation != null) 'usageLocation': usageLocation,
        if (pozCode != null) 'pozCode': pozCode,
        if (pozCategory != null) 'pozCategory': pozCategory,
        if (approvals != null) 'approvals': approvals!.toJson(),
        if (receivedBy != null) 'receivedBy': receivedBy,
      };

  factory MaterialRequest.fromJson(Map<String, dynamic> json) {
    return MaterialRequest(
      id: json['id']?.toString() ?? '',
      projectId: json['projectId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString(),
      unit: json['unit']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      requestDate: json['requestDate']?.toString() ?? '',
      requestedBy: json['requestedBy']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      note: json['note']?.toString() ?? '',
      usageLocation: json['usageLocation']?.toString(),
      pozCode: json['pozCode']?.toString(),
      pozCategory: json['pozCategory']?.toString(),
      approvals: json['approvals'] is Map
          ? MaterialRequestApprovals.fromJson(
              Map<String, dynamic>.from(json['approvals'] as Map),
            )
          : null,
      receivedBy: json['receivedBy']?.toString(),
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
        pozCategory,
        approvals,
        receivedBy,
      ];
}
