import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/providers/app_data_provider.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/collaboration_provider.dart';
import '../../data/providers/saha_realtime_sync_provider.dart';
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
      // ignore: unawaited_futures
      ref.read(sahaRealtimeSyncProvider).startForProject(widget.projectId);
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
    final sync = ref.watch(sahaSyncStateProvider);
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
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                switch (sync.phase) {
                  SahaSyncPhase.live => Icons.cloud_done_outlined,
                  SahaSyncPhase.syncing => Icons.cloud_sync_outlined,
                  SahaSyncPhase.error => Icons.cloud_off_outlined,
                  SahaSyncPhase.offline => Icons.cloud_off_outlined,
                  SahaSyncPhase.idle => Icons.cloud_outlined,
                },
              ),
              title: Text(sync.label),
              subtitle: Text(
                sync.lastSyncedAt == null
                    ? 'Değişiklikler cihazlar arasında otomatik senkronize edilir.'
                    : 'Son senkron: ${_fmtTime(sync.lastSyncedAt!)}',
              ),
            ),
            OutlinedButton.icon(
              onPressed: sync.phase == SahaSyncPhase.syncing
                  ? null
                  : () async {
                      try {
                        final cloudId = await ref
                            .read(sahaRealtimeSyncProvider)
                            .pushProject(widget.projectId);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Bulutla senkronize edildi'),
                          ),
                        );
                        if (cloudId != widget.projectId) {
                          context.go(AppRoutes.projeUyeler(cloudId));
                        }
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Senkron başarısız: $e')),
                        );
                      }
                    },
              icon: const Icon(Icons.sync),
              label: const Text('Şimdi senkronize et'),
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

  String _fmtTime(DateTime t) {
    final local = t.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
