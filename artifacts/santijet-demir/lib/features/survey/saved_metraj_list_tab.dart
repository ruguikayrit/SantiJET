import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/domain/entities/rebar_metraj.dart';
import 'package:santijet_demir/domain/entities/survey.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';
import 'package:santijet_demir/features/rebar_metraj/providers/rebar_metraj_storage_provider.dart';
import 'package:santijet_demir/features/survey/providers/survey_provider.dart';

/// Kaydedilmiş CAD metraj kayıtları — imalat listesi ile aynı düzen.
class SavedMetrajListTab extends ConsumerWidget {
  const SavedMetrajListTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(savedRebarMetrajProvider);
    final project = ref.watch(surveyProjectProvider);
    final projectId = ref.watch(activeProjectIdProvider);
    final expandedId = ref.watch(expandedMetrajRecordProvider);
    final totalTonnage = records.fold<double>(0, (sum, r) => sum + r.result.totalTonnage);

    return Material(
      color: AppColors.canvas,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _ProjectMetaRow(project: project),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text('Metraj Listesi', style: AppTypography.headlineMedium),
              ),
              if (records.isNotEmpty)
                Text(
                  '${totalTonnage.toStringAsFixed(1)} t',
                  style: AppTypography.kpiValue.copyWith(fontSize: 22),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (projectId == null)
            const _InfoCard(
              icon: Icons.folder_off_outlined,
              title: 'Proje seçilmedi',
              subtitle: 'Metraj kayıtları proje bazında saklanır.',
            )
          else if (records.isEmpty)
            _InfoCard(
              icon: Icons.save_outlined,
              title: 'Henüz metraj kaydı yok',
              subtitle:
                  'Demir Metraj sekmesinde CAD yükleyip "Sonucu Kaydet" ile buraya ekleyin.',
              actionLabel: 'Demir Metraj\'a git',
              onAction: () => ref.read(surveyTabIndexProvider.notifier).state = 1,
            )
          else
            ...records.map(
              (record) => MetrajRecordCard(
                record: record,
                expanded: expandedId == record.id,
                onToggle: () {
                  ref.read(expandedMetrajRecordProvider.notifier).state =
                      expandedId == record.id ? null : record.id;
                },
                onDetail: () => context.push(AppRoutes.savedMetrajDetail(record.id)),
              ),
            ),
          const SizedBox(height: 16),
          if (records.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.architecture, size: 16, color: AppColors.electricBlueLight),
                  label: Text('${records.length} kayıt', style: AppTypography.labelMedium),
                  backgroundColor: AppColors.surfaceElevated,
                  side: const BorderSide(color: AppColors.border),
                ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 16, color: AppColors.electricBlueLight),
                  label: Text('Yeni Metraj', style: AppTypography.labelMedium),
                  backgroundColor: AppColors.surfaceElevated,
                  side: const BorderSide(color: AppColors.border),
                  onPressed: () => ref.read(surveyTabIndexProvider.notifier).state = 1,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ProjectMetaRow extends StatelessWidget {
  const _ProjectMetaRow({required this.project});

  final SurveyProject project;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _MetaItem(label: 'Proje', value: project.projectName),
          _MetaItem(
            label: 'Tarih',
            value:
                '${project.date.day}.${project.date.month}.${project.date.year}',
          ),
          _MetaItem(label: 'Kayıt', value: '${project.imalats.length} imalat'),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.labelMedium),
          Text(
            value,
            style: AppTypography.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(title, style: AppTypography.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(subtitle, style: AppTypography.bodySmall, textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class MetrajRecordCard extends StatelessWidget {
  const MetrajRecordCard({
    super.key,
    required this.record,
    required this.expanded,
    required this.onToggle,
    required this.onDetail,
  });

  final SavedRebarMetraj record;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    final result = record.result;
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm', 'tr_TR');
    final totalTonnage = result.totalTonnage;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggle,
              borderRadius: AppRadii.md,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            record.displayTitle,
                            style: AppTypography.titleLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          expanded ? Icons.expand_less : Icons.expand_more,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(dateFormat.format(record.savedAt), style: AppTypography.labelMedium),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${totalTonnage.toStringAsFixed(0)}t',
                          style: AppTypography.kpiValue.copyWith(fontSize: 22),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${result.totalBarCount} çubuk',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.electricBlueLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      result.lines.map((line) => 'Ø${line.diameter}').join(' · '),
                      style: AppTypography.bodySmall,
                    ),
                    if (record.surveyImalatName != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Keşif: ${record.surveyImalatName}',
                        style: AppTypography.labelMedium.copyWith(color: AppColors.success),
                      ),
                    ],
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: AppRadii.full,
                      child: LinearProgressIndicator(
                        value: 1,
                        minHeight: 4,
                        backgroundColor: AppColors.border,
                        color: AppColors.electricBlueLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'ÇAP',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'MİKTAR (ton)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'ORAN',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...result.lines.map((line) {
                    final color = AppColors.diameterColor(line.diameter);
                    final ratio = totalTonnage > 0 ? line.tonnage / totalTonnage * 100 : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Ø${line.diameter}',
                              style: AppTypography.titleMedium.copyWith(color: color),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              line.tonnage.toStringAsFixed(2),
                              style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: AppRadii.full,
                                    child: LinearProgressIndicator(
                                      value: ratio / 100,
                                      minHeight: 4,
                                      backgroundColor: AppColors.border,
                                      color: color,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${ratio.toStringAsFixed(0)}%',
                                  style: AppTypography.labelMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onDetail,
                      child: const Text('Metraj Detayı →'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
