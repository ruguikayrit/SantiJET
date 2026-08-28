import 'package:flutter/material.dart';

import '../../domain/models/production_metrics.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';

/// Tamamlanma yüzdesi (metraj / süre / AG) — mavi-cyan skala.
Color completionColorForPct(double pct) {
  if (pct >= 100) return AppColors.success;
  if (pct >= 66) return AppColors.info;
  if (pct >= 33) return AppColors.electricBlueLight;
  return AppColors.textMuted;
}

/// Birim verim oranı (1.0 = plan) — yeşil / amber / kırmızı skala.
Color efficiencyColorForRatio(double? ratio) {
  if (ratio == null) return AppColors.cardTextMuted;
  if (ratio >= 1.0) return AppColors.success;
  if (ratio >= 0.8) return AppColors.warning;
  return AppColors.critical;
}

/// Metraj · Süre · Adam-gün — İmalat ve Verim’de ortak üçlü ilerleme gösterimi.
class ProductionTripleProgress extends StatelessWidget {
  const ProductionTripleProgress({
    super.key,
    required this.metrics,
    this.dense = true,
    this.showPctLabels = true,
  });

  final ProductionMetrics metrics;
  final bool dense;
  final bool showPctLabels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final barH = dense ? 6.0 : 8.0;
    final gap = dense ? AppSpacing.xs : AppSpacing.sm;
    final labelStyle = theme.textTheme.labelSmall;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < metrics.axes.length; i++) ...[
          if (i > 0) SizedBox(height: gap),
          _CompletionProgressLine(
            axis: metrics.axes[i],
            barHeight: barH,
            labelStyle: labelStyle,
            showPct: showPctLabels,
          ),
        ],
      ],
    );
  }
}

class _CompletionProgressLine extends StatelessWidget {
  const _CompletionProgressLine({
    required this.axis,
    required this.barHeight,
    required this.labelStyle,
    required this.showPct,
  });

  final ProductionProgressAxis axis;
  final double barHeight;
  final TextStyle? labelStyle;
  final bool showPct;

  @override
  Widget build(BuildContext context) {
    final pct = axis.progressPct;
    final color = completionColorForPct(pct);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              axis.label,
              style: labelStyle?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                axis.detail,
                style: labelStyle?.copyWith(
                  color: axis.hasPlan
                      ? labelStyle?.color
                      : AppColors.cardTextMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showPct && axis.hasPlan)
              Text(
                '%${pct.toStringAsFixed(0)}',
                style: labelStyle?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: axis.hasPlan ? (pct / 100).clamp(0.0, 1.0) : 0,
            minHeight: barHeight,
            backgroundColor: color.withValues(alpha: 0.12),
            color: axis.hasPlan ? color : AppColors.cardTextMuted,
          ),
        ),
      ],
    );
  }
}

/// Birim verim rozeti — İmalat kartı + Verim satırı.
class UnitEfficiencyBadge extends StatelessWidget {
  const UnitEfficiencyBadge({
    super.key,
    required this.efficiency,
    this.compact = false,
    this.missingLabel,
  });

  final double? efficiency;
  final bool compact;
  final String? missingLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (efficiency == null) {
      if (missingLabel == null) return const SizedBox.shrink();
      return Text(
        missingLabel!,
        style: theme.textTheme.labelSmall?.copyWith(
          color: AppColors.warning,
        ),
      );
    }

    final color = efficiencyColorForRatio(efficiency);
    final label = compact ? 'Verim' : 'Birim verim';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppRadii.full,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!compact) ...[
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            '%${(efficiency! * 100).toStringAsFixed(0)}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Birim verim çubuğu — tamamlanma barlarından ayrı renk skalası.
class UnitEfficiencyBar extends StatelessWidget {
  const UnitEfficiencyBar({
    super.key,
    required this.efficiency,
    this.height = 6,
  });

  final double efficiency;
  final double height;

  @override
  Widget build(BuildContext context) {
    final color = efficiencyColorForRatio(efficiency);
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: efficiency.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: color.withValues(alpha: 0.15),
        color: color,
      ),
    );
  }
}
