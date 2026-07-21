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
import 'package:santijet_demir/domain/entities/survey.dart';
import 'package:santijet_demir/domain/entities/work_schedule.dart';
import 'package:santijet_demir/features/prediction/providers/work_schedule_provider.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';
import 'package:santijet_demir/features/survey/providers/survey_provider.dart';

class WorkScheduleScreen extends ConsumerStatefulWidget {
  const WorkScheduleScreen({super.key});

  @override
  ConsumerState<WorkScheduleScreen> createState() => _WorkScheduleScreenState();
}

class _WorkScheduleScreenState extends ConsumerState<WorkScheduleScreen> {
  String? _syncedProjectId;

  @override
  Widget build(BuildContext context) {
    final survey = ref.watch(surveyProjectProvider);
    final schedule = ref.watch(workScheduleProvider);
    final canEdit = ref.watch(canEditActiveProjectProvider);
    final projectId = ref.watch(activeProjectIdProvider);
    final hasProject = projectId != null;
    final dateFmt = DateFormat('d MMM yy', 'tr_TR');

    if (hasProject && _syncedProjectId != projectId && survey.imalats.isNotEmpty) {
      _syncedProjectId = projectId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(workScheduleProvider.notifier).syncFromSurvey(survey);
      });
    }

    final byImalatId = {for (final item in schedule) item.imalatId: item};
    final rows = <_ScheduleRow>[];
    for (final imalat in survey.imalats) {
      final saved = byImalatId[imalat.id];
      rows.add(
        _ScheduleRow(
          imalat: imalat,
          item: saved ??
              WorkScheduleImalat(
                id: 'ws-${imalat.id}',
                imalatId: imalat.id,
                imalatName: imalat.name,
              ),
        ),
      );
    }

    final datedCount =
        rows.where((r) => r.item.startDate != null && r.item.endDate != null).length;
    final totalTonnage =
        rows.fold<double>(0, (sum, row) => sum + row.imalat.planned);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('İş Programı')),
      body: !hasProject
          ? const ModuleEmptyState(type: EmptyStateType.noProject)
          : survey.imalats.isEmpty
              ? const ModuleEmptyState(type: EmptyStateType.noSurvey)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.md,
                        8,
                      ),
                      child: Text(
                        'Keşif imalatlarına göre başlangıç / bitiş ve '
                        'planlanan adam sayısını girin. Tonaj keşiften alınır; '
                        'süre otomatik hesaplanır.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: AppRadii.md,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _SummaryChip(
                                label: 'İmalat',
                                value: '${rows.length}',
                              ),
                            ),
                            Expanded(
                              child: _SummaryChip(
                                label: 'Planlı',
                                value: '$datedCount',
                              ),
                            ),
                            Expanded(
                              child: _SummaryChip(
                                label: 'Keşif',
                                value: '${AppFormat.tonnage(totalTonnage)} t',
                              ),
                            ),
                            Expanded(
                              child: _SummaryChip(
                                label: 'Adam',
                                value: '${rows.fold<int>(0, (s, r) => s + (r.item.plannedWorkerCount ?? 0))}',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          0,
                          AppSpacing.md,
                          AppSpacing.xl,
                        ),
                        itemCount: rows.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final row = rows[index];
                          final duration = row.item.durationDays;
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
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
                                        row.imalat.name,
                                        style: AppTypography.titleMedium,
                                      ),
                                    ),
                                    Text(
                                      '${AppFormat.tonnage(row.imalat.planned)} t',
                                      style: AppTypography.titleMedium.copyWith(
                                        color: AppColors.electricBlueLight,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Keşif tonajı · ${row.imalat.diameterLines.length} çap',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _DateField(
                                        label: 'Başlangıç',
                                        value: row.item.startDate,
                                        enabled: canEdit,
                                        dateFmt: dateFmt,
                                        onPick: () => _pickDate(
                                          context,
                                          initial: row.item.startDate ??
                                              DateTime.now(),
                                          onPicked: (date) => _saveRow(
                                            row.item.copyWith(startDate: date),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _DateField(
                                        label: 'Bitiş',
                                        value: row.item.endDate,
                                        enabled: canEdit,
                                        dateFmt: dateFmt,
                                        onPick: () => _pickDate(
                                          context,
                                          initial: row.item.endDate ??
                                              row.item.startDate ??
                                              DateTime.now(),
                                          onPicked: (date) => _saveRow(
                                            row.item.copyWith(endDate: date),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: _PlannedWorkerField(
                                        value: row.item.plannedWorkerCount,
                                        enabled: canEdit,
                                        onCommit: (count) => _saveRow(
                                          row.item.copyWith(
                                            plannedWorkerCount: count,
                                            clearPlannedWorkerCount:
                                                count == null,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 2,
                                      child: _DurationBadge(
                                        days: duration,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Future<void> _pickDate(
    BuildContext context, {
    required DateTime initial,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _saveRow(WorkScheduleImalat item) async {
    final start = item.startDate;
    final end = item.endDate;
    if (start != null && end != null) {
      final s = WorkScheduleImalat.normalizeDate(start);
      final e = WorkScheduleImalat.normalizeDate(end);
      if (e.isBefore(s)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showAppSnackBar(
          const SnackBar(content: Text('Bitiş tarihi başlangıçtan önce olamaz')),
        );
        return;
      }
    }
    await ref.read(workScheduleProvider.notifier).upsert(item);
  }
}

class _ScheduleRow {
  const _ScheduleRow({required this.imalat, required this.item});

  final SurveyImalat imalat;
  final WorkScheduleImalat item;
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 2),
        Text(value, style: AppTypography.titleMedium),
      ],
    );
  }
}

class _PlannedWorkerField extends StatelessWidget {
  const _PlannedWorkerField({
    required this.value,
    required this.enabled,
    required this.onCommit,
  });

  final int? value;
  final bool enabled;
  final ValueChanged<int?> onCommit;

  static const _max = 999;

  void _step(int delta) {
    if (!enabled) return;
    final current = value ?? 0;
    final next = (current + delta).clamp(0, _max);
    if (next == 0 && value == null) return;
    onCommit(next == 0 ? null : next);
  }

  @override
  Widget build(BuildContext context) {
    final count = value;
    final display = count == null ? '—' : '$count';

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: AppRadii.sm,
        border: Border.all(
          color: count != null
              ? AppColors.electricBlueLight.withValues(alpha: 0.45)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.electricBlue.withValues(alpha: 0.14),
              borderRadius: AppRadii.sm,
            ),
            child: const Icon(
              Icons.groups_outlined,
              size: 18,
              color: AppColors.electricBlueLight,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Planlanan ekip',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                InkWell(
                  onTap: enabled
                      ? () => _promptCount(context)
                      : null,
                  borderRadius: AppRadii.sm,
                  child: Text(
                    display,
                    style: AppTypography.kpiValue.copyWith(
                      fontSize: 22,
                      height: 1.1,
                      color: count == null
                          ? AppColors.textMuted
                          : AppColors.electricBlueLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _CrewStepButton(
            icon: Icons.remove,
            enabled: enabled && (count ?? 0) > 0,
            onTap: () => _step(-1),
          ),
          const SizedBox(width: 4),
          _CrewStepButton(
            icon: Icons.add,
            enabled: enabled && (count ?? 0) < _max,
            onTap: () => _step(1),
          ),
        ],
      ),
    );
  }

  Future<void> _promptCount(BuildContext context) async {
    final controller = TextEditingController(
      text: value == null ? '' : '$value',
    );
    final confirmed = await showDialog<_CountDialogResult>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Planlanan adam sayısı'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            hintText: 'Örn. 12',
            suffixText: 'adam',
          ),
          onSubmitted: (raw) {
            final trimmed = raw.trim();
            if (trimmed.isEmpty) {
              Navigator.pop(ctx, const _CountDialogResult.clear());
              return;
            }
            final parsed = int.tryParse(trimmed);
            if (parsed == null) {
              Navigator.pop(ctx);
              return;
            }
            Navigator.pop(ctx, _CountDialogResult.value(parsed.clamp(0, _max)));
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, const _CountDialogResult.clear()),
            child: const Text('Temizle'),
          ),
          FilledButton(
            onPressed: () {
              final trimmed = controller.text.trim();
              if (trimmed.isEmpty) {
                Navigator.pop(ctx, const _CountDialogResult.clear());
                return;
              }
              final parsed = int.tryParse(trimmed);
              if (parsed == null) {
                Navigator.pop(ctx);
                return;
              }
              Navigator.pop(
                ctx,
                _CountDialogResult.value(parsed.clamp(0, _max)),
              );
            },
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (confirmed == null) return;
    if (confirmed.clear) {
      if (value != null) onCommit(null);
      return;
    }
    if (confirmed.count != value) onCommit(confirmed.count);
  }
}

class _CountDialogResult {
  const _CountDialogResult.value(this.count) : clear = false;
  const _CountDialogResult.clear()
      : count = null,
        clear = true;

  final int? count;
  final bool clear;
}

class _CrewStepButton extends StatelessWidget {
  const _CrewStepButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled
          ? AppColors.surfaceElevated
          : AppColors.border.withValues(alpha: 0.25),
      borderRadius: AppRadii.sm,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: AppRadii.sm,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            size: 18,
            color: enabled ? AppColors.textPrimary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _DurationBadge extends StatelessWidget {
  const _DurationBadge({required this.days});

  final int? days;

  @override
  Widget build(BuildContext context) {
    final hasDays = days != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: AppRadii.sm,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Süre',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            hasDays ? '$days' : '—',
            style: AppTypography.kpiValue.copyWith(
              fontSize: 22,
              height: 1.1,
              color: hasDays
                  ? AppColors.textPrimary
                  : AppColors.textMuted,
            ),
          ),
          Text(
            hasDays ? 'gün' : 'tarih gir',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.enabled,
    required this.dateFmt,
    required this.onPick,
  });

  final String label;
  final DateTime? value;
  final bool enabled;
  final DateFormat dateFmt;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onPick : null,
      borderRadius: AppRadii.sm,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: AppRadii.sm,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value == null ? 'Seç' : dateFmt.format(value!),
                    style: AppTypography.bodyMedium.copyWith(
                      color: value == null
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
