import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.name,
    required this.roleId,
    required this.pin,
    required this.profession,
    required this.phone,
    required this.address,
    required this.company,
    this.team,
  });

  final String id;
  final String name;
  final String roleId;
  final String pin;
  final String profession;
  final String phone;
  final String address;
  final String company;
  final String? team;

  AppUser copyWith({
    String? id,
    String? name,
    String? roleId,
    String? pin,
    String? profession,
    String? phone,
    String? address,
    String? company,
    String? team,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      roleId: roleId ?? this.roleId,
      pin: pin ?? this.pin,
      profession: profession ?? this.profession,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      company: company ?? this.company,
      team: team ?? this.team,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'roleId': roleId,
        'pin': pin,
        'profession': profession,
        'phone': phone,
        'address': address,
        'company': company,
        if (team != null) 'team': team,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      roleId: json['roleId']?.toString() ?? '',
      pin: json['pin']?.toString() ?? '',
      profession: json['profession']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      company: json['company']?.toString() ?? '',
      team: json['team']?.toString(),
    );
  }

  @override
  List<Object?> get props =>
      [id, name, roleId, pin, profession, phone, address, company, team];
}
