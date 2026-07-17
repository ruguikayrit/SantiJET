import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:santijet_demir/core/format/app_format.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/app_toast.dart';
import 'package:santijet_demir/core/widgets/empty_states.dart';
import 'package:santijet_demir/domain/entities/work_schedule.dart';
import 'package:santijet_demir/features/prediction/providers/work_schedule_provider.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';
import 'package:santijet_demir/features/survey/providers/survey_provider.dart';

class WorkScheduleScreen extends ConsumerWidget {
  const WorkScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(workScheduleProvider);
    final canEdit = ref.watch(canEditActiveProjectProvider);
    final hasProject = ref.watch(activeProjectIdProvider) != null;
    final dateFmt = DateFormat('d MMM yyyy', 'tr_TR');

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('İş Programı')),
      floatingActionButton: hasProject && canEdit
          ? FloatingActionButton.extended(
              onPressed: () => _openEditor(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Gün ekle'),
            )
          : null,
      body: !hasProject
          ? const ModuleEmptyState(type: EmptyStateType.noProject)
          : days.isEmpty
              ? ModuleEmptyState(
                  type: EmptyStateType.noActivity,
                  actionLabel: canEdit ? 'İlk günü ekle' : null,
                  onAction: canEdit ? () => _openEditor(context, ref) : null,
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: days.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final day = days[index];
                    return Material(
                      color: AppColors.surfaceElevated,
                      borderRadius: AppRadii.md,
                      child: InkWell(
                        borderRadius: AppRadii.md,
                        onTap: canEdit
                            ? () => _openEditor(context, ref, existing: day)
                            : null,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: AppRadii.md,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      dateFmt.format(day.date),
                                      style: AppTypography.titleMedium,
                                    ),
                                  ),
                                  Text(
                                    '${AppFormat.tonnage(day.totalPlannedTonnage)} t',
                                    style: AppTypography.titleMedium.copyWith(
                                      color: AppColors.electricBlueLight,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                day.activities
                                    .map((a) => a.imalatName)
                                    .join(' · '),
                                style: AppTypography.bodySmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    WorkScheduleDay? existing,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WorkScheduleDayEditorScreen(existing: existing),
      ),
    );
  }
}

class WorkScheduleDayEditorScreen extends ConsumerStatefulWidget {
  const WorkScheduleDayEditorScreen({super.key, this.existing});

  final WorkScheduleDay? existing;

  @override
  ConsumerState<WorkScheduleDayEditorScreen> createState() =>
      _WorkScheduleDayEditorScreenState();
}

class _WorkScheduleDayEditorScreenState
    extends ConsumerState<WorkScheduleDayEditorScreen> {
  late DateTime _date;
  late List<_ActivityDraft> _activities;

  @override
  void initState() {
    super.initState();
    _date = widget.existing?.date ?? DateTime.now();
    _activities = (widget.existing?.activities ?? const [])
        .map(_ActivityDraft.fromActivity)
        .toList();
    if (_activities.isEmpty) {
      _activities.add(_ActivityDraft.empty());
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final activities = <WorkActivity>[];
    for (final draft in _activities) {
      final name = draft.nameCtrl.text.trim();
      final byDiameter = <int, double>{};
      for (final e in draft.tonnageCtrls.entries) {
        final v = double.tryParse(e.value.text.replaceAll(',', '.'));
        if (v != null && v > 0) byDiameter[e.key] = v;
      }
      if (name.isEmpty && byDiameter.isEmpty) continue;
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showAppSnackBar(
          const SnackBar(content: Text('İmalat adı gerekli')),
        );
        return;
      }
      if (byDiameter.isEmpty) {
        ScaffoldMessenger.of(context).showAppSnackBar(
          const SnackBar(content: Text('En az bir çap tonajı girin')),
        );
        return;
      }
      activities.add(
        WorkActivity(
          id: draft.id,
          imalatId: draft.imalatId,
          imalatName: name,
          plannedTonnageByDiameter: byDiameter,
          notes: draft.notesCtrl.text.trim().isEmpty
              ? null
              : draft.notesCtrl.text.trim(),
        ),
      );
    }

    await ref.read(workScheduleProvider.notifier).upsertDay(
          WorkScheduleDay(date: _date, activities: activities),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showAppSnackBar(
      const SnackBar(content: Text('İş programı kaydedildi')),
    );
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    await ref.read(workScheduleProvider.notifier).deleteDay(_date);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _addFromSurvey() {
    final survey = ref.read(surveyProjectProvider);
    final diameters = <int>{};
    for (final imalat in survey.imalats) {
      for (final line in imalat.diameterLines) {
        if (line.planned > 0) diameters.add(line.diameter);
      }
    }
    final sorted = diameters.toList()..sort();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Keşiften imalat seç', style: AppTypography.titleLarge),
              ),
              for (final imalat in survey.imalats)
                ListTile(
                  title: Text(imalat.name),
                  subtitle: Text(
                    '${AppFormat.tonnage(imalat.planned)} t planlı',
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _activities.add(
                        _ActivityDraft.fromSurvey(
                          imalatId: imalat.id,
                          name: imalat.name,
                          diameters: sorted.isNotEmpty
                              ? sorted
                              : imalat.diameterLines
                                  .map((l) => l.diameter)
                                  .toList(),
                        ),
                      );
                    });
                  },
                ),
              if (survey.imalats.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Keşifte imalat yok. Önce keşif ekleyin.'),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('d MMMM yyyy', 'tr_TR');
    final survey = ref.watch(surveyProjectProvider);
    final diameters = <int>{};
    for (final imalat in survey.imalats) {
      for (final line in imalat.diameterLines) {
        diameters.add(line.diameter);
      }
    }
    final diameterList = diameters.toList()..sort();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Gün ekle' : 'Günü düzenle'),
        actions: [
          if (widget.existing != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Tarih'),
            subtitle: Text(dateFmt.format(_date)),
            trailing: const Icon(Icons.calendar_today),
            onTap: _pickDate,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Aktiviteler', style: AppTypography.titleMedium),
              const Spacer(),
              TextButton.icon(
                onPressed: _addFromSurvey,
                icon: const Icon(Icons.playlist_add, size: 18),
                label: const Text('Keşiften'),
              ),
              IconButton(
                onPressed: () => setState(() {
                  _activities.add(
                    _ActivityDraft.empty(diameters: diameterList),
                  );
                }),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          for (var i = 0; i < _activities.length; i++) ...[
            const SizedBox(height: 10),
            _ActivityCard(
              draft: _activities[i],
              diameters: diameterList.isEmpty
                  ? const [8, 10, 12, 14, 16, 18, 20, 22, 25, 28, 32]
                  : diameterList,
              onRemove: _activities.length > 1
                  ? () => setState(() => _activities.removeAt(i))
                  : null,
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _save,
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}

class _ActivityDraft {
  _ActivityDraft({
    required this.id,
    this.imalatId,
    required this.nameCtrl,
    required this.notesCtrl,
    required this.tonnageCtrls,
  });

  final String id;
  final String? imalatId;
  final TextEditingController nameCtrl;
  final TextEditingController notesCtrl;
  final Map<int, TextEditingController> tonnageCtrls;

  factory _ActivityDraft.empty({List<int> diameters = const []}) {
    final ctrls = <int, TextEditingController>{
      for (final d in diameters) d: TextEditingController(),
    };
    return _ActivityDraft(
      id: 'act-${DateTime.now().microsecondsSinceEpoch}',
      nameCtrl: TextEditingController(),
      notesCtrl: TextEditingController(),
      tonnageCtrls: ctrls,
    );
  }

  factory _ActivityDraft.fromActivity(WorkActivity a) {
    return _ActivityDraft(
      id: a.id,
      imalatId: a.imalatId,
      nameCtrl: TextEditingController(text: a.imalatName),
      notesCtrl: TextEditingController(text: a.notes ?? ''),
      tonnageCtrls: {
        for (final e in a.plannedTonnageByDiameter.entries)
          e.key: TextEditingController(
            text: e.value == 0 ? '' : e.value.toString(),
          ),
      },
    );
  }

  factory _ActivityDraft.fromSurvey({
    required String imalatId,
    required String name,
    required List<int> diameters,
  }) {
    return _ActivityDraft(
      id: 'act-${DateTime.now().microsecondsSinceEpoch}',
      imalatId: imalatId,
      nameCtrl: TextEditingController(text: name),
      notesCtrl: TextEditingController(),
      tonnageCtrls: {
        for (final d in diameters) d: TextEditingController(),
      },
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.draft,
    required this.diameters,
    this.onRemove,
  });

  final _ActivityDraft draft;
  final List<int> diameters;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    for (final d in diameters) {
      draft.tonnageCtrls.putIfAbsent(d, TextEditingController.new);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: draft.nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'İmalat / aktivite',
                    isDense: true,
                  ),
                ),
              ),
              if (onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text('Planlı tonaj (t)', style: AppTypography.labelMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final d in diameters)
                SizedBox(
                  width: 88,
                  child: TextField(
                    controller: draft.tonnageCtrls[d],
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Ø$d',
                      isDense: true,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: draft.notesCtrl,
            decoration: const InputDecoration(
              labelText: 'Not (opsiyonel)',
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }
}
