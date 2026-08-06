import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/sj_card.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../core/design_system/sj_modal.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/puantaj_date.dart';
import '../../core/widgets/santijet_header.dart';
import '../../data/providers/active_operator_provider.dart';
import '../../data/providers/app_data_provider.dart';
import '../../data/providers/catalog_provider.dart';
import '../../data/providers/tasks_provider.dart';
import '../../domain/entities/person.dart';
import '../../domain/entities/site_task.dart';
import '../../domain/enums/task_status.dart';
import '../../domain/permissions/role_degree.dart';
import 'widgets/task_calendar_panel.dart';

/// Saha görevleri — atayan (1. derece) + atanan görür.
class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  TaskStatus? _filter;
  String? _categoryFilter;

  Future<Person?> _pickPersonSheet({
    required List<Person> people,
    required String title,
    String? subtitle,
    String? selectedId,
    bool showDegreeHint = false,
  }) {
    final sheetTheme = SJModal.sheetThemeOf(context);

    return showModalBottomSheet<Person>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: SJModal.sheetSurface,
      builder: (ctx) {
        final theme = sheetTheme;
        return Theme(
          data: sheetTheme,
          child: SafeArea(
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
                  child: Text(title, style: theme.textTheme.headlineMedium),
                ),
                if (subtitle != null)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Text(subtitle, style: theme.textTheme.bodySmall),
                  ),
                if (subtitle != null) const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: ListView.separated(
                    itemCount: people.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final p = people[index];
                      final selected = p.id == selectedId;
                      final degree = RoleDegree.forPerson(p);
                      return ListTile(
                        selected: selected,
                        title: Text(p.name),
                        subtitle: Text(
                          [
                            if (p.profession.isNotEmpty) p.profession,
                            if (showDegreeHint)
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('İptal'),
                  ),
                ),
              ],
            ),
          ),
          ),
        );
      },
    );
  }

  Future<String?> _pickDateField({
    required BuildContext hostContext,
    required String label,
    required String current,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    final first = firstDate ?? DateTime(2020);
    final last = lastDate ?? DateTime(2100);
    if (first.isAfter(last)) return null;
    var initial = PuantajDate.tryParse(current) ?? DateTime.now();
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;
    final picked = await showDatePicker(
      context: hostContext,
      helpText: label,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked == null) return null;
    return PuantajDate.format(picked);
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
    if (existing != null &&
        !isAssigner &&
        existing.assigneePersonId != operator.id) {
      return;
    }

    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    var earliestStart = existing?.earliestStart ?? '';
    var latestDelivery = existing?.dueDate ?? '';
    var status = existing?.status ?? TaskStatus.todo;
    var category = existing?.category.trim() ?? '';
    Person? assignee;
    if (existing != null) {
      for (final p in people) {
        if (p.id == existing.assigneePersonId) {
          assignee = p;
          break;
        }
      }
    }

    final editorTheme = SJModal.sheetThemeOf(context);

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: SJModal.sheetSurface,
      builder: (ctx) => Theme(
        data: editorTheme,
        child: Builder(builder: (ctx) {
        final bottom = MediaQuery.viewInsetsOf(ctx).bottom;
        return StatefulBuilder(
          builder: (ctx, setModal) {
            final theme = editorTheme;
            final canEditFields = existing == null || isAssigner;

            Future<void> pickAssignee() async {
              if (!canEditFields) return;
              final picked = await _pickPersonSheet(
                people: people,
                title: 'Atanan personel',
                subtitle: 'Görevi yalnızca bu kişi ve siz görürsünüz.',
                selectedId: assignee?.id,
              );
              if (picked != null) setModal(() => assignee = picked);
            }

            Future<void> pickStart() async {
              if (!canEditFields) return;
              final due = PuantajDate.tryParse(latestDelivery);
              final value = await _pickDateField(
                hostContext: ctx,
                label: 'En erken başlangıç',
                current: earliestStart,
                lastDate: due,
              );
              if (value != null) setModal(() => earliestStart = value);
            }

            Future<void> pickDue() async {
              if (!canEditFields) return;
              final start = PuantajDate.tryParse(earliestStart);
              final value = await _pickDateField(
                hostContext: ctx,
                label: 'En geç teslimat',
                current: latestDelivery,
                firstDate: start,
              );
              if (value != null) setModal(() => latestDelivery = value);
            }

            Future<void> pickCategory() async {
              if (!canEditFields) return;
              final categories = [
                ...ref.read(taskCategoriesProvider),
              ];
              if (category.isNotEmpty &&
                  !categories.any(
                    (c) => c.toLowerCase() == category.toLowerCase(),
                  )) {
                categories.add(category);
                categories.sort((a, b) => a.compareTo(b));
              }
              final picked = await showModalBottomSheet<String>(
                context: ctx,
                showDragHandle: true,
                backgroundColor: SJModal.sheetSurface,
                builder: (sheetCtx) {
                  final sheetTheme = SJModal.sheetThemeOf(ctx);
                  return Theme(
                    data: sheetTheme,
                    child: SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
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
                              'Kategori seçin',
                              style: sheetTheme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Flexible(
                            child: ListView(
                              shrinkWrap: true,
                              children: [
                                ListTile(
                                  title: const Text('Kategori yok'),
                                  trailing: category.isEmpty
                                      ? Icon(
                                          Icons.check_circle,
                                          color: sheetTheme.colorScheme.primary,
                                        )
                                      : null,
                                  onTap: () => Navigator.pop(sheetCtx, ''),
                                ),
                                for (final c in categories)
                                  ListTile(
                                    title: Text(c),
                                    trailing: c == category
                                        ? Icon(
                                            Icons.check_circle,
                                            color:
                                                sheetTheme.colorScheme.primary,
                                          )
                                        : null,
                                    onTap: () => Navigator.pop(sheetCtx, c),
                                  ),
                                ListTile(
                                  leading: Icon(
                                    Icons.add,
                                    color: sheetTheme.colorScheme.primary,
                                  ),
                                  title: const Text('Yeni kategori ekle'),
                                  onTap: () async {
                                    final created =
                                        await _promptNewCategory(sheetCtx);
                                    if (created == null) return;
                                    if (sheetCtx.mounted) {
                                      Navigator.pop(sheetCtx, created);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
              if (picked != null) setModal(() => category = picked);
            }

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
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Kategori',
                      ),
                      child: InkWell(
                        onTap: canEditFields ? pickCategory : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  category.isEmpty
                                      ? 'Kategori seçin veya oluşturun'
                                      : category,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: category.isEmpty
                                        ? theme.hintColor
                                        : null,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.expand_more,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Atanan personel *',
                      ),
                      child: InkWell(
                        onTap: canEditFields ? pickAssignee : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  assignee == null
                                      ? 'Personel seçin'
                                      : '${assignee!.name}'
                                          '${assignee!.profession.isNotEmpty ? ' · ${assignee!.profession}' : ''}',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: assignee == null
                                        ? theme.hintColor
                                        : null,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.expand_more,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: canEditFields ? pickStart : null,
                            icon: const Icon(Icons.play_arrow_rounded, size: 18),
                            label: Text(
                              earliestStart.isEmpty
                                  ? 'En erken başlangıç'
                                  : earliestStart,
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.success,
                              side: BorderSide(
                                color: AppColors.success.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: canEditFields ? pickDue : null,
                            icon: const Icon(Icons.flag_outlined, size: 18),
                            label: Text(
                              latestDelivery.isEmpty
                                  ? 'En geç teslimat'
                                  : latestDelivery,
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.critical,
                              side: BorderSide(
                                color:
                                    AppColors.critical.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ),
                      ],
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
                        if (earliestStart.isEmpty || latestDelivery.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'En erken başlangıç ve en geç teslimat '
                                'tarihlerini seçin.',
                              ),
                            ),
                          );
                          return;
                        }
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
        }),
      ),
    );

    final title = titleCtrl.text.trim();
    final description = descCtrl.text.trim();
    titleCtrl.dispose();
    descCtrl.dispose();
    if (saved != true ||
        title.isEmpty ||
        assignee == null ||
        earliestStart.isEmpty ||
        latestDelivery.isEmpty) {
      return;
    }

    if (existing == null) {
      if (category.isNotEmpty) {
        ref.read(taskCategoriesProvider.notifier).add(category);
      }
      ref.read(tasksProvider.notifier).add(
            projectId: project.id,
            title: title,
            description: description,
            category: category,
            earliestStart: earliestStart,
            dueDate: latestDelivery,
            status: status,
            assigner: operator,
            assignee: assignee!,
          );
    } else if (isAssigner) {
      if (category.isNotEmpty) {
        ref.read(taskCategoriesProvider.notifier).add(category);
      }
      ref.read(tasksProvider.notifier).upsert(
            existing.copyWith(
              title: title,
              description: description,
              category: category,
              earliestStart: earliestStart,
              dueDate: latestDelivery,
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
      ref.read(tasksProvider.notifier).setStatus(existing.id, status);
    }
  }

  Future<String?> _promptNewCategory(BuildContext hostContext) async {
    final ctrl = TextEditingController();
    final sheetTheme = SJModal.sheetThemeOf(hostContext);
    final result = await showDialog<String>(
      context: hostContext,
      builder: (ctx) => Theme(
        data: sheetTheme,
        child: AlertDialog(
          backgroundColor: SJModal.sheetSurface,
          title: const Text('Yeni kategori'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Kategori adı',
              hintText: 'ör. Satın Alma, Saha, Ofis',
            ),
            onSubmitted: (v) {
              final t = v.trim();
              if (t.isNotEmpty) Navigator.pop(ctx, t);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () {
                final t = ctrl.text.trim();
                if (t.isEmpty) return;
                Navigator.pop(ctx, t);
              },
              child: const Text('Ekle'),
            ),
          ],
        ),
      ),
    );
    ctrl.dispose();
    final trimmed = result?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    ref.read(taskCategoriesProvider.notifier).add(trimmed);
    return trimmed;
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
    final catalogCategories = ref.watch(taskCategoriesProvider);
    final usedCategories = {
      for (final t in tasks)
        if (t.category.trim().isNotEmpty) t.category.trim(),
    };
    final filterCategories = {
      ...catalogCategories,
      ...usedCategories,
    }.toList()
      ..sort((a, b) => a.compareTo(b));
    final statusFiltered = _filter == null
        ? tasks
        : tasks.where((t) => t.status == _filter).toList();
    final filtered = _categoryFilter == null
        ? statusFiltered
        : statusFiltered
            .where((t) => t.category.trim() == _categoryFilter)
            .toList();
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
            if (operator == null)
              Expanded(
                child: SJEmptyState(
                  title: 'Aktif kullanıcı yok',
                  message:
                      'Görev yetkisi Ayarlar → Yönetim → Aktif kullanıcı '
                      'üzerinden belirlenir.',
                  icon: Icons.manage_accounts_outlined,
                  actionLabel: 'Aktif kullanıcı',
                  onAction: () => context.push(AppRoutes.aktifKullanici),
                ),
              )
            else ...[
              TaskCalendarPanel(tasks: tasks),
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
              const SizedBox(height: AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            FilterChip(
                              avatar: Icon(
                                Icons.category_outlined,
                                size: 16,
                                color: _categoryFilter == null
                                    ? null
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                              ),
                              label: const Text('Tüm kategoriler'),
                              selected: _categoryFilter == null,
                              onSelected: (_) =>
                                  setState(() => _categoryFilter = null),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            for (final c in filterCategories) ...[
                              FilterChip(
                                label: Text(
                                  '$c (${tasks.where((t) => t.category.trim() == c).length})',
                                ),
                                selected: _categoryFilter == c,
                                onSelected: (_) =>
                                    setState(() => _categoryFilter = c),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                            ],
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Kategorileri yönet',
                      visualDensity: VisualDensity.compact,
                      onPressed: () async {
                        await context.push(AppRoutes.gorevKategorileri);
                        if (!mounted) return;
                        final cats = ref.read(taskCategoriesProvider);
                        if (_categoryFilter != null &&
                            !cats.contains(_categoryFilter)) {
                          setState(() => _categoryFilter = null);
                        }
                      },
                      icon: const Icon(Icons.tune_outlined, size: 20),
                    ),
                  ],
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
                                'yalnızca siz ve atanan kişi görür. '
                                'Kategori ve durum filtrelerini birlikte kullanabilirsiniz.'
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
                                    Text(
                                      task.title,
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        decoration:
                                            task.status == TaskStatus.done
                                                ? TextDecoration.lineThrough
                                                : null,
                                      ),
                                    ),
                                    if (task.category.trim().isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary
                                                .withValues(alpha: 0.12),
                                            borderRadius: AppRadii.sm,
                                            border: Border.all(
                                              color: theme.colorScheme.primary
                                                  .withValues(alpha: 0.35),
                                            ),
                                          ),
                                          child: Text(
                                            task.category.trim(),
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
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
                                      ].join(' · '),
                                      style: theme.textTheme.labelSmall,
                                    ),
                                    if (task.earliestStart.isNotEmpty ||
                                        task.dueDate.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: AppSpacing.sm,
                                        runSpacing: 4,
                                        children: [
                                          if (task.earliestStart.isNotEmpty)
                                            _DateChip(
                                              label:
                                                  'Başlangıç ${task.earliestStart}',
                                              color: AppColors.success,
                                            ),
                                          if (task.dueDate.isNotEmpty)
                                            _DateChip(
                                              label:
                                                  'Teslimat ${task.dueDate}',
                                              color: AppColors.critical,
                                            ),
                                        ],
                                      ),
                                    ],
                                    const SizedBox(height: AppSpacing.sm),
                                    Row(
                                      children: [
                                        for (final s in TaskStatus.values) ...[
                                          Expanded(
                                            child: _StatusSelectButton(
                                              label: s.label,
                                              selected: task.status == s,
                                              color: _statusColor(s),
                                              onTap: () => ref
                                                  .read(tasksProvider.notifier)
                                                  .setStatus(task.id, s),
                                            ),
                                          ),
                                          if (s != TaskStatus.done)
                                            const SizedBox(width: 6),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Row(
                                      children: [
                                        const Spacer(),
                                        IconButton(
                                          tooltip: 'Düzenle',
                                          visualDensity: VisualDensity.compact,
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
                                            visualDensity: VisualDensity.compact,
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

class _DateChip extends StatelessWidget {
  const _DateChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: AppRadii.sm,
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Görev durumu seçici — seçili dolgulu, diğerleri yalnızca çerçeve.
class _StatusSelectButton extends StatelessWidget {
  const _StatusSelectButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = selected
        ? AppColors.readableOn(color)
        : theme.colorScheme.onSurfaceVariant;
    return Material(
      color: selected ? color : Colors.transparent,
      borderRadius: AppRadii.sm,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.sm,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          decoration: BoxDecoration(
            borderRadius: AppRadii.sm,
            border: Border.all(
              color: selected ? color : theme.dividerColor,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: ink,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
