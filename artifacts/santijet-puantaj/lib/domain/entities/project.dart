import 'package:equatable/equatable.dart';

/// Proje — puantaj kayıtları proje kapsamında tutulur.
///
/// [ownerId] doluysa bulut/çok kullanıcılı iş; boşsa yalnızca yerel.
class Project extends Equatable {
  const Project({
    required this.id,
    required this.name,
    this.code = '',
    this.company = '',
    this.logoBase64 = '',
    this.logoMimeType = 'image/jpeg',
    this.ownerId,
    this.createdAt,
  });

  final String id;
  final String name;
  final String code;
  final String company;

  /// Firma logosu (base64) — günlük rapor PDF ve Projelerim.
  final String logoBase64;
  final String logoMimeType;

  /// Sahip kullanıcı id (Supabase auth). Yerel-only projelerde null.
  final String? ownerId;
  final DateTime? createdAt;

  bool get hasLogo => logoBase64.trim().isNotEmpty;

  bool get isShared => ownerId != null && ownerId!.isNotEmpty;

  Project copyWith({
    String? id,
    String? name,
    String? code,
    String? company,
    String? logoBase64,
    String? logoMimeType,
    String? ownerId,
    DateTime? createdAt,
    bool clearLogo = false,
    bool clearOwnerId = false,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      company: company ?? this.company,
      logoBase64: clearLogo ? '' : (logoBase64 ?? this.logoBase64),
      logoMimeType: clearLogo
          ? 'image/jpeg'
          : (logoMimeType ?? this.logoMimeType),
      ownerId: clearOwnerId ? null : (ownerId ?? this.ownerId),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'company': company,
        'logoBase64': logoBase64,
        'logoMimeType': logoMimeType,
        'ownerId': ownerId,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        code: json['code'] as String? ?? '',
        company: json['company'] as String? ?? '',
        logoBase64: json['logoBase64'] as String? ?? '',
        logoMimeType: json['logoMimeType'] as String? ?? 'image/jpeg',
        ownerId: json['ownerId'] as String? ?? json['owner_id'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : (json['created_at'] != null
                ? DateTime.tryParse(json['created_at'] as String)
                : null),
      );

  @override
  List<Object?> get props => [
        id,
        name,
        code,
        company,
        logoBase64,
        logoMimeType,
        ownerId,
        createdAt,
      ];
}
