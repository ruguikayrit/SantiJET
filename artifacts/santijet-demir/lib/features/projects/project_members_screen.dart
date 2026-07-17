import 'package:flutter/material.dart';
import 'package:santijet_demir/core/widgets/app_toast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/data/repositories/project_repository.dart';
import 'package:santijet_demir/domain/entities/project_member.dart';
import 'package:santijet_demir/domain/enums/corporate_role.dart';
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
    final myMembership =
        members.where((m) => m.userId == auth.user?.id).firstOrNull;
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
              'Bu kodu paylaşarak ekip üyelerinin aynı şantiye verilerine '
              'erişmesini sağlayın. Proje sahibi her üyeye kurumsal rol atayabilir.',
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
                    ScaffoldMessenger.of(context).showAppSnackBar(
                      SnackBar(content: Text(e.message)),
                    );
                  }
                }
              },
              onAssignRole: isOwner
                  ? (role) async {
                      try {
                        await ref
                            .read(projectsControllerProvider)
                            .setMemberCorporateRole(
                              projectId: projectId,
                              memberUserId: member.userId,
                              corporateRole: role,
                            );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showAppSnackBar(
                            SnackBar(
                              content: Text(
                                role == null
                                    ? 'Rol kaldırıldı — hesap rolü geçerli'
                                    : '${member.displayName}: ${role.label}',
                              ),
                            ),
                          );
                        }
                      } on ProjectException catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showAppSnackBar(
                            SnackBar(content: Text(e.message)),
                          );
                        }
                      }
                    }
                  : null,
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
    required this.onAssignRole,
  });

  final ProjectMember member;
  final bool isOwner;
  final bool isSelf;
  final ValueChanged<bool> onToggleEdit;
  final ValueChanged<CorporateRole?>? onAssignRole;

  @override
  Widget build(BuildContext context) {
    final roleLabel = member.corporateRole?.label ?? 'Hesap rolü';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: Text('${member.displayName}${isSelf ? ' (Siz)' : ''}'),
            subtitle: Text(
              '${member.role.label} · $roleLabel\n${member.email}',
            ),
            isThreeLine: true,
            value: member.canEdit,
            onChanged: isOwner && !member.isOwner ? onToggleEdit : null,
          ),
          if (onAssignRole != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: DropdownButtonFormField<CorporateRole?>(
                value: member.corporateRole,
                decoration: const InputDecoration(
                  labelText: 'Kurumsal rol',
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<CorporateRole?>(
                    value: null,
                    child: Text('Hesap rolünü kullan'),
                  ),
                  ...CorporateRole.values.map(
                    (role) => DropdownMenuItem<CorporateRole?>(
                      value: role,
                      child: Text(role.label),
                    ),
                  ),
                ],
                onChanged: onAssignRole,
              ),
            ),
        ],
      ),
    );
  }
}
