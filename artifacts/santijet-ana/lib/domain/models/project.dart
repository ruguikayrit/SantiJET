import 'package:equatable/equatable.dart';

class Project extends Equatable {
  const Project({
    required this.id,
    required this.name,
    required this.location,
    required this.contractor,
    required this.startDate,
    required this.endDate,
    required this.budget,
    required this.status,
    required this.description,
  });

  final String id;
  final String name;
  final String location;
  final String contractor;
  final String startDate;
  final String endDate;
  final double budget;
  final String status; // active | paused | completed
  final String description;

  Project copyWith({
    String? id,
    String? name,
    String? location,
    String? contractor,
    String? startDate,
    String? endDate,
    double? budget,
    String? status,
    String? description,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      contractor: contractor ?? this.contractor,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      budget: budget ?? this.budget,
      status: status ?? this.status,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'location': location,
        'contractor': contractor,
        'startDate': startDate,
        'endDate': endDate,
        'budget': budget,
        'status': status,
        'description': description,
      };

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      contractor: json['contractor']?.toString() ?? '',
      startDate: json['startDate']?.toString() ?? '',
      endDate: json['endDate']?.toString() ?? '',
      budget: (json['budget'] as num?)?.toDouble() ?? 0,
      status: json['status']?.toString() ?? 'active',
      description: json['description']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        location,
        contractor,
        startDate,
        endDate,
        budget,
        status,
        description,
      ];
}
