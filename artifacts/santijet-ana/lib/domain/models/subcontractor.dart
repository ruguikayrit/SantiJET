import 'package:equatable/equatable.dart';

class Subcontractor extends Equatable {
  const Subcontractor({
    required this.id,
    required this.projectId,
    required this.name,
    required this.contactPerson,
    required this.phone,
    required this.email,
    required this.specialty,
    required this.contractAmount,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.notes,
  });

  final String id;
  final String projectId;
  final String name;
  final String contactPerson;
  final String phone;
  final String email;
  final String specialty;
  final double contractAmount;
  final String startDate;
  final String endDate;
  final String status; // active | completed | cancelled
  final String notes;

  Subcontractor copyWith({
    String? id,
    String? projectId,
    String? name,
    String? contactPerson,
    String? phone,
    String? email,
    String? specialty,
    double? contractAmount,
    String? startDate,
    String? endDate,
    String? status,
    String? notes,
  }) {
    return Subcontractor(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      specialty: specialty ?? this.specialty,
      contractAmount: contractAmount ?? this.contractAmount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'name': name,
        'contactPerson': contactPerson,
        'phone': phone,
        'email': email,
        'specialty': specialty,
        'contractAmount': contractAmount,
        'startDate': startDate,
        'endDate': endDate,
        'status': status,
        'notes': notes,
      };

  factory Subcontractor.fromJson(Map<String, dynamic> json) {
    return Subcontractor(
      id: json['id']?.toString() ?? '',
      projectId: json['projectId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      contactPerson: json['contactPerson']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      specialty: json['specialty']?.toString() ?? '',
      contractAmount: (json['contractAmount'] as num?)?.toDouble() ?? 0,
      startDate: json['startDate']?.toString() ?? '',
      endDate: json['endDate']?.toString() ?? '',
      status: json['status']?.toString() ?? 'active',
      notes: json['notes']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [
        id,
        projectId,
        name,
        contactPerson,
        phone,
        email,
        specialty,
        contractAmount,
        startDate,
        endDate,
        status,
        notes,
      ];
}
