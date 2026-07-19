import 'package:flutter/material.dart';
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
                        'Keşif imalatlarına göre başlangıç / bitiş girin. '
                        'Tonaj keşiften alınır; süre otomatik hesaplanır.',
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
                                Text(
                                  duration == null
                                      ? 'Süre: —'
                                      : 'Toplam süre: $duration gün',
                                  style: AppTypography.labelMedium.copyWith(
                                    color: duration == null
                                        ? AppColors.textMuted
                                        : AppColors.textSecondary,
                                  ),
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
