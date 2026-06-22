import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/app_components.dart';
import 'package:santijet_demir/domain/entities/survey.dart';
import 'package:santijet_demir/features/survey/providers/survey_provider.dart';

class SurveyDetailScreen extends ConsumerWidget {
  const SurveyDetailScreen({super.key, required this.imalatId});

  final String imalatId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(surveyProjectProvider);
    final imalat = project.imalats.firstWhere((i) => i.id == imalatId);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(imalat.name, style: AppTypography.titleLarge),
            Text(project.projectName, style: AppTypography.labelMedium),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _MetaBar(project: project),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              KpiCard(
                label: 'Planlanan',
                value: imalat.planned.toStringAsFixed(0),
                unit: 't',
                accentColor: AppColors.electricBlueLight,
              ),
              KpiCard(
                label: 'Sipariş Edilen',
                value: imalat.ordered.toStringAsFixed(0),
                unit: 't',
                accentColor: AppColors.info,
              ),
              KpiCard(
                label: 'Teslim Alınan',
                value: imalat.delivered.toStringAsFixed(0),
                unit: 't',
                accentColor: AppColors.success,
              ),
              KpiCard(
                label: 'Bekleyen',
                value: imalat.pending.toStringAsFixed(0),
                unit: 't',
                accentColor: AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ProgressCard(
            label: 'Sipariş',
            percentage: imalat.orderProgress,
            color: AppColors.info,
          ),
          const SizedBox(height: 8),
          ProgressCard(
            label: 'Teslimat',
            percentage: imalat.deliveryProgress,
            color: AppColors.success,
          ),
          const SizedBox(height: 20),
          Text('Çap Detay Tablosu', style: AppTypography.headlineMedium),
          const SizedBox(height: 12),
          _DiameterDetailTable(imalat: imalat),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.electricBlue.withValues(alpha: 0.08),
              borderRadius: AppRadii.md,
              border: Border.all(color: AppColors.electricBlue.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('TOPLAM', style: AppTypography.titleLarge),
                Text(
                  '${imalat.planned.toStringAsFixed(0)}t',
                  style: AppTypography.kpiValue.copyWith(
                    color: AppColors.electricBlueLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaBar extends StatelessWidget {
  const _MetaBar({required this.project});

  final SurveyProject project;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(child: Text('Rev: ${project.revision}', style: AppTypography.bodySmall)),
          Expanded(
            child: Text(
              '${project.date.day}.${project.date.month}.${project.date.year}',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              project.projectName,
              style: AppTypography.bodySmall,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _DiameterDetailTable extends StatelessWidget {
  const _DiameterDetailTable({required this.imalat});

  final SurveyImalat imalat;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                _HeaderCell('ÇAP', flex: 2),
                _HeaderCell('PLAN.', flex: 2),
                _HeaderCell('SİP.', flex: 2),
                _HeaderCell('TESLİM', flex: 2),
                _HeaderCell('BEKL.', flex: 2),
              ],
            ),
          ),
          ...imalat.diameterLines.map((line) {
            final color = AppColors.diameterColor(line.diameter);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _DataCell('Ø${line.diameter}', flex: 2, color: color),
                      _DataCell('${line.planned.toStringAsFixed(0)}t', flex: 2),
                      _DataCell('${line.ordered.toStringAsFixed(0)}t', flex: 2),
                      _DataCell('${line.delivered.toStringAsFixed(0)}t', flex: 2),
                      _DataCell('${line.pending.toStringAsFixed(0)}t', flex: 2),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: AppRadii.full,
                    child: Stack(
                      children: [
                        LinearProgressIndicator(
                          value: line.planned > 0 ? line.ordered / line.planned : 0,
                          minHeight: 3,
                          backgroundColor: AppColors.border,
                          color: color.withValues(alpha: 0.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text, {required this.flex});

  final String text;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _DataCell extends StatelessWidget {
  const _DataCell(this.text, {required this.flex, this.color});

  final String text;
  final int flex;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: AppTypography.bodyMedium.copyWith(
          fontSize: 12,
          color: color ?? AppColors.textSecondary,
          fontWeight: color != null ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}
