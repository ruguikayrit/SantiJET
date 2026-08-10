import 'package:equatable/equatable.dart';

class Worker extends Equatable {
  const Worker({
    required this.id,
    required this.projectId,
    required this.name,
    required this.role,
    required this.phone,
    required this.dailyRate,
    required this.company,
  });

  final String id;
  final String projectId;
  final String name;
  final String role;
  final String phone;
  final double dailyRate;
  final String company;

  Worker copyWith({
    String? id,
    String? projectId,
    String? name,
    String? role,
    String? phone,
    double? dailyRate,
    String? company,
  }) {
    return Worker(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      dailyRate: dailyRate ?? this.dailyRate,
      company: company ?? this.company,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'name': name,
        'role': role,
        'phone': phone,
        'dailyRate': dailyRate,
        'company': company,
      };

  factory Worker.fromJson(Map<String, dynamic> json) {
    return Worker(
      id: json['id']?.toString() ?? '',
      projectId: json['projectId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      dailyRate: (json['dailyRate'] as num?)?.toDouble() ?? 0,
      company: json['company']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props =>
      [id, projectId, name, role, phone, dailyRate, company];
}
