import 'package:santijet_demir/core/utils/project_code_generator.dart';
import 'package:santijet_demir/data/remote/supabase_service.dart';
import 'package:santijet_demir/data/repositories/project_repository.dart';
import 'package:santijet_demir/domain/entities/project.dart';
import 'package:santijet_demir/domain/entities/project_member.dart';
import 'package:santijet_demir/domain/entities/user_account.dart';
import 'package:santijet_demir/domain/enums/project_role.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseProjectSync {
  SupabaseProjectSync(this._local);

  final ProjectRepository _local;

  SupabaseClient get _client => SupabaseService.client;

  Future<void> pullUserProjects(String userId) async {
    final rows = await _client
        .from('project_members')
        .select('*, projects(*)')
        .eq('user_id', userId);

    final projects = <Project>[];
    final members = <ProjectMember>[];

    for (final row in rows) {
      final projectJson = row['projects'] as Map<String, dynamic>?;
      if (projectJson == null) continue;

      final project = _projectFromJson(projectJson);
      projects.add(project);
      members.add(_memberFromJson(row, project.id));
    }

    await _local.replaceAll(projects, members);
  }

  Future<Project> createProject({
    required UserAccount owner,
    required String name,
    required String location,
    DateTime? startDate,
    DateTime? endDate,
    double progress = 0,
    String? code,
  }) async {
    var finalCode = code?.trim().toUpperCase();
    if (finalCode == null || finalCode.isEmpty) {
      finalCode = ProjectCodeGenerator.generate();
    }

    final inserted = await _client
        .from('projects')
        .insert({
          'code': finalCode,
          'name': name.trim(),
          'location': location.trim(),
          'owner_id': owner.id,
          'start_date': startDate?.toIso8601String().split('T').first,
          'end_date': endDate?.toIso8601String().split('T').first,
          'progress': progress,
        })
        .select()
        .single();

    final project = _projectFromJson(inserted);

    await _client.from('project_members').insert({
      'project_id': project.id,
      'user_id': owner.id,
      'email': owner.email,
      'display_name': owner.displayName,
      'role': ProjectRole.owner.name,
      'can_edit': true,
    });

    await _local.upsertProject(project);
    await _local.upsertMember(
      ProjectMember(
        projectId: project.id,
        userId: owner.id,
        email: owner.email,
        displayName: owner.displayName,
        role: ProjectRole.owner,
        canEdit: true,
        joinedAt: DateTime.now(),
      ),
    );
    await _local.setActiveProjectId(project.id);
    return project;
  }

  Future<Project> joinByCode({
    required UserAccount user,
    required String code,
  }) async {
    try {
      final projectId = await _client.rpc(
        'join_project_by_code',
        params: {'p_code': code.trim().toUpperCase()},
      ) as String;

      final projectRow = await _client
          .from('projects')
          .select()
          .eq('id', projectId)
          .single();

      final project = _projectFromJson(projectRow);
      await pullUserProjects(user.id);
      await _local.setActiveProjectId(project.id);
      return project;
    } on PostgrestException catch (e) {
      final message = e.message.toLowerCase();
      if (message.contains('bulunamadı') || message.contains('not found')) {
        throw ProjectException('Proje kodu bulunamadı');
      }
      throw ProjectException(e.message);
    }
  }

  Future<Project> updateProject(Project project) async {
    await _client.from('projects').update({
      'name': project.name,
      'location': project.location,
      'start_date': project.startDate?.toIso8601String().split('T').first,
      'end_date': project.endDate?.toIso8601String().split('T').first,
      'progress': project.progress,
    }).eq('id', project.id);

    await _local.updateProject(project);
    return project;
  }

  Future<void> updateMemberPermissions({
    required String projectId,
    required String memberUserId,
    required bool canEdit,
    required String actingUserId,
  }) async {
    await _client.from('project_members').update({
      'can_edit': canEdit,
      'role': canEdit ? ProjectRole.editor.name : ProjectRole.viewer.name,
    }).eq('project_id', projectId).eq('user_id', memberUserId);

    await _local.updateMemberPermissions(
      projectId: projectId,
      memberUserId: memberUserId,
      canEdit: canEdit,
      actingUserId: actingUserId,
    );
  }

  Project _projectFromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String? ?? '',
      location: json['location'] as String? ?? '',
      ownerId: json['owner_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'] as String)
          : null,
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
    );
  }

  ProjectMember _memberFromJson(Map<String, dynamic> json, String projectId) {
    return ProjectMember(
      projectId: projectId,
      userId: json['user_id'] as String,
      email: json['email'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      role: ProjectRole.values.byName(json['role'] as String? ?? 'viewer'),
      canEdit: json['can_edit'] as bool? ?? false,
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }
}
