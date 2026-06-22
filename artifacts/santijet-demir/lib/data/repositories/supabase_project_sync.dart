import 'dart:math';

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
    final memberRows = await _client
        .from('project_members')
        .select()
        .eq('user_id', userId);

    if (memberRows.isEmpty) {
      return;
    }

    final projectIds = memberRows
        .map((row) => row['project_id'] as String)
        .toSet()
        .toList();

    final projectRows = await _client
        .from('projects')
        .select()
        .inFilter('id', projectIds);

    final projectsById = <String, Project>{
      for (final row in projectRows)
        row['id'] as String: _projectFromJson(row),
    };

    final projects = <Project>[];
    final members = <ProjectMember>[];

    for (final row in memberRows) {
      final projectId = row['project_id'] as String;
      final project = projectsById[projectId];
      if (project == null) continue;

      projects.add(project);
      members.add(_memberFromJson(row, projectId));
    }

    if (projects.isEmpty) {
      return;
    }

    await _local.mergeFromCloud(projects, members);
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
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ProjectException('Proje adı boş olamaz');
    }

    var finalCode = code?.trim().toUpperCase();
    if (finalCode == null || finalCode.isEmpty) {
      finalCode = ProjectCodeGenerator.generate();
    }

    final projectId = _newUuidV4();
    final createdAt = DateTime.now().toUtc();

    try {
      await _ensureProfile(owner);
      await _client.from('projects').insert({
        'id': projectId,
        'code': finalCode,
        'name': trimmedName,
        'location': location.trim(),
        'owner_id': owner.id,
        'start_date': startDate?.toIso8601String().split('T').first,
        'end_date': endDate?.toIso8601String().split('T').first,
        'progress': progress,
      });

      await _client.from('project_members').insert({
        'project_id': projectId,
        'user_id': owner.id,
        'email': owner.email,
        'display_name': owner.displayName,
        'role': ProjectRole.owner.name,
        'can_edit': true,
      });
    } on PostgrestException catch (e) {
      throw ProjectException(_mapProjectError(e));
    }

    final project = Project(
      id: projectId,
      code: finalCode,
      name: trimmedName,
      location: location.trim(),
      ownerId: owner.id,
      createdAt: createdAt,
      startDate: startDate,
      endDate: endDate,
      progress: progress,
    );

    await _local.upsertProject(project);
    await _local.upsertMember(
      ProjectMember(
        projectId: project.id,
        userId: owner.id,
        email: owner.email,
        displayName: owner.displayName,
        role: ProjectRole.owner,
        canEdit: true,
        joinedAt: createdAt,
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
      await _ensureProfile(user);
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

  String _mapProjectError(PostgrestException e) {
    final message = e.message.toLowerCase();
    if (message.contains('invalid path specified')) {
      return 'Supabase bağlantı ayarı hatalı. Yöneticiye bildirin.';
    }
    if (message.contains('duplicate key') || message.contains('unique')) {
      return 'Bu proje kodu zaten kullanılıyor';
    }
    if (message.contains('foreign key') || message.contains('profiles')) {
      return 'Hesap profili henüz hazır değil. Çıkış yapıp tekrar giriş deneyin.';
    }
    if (message.contains('row-level security') || message.contains('policy')) {
      return 'Proje oluşturma izni yok. Supabase RLS ayarlarını kontrol edin.';
    }
    return e.message;
  }

  Future<void> _ensureProfile(UserAccount user) async {
    final existing = await _client
        .from('profiles')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();
    if (existing != null) return;

    await _client.from('profiles').insert({
      'id': user.id,
      'email': user.email,
      'display_name': user.displayName,
    });
  }
}

String _newUuidV4() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
