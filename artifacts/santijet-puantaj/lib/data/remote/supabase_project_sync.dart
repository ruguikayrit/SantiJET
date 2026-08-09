import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/project_code_generator.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/project_member.dart';
import '../../domain/entities/user_account.dart';
import '../../domain/enums/project_role.dart';
import 'supabase_service.dart';

class ProjectException implements Exception {
  ProjectException(this.message);
  final String message;

  @override
  String toString() => message;
}

class SupabaseProjectSync {
  SupabaseClient get _client => SupabaseService.client;

  Future<List<(Project, ProjectMember)>> pullUserProjects(String userId) async {
    final memberRows = await _client
        .from('saha_project_members')
        .select()
        .eq('user_id', userId);

    if (memberRows.isEmpty) return const [];

    final projectIds = memberRows
        .map((row) => row['project_id'] as String)
        .toSet()
        .toList();

    final projectRows = await _client
        .from('saha_projects')
        .select()
        .inFilter('id', projectIds);

    final projectsById = <String, Project>{
      for (final row in projectRows)
        row['id'] as String: _projectFromJson(row),
    };

    final out = <(Project, ProjectMember)>[];
    for (final row in memberRows) {
      final projectId = row['project_id'] as String;
      final project = projectsById[projectId];
      if (project == null) continue;
      out.add((project, _memberFromJson(row, projectId)));
    }
    return out;
  }

  Future<Project> createProject({
    required UserAccount owner,
    required String name,
    String company = '',
    String? code,
    String logoBase64 = '',
    String logoMimeType = 'image/jpeg',
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ProjectException('İş adı boş olamaz');
    }

    var finalCode = code?.trim().toUpperCase();
    if (finalCode == null || finalCode.isEmpty) {
      finalCode = ProjectCodeGenerator.generate();
    }

    final projectId = _newUuidV4();
    final createdAt = DateTime.now().toUtc();

    try {
      await _ensureProfile(owner);
      await _client.from('saha_projects').insert({
        'id': projectId,
        'code': finalCode,
        'name': trimmedName,
        'company': company.trim(),
        'owner_id': owner.id,
        'logo_base64': logoBase64,
        'logo_mime_type': logoMimeType,
      });

      await _client.from('saha_project_members').insert({
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

    return Project(
      id: projectId,
      code: finalCode,
      name: trimmedName,
      company: company.trim(),
      ownerId: owner.id,
      logoBase64: logoBase64,
      logoMimeType: logoMimeType,
      createdAt: createdAt,
    );
  }

  Future<Project> joinByCode({
    required UserAccount user,
    required String code,
  }) async {
    try {
      await _ensureProfile(user);
      final projectId = await _client.rpc(
        'join_saha_project_by_code',
        params: {'p_code': code.trim().toUpperCase()},
      ) as String;

      final projectRow = await _client
          .from('saha_projects')
          .select()
          .eq('id', projectId)
          .single();

      return _projectFromJson(projectRow);
    } on PostgrestException catch (e) {
      final message = e.message.toLowerCase();
      if (message.contains('bulunamadı') || message.contains('not found')) {
        throw ProjectException('İş kodu bulunamadı');
      }
      throw ProjectException(e.message);
    }
  }

  Future<void> updateProject(Project project) async {
    await _client.from('saha_projects').update({
      'name': project.name,
      'company': project.company,
      'logo_base64': project.logoBase64,
      'logo_mime_type': project.logoMimeType,
    }).eq('id', project.id);
  }

  Future<List<ProjectMember>> fetchMembers(String projectId) async {
    final rows = await _client
        .from('saha_project_members')
        .select()
        .eq('project_id', projectId);
    return rows
        .map((row) => _memberFromJson(row, projectId))
        .toList();
  }

  Future<void> updateMemberPermissions({
    required String projectId,
    required String memberUserId,
    required bool canEdit,
  }) async {
    await _client.from('saha_project_members').update({
      'can_edit': canEdit,
      'role': canEdit ? ProjectRole.editor.name : ProjectRole.viewer.name,
    }).eq('project_id', projectId).eq('user_id', memberUserId);
  }

  Project _projectFromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      company: json['company'] as String? ?? '',
      ownerId: json['owner_id'] as String?,
      logoBase64: json['logo_base64'] as String? ?? '',
      logoMimeType: json['logo_mime_type'] as String? ?? 'image/jpeg',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
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
      joinedAt: DateTime.parse(
        json['joined_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  String _mapProjectError(PostgrestException e) {
    final message = e.message.toLowerCase();
    if (message.contains('duplicate key') || message.contains('unique')) {
      return 'Bu iş kodu zaten kullanılıyor';
    }
    if (message.contains('foreign key') || message.contains('profiles')) {
      return 'Hesap profili henüz hazır değil. Çıkış yapıp tekrar giriş deneyin.';
    }
    if (message.contains('row-level security') || message.contains('policy')) {
      return 'İş oluşturma izni yok. Supabase RLS ayarlarını kontrol edin.';
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
