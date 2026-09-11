import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/program_project.dart';
import '../../state/app_state.dart';
import '../../ui/design_system.dart';
import 'settings_scaffold.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectsProvider);
    final activeId = ref.watch(activeProjectProvider)?.id;

    return SettingsScaffold(
      title: 'Projelerim',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          Text(
            'Aktif şantiye Program, Gantt ve Özet’te kullanılır. '
            'Seçim bu cihazda kalır.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (projects.isEmpty)
            const SJCard(
              child: Text('Henüz proje yok. Yeni şantiye ekleyin.'),
            )
          else
            ...projects.map(
              (project) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SJCard(
                  selected: project.id == activeId,
                  onTap: () =>
                      ref.read(projectsProvider.notifier).select(project.id),
                  child: Row(
                    children: [
                      Icon(
                        project.id == activeId
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: AppColors.electricBlue,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              project.name,
                              style: AppTypography.cardTitleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              project.code,
                              style: AppTypography.cardBodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Yeniden adlandır',
                        onPressed: () => _edit(context, ref, project),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Sil',
                        onPressed: () => _delete(context, ref, project),
                        icon: Icon(
                          Icons.delete_outline,
                          color: AppColors.critical,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          SJButton(
            label: 'Yeni şantiye',
            icon: Icons.add_rounded,
            onPressed: () => _edit(context, ref, null),
            expanded: true,
          ),
        ],
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    ProgramProject? existing,
  ) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: Text(
          existing == null ? 'Yeni şantiye' : 'Şantiyeyi düzenle',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: name,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Şantiye adı'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    final trimmed = name.text.trim();
    name.dispose();
    if (accepted != true || trimmed.isEmpty) return;
    if (existing == null) {
      await ref.read(projectsProvider.notifier).ensureNamed(trimmed);
    } else {
      await ref.read(projectsProvider.notifier).save(
        existing.copyWith(name: trimmed),
      );
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    ProgramProject project,
  ) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: Text(
          'Şantiye silinsin mi?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          '${project.name} ve bu şantiyedeki imalatlar silinir.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (accepted == true) {
      await ref.read(projectsProvider.notifier).delete(project.id);
    }
  }
}
