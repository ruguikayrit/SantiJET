import 'package:flutter/material.dart';
import 'package:santijet_demir/core/format/app_format.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/empty_states.dart';
import 'package:santijet_demir/features/incoming_rebar/providers/incoming_rebar_provider.dart';

class DeliveredDiameterTable extends StatelessWidget {
  const DeliveredDiameterTable({super.key, required this.rows});

  final List<DeliveredDiameterRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const ModuleEmptyState(type: EmptyStateType.noDelivery, inline: true);
    }

    final totalDelivered = rows.fold(0.0, (sum, row) => sum + row.delivered);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'ÇAP',
                    style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Expanded(
                  child: Text(
                    'MİKTAR',
                    style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
          ...rows.map(
            (row) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ø${row.diameter}',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.diameterColor(row.diameter),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${AppFormat.tonnage(row.delivered)}t',
                      style: AppTypography.bodyMedium,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            color: AppColors.success.withValues(alpha: 0.06),
            child: Row(
              children: [
                Expanded(
                  child: Text('TOPLAM', style: AppTypography.titleMedium),
                ),
                Expanded(
                  child: Text(
                    '${AppFormat.tonnage(totalDelivered)}t',
                    style: AppTypography.titleMedium.copyWith(color: AppColors.success),
                    textAlign: TextAlign.end,
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
