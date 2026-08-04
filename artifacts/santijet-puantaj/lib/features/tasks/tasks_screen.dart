import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/sj_card.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/santijet_header.dart';
import '../../data/providers/app_data_provider.dart';
import '../../data/providers/tasks_provider.dart';
import '../../domain/entities/site_task.dart';
import '../../domain/enums/task_status.dart';
import '../projects/widgets/project_switcher.dart';

/// Saha görevleri — aktif proje kapsamında.
class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  TaskStatus? _filter;

  Future<void> _openEditor({SiteTask? existing}) async {
    final project = ref.read(activeProjectProvider);
    if (project == null) return;

    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final assigneeCtrl = TextEditingController(text: existing?.assignee ?? '');
    final dueCtrl = TextEditingController(text: existing?.dueDate ?? '');
    var status = existing?.status ?? TaskStatus.todo;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surfaceElevated,
      builder: (ctx) {
        final bottom = MediaQuery.viewInsetsOf(ctx).bottom;
        return StatefulBuilder(
          builder: (ctx, setModal) {
            final theme = Theme.of(ctx);
            return Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                bottom + AppSpacing.md,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      existing == null ? 'Yeni görev' : 'Görevi düzenle',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Görev başlığı *',
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Açıklama',
                      ),
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: assigneeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Sorumlu',
                        hintText: 'Kişi veya ekip',
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: dueCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Termin',
                        hintText: 'dd.MM.yyyy',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Durum', style: theme.textTheme.labelLarge),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      children: [
                        for (final s in TaskStatus.values)
                          ChoiceChip(
                            label: Text(s.label),
                            selected: status == s,
                            onSelected: (_) => setModal(() => status = s),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(
                      onPressed: () {
                        if (titleCtrl.text.trim().isEmpty) return;
                        Navigator.pop(ctx, true);
                      },
                      child: const Text('Kaydet'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    final title = titleCtrl.text.trim();
    final description = descCtrl.text.trim();
    final assignee = assigneeCtrl.text.trim();
    final dueDate = dueCtrl.text.trim();
    titleCtrl.dispose();
    descCtrl.dispose();
    assigneeCtrl.dispose();
    dueCtrl.dispose();
    if (saved != true || title.isEmpty) return;

    if (existing == null) {
      ref.read(tasksProvider.notifier).add(
            projectId: project.id,
            title: title,
            description: description,
            assignee: assignee,
            dueDate: dueDate,
            status: status,
          );
    } else {
      ref.read(tasksProvider.notifier).upsert(
            existing.copyWith(
              title: title,
              description: description,
              assignee: assignee,
              dueDate: dueDate,
              status: status,
            ),
          );
    }
  }

  Color _statusColor(TaskStatus status) => switch (status) {
        TaskStatus.todo => AppColors.info,
        TaskStatus.doing => AppColors.warning,
        TaskStatus.done => AppColors.success,
      };

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(activeProjectProvider);
    final tasks = ref.watch(projectTasksProvider);
    final filtered = _filter == null
        ? tasks
        : tasks.where((t) => t.status == _filter).toList();

    if (project == null) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SantijetHeader(subtitle: 'Görevler'),
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: ProjectSwitcher(),
              ),
              Expanded(
                child: SJEmptyState(
                  title: 'Önce proje ekleyin',
                  message: 'Görev tanımlamak için en az bir projeniz olmalı.',
                  icon: Icons.apartment_outlined,
                  actionLabel: 'Projelere Git',
                  onAction: () => context.go(AppRoutes.projeler),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add_task_outlined),
        label: const Text('Görev'),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SantijetHeader(subtitle: 'Görevler'),
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: ProjectSwitcher(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: Text('Tümü (${tasks.length})'),
                      selected: _filter == null,
                      onSelected: (_) => setState(() => _filter = null),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    for (final s in TaskStatus.values) ...[
                      FilterChip(
                        label: Text(
                          '${s.label} (${tasks.where((t) => t.status == s).length})',
                        ),
                        selected: _filter == s,
                        onSelected: (_) => setState(() => _filter = s),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: filtered.isEmpty
                  ? SJEmptyState(
                      title: tasks.isEmpty
                          ? 'Henüz görev yok'
                          : 'Bu filtrede görev yok',
                      message: tasks.isEmpty
                          ? 'Şantiye işlerini takip etmek için görev ekleyin.'
                          : 'Başka bir durum seçin veya yeni görev ekleyin.',
                      icon: Icons.task_alt_outlined,
                      actionLabel: 'Görev Ekle',
                      onAction: () => _openEditor(),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.xs,
                        AppSpacing.md,
                        100,
                      ),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final task = filtered[index];
                        return SJCard(
                          child: Builder(
                            builder: (context) {
                              final theme = Theme.of(context);
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          task.title,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            decoration:
                                                task.status == TaskStatus.done
                                                    ? TextDecoration
                                                        .lineThrough
                                                    : null,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _statusColor(task.status)
                                              .withValues(alpha: 0.16),
                                          borderRadius: AppRadii.sm,
                                        ),
                                        child: Text(
                                          task.status.label,
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                            color: _statusColor(task.status),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (task.description.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      task.description,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Text(
                                    [
                                      if (task.assignee.isNotEmpty)
                                        task.assignee,
                                      if (task.dueDate.isNotEmpty)
                                        'Termin ${task.dueDate}',
                                    ].join(' · '),
                                    style: theme.textTheme.labelSmall,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Row(
                                    children: [
                                      PopupMenuButton<TaskStatus>(
                                        tooltip: 'Durum değiştir',
                                        onSelected: (s) => ref
                                            .read(tasksProvider.notifier)
                                            .setStatus(task.id, s),
                                        itemBuilder: (ctx) => [
                                          for (final s in TaskStatus.values)
                                            PopupMenuItem(
                                              value: s,
                                              child: Text(s.label),
                                            ),
                                        ],
                                        child: Text(
                                          'Durum',
                                          style: theme.textTheme.labelLarge
                                              ?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        tooltip: 'Düzenle',
                                        onPressed: () =>
                                            _openEditor(existing: task),
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          size: 20,
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Sil',
                                        onPressed: () async {
                                          final ok = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('Görevi sil'),
                                              content: Text(
                                                '“${task.title}” silinsin mi?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx, false),
                                                  child: const Text('Vazgeç'),
                                                ),
                                                FilledButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx, true),
                                                  child: const Text('Sil'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (ok == true) {
                                            ref
                                                .read(tasksProvider.notifier)
                                                .delete(task.id);
                                          }
                                        },
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
