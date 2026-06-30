import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/app_components.dart';
import 'package:santijet_demir/domain/entities/order.dart';
import 'package:santijet_demir/domain/enums/app_enums.dart';
import 'package:santijet_demir/features/orders/providers/orders_provider.dart';
import 'package:santijet_demir/features/orders/widgets/order_approval_panel.dart';
import 'package:santijet_demir/features/orders/widgets/order_cancel_dialog.dart';

class OrderCard extends ConsumerWidget {
  const OrderCard({super.key, required this.order});

  final OrderItem order;

  Future<void> _advanceStatus(BuildContext context, WidgetRef ref) async {
    if (order.status == OrderStatus.inTransit) {
      context.go(AppRoutes.newDeliveryForOrder(order.id));
      return;
    }

    final next = order.status.nextStatus;
    if (next == null) return;

    await ref.read(ordersProvider.notifier).advanceStatus(order.id);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${order.orderNo} → ${next.label}'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _cancelOrder(BuildContext context, WidgetRef ref) async {
    final input = await showOrderCancelDialog(context, order: order);
    if (input == null || !context.mounted) return;

    final result = await ref.read(ordersProvider.notifier).cancelOrder(
          orderId: order.id,
          cancelledByName: input.cancelledByName,
          cancellationReason: input.cancellationReason,
        );
    if (!context.mounted) return;

    final message = switch (result) {
      OrderCancelResult.success => '${order.orderNo} iptal edildi',
      OrderCancelResult.notCancellable =>
        'Bu sipariş iptal edilemez (yalnızca Verildi durumundaki siparişler)',
      OrderCancelResult.invalidInput => 'Ad soyad ve iptal nedeni zorunludur',
      OrderCancelResult.notFound => 'Sipariş bulunamadı',
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: result == OrderCancelResult.success
            ? AppColors.warning
            : AppColors.critical,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = Color(order.status.colorValue);
    final dateStr = DateFormat('d MMM yyyy').format(order.date);
    final actionLabel = order.status.actionLabel;
    final showApprovalPanel = order.status == OrderStatus.pendingApproval;
    final showCancelButton = order.status.canCancel;
    final cancellation = order.cancellation;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
                      Expanded(
                        child: Text(order.orderNo, style: AppTypography.titleMedium),
                      ),
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
                      Flexible(
                        child: Text(
                          order.supplier,
                          textAlign: TextAlign.end,
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.electricBlueLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (cancellation != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.critical.withValues(alpha: 0.08),
                        borderRadius: AppRadii.sm,
                        border: Border.all(
                          color: AppColors.critical.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'İptal Eden: ${cancellation.cancelledByName}',
                            style: AppTypography.labelMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Neden: ${cancellation.cancellationReason}',
                            style: AppTypography.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('d MMM yyyy HH:mm')
                                .format(cancellation.cancelledAt),
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (showApprovalPanel) ...[
                    const SizedBox(height: 14),
                    OrderApprovalPanel(order: order),
                  ],
                  if (actionLabel.isNotEmpty || showCancelButton) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (actionLabel.isNotEmpty)
                            FilledButton(
                              onPressed: () => _advanceStatus(context, ref),
                              child: Text(actionLabel),
                            ),
                          if (showCancelButton) ...[
                            if (actionLabel.isNotEmpty) const SizedBox(height: 8),
                            OutlinedButton(
                              onPressed: () => _cancelOrder(context, ref),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.critical,
                                side: const BorderSide(color: AppColors.critical),
                              ),
                              child: const Text('İptal'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
