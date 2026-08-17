import 'package:equatable/equatable.dart';

/// Proje — beton kayıtları proje kapsamında tutulur.
class Project extends Equatable {
  const Project({
    required this.id,
    required this.name,
    this.code = '',
    this.company = '',
    this.whatsappNumber = '',
    this.createdAt,
  });

  final String id;
  final String name;
  final String code;
  final String company;
  /// Sipariş paylaşımının gideceği WhatsApp (santral / tedarikçi).
  final String whatsappNumber;
  final DateTime? createdAt;

  Project copyWith({
    String? id,
    String? name,
    String? code,
    String? company,
    String? whatsappNumber,
    DateTime? createdAt,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      company: company ?? this.company,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'company': company,
        'whatsappNumber': whatsappNumber,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        code: json['code'] as String? ?? '',
        company: json['company'] as String? ?? '',
        whatsappNumber: json['whatsappNumber'] as String? ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );

  @override
  List<Object?> get props =>
      [id, name, code, company, whatsappNumber, createdAt];
}
