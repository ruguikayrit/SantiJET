import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/core/format/app_format.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/app_components.dart';
import 'package:santijet_demir/domain/entities/cutting_bending.dart';
import 'package:santijet_demir/features/analysis/cutting_bending_calculator.dart';
import 'package:santijet_demir/features/analysis/providers/cutting_bending_provider.dart';

class AnalysisFireSummaryPanel extends ConsumerWidget {
  const AnalysisFireSummaryPanel({super.key, required this.batch});

  final CuttingBendingBatch batch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = computeAnalysisFireSummary(batch);
    final comparison =
        batch.isOptimized ? computeAnalysisComparison(batch) : null;
    final lengthMatchDone = isLengthMatchingComplete(batch.lengthMatches);
    final tahvilApproved =
        batch.tahvilGroups.where((group) => group.approved).length;
    final tahvilTotal = batch.tahvilGroups.length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: AppColors.electricBlueGlow,
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadii.md,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.success.withValues(alpha: 0.85),
                    AppColors.electricBlueLight.withValues(alpha: 0.45),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.28),
                          ),
                        ),
                        child: const Icon(
                          Icons.local_fire_department_outlined,
                          color: AppColors.success,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Fire Özeti', style: AppTypography.titleMedium),
                            const SizedBox(height: 2),
                            Text(
                              batch.isOptimized
                                  ? 'Ham kaynak veri ile optimize sonuç karşılaştırması'
                                  : 'Ön imalat ham verisi — optimize analiz bekleniyor',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: KpiCard(
                            label: 'Ham Tonaj',
                            value: AppFormat.tonnage(summary.rawMaterialTonnage),
                            unit: 't',
                            accentColor: AppColors.electricBlueLight,
                            dense: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: KpiCard(
                            label: 'Ham Fire',
                            value: AppFormat.tonnage(summary.rawWasteTonnage),
                            unit: 't',
                            percent: '%${summary.rawWastePercent.toStringAsFixed(1)}',
                            accentColor: AppColors.warning,
                            dense: true,
                          ),
                        ),
                        if (batch.isOptimized) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: KpiCard(
                              label: 'Plan Fire',
                              value: summary.isPlannedReady
                                  ? AppFormat.tonnage(summary.plannedWasteTonnage!)
                                  : '—',
                              unit: summary.isPlannedReady ? 't' : '',
                              percent: summary.isPlannedReady
                                  ? '%${summary.plannedWastePercent!.toStringAsFixed(1)}'
                                  : null,
                              accentColor: summary.isPlannedReady
                                  ? _fireColor(summary.plannedWastePercent!)
                                  : AppColors.textMuted,
                              dense: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: KpiCard(
                              label: 'Kazanç',
                              value: summary.savedWasteTonnage > 0
                                  ? AppFormat.tonnage(summary.savedWasteTonnage)
                                  : '—',
                              unit: summary.savedWasteTonnage > 0 ? 't' : '',
                              percent: summary.savedWastePercent > 0
                                  ? '−%${summary.savedWastePercent.toStringAsFixed(1)}'
                                  : null,
                              accentColor: AppColors.success,
                              dense: true,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!batch.isOptimized) ...[
                    const SizedBox(height: 14),
                    _MatteGreenGradientButton(
                      onPressed: batch.pieceLines.isEmpty
                          ? null
                          : () => ref
                              .read(cuttingBendingBatchesProvider.notifier)
                              .runOptimumFireAnalysis(),
                      icon: Icons.auto_fix_high_outlined,
                      label: 'Optimum Fire Analizi',
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Boy eşleştirme, tahvil ve planlı kesim otomatik uygulanır. '
                      'Kaynak veri korunur.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (comparison != null) ...[
                    const SizedBox(height: 14),
                    AnalysisComparisonPanel(comparison: comparison),
                  ],
                  if (batch.isOptimized) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _PipelineChip(
                          label: 'Boy eşleştirme',
                          done: lengthMatchDone,
                          detail: lengthMatchDone
                              ? '${batch.lengthMatches.length} grup'
                              : 'Eksik',
                        ),
                        if (tahvilTotal > 0)
                          _PipelineChip(
                            label: 'Tahvil',
                            done: tahvilApproved > 0,
                            detail: '$tahvilApproved / $tahvilTotal',
                            optional: tahvilApproved == 0,
                          ),
                        _PipelineChip(
                          label: 'Kesim planı',
                          done: batch.stockCutPlans.isNotEmpty,
                          detail: batch.stockCutPlans.isNotEmpty
                              ? '${batch.stockCutPlans.length} çap'
                              : 'Yok',
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _fireColor(double percent) {
    if (percent <= 1.5) return AppColors.success;
    if (percent <= 4) return AppColors.warning;
    return AppColors.critical;
  }
}

class AnalysisComparisonPanel extends StatelessWidget {
  const AnalysisComparisonPanel({super.key, required this.comparison});

  final AnalysisComparison comparison;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: AppRadii.sm,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Ham → Revize', style: AppTypography.labelMedium),
          const SizedBox(height: 4),
          Text(
            'Fire oranı = fire tonajı ÷ 12 m stok tonajı',
            style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          _ComparisonRow(
            label: 'Boy çeşidi',
            before: '${comparison.rawLineCount} satır',
            after: '${comparison.revisedLineCount} satır',
            delta: comparison.savedLines > 0 ? '−${comparison.savedLines}' : null,
            positive: comparison.savedLines > 0,
          ),
          _ComparisonRow(
            label: 'Toplam adet',
            before: AppFormat.integer(comparison.rawPieceCount),
            after: AppFormat.integer(comparison.revisedPieceCount),
            delta: comparison.rawPieceCount != comparison.revisedPieceCount
                ? '${comparison.revisedPieceCount - comparison.rawPieceCount >= 0 ? '+' : ''}${comparison.revisedPieceCount - comparison.rawPieceCount}'
                : null,
            positive: comparison.revisedPieceCount >= comparison.rawPieceCount,
          ),
          _ComparisonRow(
            label: 'Stok fire oranı',
            before: '%${comparison.rawFirePercent.toStringAsFixed(1)}',
            after: '%${comparison.plannedFirePercent.toStringAsFixed(1)}',
            delta: comparison.savedFirePercent > 0.05
                ? '−%${comparison.savedFirePercent.toStringAsFixed(1)}'
                : comparison.savedFirePercent < -0.05
                    ? '+%${(-comparison.savedFirePercent).toStringAsFixed(1)}'
                    : null,
            positive: comparison.savedFirePercent > 0.05,
            negative: comparison.savedFirePercent < -0.05,
          ),
          _ComparisonRow(
            label: 'Fire tonajı',
            before: AppFormat.tonnage(comparison.rawFireTonnage),
            after: AppFormat.tonnage(comparison.plannedFireTonnage),
            delta: comparison.savedFireTonnage > 0
                ? '−${AppFormat.tonnage(comparison.savedFireTonnage)} t'
                : null,
            positive: comparison.savedFireTonnage > 0,
          ),
          if (comparison.lengthMatchGroupsApplied > 0 ||
              comparison.tahvilGroupsApplied > 0) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (comparison.lengthMatchGroupsApplied > 0)
                  _ChangeChip(
                    icon: Icons.straighten,
                    label:
                        '${comparison.lengthMatchGroupsApplied} boy eşleştirme',
                  ),
                if (comparison.tahvilGroupsApplied > 0)
                  _ChangeChip(
                    icon: Icons.swap_horiz,
                    label: '${comparison.tahvilGroupsApplied} tahvil',
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.label,
    required this.before,
    required this.after,
    this.delta,
    this.positive = false,
    this.negative = false,
  });

  final String label;
  final String before;
  final String after;
  final String? delta;
  final bool positive;
  final bool negative;

  @override
  Widget build(BuildContext context) {
    final afterColor = positive
        ? AppColors.success
        : negative
            ? AppColors.warning
            : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              before,
              style: AppTypography.bodySmall,
              textAlign: TextAlign.end,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Icon(Icons.arrow_forward, size: 14, color: AppColors.textMuted),
          ),
          Expanded(
            child: Text(
              after,
              style: AppTypography.bodySmall.copyWith(
                color: afterColor,
                fontWeight: (positive || negative) ? FontWeight.w600 : null,
              ),
            ),
          ),
          if (delta != null)
            SizedBox(
              width: 72,
              child: Text(
                delta!,
                style: AppTypography.labelMedium.copyWith(
                  color: positive
                      ? AppColors.success
                      : negative
                          ? AppColors.warning
                          : AppColors.textMuted,
                ),
                textAlign: TextAlign.end,
              ),
            ),
        ],
      ),
    );
  }
}

class _ChangeChip extends StatelessWidget {
  const _ChangeChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: AppRadii.full,
        border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.success),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(color: AppColors.success),
          ),
        ],
      ),
    );
  }
}

class _MatteGreenGradientButton extends StatelessWidget {
  const _MatteGreenGradientButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;

  static const _enabledGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0A5C45),
      Color(0xFF0F7358),
      Color(0xFF116B52),
    ],
  );

  static const _disabledGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A2E28),
      Color(0xFF1F3530),
      Color(0xFF1A2E28),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return Material(
      color: Colors.transparent,
      borderRadius: AppRadii.sm,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadii.sm,
        splashColor: Colors.white.withValues(alpha: 0.08),
        highlightColor: Colors.white.withValues(alpha: 0.04),
        child: Ink(
          height: 46,
          decoration: BoxDecoration(
            borderRadius: AppRadii.sm,
            gradient: enabled ? _enabledGradient : _disabledGradient,
            border: Border.all(
              color: enabled
                  ? const Color(0xFF0F6B52).withValues(alpha: 0.55)
                  : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: enabled
                    ? const Color(0xFFD1FAE5)
                    : AppColors.textDisabled,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: enabled
                      ? const Color(0xFFE8F5F0)
                      : AppColors.textDisabled,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PipelineChip extends StatelessWidget {
  const _PipelineChip({
    required this.label,
    required this.done,
    required this.detail,
    this.optional = false,
  });

  final String label;
  final bool done;
  final String detail;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    final color = done ? AppColors.success : AppColors.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: done
            ? AppColors.success.withValues(alpha: 0.08)
            : AppColors.canvas,
        borderRadius: AppRadii.full,
        border: Border.all(
          color: done
              ? AppColors.success.withValues(alpha: 0.35)
              : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            optional ? '$label (ops.)' : label,
            style: AppTypography.labelMedium.copyWith(color: color),
          ),
          const SizedBox(width: 6),
          Text(
            detail,
            style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class AnalysisStepHeader extends StatelessWidget {
  const AnalysisStepHeader({
    super.key,
    required this.step,
    required this.title,
    required this.subtitle,
    this.complete = false,
  });

  final int step;
  final String title;
  final String subtitle;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final color = complete ? AppColors.success : AppColors.electricBlueLight;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: complete
                ? Icon(Icons.check, size: 16, color: color)
                : Text(
                    '$step',
                    style: AppTypography.labelMedium.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleMedium),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
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
