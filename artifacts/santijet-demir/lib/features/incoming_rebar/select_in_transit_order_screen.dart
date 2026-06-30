import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/empty_states.dart';
import 'package:santijet_demir/domain/entities/order.dart';
import 'package:santijet_demir/features/incoming_rebar/providers/incoming_rebar_provider.dart';

class SelectInTransitOrderScreen extends ConsumerWidget {
  const SelectInTransitOrderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inTransitOrders = ref.watch(inTransitOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Yoldaki Sevkiyatlar'),
      ),
      body: inTransitOrders.isEmpty
          ? const ModuleEmptyState(
              type: EmptyStateType.noDelivery,
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Text(
                  'Teslim alınacak yoldaki sevkiyatı seçin',
                  style: AppTypography.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Seçilen sipariş için irsaliye bilgileri ve çap bazlı teslim miktarları girilecektir.',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: 16),
                ...inTransitOrders.map(
                  (order) => _InTransitOrderTile(order: order),
                ),
              ],
            ),
    );
  }
}

class _InTransitOrderTile extends StatelessWidget {
  const _InTransitOrderTile({required this.order});

  final OrderItem order;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('d MMM yyyy').format(order.date);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push(AppRoutes.newDeliveryForOrder(order.id)),
          borderRadius: AppRadii.md,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: AppRadii.md,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Color(order.status.colorValue),
                    borderRadius: AppRadii.xs,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.orderNo, style: AppTypography.titleMedium),
                      const SizedBox(height: 4),
                      Text(dateStr, style: AppTypography.bodySmall),
                      const SizedBox(height: 6),
                      Text(
                        order.imalatTypes.join(' · '),
                        style: AppTypography.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${order.tonnage.toStringAsFixed(0)}t',
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.electricBlueLight,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              order.supplier,
                              textAlign: TextAlign.end,
                              style: AppTypography.labelMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
