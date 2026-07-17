import 'package:santijet_demir/domain/enums/corporate_role.dart';
import 'package:santijet_demir/domain/enums/project_role.dart';

class ProjectMember {
  const ProjectMember({
    required this.projectId,
    required this.userId,
    required this.email,
    required this.displayName,
    required this.role,
    required this.canEdit,
    required this.joinedAt,
    this.corporateRole,
  });

  final String projectId;
  final String userId;
  final String email;
  final String displayName;
  final ProjectRole role;
  final bool canEdit;
  final DateTime joinedAt;

  /// Proje bazlı kurumsal rol (sahip atar). Yoksa hesap rolü kullanılır.
  final CorporateRole? corporateRole;

  bool get isOwner => role == ProjectRole.owner;

  ProjectMember copyWith({
    String? projectId,
    String? userId,
    String? email,
    String? displayName,
    ProjectRole? role,
    bool? canEdit,
    DateTime? joinedAt,
    CorporateRole? corporateRole,
    bool clearCorporateRole = false,
  }) {
    return ProjectMember(
      projectId: projectId ?? this.projectId,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      canEdit: canEdit ?? this.canEdit,
      joinedAt: joinedAt ?? this.joinedAt,
      corporateRole: clearCorporateRole
          ? null
          : (corporateRole ?? this.corporateRole),
    );
  }

  Map<String, dynamic> toJson() => {
        'projectId': projectId,
        'userId': userId,
        'email': email,
        'displayName': displayName,
        'role': role.name,
        'canEdit': canEdit,
        'joinedAt': joinedAt.toIso8601String(),
        'corporateRole': corporateRole?.storageValue,
      };

  factory ProjectMember.fromJson(Map<dynamic, dynamic> json) {
    return ProjectMember(
      projectId: json['projectId'] as String,
      userId: json['userId'] as String,
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      role: ProjectRole.values.byName(json['role'] as String? ?? 'viewer'),
      canEdit: json['canEdit'] as bool? ?? false,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      corporateRole: CorporateRole.fromStorage(
        json['corporateRole'] as String? ?? json['corporate_role'] as String?,
      ),
    );
  }
}
