import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/domain/entities/rebar_metraj.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';
import 'package:santijet_demir/features/rebar_metraj/providers/rebar_metraj_storage_provider.dart';
import 'package:santijet_demir/features/survey/providers/survey_provider.dart';

/// Kaydedilmiş CAD metraj sonuçları — yalnızca analiz tonaj verileri.
class SavedMetrajListTab extends ConsumerWidget {
  const SavedMetrajListTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(savedRebarMetrajProvider);
    final projectId = ref.watch(activeProjectIdProvider);
    final expandedId = ref.watch(expandedMetrajRecordProvider);
    final totalTonnage =
        records.fold<double>(0, (sum, r) => sum + r.result.totalTonnage);

    return Material(
      color: AppColors.canvas,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _MetrajSummaryRow(
            recordCount: records.length,
            totalTonnage: totalTonnage,
          ),
          const SizedBox(height: 16),
          Text('Metraj Listesi', style: AppTypography.headlineMedium),
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
              onAction: () =>
                  ref.read(surveyTabIndexProvider.notifier).state = 1,
            )
          else
            ...records.map(
              (record) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: MetrajRecordCard(
                  record: record,
                  expanded: expandedId == record.id,
                  onToggle: () {
                    ref.read(expandedMetrajRecordProvider.notifier).state =
                        expandedId == record.id ? null : record.id;
                  },
                ),
              ),
            ),
          if (records.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(
                    Icons.list_alt,
                    size: 16,
                    color: AppColors.electricBlueLight,
                  ),
                  label: Text('${records.length} kayıt',
                      style: AppTypography.labelMedium),
                  backgroundColor: AppColors.surfaceElevated,
                  side: const BorderSide(color: AppColors.border),
                ),
                ActionChip(
                  avatar: const Icon(
                    Icons.add,
                    size: 16,
                    color: AppColors.electricBlueLight,
                  ),
                  label: Text('Yeni Metraj', style: AppTypography.labelMedium),
                  backgroundColor: AppColors.surfaceElevated,
                  side: const BorderSide(color: AppColors.border),
                  onPressed: () =>
                      ref.read(surveyTabIndexProvider.notifier).state = 1,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MetrajSummaryRow extends StatelessWidget {
  const _MetrajSummaryRow({
    required this.recordCount,
    required this.totalTonnage,
  });

  final int recordCount;
  final double totalTonnage;

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
          _MetaItem(label: 'Kayıt', value: '$recordCount metraj'),
          _MetaItem(
            label: 'Toplam',
            value: recordCount > 0 ? _formatTonnage(totalTonnage) : '-',
          ),
          _MetaItem(
            label: 'Veri',
            value: 'Analiz sonucu',
          ),
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
          Text(title,
              style: AppTypography.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(subtitle,
              style: AppTypography.bodySmall, textAlign: TextAlign.center),
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
  });

  final SavedRebarMetraj record;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final result = record.result;
    final lines = result.lines;

    return Container(
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
                    Text(_formatDate(record.savedAt),
                        style: AppTypography.labelMedium),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          _formatTonnage(result.totalTonnage),
                          style: AppTypography.kpiValue.copyWith(fontSize: 22),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${result.totalBarCount} çubuk',
                          style: AppTypography.bodySmall,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          result.sourceFormat.toUpperCase(),
                          style: AppTypography.labelMedium,
                        ),
                      ],
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Çap Bazlı Tonaj', style: AppTypography.titleMedium),
                  const SizedBox(height: 10),
                  if (lines.isEmpty)
                    Text(
                      'Çap bazlı analiz satırı bulunamadı.',
                      style: AppTypography.bodySmall,
                    )
                  else
                    ...lines.map((line) {
                      final color = AppColors.diameterColor(line.diameter);
                      final ratio = result.totalTonnage > 0
                          ? line.tonnage / result.totalTonnage * 100
                          : 0.0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Ø${line.diameter}',
                                style: AppTypography.titleMedium
                                    .copyWith(color: color),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                _formatTonnage(line.tonnage),
                                style: AppTypography.bodyMedium
                                    .copyWith(fontSize: 12),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${ratio.toStringAsFixed(0)}%',
                                style: AppTypography.labelMedium,
                                textAlign: TextAlign.end,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _formatTonnage(double value) {
  final decimals = value.abs() >= 100 ? 1 : 2;
  return '${value.toStringAsFixed(decimals)} t';
}

String _formatDate(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(value.day)}.${two(value.month)}.${value.year} '
      '${two(value.hour)}:${two(value.minute)}';
}
