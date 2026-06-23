import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'sj_card.dart';

/// ŞantiJET Design System — istatistik/KPI kartı.
///
/// ŞantiJET Demir `KpiCard` deseni: etiket + büyük değer (Rajdhani) + birim +
/// opsiyonel trend göstergesi. Değer rengi vurgu rengiyle verilir.
class SJStatCard extends StatelessWidget {
  const SJStatCard({
    required this.label,
    required this.value,
    this.unit,
    this.accentColor = AppColors.electricBlueLight,
    this.trend,
    this.trendUp,
    this.onTap,
    super.key,
  });

  final String label;
  final String value;
  final String? unit;
  final Color accentColor;
  final String? trend;
  final bool? trendUp;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SJCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: accentColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(unit!, style: theme.textTheme.labelMedium),
                ),
              ],
            ],
          ),
          if (trend != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(
                  trendUp == true ? Icons.trending_up : Icons.trending_down,
                  size: 14,
                  color:
                      trendUp == true ? AppColors.success : AppColors.critical,
                ),
                const SizedBox(width: 4),
                Text(
                  trend!,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: trendUp == true
                        ? AppColors.success
                        : AppColors.critical,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
