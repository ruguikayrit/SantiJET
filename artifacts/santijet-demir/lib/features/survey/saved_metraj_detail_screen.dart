import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/app_components.dart';
import 'package:santijet_demir/domain/entities/rebar_metraj.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';
import 'package:santijet_demir/features/rebar_metraj/providers/rebar_metraj_storage_provider.dart';
import 'package:santijet_demir/features/rebar_metraj/widgets/metraj_cutting_actions.dart';
import 'package:santijet_demir/features/rebar_metraj/widgets/metraj_survey_actions.dart';
import 'package:santijet_demir/features/survey/providers/survey_provider.dart';

class SavedMetrajDetailScreen extends ConsumerWidget {
  const SavedMetrajDetailScreen({super.key, required this.recordId});

  final String recordId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(savedRebarMetrajProvider);
    final project = ref.watch(surveyProjectProvider);
    SavedRebarMetraj? record;
    for (final item in records) {
      if (item.id == recordId) {
        record = item;
        break;
      }
    }

    if (record == null) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(title: const Text('Ön İmalat')),
        body: const Center(child: Text('Kayıt bulunamadı')),
      );
    }

    final result = record.result;
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm', 'tr_TR');
    final numberFormat = NumberFormat('#,##0.00', 'tr_TR');

    final canEdit = ref.watch(canEditActiveProjectProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ön İmalat', style: AppTypography.titleLarge),
            Text(record.displayTitle, style: AppTypography.labelMedium),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: AppRadii.md,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Kayıt: ${dateFormat.format(record.savedAt)}',
                    style: AppTypography.bodySmall,
                  ),
                ),
                Expanded(
                  child: Text(
                    result.sourceFormat,
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
          ),
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
                label: 'Toplam Tonaj',
                value: numberFormat.format(result.totalTonnage),
                unit: 't',
                accentColor: AppColors.electricBlueLight,
              ),
              KpiCard(
                label: 'Toplam Uzunluk',
                value: numberFormat.format(result.totalLengthM),
                unit: 'm',
                accentColor: AppColors.success,
              ),
              KpiCard(
                label: 'Çubuk Sayısı',
                value: '${result.totalBarCount}',
                unit: 'ad',
                accentColor: AppColors.info,
              ),
              KpiCard(
                label: 'Etiket Sayısı',
                value: '${result.textDetails.length}',
                unit: 'ad',
                accentColor: AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Çap Detay Tablosu', style: AppTypography.headlineMedium),
          const SizedBox(height: 12),
          _MetrajDiameterTable(result: result, numberFormat: numberFormat),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.electricBlue.withValues(alpha: 0.08),
              borderRadius: AppRadii.md,
              border: Border.all(
                  color: AppColors.electricBlue.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('TOPLAM', style: AppTypography.titleLarge),
                Text(
                  '${numberFormat.format(result.totalTonnage)} t',
                  style: AppTypography.kpiValue.copyWith(
                    color: AppColors.electricBlueLight,
                  ),
                ),
              ],
            ),
          ),
          if (record.surveyImalatName != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: AppRadii.md,
                border:
                    Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: AppColors.success, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'İmalata aktarıldı: ${record.surveyImalatName}',
                      style: AppTypography.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (canEdit) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () =>
                    sendMetrajRecordToSurvey(context, ref, record!),
                icon: const Icon(Icons.send),
                label: const Text('İmalata Gönder'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () =>
                    sendMetrajRecordToCuttingBending(context, ref, record!),
                icon: const Icon(Icons.content_cut),
                label: const Text('Kesme-Bükme\'ye Gönder'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetrajDiameterTable extends StatelessWidget {
  const _MetrajDiameterTable({
    required this.result,
    required this.numberFormat,
  });

  final RebarMetrajResult result;
  final NumberFormat numberFormat;

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
            child: const Row(
              children: [
                _HeaderCell('ÇAP', flex: 2),
                _HeaderCell('TONAJ', flex: 2),
                _HeaderCell('UZUNLUK', flex: 2),
                _HeaderCell('ADET', flex: 2),
              ],
            ),
          ),
          ...result.lines.map((line) {
            final color = AppColors.diameterColor(line.diameter);
            final ratio = result.totalTonnage > 0
                ? line.tonnage / result.totalTonnage
                : 0.0;
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
                      _DataCell('${numberFormat.format(line.tonnage)} t',
                          flex: 2),
                      _DataCell('${numberFormat.format(line.totalLengthM)} m',
                          flex: 2),
                      _DataCell('${line.barCount}', flex: 2),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: AppRadii.full,
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 3,
                      backgroundColor: AppColors.border,
                      color: color.withValues(alpha: 0.5),
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
