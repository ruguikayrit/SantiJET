import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/widgets/app_components.dart';
import 'package:santijet_demir/data/services/metraj_cetvel_summary.dart';
import 'package:santijet_demir/domain/entities/rebar_metraj.dart';

/// Metraj tonaj özeti: toplam → ince/kalın → çap kartları.
class MetrajTonnageSummaryCards extends StatelessWidget {
  const MetrajTonnageSummaryCards({
    super.key,
    required this.lines,
  });

  final List<RebarMetrajLine> lines;

  static const _rowGap = 12.0;
  static const _diameterGap = 8.0;
  static const _minDiameterCardWidth = 76.0;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) return const SizedBox.shrink();

    final summary = summarizeLines(lines);
    final numberFormat = NumberFormat('#,##0.00', 'tr_TR');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KpiCard(
          label: 'Toplam Tonaj',
          value: numberFormat.format(summary.totalTonnage),
          unit: 't',
          accentColor: AppColors.electricBlueLight,
          compactHeight: true,
        ),
        const SizedBox(height: _rowGap),
        Row(
          children: [
            Expanded(
              child: KpiCard(
                label: 'İnce Demir',
                value: numberFormat.format(summary.thinTonnage),
                unit: 't',
                accentColor: AppColors.info,
                dense: true,
                compactHeight: true,
              ),
            ),
            const SizedBox(width: _diameterGap),
            Expanded(
              child: KpiCard(
                label: 'Kalın Demir',
                value: numberFormat.format(summary.thickTonnage),
                unit: 't',
                accentColor: AppColors.success,
                dense: true,
                compactHeight: true,
              ),
            ),
          ],
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

              return Wrap(
                spacing: _diameterGap,
                runSpacing: _diameterGap,
                children: [
                  for (final line in summary.lines)
                    SizedBox(
                      width: cardWidth,
                      child: KpiCard(
                        label: 'Ø${line.diameter}',
                        value: numberFormat.format(line.tonnage),
                        unit: 't',
                        accentColor: AppColors.diameterColor(line.diameter),
                        dense: true,
                        centerContent: true,
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
