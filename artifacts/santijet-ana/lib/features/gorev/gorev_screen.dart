import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:santijet_ana/core/routing/app_routes.dart';
import 'package:santijet_ana/core/theme/app_radii.dart';
import 'package:santijet_ana/core/theme/app_spacing.dart';
import 'package:santijet_ana/core/theme/app_typography.dart';
import 'package:santijet_ana/core/theme/theme_provider.dart';
import 'package:santijet_ana/core/widgets/sj_empty_state.dart';
import 'package:santijet_ana/core/widgets/sj_form_field.dart';
import 'package:santijet_ana/core/widgets/sj_header.dart';
import 'package:santijet_ana/data/providers/app_state_provider.dart';
import 'package:santijet_ana/domain/models/page_key.dart';
import 'package:santijet_ana/domain/models/task.dart';
import 'package:santijet_ana/features/_shared/entity_form_sheet.dart';

const _priorityOpts = <({String value, String label})>[
  (value: 'low', label: 'Düşük'),
  (value: 'medium', label: 'Orta'),
  (value: 'high', label: 'Yüksek'),
];

const _statusOpts = <({String value, String label})>[
  (value: 'open', label: 'Açık'),
  (value: 'in_progress', label: 'Devam'),
  (value: 'done', label: 'Bitti'),
];

const _priorityColor = <String, Color>{
  'low': Color(0xFF64748B),
  'medium': Color(0xFFD97706),
  'high': Color(0xFFDC2626),
};

class GorevScreen extends ConsumerStatefulWidget {
  const GorevScreen({super.key});

  @override
  ConsumerState<GorevScreen> createState() => _GorevScreenState();
}

class _GorevScreenState extends ConsumerState<GorevScreen> {
  String? _filterProjectId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _guard());
  }

  void _guard() {
    if (!mounted) return;
    final perm = ref.read(appStateProvider).getPermission('gorev');
    if (perm == Permission.none) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.home);
      }
    }
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _open([Task? t]) async {
    final state = ref.read(appStateProvider);
    final c = ref.read(themeDefinitionProvider).colors;
    final projects = state.projects;
    final titleCtrl = TextEditingController(text: t?.title ?? '');
    final descCtrl = TextEditingController(text: t?.description ?? '');
    final assigneeCtrl = TextEditingController(text: t?.assignee ?? '');
    var deadline = t?.deadline ?? '';
    var priority = t?.priority ?? 'medium';
    var status = t?.status ?? 'open';
    var projectId = t?.projectId ??
        _filterProjectId ??
        (projects.isNotEmpty ? projects.first.id : '');
    final editId = t?.id;

    await showEntityFormSheet(
      context: context,
      title: editId == null ? 'Yeni Görev' : 'Görevi Düzenle',
      onSave: () {
        final title = titleCtrl.text.trim();
        if (title.isEmpty) return;
        final notifier = ref.read(appStateProvider.notifier);
        if (editId == null) {
          notifier.addTask(Task(
            id: '',
            projectId: projectId,
            title: title,
            description: descCtrl.text.trim(),
            assignee: assigneeCtrl.text.trim(),
            deadline: deadline,
            priority: priority,
            status: status,
          ));
        } else {
          notifier.updateTask(
            editId,
            (e) => e.copyWith(
              projectId: projectId,
              title: title,
              description: descCtrl.text.trim(),
              assignee: assigneeCtrl.text.trim(),
              deadline: deadline,
              priority: priority,
              status: status,
            ),
          );
        }
        Navigator.pop(context);
      },
      onDelete: editId == null
          ? null
          : () {
              ref.read(appStateProvider.notifier).deleteTask(editId);
              Navigator.pop(context);
            },
      form: StatefulBuilder(
        builder: (ctx, setModal) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (projects.isNotEmpty) ...[
                Text(
                  'Proje',
                  style:
                      AppTypography.labelMedium.copyWith(color: c.foreground),
                ),
                const SizedBox(height: AppSpacing.xxs),
                DropdownButtonFormField<String>(
                  value: projects.any((p) => p.id == projectId)
                      ? projectId
                      : projects.first.id,
                  items: [
                    for (final p in projects)
                      DropdownMenuItem(value: p.id, child: Text(p.name)),
                  ],
                  onChanged: (v) {
                    if (v != null) setModal(() => projectId = v);
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: c.background,
                    border: OutlineInputBorder(
                      borderRadius: AppRadii.md,
                      borderSide: BorderSide(color: c.input),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              SjFormField(
                label: 'Başlık',
                controller: titleCtrl,
                hint: 'Görev başlığı',
              ),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(
                label: 'Açıklama',
                controller: descCtrl,
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(
                label: 'Atanan',
                controller: assigneeCtrl,
                hint: 'Personel adı',
              ),
              const SizedBox(height: AppSpacing.sm),
              SjDateField(
                label: 'Son Tarih',
                value: deadline,
                onPicked: (v) => setModal(() => deadline = v),
                foreground: c.foreground,
                mutedForeground: c.mutedForeground,
                card: c.background,
                input: c.input,
                primary: c.primary,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Öncelik',
                style: AppTypography.labelMedium.copyWith(color: c.foreground),
              ),
              const SizedBox(height: AppSpacing.xxs),
              SjOptionChips(
                options: _priorityOpts,
                value: priority,
                onChanged: (v) => setModal(() => priority = v),
                foreground: c.foreground,
                muted: c.muted,
                primary: c.primary,
                border: c.border,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Durum',
                style: AppTypography.labelMedium.copyWith(color: c.foreground),
              ),
              const SizedBox(height: AppSpacing.xxs),
              SjOptionChips(
                options: _statusOpts,
                value: status,
                onChanged: (v) => setModal(() => status = v),
                foreground: c.foreground,
                muted: c.muted,
                primary: c.primary,
                border: c.border,
              ),
            ],
          );
        },
      ),
    );

    titleCtrl.dispose();
    descCtrl.dispose();
    assigneeCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(themeDefinitionProvider).colors;
    final state = ref.watch(appStateProvider);
    final perm = state.getPermission('gorev');
    if (perm == Permission.none) {
      return Scaffold(backgroundColor: c.background);
    }
    final canEdit = perm == Permission.edit;
    final projects = state.projects;
    final tasks = _filterProjectId == null
        ? state.tasks
        : state.tasks.where((t) => t.projectId == _filterProjectId).toList();

    String projectName(String id) {
      for (final p in projects) {
        if (p.id == id) return p.name;
      }
      return '';
    }

    return Scaffold(
      backgroundColor: c.background,
      body: Column(
        children: [
          SjHeader(
            title: 'Görevler',
            onBack: _goBack,
            trailing: canEdit
                ? IconButton(
                    onPressed: () => _open(),
                    icon: const Icon(Icons.add, color: Colors.white),
                  )
                : null,
          ),
          if (projects.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                0,
              ),
              child: DropdownButtonFormField<String?>(
                value: _filterProjectId,
                decoration: InputDecoration(
                  labelText: 'Proje filtresi',
                  filled: true,
                  fillColor: c.card,
                  border: OutlineInputBorder(
                    borderRadius: AppRadii.md,
                    borderSide: BorderSide(color: c.border),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Tüm projeler'),
                  ),
                  for (final p in projects)
                    DropdownMenuItem<String?>(
                      value: p.id,
                      child: Text(p.name),
                    ),
                ],
                onChanged: (v) => setState(() => _filterProjectId = v),
              ),
            ),
          Expanded(
            child: tasks.isEmpty
                ? const SjEmptyState(
                    title: 'Henüz görev yok',
                    message: 'Yeni görev eklemek için + düğmesine dokunun',
                    icon: Icons.task_alt_outlined,
                  )
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      MediaQuery.paddingOf(context).bottom + AppSpacing.xl,
                    ),
                    itemCount: tasks.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, i) {
                      final t = tasks[i];
                      final pc =
                          _priorityColor[t.priority] ?? c.mutedForeground;
                      final plabel = _priorityOpts
                          .firstWhere(
                            (o) => o.value == t.priority,
                            orElse: () =>
                                (value: t.priority, label: t.priority),
                          )
                          .label;
                      final slabel = _statusOpts
                          .firstWhere(
                            (o) => o.value == t.status,
                            orElse: () => (value: t.status, label: t.status),
                          )
                          .label;
                      return Material(
                        color: c.card,
                        borderRadius: AppRadii.md,
                        child: InkWell(
                          borderRadius: AppRadii.md,
                          onTap: canEdit ? () => _open(t) : null,
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              borderRadius: AppRadii.md,
                              border: Border.all(
                                color: c.border.withValues(alpha: 0.6),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        t.title,
                                        style: AppTypography.headlineMedium
                                            .copyWith(
                                          color: c.foreground,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: pc.withValues(alpha: 0.13),
                                        borderRadius: AppRadii.sm,
                                      ),
                                      child: Text(
                                        plabel,
                                        style: TextStyle(
                                          color: pc,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  slabel,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: c.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (t.assignee.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Atanan: ${t.assignee}',
                                    style: AppTypography.bodySmall
                                        .copyWith(color: c.mutedForeground),
                                  ),
                                ],
                                if (t.deadline.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Son: ${displayDate(t.deadline)}',
                                    style: AppTypography.bodySmall
                                        .copyWith(color: c.mutedForeground),
                                  ),
                                ],
                                if (projectName(t.projectId).isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    projectName(t.projectId),
                                    style: AppTypography.bodySmall
                                        .copyWith(color: c.mutedForeground),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
