class Project {
  const Project({
    required this.id,
    required this.code,
    required this.name,
    required this.location,
    required this.ownerId,
    required this.createdAt,
    this.startDate,
    this.endDate,
    this.progress = 0,
  });

  final String id;
  final String code;
  final String name;
  final String location;
  final String ownerId;
  final DateTime createdAt;
  final DateTime? startDate;
  final DateTime? endDate;
  final double progress;

  Project copyWith({
    String? id,
    String? code,
    String? name,
    String? location,
    String? ownerId,
    DateTime? createdAt,
    DateTime? startDate,
    DateTime? endDate,
    double? progress,
  }) {
    return Project(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      location: location ?? this.location,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      progress: progress ?? this.progress,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'location': location,
        'ownerId': ownerId,
        'createdAt': createdAt.toIso8601String(),
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'progress': progress,
      };

  factory Project.fromJson(Map<dynamic, dynamic> json) {
    return Project(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String? ?? '',
      location: json['location'] as String? ?? '',
      ownerId: json['ownerId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'] as String)
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'] as String)
          : null,
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
    );
  }
}
