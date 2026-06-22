import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:santijet_demir/data/repositories/project_data_repository.dart';
import 'package:santijet_demir/data/repositories/project_repository.dart';
import 'package:santijet_demir/domain/entities/project.dart';
import 'package:santijet_demir/domain/entities/project_member.dart';
import 'package:santijet_demir/features/auth/providers/auth_provider.dart';
import 'package:santijet_demir/features/settings/providers/settings_provider.dart';

final projectsBoxProvider = Provider<Box>((ref) {
  return Hive.box('projects');
});

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepository(ref.watch(projectsBoxProvider));
});

final projectDataRepositoryProvider = Provider<ProjectDataRepository>((ref) {
  return ProjectDataRepository(ref.watch(projectsBoxProvider));
});

final userProjectsProvider = Provider<List<Project>>((ref) {
  final auth = ref.watch(authProvider);
  final userId = auth.user?.id;
  if (userId == null) return [];
  return ref.watch(projectRepositoryProvider).getProjectsForUser(userId);
});

final activeProjectIdProvider = StateProvider<String?>((ref) {
  return ref.watch(projectRepositoryProvider).getActiveProjectId();
});

final activeProjectProvider = Provider<Project?>((ref) {
  final id = ref.watch(activeProjectIdProvider);
  if (id == null) return null;
  return ref.watch(projectRepositoryProvider).getProject(id);
});

final activeProjectMembershipProvider = Provider<ProjectMember?>((ref) {
  final auth = ref.watch(authProvider);
  final projectId = ref.watch(activeProjectIdProvider);
  final userId = auth.user?.id;
  if (projectId == null || userId == null) return null;
  return ref.watch(projectRepositoryProvider).getMembership(
        projectId: projectId,
        userId: userId,
      );
});

final canEditActiveProjectProvider = Provider<bool>((ref) {
  final membership = ref.watch(activeProjectMembershipProvider);
  return membership?.canEdit ?? false;
});

final projectMembersProvider =
    Provider.family<List<ProjectMember>, String>((ref, projectId) {
  return ref.watch(projectRepositoryProvider).getMembers(projectId);
});

final projectsControllerProvider =
    Provider<ProjectsController>((ref) => ProjectsController(ref));

class ProjectsController {
  ProjectsController(this._ref);

  final Ref _ref;

  ProjectRepository get _repo => _ref.read(projectRepositoryProvider);
  AuthState get _auth => _ref.read(authProvider);

  Future<void> ensureMigratedFromLegacy() async {
    final user = _auth.user;
    if (user == null) return;

    if (_repo.getAllProjects().isNotEmpty) {
      _ref.read(activeProjectIdProvider.notifier).state =
          _repo.getActiveProjectId();
      return;
    }

    final settings = _ref.read(appSettingsProvider);
    await _repo.createProject(
      owner: user,
      name: settings.projectName.isEmpty ? 'Yeni Proje' : settings.projectName,
      location: settings.projectLocation,
      startDate: settings.projectStartDate,
      endDate: settings.projectEndDate,
      progress: settings.projectProgress,
      code: settings.projectCode,
    );
    _ref.read(activeProjectIdProvider.notifier).state =
        _repo.getActiveProjectId();
    _ref.invalidate(userProjectsProvider);
  }

  Future<Project> createProject({
    required String name,
    required String location,
    DateTime? startDate,
    DateTime? endDate,
    double progress = 0,
  }) async {
    final user = _auth.user!;
    final project = await _repo.createProject(
      owner: user,
      name: name,
      location: location,
      startDate: startDate,
      endDate: endDate,
      progress: progress,
    );
    _ref.read(activeProjectIdProvider.notifier).state = project.id;
    _ref.invalidate(userProjectsProvider);
    return project;
  }

  Future<Project> joinByCode(String code) async {
    final user = _auth.user!;
    final project = await _repo.joinByCode(user: user, code: code);
    _ref.read(activeProjectIdProvider.notifier).state = project.id;
    _ref.invalidate(userProjectsProvider);
    return project;
  }

  Future<void> switchProject(String projectId) async {
    await _repo.setActiveProjectId(projectId);
    _ref.read(activeProjectIdProvider.notifier).state = projectId;
  }

  Future<void> updateProject(Project project) async {
    await _repo.updateProject(project);
    _ref.invalidate(userProjectsProvider);
    _ref.invalidate(activeProjectProvider);
  }

  Future<void> setMemberCanEdit({
    required String projectId,
    required String memberUserId,
    required bool canEdit,
  }) async {
    await _repo.updateMemberPermissions(
      projectId: projectId,
      memberUserId: memberUserId,
      canEdit: canEdit,
      actingUserId: _auth.user!.id,
    );
    _ref.invalidate(projectMembersProvider(projectId));
    _ref.invalidate(activeProjectMembershipProvider);
  }
}
