import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/data/repositories/project_repository.dart';
import 'package:santijet_demir/domain/entities/project_member.dart';
import 'package:santijet_demir/features/auth/providers/auth_provider.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';

class ProjectMembersScreen extends ConsumerWidget {
  const ProjectMembersScreen({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(projectRepositoryProvider).getProject(projectId);
    final members = ref.watch(projectMembersProvider(projectId));
    final auth = ref.watch(authProvider);
    final myMembership = members.where((m) => m.userId == auth.user?.id).firstOrNull;
    final isOwner = myMembership?.isOwner ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(project?.name ?? 'Ekip'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (project != null) ...[
            Text('Proje Kodu: ${project.code}', style: AppTypography.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Bu kodu paylaşarak ekip üyelerinin aynı şantiye verilerine erişmesini sağlayın.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 20),
          ],
          Text('Ekip Üyeleri', style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          ...members.map(
            (member) => _MemberTile(
              member: member,
              isOwner: isOwner,
              isSelf: member.userId == auth.user?.id,
              onToggleEdit: (canEdit) async {
                try {
                  await ref.read(projectsControllerProvider).setMemberCanEdit(
                        projectId: projectId,
                        memberUserId: member.userId,
                        canEdit: canEdit,
                      );
                } on ProjectException catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.message)),
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.isOwner,
    required this.isSelf,
    required this.onToggleEdit,
  });

  final ProjectMember member;
  final bool isOwner;
  final bool isSelf;
  final ValueChanged<bool> onToggleEdit;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text('${member.displayName}${isSelf ? ' (Siz)' : ''}'),
      subtitle: Text('${member.role.label} • ${member.email}'),
      value: member.canEdit,
      onChanged: isOwner && !member.isOwner
          ? onToggleEdit
          : null,
    );
  }
}
