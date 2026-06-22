import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/app_components.dart';
import 'package:santijet_demir/domain/entities/delivery.dart';

class DeliveryCard extends StatelessWidget {
  const DeliveryCard({super.key, required this.delivery, this.onTap});

  final DeliveryItem delivery;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = Color(delivery.status.colorValue);
    final dateStr = DateFormat('d MMM yyyy').format(delivery.date);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.md,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: AppRadii.md,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(delivery.supplier, style: AppTypography.titleMedium),
                          StatusBadge(label: delivery.status.label, color: statusColor),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(dateStr, style: AppTypography.bodySmall),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              delivery.orderNo,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            delivery.irsaliyeNo,
                            style: AppTypography.labelMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${delivery.tonnage.toStringAsFixed(0)}t',
                            style: AppTypography.kpiValue.copyWith(fontSize: 22),
                          ),
                          Text(
                            '%${delivery.fulfillmentPercent.toStringAsFixed(0)} karşılama',
                            style: AppTypography.labelMedium.copyWith(color: statusColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CompactDeliveryTile extends StatelessWidget {
  const CompactDeliveryTile({super.key, required this.delivery, this.onTap});

  final DeliveryItem delivery;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = Color(delivery.status.colorValue);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 36,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: AppRadii.xs,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(delivery.supplier, style: AppTypography.titleMedium),
                    Text(
                      '${delivery.orderNo} · ${delivery.tonnage.toStringAsFixed(0)}t',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
