import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/app_components.dart';
import 'package:santijet_demir/domain/entities/order.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, this.onTap});

  final OrderItem order;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = Color(order.status.colorValue);
    final dateStr = DateFormat('d MMM yyyy').format(order.date);

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
                          Text(order.orderNo, style: AppTypography.titleMedium),
                          StatusBadge(label: order.status.label, color: statusColor),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(dateStr, style: AppTypography.bodySmall),
                      const SizedBox(height: 8),
                      Text(
                        order.imalatTypes.join(' · '),
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${order.tonnage.toStringAsFixed(0)}t',
                            style: AppTypography.kpiValue.copyWith(fontSize: 22),
                          ),
                          Text(
                            order.supplier,
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.electricBlueLight,
                            ),
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
