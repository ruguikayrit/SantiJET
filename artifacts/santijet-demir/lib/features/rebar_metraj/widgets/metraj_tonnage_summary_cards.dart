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

  static const _rowGap = 10.0;
  static const _diameterGap = 8.0;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) return const SizedBox.shrink();

    final summary = summarizeLines(lines);
    final numberFormat = NumberFormat('#,##0.00', 'tr_TR');
    final percentFormat = NumberFormat('#,##0.0', 'tr_TR');
    final total = summary.totalTonnage;

    String? shareOf(double tonnage) {
      if (total <= 0) return null;
      return '%${percentFormat.format(tonnage / total * 100)}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _StackedMetricCard(
                label: 'Toplam Tonaj',
                value: numberFormat.format(summary.totalTonnage),
                accentColor: AppColors.electricBlueLight,
              ),
            ),
            const SizedBox(width: _diameterGap),
            Expanded(
              child: _StackedMetricCard(
                label: 'İnce Demir',
                value: numberFormat.format(summary.thinTonnage),
                accentColor: AppColors.info,
              ),
            ),
            const SizedBox(width: _diameterGap),
            Expanded(
              child: _StackedMetricCard(
                label: 'Kalın Demir',
                value: numberFormat.format(summary.thickTonnage),
                accentColor: AppColors.success,
              ),
            ),
          ],
        ),
        if (summary.lines.isNotEmpty) ...[
          const SizedBox(height: _rowGap),
          LayoutBuilder(
            builder: (context, constraints) {
              const perRow = 2;
              final cardWidth =
                  (constraints.maxWidth - _diameterGap * (perRow - 1)) /
                      perRow;

              return Wrap(
                spacing: _diameterGap,
                runSpacing: _diameterGap,
                children: [
                  for (final line in summary.lines)
                    SizedBox(
                      width: cardWidth,
                      child: _StackedMetricCard(
                        label: 'Ø${line.diameter}',
                        value: numberFormat.format(line.tonnage),
                        shareLabel: shareOf(line.tonnage),
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
}

/// Başlık → tonaj → pay yüzdesi; içerik yüksekliği (boş alan yok).
class _StackedMetricCard extends StatelessWidget {
  const _StackedMetricCard({
    required this.label,
    required this.value,
    required this.accentColor,
    this.shareLabel,
  });

  final String label;
  final String value;
  final String? shareLabel;
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(height: 1.1),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: value,
                      style: AppTypography.kpiValue.copyWith(
                        color: accentColor,
                        fontSize: 18,
                        height: 1.05,
                      ),
                    ),
                    TextSpan(
                      text: ' t',
                      style: AppTypography.labelSmall.copyWith(height: 1.05),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ),
            if (shareLabel != null) ...[
              const SizedBox(height: 2),
              Text(
                shareLabel!,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textMuted,
                  height: 1.1,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
