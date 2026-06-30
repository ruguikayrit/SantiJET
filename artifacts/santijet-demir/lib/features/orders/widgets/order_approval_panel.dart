import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/domain/entities/order.dart';
import 'package:santijet_demir/domain/enums/app_enums.dart';
import 'package:santijet_demir/features/orders/providers/orders_provider.dart';

class OrderApprovalPanel extends ConsumerWidget {
  const OrderApprovalPanel({super.key, required this.order});

  final OrderItem order;

  Future<void> _approve(
    BuildContext context,
    WidgetRef ref,
    OrderApproverRole role,
  ) async {
    final result =
        await ref.read(ordersProvider.notifier).approveOrderRole(order.id, role);
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    switch (result.type) {
      case OrderApprovalResultType.success:
        if (result.completed) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                '${order.orderNo} onaylandı → ${OrderStatus.submitted.label}',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          messenger.showSnackBar(
            SnackBar(
              content: Text('${role.label} onayı kaydedildi'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      case OrderApprovalResultType.alreadyApproved:
        messenger.showSnackBar(
          SnackBar(content: Text('${role.label} zaten onayladı')),
        );
      case OrderApprovalResultType.notPending:
      case OrderApprovalResultType.notFound:
        messenger.showSnackBar(
          const SnackBar(content: Text('Onay işlemi yapılamadı')),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approvals = order.approvals;
    final dateFormat = DateFormat('d MMM HH:mm');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Onay Süreci', style: AppTypography.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Satın Alma + (Proje Müdürü veya İşveren) onayı ile sipariş verilir.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 12),
          _ApproverRow(
            role: OrderApproverRole.purchasing,
            approved: approvals.purchasing,
            approvedAt: approvals.purchasingAt,
            dateFormat: dateFormat,
            required: true,
            onApprove: () => _approve(context, ref, OrderApproverRole.purchasing),
          ),
          const SizedBox(height: 8),
          _ApproverRow(
            role: OrderApproverRole.projectManager,
            approved: approvals.projectManager,
            approvedAt: approvals.projectManagerAt,
            dateFormat: dateFormat,
            required: false,
            onApprove: () =>
                _approve(context, ref, OrderApproverRole.projectManager),
          ),
          const SizedBox(height: 8),
          _ApproverRow(
            role: OrderApproverRole.employer,
            approved: approvals.employer,
            approvedAt: approvals.employerAt,
            dateFormat: dateFormat,
            required: false,
            onApprove: () => _approve(context, ref, OrderApproverRole.employer),
          ),
          if (approvals.isComplete) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tüm onay koşulları sağlandı',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.success,
                    ),
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

class _ApproverRow extends StatelessWidget {
  const _ApproverRow({
    required this.role,
    required this.approved,
    required this.approvedAt,
    required this.dateFormat,
    required this.required,
    required this.onApprove,
  });

  final OrderApproverRole role;
  final bool approved;
  final DateTime? approvedAt;
  final DateFormat dateFormat;
  final bool required;
  final VoidCallback onApprove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          approved ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 20,
          color: approved ? AppColors.success : AppColors.textMuted,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(role.label, style: AppTypography.titleMedium),
                  if (required) ...[
                    const SizedBox(width: 6),
                    Text(
                      'Zorunlu',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ],
              ),
              if (approved && approvedAt != null)
                Text(
                  dateFormat.format(approvedAt!),
                  style: AppTypography.bodySmall,
                ),
            ],
          ),
        ),
        if (!approved)
          FilledButton.tonal(
            onPressed: onApprove,
            child: const Text('Onayla'),
          )
        else
          Text(
            'Onaylandı',
            style: AppTypography.labelMedium.copyWith(color: AppColors.success),
          ),
      ],
    );
  }
}
