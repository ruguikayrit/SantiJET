import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/widgets/sj_empty_state.dart';
import '../../core/widgets/sj_form_field.dart';
import '../../core/widgets/sj_primary_button.dart';
import '../../data/providers/app_state_provider.dart';
import '../../domain/models/page_key.dart';
import '../../domain/models/schedule_task.dart';
import '../common/module_helpers.dart';

const _statusLabels = {
  'planned': ('Planlandı', Color(0xFF64748B)),
  'in_progress': ('Devam Ediyor', Color(0xFF2563EB)),
  'completed': ('Tamamlandı', Color(0xFF16A34A)),
  'delayed': ('Gecikti', Color(0xFFDC2626)),
};

class IsProgramiScreen extends ConsumerStatefulWidget {
  const IsProgramiScreen({super.key});

  @override
  ConsumerState<IsProgramiScreen> createState() => _IsProgramiScreenState();
}

class _IsProgramiScreenState extends ConsumerState<IsProgramiScreen> {
  String? _projectFilter;
  bool _canEdit = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _canEdit = guardPage(context, ref, 'is-programi');
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final colors = ref.watch(themeDefinitionProvider).colors;
    final perm = state.getPermission('is-programi');
    if (perm == Permission.none) return const SizedBox.shrink();
    _canEdit = perm == Permission.edit;

    if (state.projects.isEmpty) {
      return const ModuleScaffold(
        title: 'İş Programı',
        body: SjEmptyState(
          title: 'Önce proje ekleyin',
          message: 'İş programı için en az bir proje gerekli.',
          icon: Icons.calendar_month_outlined,
        ),
      );
    }

    final items = state.scheduleTasks
        .where((t) => _projectFilter == null || t.projectId == _projectFilter)
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    return ModuleScaffold(
      title: 'İş Programı',
      floatingActionButton: _canEdit
          ? FloatingActionButton(
              onPressed: () => _edit(null),
              backgroundColor: colors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      bottom: ProjectFilterBar(
        value: _projectFilter,
        onChanged: (v) => setState(() => _projectFilter = v),
      ),
      body: items.isEmpty
          ? const SjEmptyState(
              title: 'Görev yok',
              message: 'İş programına görev ekleyin.',
              icon: Icons.event_note_outlined,
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 88),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final t = items[i];
                final st = _statusLabels[t.status] ?? _statusLabels['planned']!;
                final pct = t.progress.clamp(0, 100);
                return EntityCard(
                  title: t.name,
                  subtitle:
                      '${projectNameOf(state.projects, t.projectId)} · ${t.startDate} → ${t.endDate}',
                  trailing: StatusPill(label: st.$1, color: st.$2),
                  onTap: _canEdit ? () => _edit(t) : null,
                  onDelete: _canEdit
                      ? () async {
                          if (await confirmDelete(context, 'Görevi sil')) {
                            ref
                                .read(appStateProvider.notifier)
                                .deleteScheduleTask(t.id);
                          }
                        }
                      : null,
                  extra: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sorumlu: ${t.responsible.isEmpty ? '—' : t.responsible}',
                        style: AppTypography.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct / 100,
                                minHeight: 8,
                                backgroundColor: colors.muted,
                                color: st.$2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '%${pct.round()}',
                            style: AppTypography.labelMedium
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Future<void> _edit(ScheduleTask? existing) async {
    final state = ref.read(appStateProvider);
    var projectId =
        existing?.projectId ?? _projectFilter ?? state.projects.first.id;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final startCtrl =
        TextEditingController(text: existing?.startDate ?? todayIso());
    final endCtrl =
        TextEditingController(text: existing?.endDate ?? todayIso());
    final progressCtrl = TextEditingController(
      text: existing?.progress.toString() ?? '0',
    );
    final respCtrl =
        TextEditingController(text: existing?.responsible ?? '');
    var status = existing?.status ?? 'planned';

    await showFormSheet(
      context: context,
      ref: ref,
      title: existing == null ? 'İş Görevi' : 'Görev Düzenle',
      child: StatefulBuilder(
        builder: (ctx, setLocal) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              SjDropdownField<String>(
                label: 'Proje',
                value: projectId,
                items: state.projects
                    .map((p) => DropdownMenuItem(
                          value: p.id,
                          child: Text(p.name),
                        ))
                    .toList(),
                onChanged: (v) => setLocal(() => projectId = v!),
              ),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(label: 'Görev adı', controller: nameCtrl),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: SjFormField(label: 'Başlangıç', controller: startCtrl),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SjFormField(label: 'Bitiş', controller: endCtrl),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(
                label: 'İlerleme %',
                controller: progressCtrl,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.sm),
              SjDropdownField<String>(
                label: 'Durum',
                value: status,
                items: _statusLabels.entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value.$1),
                        ))
                    .toList(),
                onChanged: (v) => setLocal(() => status = v!),
              ),
              const SizedBox(height: AppSpacing.sm),
              SjFormField(label: 'Sorumlu', controller: respCtrl),
              const SizedBox(height: AppSpacing.md),
              SjPrimaryButton(
                label: 'Kaydet',
                onPressed: () {
                  if (nameCtrl.text.trim().isEmpty) return;
                  final model = ScheduleTask(
                    id: existing?.id ?? '',
                    projectId: projectId,
                    name: nameCtrl.text.trim(),
                    startDate: startCtrl.text.trim().isEmpty
                        ? todayIso()
                        : startCtrl.text.trim(),
                    endDate: endCtrl.text.trim().isEmpty
                        ? todayIso()
                        : endCtrl.text.trim(),
                    progress: parseNum(progressCtrl.text).clamp(0, 100),
                    status: status,
                    responsible: respCtrl.text.trim(),
                  );
                  final n = ref.read(appStateProvider.notifier);
                  if (existing == null) {
                    n.addScheduleTask(model);
                  } else {
                    n.updateScheduleTask(existing.id, (_) => model);
                  }
                  Navigator.pop(ctx);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
