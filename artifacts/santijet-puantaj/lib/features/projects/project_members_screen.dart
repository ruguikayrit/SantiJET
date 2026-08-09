import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../data/providers/app_data_provider.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/collaboration_provider.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/project_member.dart';

class ProjectMembersScreen extends ConsumerStatefulWidget {
  const ProjectMembersScreen({super.key, required this.projectId});

  final String projectId;

  @override
  ConsumerState<ProjectMembersScreen> createState() =>
      _ProjectMembersScreenState();
}

class _ProjectMembersScreenState extends ConsumerState<ProjectMembersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(collaborationControllerProvider).refreshMembers(widget.projectId);
    });
  }

  Project? _findProject(List<Project> projects) {
    for (final p in projects) {
      if (p.id == widget.projectId) return p;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final proj = _findProject(ref.watch(projectsProvider));
    final members = ref.watch(projectMembersProvider(widget.projectId));
    final auth = ref.watch(authProvider);
    ProjectMember? myMembership;
    for (final m in members) {
      if (m.userId == auth.user?.id) {
        myMembership = m;
        break;
      }
    }
    final isOwner = myMembership?.isOwner == true ||
        (proj?.ownerId != null && proj!.ownerId == auth.user?.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(proj?.name ?? 'Ekip'),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: () => ref
                .read(collaborationControllerProvider)
                .refreshMembers(widget.projectId),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (proj != null) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    'İş Kodu: ${proj.code.isEmpty ? '—' : proj.code}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (proj.code.isNotEmpty)
                  IconButton(
                    tooltip: 'Kodu kopyala',
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: proj.code));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('İş kodu kopyalandı')),
                      );
                    },
                    icon: const Icon(Icons.copy),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Bu kodu paylaşarak ekip üyelerinin aynı şantiye verilerine '
              'erişmesini sağlayın. Sahip, her üyeye düzenleme açabilir.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  await ref
                      .read(collaborationControllerProvider)
                      .pushDomain(widget.projectId);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veriler buluta gönderildi')),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gönderilemedi: $e')),
                  );
                }
              },
              icon: const Icon(Icons.cloud_upload_outlined),
              label: const Text('Verileri senkronize et (gönder)'),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  await ref
                      .read(collaborationControllerProvider)
                      .pullDomain(widget.projectId);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veriler buluttan alındı')),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Çekilemedi: $e')),
                  );
                }
              },
              icon: const Icon(Icons.cloud_download_outlined),
              label: const Text('Verileri senkronize et (çek)'),
            ),
            const SizedBox(height: 20),
          ],
          Text('Ekip Üyeleri', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (members.isEmpty)
            const Text('Henüz üye listesi yok. Buluttan yenileyin.'),
          ...members.map(
            (member) => SwitchListTile(
              title: Text(
                '${member.displayName.isEmpty ? member.email : member.displayName}'
                '${member.userId == auth.user?.id ? ' (Siz)' : ''}',
              ),
              subtitle: Text('${member.role.label}\n${member.email}'),
              isThreeLine: true,
              value: member.canEdit,
              onChanged: isOwner && !member.isOwner
                  ? (canEdit) async {
                      try {
                        await ref
                            .read(collaborationControllerProvider)
                            .setMemberCanEdit(
                              projectId: widget.projectId,
                              memberUserId: member.userId,
                              canEdit: canEdit,
                            );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$e')),
                        );
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
