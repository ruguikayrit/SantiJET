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

    final createdAt = DateTime.now().toUtc();

    try {
      await _ensureProfile(owner);
      final projectId = await _client.rpc(
        'create_saha_project',
        params: {
          'p_name': trimmedName,
          'p_code': finalCode,
          'p_company': company.trim(),
          'p_logo_base64': logoBase64,
          'p_logo_mime_type': logoMimeType,
        },
      ) as String;

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
    } on PostgrestException catch (e) {
      throw ProjectException(_mapProjectError(e));
    }
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

  /// İş koduna göre (üyesi/sahibi olunan) bulut projeyi bul.
  Future<Project?> findProjectByCode(String code) async {
    final trimmed = code.trim().toUpperCase();
    if (trimmed.isEmpty) return null;
    try {
      final row = await _client
          .from('saha_projects')
          .select()
          .eq('code', trimmed)
          .maybeSingle();
      if (row == null) return null;
      return _projectFromJson(row);
    } on PostgrestException {
      return null;
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
    if (message.contains('invalid input syntax for type uuid')) {
      return 'Bu iş henüz buluta bağlanmamış. Senkron tekrar denensin '
          '(yerel iş bulut UUID’sine taşınacak).';
    }
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

/// Supabase `uuid` kolonları için geçerli kimlik mi?
bool isSahaUuid(String id) {
  return RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  ).hasMatch(id.trim());
}
