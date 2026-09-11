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
  return AppColors.cardTextMuted;
}

/// Ekip özet kartları — eksen başına sabit renk; doluluk arttıkça soft → doygun.
enum ProductionProgressColorMode {
  /// Tamamlanma % eşiğine göre yeşil / mavi / gri (imalat kartı).
  completionThreshold,

  /// Metraj / Süre / AG kendi rengi; yoğunluk doluluk oranına bağlı.
  axisFillIntensity,
}

/// Ekip özet kartı — eksen gradyanı (sol soft → sağ doygun).
LinearGradient axisFillGradient(String label, double fillRatio) {
  final t = fillRatio.clamp(0.0, 1.0);
  final whiteBlend = AppColors.useDarkCards ? 0.68 : 0.58;

  late Color start;
  late Color end;
  switch (label) {
    case 'Metraj':
      start = const Color(0xFF6EE7B7);
      end = AppColors.success;
    case 'Süre':
      start = AppColors.info;
      end = AppColors.electricBlue;
    case 'Adam-gün':
      start = const Color(0xFFFDBA74);
      end = AppColors.warning;
    default:
      start = AppColors.info;
      end = AppColors.electricBlue;
  }

  final softStart = Color.lerp(start, Colors.white, whiteBlend) ?? start;
  final softEnd = Color.lerp(end, Colors.white, whiteBlend) ?? end;
  return LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color.lerp(softStart, start, t)!,
      Color.lerp(softEnd, end, t)!,
    ],
  );
}

Color axisFillAccentColor(String label) {
  return switch (label) {
    'Metraj' => AppColors.success,
    'Süre' => AppColors.electricBlue,
    'Adam-gün' => AppColors.warning,
    _ => AppColors.electricBlue,
  };
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
    ProductionMetrics? metrics,
    List<ProductionProgressAxis>? axes,
    this.dense = true,
    this.showPctLabels = true,
    this.colorMode = ProductionProgressColorMode.completionThreshold,
  })  : assert(metrics != null || axes != null),
        _metrics = metrics,
        _axes = axes;

  factory ProductionTripleProgress.fromMetrics({
    required ProductionMetrics metrics,
    bool dense = true,
    bool showPctLabels = true,
  }) {
    return ProductionTripleProgress(
      metrics: metrics,
      dense: dense,
      showPctLabels: showPctLabels,
    );
  }

  final ProductionMetrics? _metrics;
  final List<ProductionProgressAxis>? _axes;
  final bool dense;
  final bool showPctLabels;
  final ProductionProgressColorMode colorMode;

  List<ProductionProgressAxis> get _resolvedAxes =>
      _axes ?? _metrics!.axes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final barH = dense ? 6.0 : 8.0;
    final gap = dense ? AppSpacing.xs : AppSpacing.sm;
    final labelStyle = theme.textTheme.labelSmall;
    final resolved = _resolvedAxes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < resolved.length; i++) ...[
          if (i > 0) SizedBox(height: gap),
          _CompletionProgressLine(
            axis: resolved[i],
            barHeight: barH,
            labelStyle: labelStyle,
            showPct: showPctLabels,
            colorMode: colorMode,
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
    required this.colorMode,
  });

  final ProductionProgressAxis axis;
  final double barHeight;
  final TextStyle? labelStyle;
  final bool showPct;
  final ProductionProgressColorMode colorMode;

  Color _barColor(double pct) {
    if (!axis.hasPlan) return AppColors.cardTextMuted;
    return switch (colorMode) {
      ProductionProgressColorMode.completionThreshold =>
        completionColorForPct(pct),
      ProductionProgressColorMode.axisFillIntensity =>
        axisFillAccentColor(axis.label),
    };
  }

  @override
  Widget build(BuildContext context) {
    final pct = axis.progressPct;
    final fill = axis.hasPlan ? (pct / 100).clamp(0.0, 1.0) : 0.0;
    final color = _barColor(pct);
    final trackBg = colorMode == ProductionProgressColorMode.axisFillIntensity
        ? axisFillAccentColor(axis.label).withValues(alpha: 0.14)
        : color.withValues(alpha: 0.12);

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
        if (colorMode == ProductionProgressColorMode.axisFillIntensity &&
            axis.hasPlan)
          _AxisGradientProgressBar(
            value: fill,
            height: barHeight,
            gradient: axisFillGradient(axis.label, fill),
            trackColor: trackBg,
          )
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fill,
              minHeight: barHeight,
              backgroundColor: trackBg,
              color: axis.hasPlan ? color : AppColors.cardTextMuted,
            ),
          ),
      ],
    );
  }
}

class _AxisGradientProgressBar extends StatelessWidget {
  const _AxisGradientProgressBar({
    required this.value,
    required this.height,
    required this.gradient,
    required this.trackColor,
  });

  final double value;
  final double height;
  final Gradient gradient;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: trackColor),
            FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              alignment: Alignment.centerLeft,
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: gradient),
              ),
            ),
          ],
        ),
      ),
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
          color: AppColors.statusInkOnCard(AppColors.warning),
        ),
      );
    }

    final color = AppColors.statusInkOnCard(
      efficiencyColorForRatio(efficiency),
    );
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
