import 'package:equatable/equatable.dart';

/// Personel kaydı — her proje kendi personel listesine sahiptir.
///
/// PIN / rol yetkilendirmesi sonraki fazda; şimdilik puantaj cetveli kaynağı.
class Person extends Equatable {
  const Person({
    required this.id,
    required this.projectId,
    required this.name,
    this.profession = '',
    this.phone = '',
    this.company = '',
    this.team = '',
    this.address = '',
    this.active = true,
  });

  final String id;

  /// Personelin ait olduğu proje — projeler arası paylaşılmaz.
  final String projectId;

  final String name;
  final String profession;
  final String phone;
  final String company;
  final String team;
  final String address;
  final bool active;

  Person copyWith({
    String? id,
    String? projectId,
    String? name,
    String? profession,
    String? phone,
    String? company,
    String? team,
    String? address,
    bool? active,
  }) {
    return Person(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      profession: profession ?? this.profession,
      phone: phone ?? this.phone,
      company: company ?? this.company,
      team: team ?? this.team,
      address: address ?? this.address,
      active: active ?? this.active,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'name': name,
        'profession': profession,
        'phone': phone,
        'company': company,
        'team': team,
        'address': address,
        'active': active,
      };

  factory Person.fromJson(Map<String, dynamic> json) => Person(
        id: json['id'] as String,
        projectId: json['projectId'] as String? ?? '',
        name: json['name'] as String? ?? '',
        profession: json['profession'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        company: json['company'] as String? ?? '',
        team: json['team'] as String? ?? '',
        address: json['address'] as String? ?? '',
        active: json['active'] as bool? ?? true,
      );

  @override
  List<Object?> get props => [
        id,
        projectId,
        name,
        profession,
        phone,
        company,
        team,
        address,
        active,
      ];
}
