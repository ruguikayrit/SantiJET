import 'package:equatable/equatable.dart';

import 'whatsapp_recipient.dart';

/// Proje — beton kayıtları proje kapsamında tutulur.
class Project extends Equatable {
  const Project({
    required this.id,
    required this.name,
    this.code = '',
    this.company = '',
    this.whatsappRecipients = const [],
    this.createdAt,
  });

  final String id;
  final String name;
  final String code;
  final String company;
  /// Sipariş paylaşımının gideceği WhatsApp alıcıları.
  final List<WhatsAppRecipient> whatsappRecipients;
  final DateTime? createdAt;

  Project copyWith({
    String? id,
    String? name,
    String? code,
    String? company,
    List<WhatsAppRecipient>? whatsappRecipients,
    DateTime? createdAt,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      company: company ?? this.company,
      whatsappRecipients: whatsappRecipients ?? this.whatsappRecipients,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'company': company,
        'whatsappRecipients':
            whatsappRecipients.map((e) => e.toJson()).toList(),
        'createdAt': createdAt?.toIso8601String(),
      };

  factory Project.fromJson(Map<String, dynamic> json) {
    final fromList = json['whatsappRecipients'];
    final legacy = (json['whatsappNumber'] as String? ?? '').trim();
    final recipients = <WhatsAppRecipient>[];
    if (fromList is List) {
      for (final e in fromList) {
        if (e is Map<String, dynamic>) {
          recipients.add(WhatsAppRecipient.fromJson(e));
        } else if (e is Map) {
          recipients.add(
            WhatsAppRecipient.fromJson(Map<String, dynamic>.from(e)),
          );
        }
      }
    } else if (legacy.isNotEmpty) {
      recipients.add(WhatsAppRecipient(number: legacy));
    }
    return Project(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      company: json['company'] as String? ?? '',
      whatsappRecipients: recipients,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, code, company, whatsappRecipients, createdAt];
}
