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
import '../../data/providers/active_operator_provider.dart';
import '../../data/providers/app_data_provider.dart';
import '../../data/providers/tasks_provider.dart';
import '../../domain/entities/person.dart';
import '../../domain/entities/site_task.dart';
import '../../domain/enums/task_status.dart';
import '../../domain/permissions/role_degree.dart';
import '../projects/widgets/project_switcher.dart';

/// Saha görevleri — atayan (1. derece) + atanan görür.
class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  TaskStatus? _filter;

  Future<void> _pickOperator(List<Person> people) async {
    final currentId = ref.read(activeOperatorIdProvider);
    final picked = await showModalBottomSheet<Person>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surfaceElevated,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(ctx).height * 0.55,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: Text(
                    'Kim olarak çalışıyorsunuz?',
                    style: theme.textTheme.headlineMedium,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Text(
                    'Görevler yalnızca size atananlar ve (1. derece iseniz) '
                    'sizin atadıklarınız olarak listelenir.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: ListView.separated(
                    itemCount: people.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final p = people[index];
                      final selected = p.id == currentId;
                      final degree = RoleDegree.forPerson(p);
                      return ListTile(
                        selected: selected,
                        title: Text(p.name),
                        subtitle: Text(
                          [
                            if (p.profession.isNotEmpty) p.profession,
                            degree == RoleDegree.first
                                ? '1. derece · görev atayabilir'
                                : 'Atanan görevleri görür',
                          ].join(' · '),
                        ),
                        trailing: selected
                            ? Icon(
                                Icons.check_circle,
                                color: theme.colorScheme.primary,
                              )
                            : null,
                        onTap: () => Navigator.pop(ctx, p),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (picked != null) {
      ref.read(activeOperatorIdProvider.notifier).set(picked.id);
    }
  }

  Future<void> _openEditor({
    SiteTask? existing,
    required Person operator,
    required List<Person> people,
  }) async {
    final project = ref.read(activeProjectProvider);
    if (project == null) return;

    final canAssign = RoleDegree.canAssignTasks(operator);
    if (existing == null && !canAssign) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Görev atamak için 1. derece rol gerekir '
            '(ör. Saha Mühendisi, Şantiye Şefi).',
          ),
        ),
      );
      return;
    }

    final isAssigner = existing == null ||
        existing.assignerPersonId == operator.id ||
        (existing.assignerPersonId.isEmpty && canAssign);
    if (existing != null && !isAssigner && existing.assigneePersonId != operator.id) {
      return;
    }

    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final dueCtrl = TextEditingController(text: existing?.dueDate ?? '');
    var status = existing?.status ?? TaskStatus.todo;
    Person? assignee;
    if (existing != null) {
      for (final p in people) {
        if (p.id == existing.assigneePersonId) {
          assignee = p;
          break;
        }
      }
    }

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
            final canEditFields = existing == null || isAssigner;
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
                      existing == null ? 'Yeni görev ata' : 'Görevi düzenle',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Atayan: ${operator.name}'
                      '${operator.profession.isNotEmpty ? ' · ${operator.profession}' : ''}',
                      style: theme.textTheme.labelMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: titleCtrl,
                      enabled: canEditFields,
                      decoration: const InputDecoration(
                        labelText: 'Görev başlığı *',
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: descCtrl,
                      enabled: canEditFields,
                      decoration: const InputDecoration(
                        labelText: 'Açıklama',
                      ),
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<String>(
                      value: assignee?.id,
                      decoration: const InputDecoration(
                        labelText: 'Atanan personel *',
                      ),
                      items: [
                        for (final p in people)
                          DropdownMenuItem(
                            value: p.id,
                            child: Text(
                              '${p.name}'
                              '${p.profession.isNotEmpty ? ' · ${p.profession}' : ''}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: canEditFields
                          ? (id) => setModal(() {
                                Person? next;
                                for (final p in people) {
                                  if (p.id == id) {
                                    next = p;
                                    break;
                                  }
                                }
                                assignee = next;
                              })
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: dueCtrl,
                      enabled: canEditFields,
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
                        if (assignee == null) return;
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
    final dueDate = dueCtrl.text.trim();
    titleCtrl.dispose();
    descCtrl.dispose();
    dueCtrl.dispose();
    if (saved != true || title.isEmpty || assignee == null) return;

    if (existing == null) {
      ref.read(tasksProvider.notifier).add(
            projectId: project.id,
            title: title,
            description: description,
            dueDate: dueDate,
            status: status,
            assigner: operator,
            assignee: assignee!,
          );
    } else if (isAssigner) {
      ref.read(tasksProvider.notifier).upsert(
            existing.copyWith(
              title: title,
              description: description,
              dueDate: dueDate,
              status: status,
              assignee: assignee!.name,
              assigneePersonId: assignee!.id,
              assignerPersonId: existing.assignerPersonId.isEmpty
                  ? operator.id
                  : existing.assignerPersonId,
              assignerName: existing.assignerName.isEmpty
                  ? operator.name
                  : existing.assignerName,
            ),
          );
    } else {
      // Atanan yalnızca durum günceller.
      ref.read(tasksProvider.notifier).setStatus(existing.id, status);
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
    final operator = ref.watch(activeOperatorProvider);
    final people = ref.watch(activePersonnelProvider);
    final tasks = ref.watch(visibleProjectTasksProvider);
    final filtered = _filter == null
        ? tasks
        : tasks.where((t) => t.status == _filter).toList();
    final canAssign =
        operator != null && RoleDegree.canAssignTasks(operator);

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

    if (people.isEmpty) {
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
                  title: 'Personel yok',
                  message:
                      'Görev atamak ve görünürlük için aktif personel ekleyin.',
                  icon: Icons.groups_outlined,
                  actionLabel: 'Personele Git',
                  onAction: () => context.push(AppRoutes.personel),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      floatingActionButton: operator == null
          ? null
          : FloatingActionButton.extended(
              onPressed: canAssign
                  ? () => _openEditor(operator: operator, people: people)
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${operator.profession.isEmpty ? 'Bu rol' : operator.profession} '
                            'görev atayamaz. Size atanan görevleri görürsünüz.',
                          ),
                        ),
                      );
                    },
              icon: const Icon(Icons.add_task_outlined),
              label: const Text('Görev Ata'),
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
              child: SJCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                onTap: () => _pickOperator(people),
                child: Builder(
                  builder: (context) {
                    final theme = Theme.of(context);
                    return Row(
                      children: [
                        Icon(
                          Icons.badge_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                operator == null
                                    ? 'Kim olarak çalışıyorsunuz?'
                                    : operator.name,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                operator == null
                                    ? 'Görevleri görmek için personel seçin'
                                    : [
                                        if (operator.profession.isNotEmpty)
                                          operator.profession,
                                        canAssign
                                            ? '1. derece · atama yapabilir'
                                            : 'Yalnızca size atananlar',
                                      ].join(' · '),
                                style: theme.textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.expand_more,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            if (operator == null)
              const Expanded(
                child: SJEmptyState(
                  title: 'Operatör seçin',
                  message:
                      'Görev listesi seçtiğiniz personele göre filtrelenir. '
                      'Formen, Saha Mühendisi’ne atanan görevi görmez.',
                  icon: Icons.person_search_outlined,
                ),
              )
            else ...[
              const SizedBox(height: AppSpacing.sm),
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
                            ? 'Görünür görev yok'
                            : 'Bu filtrede görev yok',
                        message: canAssign
                            ? 'Personele görev atayın. Atadığınız görevleri '
                                'yalnızca siz ve atanan kişi görür.'
                            : 'Size atanmış görev bulunmuyor.',
                        icon: Icons.task_alt_outlined,
                        actionLabel: canAssign ? 'Görev Ata' : null,
                        onAction: canAssign
                            ? () => _openEditor(
                                  operator: operator,
                                  people: people,
                                )
                            : null,
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
                          final iAmAssigner =
                              task.assignerPersonId == operator.id ||
                                  (task.assignerPersonId.isEmpty && canAssign);
                          return SJCard(
                            child: Builder(
                              builder: (context) {
                                final theme = Theme.of(context);
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
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
                                              decoration: task.status ==
                                                      TaskStatus.done
                                                  ? TextDecoration.lineThrough
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
                                          'Atanan: ${task.assignee}',
                                        if (task.assignerName.isNotEmpty)
                                          'Atayan: ${task.assignerName}',
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
                                          onPressed: () => _openEditor(
                                            existing: task,
                                            operator: operator,
                                            people: people,
                                          ),
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            size: 20,
                                          ),
                                        ),
                                        if (iAmAssigner)
                                          IconButton(
                                            tooltip: 'Sil',
                                            onPressed: () async {
                                              final ok = await showDialog<bool>(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title:
                                                      const Text('Görevi sil'),
                                                  content: Text(
                                                    '“${task.title}” silinsin mi?',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                        ctx,
                                                        false,
                                                      ),
                                                      child:
                                                          const Text('Vazgeç'),
                                                    ),
                                                    FilledButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                        ctx,
                                                        true,
                                                      ),
                                                      child: const Text('Sil'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (ok == true) {
                                                ref
                                                    .read(
                                                      tasksProvider.notifier,
                                                    )
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
          ],
        ),
      ),
    );
  }
}
