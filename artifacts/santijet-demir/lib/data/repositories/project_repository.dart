import 'package:hive/hive.dart';
import 'package:santijet_demir/core/utils/project_code_generator.dart';
import 'package:santijet_demir/domain/entities/project.dart';
import 'package:santijet_demir/domain/entities/project_member.dart';
import 'package:santijet_demir/domain/entities/user_account.dart';
import 'package:santijet_demir/domain/enums/project_role.dart';

const _projectsKey = 'projects';
const _membersKey = 'members';
const _codesKey = 'project_codes';
const _activeProjectKey = 'active_project_id';

class ProjectRepository {
  ProjectRepository(this._box);

  final Box _box;

  List<Project> getAllProjects() {
    final raw = _box.get(_projectsKey);
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => Project.fromJson(e))
        .toList();
  }

  Project? getProject(String id) {
    for (final project in getAllProjects()) {
      if (project.id == id) return project;
    }
    return null;
  }

  Project? findByCode(String code) {
    final normalized = code.trim().toUpperCase();
    final codes = _loadCodes();
    final projectId = codes[normalized];
    if (projectId == null) return null;
    return getProject(projectId);
  }

  List<ProjectMember> getMembers(String projectId) {
    final raw = _box.get(_membersKey);
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => ProjectMember.fromJson(e))
        .where((m) => m.projectId == projectId)
        .toList();
  }

  List<Project> getProjectsForUser(String userId) {
    final memberProjectIds = _allMembers()
        .where((m) => m.userId == userId)
        .map((m) => m.projectId)
        .toSet();
    return getAllProjects()
        .where((p) => memberProjectIds.contains(p.id))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  ProjectMember? getMembership({
    required String projectId,
    required String userId,
  }) {
    for (final member in getMembers(projectId)) {
      if (member.userId == userId) return member;
    }
    return null;
  }

  String? getActiveProjectId() {
    return _box.get(_activeProjectKey) as String?;
  }

  Future<void> setActiveProjectId(String? projectId) async {
    if (projectId == null) {
      await _box.delete(_activeProjectKey);
    } else {
      await _box.put(_activeProjectKey, projectId);
    }
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
    final id = _newId('proj');
    final codes = _loadCodes();
    final projectCode = code?.trim().toUpperCase();
    var finalCode = ProjectCodeGenerator.generate();
    if (projectCode == null || projectCode.isEmpty) {
      while (codes.containsKey(finalCode)) {
        finalCode = ProjectCodeGenerator.generate();
      }
    } else {
      finalCode = projectCode;
      if (codes.containsKey(finalCode)) {
        throw ProjectException('Bu proje kodu zaten kullanılıyor');
      }
    }

    final project = Project(
      id: id,
      code: finalCode,
      name: name.trim(),
      location: location.trim(),
      ownerId: owner.id,
      createdAt: DateTime.now(),
      startDate: startDate,
      endDate: endDate,
      progress: progress,
    );

    final projects = getAllProjects()..add(project);
    await _saveProjects(projects);

    codes[finalCode] = id;
    await _saveCodes(codes);

    await _addMember(
      ProjectMember(
        projectId: id,
        userId: owner.id,
        email: owner.email,
        displayName: owner.displayName,
        role: ProjectRole.owner,
        canEdit: true,
        joinedAt: DateTime.now(),
      ),
    );

    await setActiveProjectId(id);
    return project;
  }

  Future<Project> joinByCode({
    required UserAccount user,
    required String code,
  }) async {
    final project = findByCode(code);
    if (project == null) {
      throw ProjectException('Proje kodu bulunamadı');
    }

    final existing = getMembership(projectId: project.id, userId: user.id);
    if (existing != null) {
      await setActiveProjectId(project.id);
      return project;
    }

    await _addMember(
      ProjectMember(
        projectId: project.id,
        userId: user.id,
        email: user.email,
        displayName: user.displayName,
        role: ProjectRole.viewer,
        canEdit: false,
        joinedAt: DateTime.now(),
      ),
    );

    await setActiveProjectId(project.id);
    return project;
  }

  Future<Project> updateProject(Project project) async {
    final projects = getAllProjects();
    final index = projects.indexWhere((p) => p.id == project.id);
    if (index < 0) throw ProjectException('Proje bulunamadı');
    projects[index] = project;
    await _saveProjects(projects);
    return project;
  }

  Future<void> updateMemberPermissions({
    required String projectId,
    required String memberUserId,
    required bool canEdit,
    required String actingUserId,
  }) async {
    final acting = getMembership(projectId: projectId, userId: actingUserId);
    if (acting == null || !acting.isOwner) {
      throw ProjectException('Yetki güncelleme izniniz yok');
    }

    final members = _allMembers();
    final index = members.indexWhere(
      (m) => m.projectId == projectId && m.userId == memberUserId,
    );
    if (index < 0) throw ProjectException('Üye bulunamadı');
    if (members[index].isOwner) {
      throw ProjectException('Proje sahibinin yetkisi değiştirilemez');
    }

    members[index] = members[index].copyWith(
      canEdit: canEdit,
      role: canEdit ? ProjectRole.editor : ProjectRole.viewer,
    );
    await _saveMembers(members);
  }

  Future<void> replaceAll(
    List<Project> projects,
    List<ProjectMember> members,
  ) async {
    await _saveProjects(projects);
    await _saveMembers(members);
    final codes = <String, String>{
      for (final project in projects) project.code: project.id,
    };
    await _saveCodes(codes);
  }

  Future<void> upsertProject(Project project) async {
    final projects = getAllProjects();
    final index = projects.indexWhere((p) => p.id == project.id);
    if (index >= 0) {
      projects[index] = project;
    } else {
      projects.add(project);
    }
    await _saveProjects(projects);

    final codes = _loadCodes();
    codes[project.code] = project.id;
    await _saveCodes(codes);
  }

  Future<void> upsertMember(ProjectMember member) async {
    final members = _allMembers();
    final index = members.indexWhere(
      (m) => m.projectId == member.projectId && m.userId == member.userId,
    );
    if (index >= 0) {
      members[index] = member;
    } else {
      members.add(member);
    }
    await _saveMembers(members);
  }

  List<ProjectMember> _allMembers() {
    final raw = _box.get(_membersKey);
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => ProjectMember.fromJson(e))
        .toList();
  }

  Future<void> _addMember(ProjectMember member) async {
    final members = _allMembers()..add(member);
    await _saveMembers(members);
  }

  Future<void> _saveProjects(List<Project> projects) async {
    await _box.put(_projectsKey, projects.map((e) => e.toJson()).toList());
  }

  Future<void> _saveMembers(List<ProjectMember> members) async {
    await _box.put(_membersKey, members.map((e) => e.toJson()).toList());
  }

  Map<String, String> _loadCodes() {
    final raw = _box.get(_codesKey);
    if (raw is! Map) return {};
    return raw.map((key, value) => MapEntry(key.toString(), value.toString()));
  }

  Future<void> _saveCodes(Map<String, String> codes) async {
    await _box.put(_codesKey, codes);
  }

  String _newId(String prefix) {
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}';
  }
}

class ProjectException implements Exception {
  ProjectException(this.message);
  final String message;

  @override
  String toString() => message;
}
