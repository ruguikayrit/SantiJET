import 'package:equatable/equatable.dart';

/// Hive typeId plan: 11
/// Üretici TDS / teknik föy.
class TechSheet extends Equatable {
  const TechSheet({
    required this.id,
    required this.productName,
    required this.manufacturer,
    this.filePath,
    this.fileName = '',
    this.mimeType = '',
    this.tags = const [],
    this.notes = '',
    this.createdAt,
  });

  final String id;
  final String productName;
  final String manufacturer;
  final String? filePath;
  final String fileName;
  final String mimeType;
  final List<String> tags;
  final String notes;
  final DateTime? createdAt;

  TechSheet copyWith({
    String? id,
    String? productName,
    String? manufacturer,
    String? filePath,
    String? fileName,
    String? mimeType,
    List<String>? tags,
    String? notes,
    DateTime? createdAt,
  }) {
    return TechSheet(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      manufacturer: manufacturer ?? this.manufacturer,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      mimeType: mimeType ?? this.mimeType,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'productName': productName,
        'manufacturer': manufacturer,
        'filePath': filePath,
        'fileName': fileName,
        'mimeType': mimeType,
        'tags': tags,
        'notes': notes,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory TechSheet.fromJson(Map<String, dynamic> json) => TechSheet(
        id: json['id'] as String,
        productName: json['productName'] as String? ?? '',
        manufacturer: json['manufacturer'] as String? ?? '',
        filePath: json['filePath'] as String?,
        fileName: json['fileName'] as String? ?? '',
        mimeType: json['mimeType'] as String? ?? '',
        tags: (json['tags'] as List? ?? const [])
            .map((e) => e.toString())
            .toList(),
        notes: json['notes'] as String? ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );

  @override
  List<Object?> get props => [
        id,
        productName,
        manufacturer,
        filePath,
        fileName,
        mimeType,
        tags,
        notes,
        createdAt,
      ];
}
