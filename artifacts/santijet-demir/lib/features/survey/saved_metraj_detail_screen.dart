import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/app_subpage_app_bar.dart';
import 'package:santijet_demir/core/widgets/app_table_header.dart';
import 'package:santijet_demir/domain/entities/rebar_metraj.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';
import 'package:santijet_demir/features/rebar_metraj/providers/rebar_metraj_storage_provider.dart';
import 'package:santijet_demir/features/rebar_metraj/widgets/metraj_cetvel_section.dart';
import 'package:santijet_demir/features/rebar_metraj/widgets/metraj_tonnage_summary_cards.dart';
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
        primary: false,
        appBar: appSubpageTitleAppBar(context, title: 'Ön İmalat'),
        body: const Center(child: Text('Kayıt bulunamadı')),
      );
    }

    final result = record.result;
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm', 'tr_TR');
    final numberFormat = NumberFormat('#,##0.00', 'tr_TR');

    final canEdit = ref.watch(canEditActiveProjectProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      primary: false,
      appBar: appSubpageTitleAppBar(
        context,
        title: 'Ön İmalat',
        subtitle: record.displayTitle,
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
          MetrajTonnageSummaryCards(lines: result.lines),
          if (result.lines.isNotEmpty || result.cetvel.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            MetrajCetvelSection(
              lines: result.lines,
              cetvel: result.cetvel,
              labelCount: result.textDetails.length,
            ),
            const SizedBox(height: AppSpacing.sm),
          ] else if (result.textDetails.isNotEmpty) ...[
            MetrajCetvelEmptyHint(labelCount: result.textDetails.length),
            const SizedBox(height: AppSpacing.sm),
          ],
          _CollapsibleDiameterDetail(
            result: result,
            numberFormat: numberFormat,
          ),
          const SizedBox(height: AppSpacing.sm),
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
            const SizedBox(height: AppSpacing.sm),
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
          if (record.isApprovedForAnalysis) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.electricBlue.withValues(alpha: 0.08),
                borderRadius: AppRadii.md,
                border: Border.all(
                  color: AppColors.electricBlue.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified,
                      color: AppColors.electricBlueLight, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Analiz için onaylandı — Hesap ve Analiz sayfasından yükleyin',
                      style: AppTypography.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (canEdit) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () =>
                    sendMetrajRecordToSurvey(context, ref, record!),
                icon: const Icon(Icons.send),
                label: const Text('İmalata Gönder'),
              ),
            ),
            if (!record.isApprovedForAnalysis) ...[
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      approveMetrajRecordForAnalysis(context, ref, record!),
                  icon: const Icon(Icons.verified_outlined),
                  label: const Text('Analize Onay Ver'),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// Varsayılan kapalı; başlığa tıklanınca çap tablosu açılır.
class _CollapsibleDiameterDetail extends StatefulWidget {
  const _CollapsibleDiameterDetail({
    required this.result,
    required this.numberFormat,
  });

  final RebarMetrajResult result;
  final NumberFormat numberFormat;

  @override
  State<_CollapsibleDiameterDetail> createState() =>
      _CollapsibleDiameterDetailState();
}

class _CollapsibleDiameterDetailState extends State<_CollapsibleDiameterDetail> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final numberFormat = widget.numberFormat;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: AppColors.electricBlue.withValues(alpha: 0.06),
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Çap Detay Tablosu',
                        style: AppTypography.headlineMedium,
                      ),
                    ),
                    Icon(
                      _expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: AppColors.electricBlueLight,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_expanded) _MetrajDiameterTableBody(
            result: result,
            numberFormat: numberFormat,
          ),
        ],
      ),
    );
  }
}

class _MetrajDiameterTableBody extends StatelessWidget {
  const _MetrajDiameterTableBody({
    required this.result,
    required this.numberFormat,
  });

  final RebarMetrajResult result;
  final NumberFormat numberFormat;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: _DiameterTableLayout.capFlex,
                  child: const AppTableHeaderBadge('ÇAP'),
                ),
                const SizedBox(width: _DiameterTableLayout.gap),
                Expanded(
                  flex: _DiameterTableLayout.agirlikFlex,
                  child: const AppTableHeaderBadge('AĞIRLIK'),
                ),
                const SizedBox(width: _DiameterTableLayout.gap),
                Expanded(
                  flex: _DiameterTableLayout.lengthFlex,
                  child: const AppTableHeaderBadge('UZUNLUK'),
                ),
                const SizedBox(width: _DiameterTableLayout.gap),
                Expanded(
                  flex: _DiameterTableLayout.adetFlex,
                  child: const AppTableHeaderBadge('ADET'),
                ),
              ],
            ),
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
                    _DataCell(
                      'Ø${line.diameter}',
                      flex: _DiameterTableLayout.capFlex,
                      color: color,
                    ),
                    const SizedBox(width: _DiameterTableLayout.gap),
                    _DataCell(
                      '${numberFormat.format(line.tonnage)} t',
                      flex: _DiameterTableLayout.agirlikFlex,
                    ),
                    const SizedBox(width: _DiameterTableLayout.gap),
                    _DataCell(
                      '${numberFormat.format(line.totalLengthM)} m',
                      flex: _DiameterTableLayout.lengthFlex,
                    ),
                    const SizedBox(width: _DiameterTableLayout.gap),
                    _DataCell(
                      '${line.barCount}',
                      flex: _DiameterTableLayout.adetFlex,
                    ),
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
    );
  }
}

/// Dört sütun dengeli; gereksiz Spacer / aşırı UZUNLUK flex yok.
abstract final class _DiameterTableLayout {
  static const gap = 4.0;
  static const capFlex = 2;
  static const agirlikFlex = 3;
  static const lengthFlex = 3;
  static const adetFlex = 2;
}

class _DataCell extends StatelessWidget {
  const _DataCell(
    this.text, {
    required this.flex,
    this.color,
    this.align = TextAlign.center,
  });

  final String text;
  final int flex;
  final Color? color;
  final TextAlign align;

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
        textAlign: align,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
