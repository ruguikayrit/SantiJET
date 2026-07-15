import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/data/services/metraj_cetvel_summary.dart';
import 'package:santijet_demir/domain/entities/rebar_metraj.dart';

/// Metraj tonaj özeti: toplam / ince / kalın tek satır, altında çap kartları.
class MetrajTonnageSummaryCards extends StatelessWidget {
  const MetrajTonnageSummaryCards({
    super.key,
    required this.lines,
  });

  final List<RebarMetrajLine> lines;

  static const _rowGap = 12.0;
  static const _diameterGap = 8.0;
  static const _minDiameterCardWidth = 76.0;
  static const _cardAspectRatio = 1.55;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) return const SizedBox.shrink();

    final summary = summarizeLines(lines);
    final numberFormat = NumberFormat('#,##0.00', 'tr_TR');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth =
                (constraints.maxWidth - _diameterGap * 2) / 3;
            final cardHeight = cardWidth / _cardAspectRatio;
            return Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: cardHeight,
                    child: _StackedMetricCard(
                      label: 'Toplam Tonaj',
                      value: numberFormat.format(summary.totalTonnage),
                      accentColor: AppColors.electricBlueLight,
                    ),
                  ),
                ),
                const SizedBox(width: _diameterGap),
                Expanded(
                  child: SizedBox(
                    height: cardHeight,
                    child: _StackedMetricCard(
                      label: 'İnce Demir',
                      value: numberFormat.format(summary.thinTonnage),
                      accentColor: AppColors.info,
                    ),
                  ),
                ),
                const SizedBox(width: _diameterGap),
                Expanded(
                  child: SizedBox(
                    height: cardHeight,
                    child: _StackedMetricCard(
                      label: 'Kalın Demir',
                      value: numberFormat.format(summary.thickTonnage),
                      accentColor: AppColors.success,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        if (summary.lines.isNotEmpty) ...[
          const SizedBox(height: _rowGap),
          LayoutBuilder(
            builder: (context, constraints) {
              final count = summary.lines.length;
              final maxWidth = constraints.maxWidth;
              final perRow = _optimalCardsPerRow(maxWidth, count);
              final cardWidth =
                  (maxWidth - _diameterGap * (perRow - 1)) / perRow;
              final cardHeight = cardWidth / _cardAspectRatio;

              return Wrap(
                spacing: _diameterGap,
                runSpacing: _diameterGap,
                children: [
                  for (final line in summary.lines)
                    SizedBox(
                      width: cardWidth,
                      height: cardHeight,
                      child: _StackedMetricCard(
                        label: 'Ø${line.diameter}',
                        value: numberFormat.format(line.tonnage),
                        accentColor: AppColors.diameterColor(line.diameter),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }

  int _optimalCardsPerRow(double maxWidth, int count) {
    if (count <= 1) return 1;

    var bestPerRow = 2;
    var bestScore = double.negativeInfinity;

    for (var perRow = 2; perRow <= count; perRow++) {
      final cardWidth =
          (maxWidth - _diameterGap * (perRow - 1)) / perRow;
      if (cardWidth < _minDiameterCardWidth) break;

      final rowCount = (count / perRow).ceil();
      final lastRowCount = count - (rowCount - 1) * perRow;
      final balancePenalty = (perRow - lastRowCount).abs() * 0.35;
      final widthBonus = cardWidth / maxWidth;
      final score = widthBonus - balancePenalty - rowCount * 0.08;

      if (score > bestScore) {
        bestScore = score;
        bestPerRow = perRow;
      }
    }

    return bestPerRow.clamp(2, count);
  }
}

/// Başlık üstte, tonaj altında — hücrede yatay ve düşey ortalı.
class _StackedMetricCard extends StatelessWidget {
  const _StackedMetricCard({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  final String label;
  final String value;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                label,
                style: AppTypography.labelMedium,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: value,
                        style: AppTypography.kpiValue.copyWith(
                          color: accentColor,
                          fontSize: 20,
                          height: 1,
                        ),
                      ),
                      TextSpan(
                        text: ' t',
                        style: AppTypography.labelSmall.copyWith(height: 1),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
