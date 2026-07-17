import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/app_toast.dart';
import 'package:santijet_demir/domain/entities/order.dart';
import 'package:santijet_demir/domain/enums/app_enums.dart';
import 'package:santijet_demir/features/auth/providers/membership_permission_provider.dart';
import 'package:santijet_demir/features/orders/providers/orders_provider.dart';
import 'package:santijet_demir/features/settings/providers/profile_provider.dart';

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
          messenger.showAppSnackBar(
            SnackBar(
              content: Text(
                '${order.orderNo} onaylandı → ${OrderStatus.submitted.label}',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          messenger.showAppSnackBar(
            SnackBar(
              content: Text('${role.label} onayı kaydedildi'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      case OrderApprovalResultType.alreadyApproved:
        messenger.showAppSnackBar(
          SnackBar(content: Text('${role.label} zaten onayladı')),
        );
      case OrderApprovalResultType.notPending:
      case OrderApprovalResultType.notFound:
        messenger.showAppSnackBar(
          const SnackBar(content: Text('Onay işlemi yapılamadı')),
        );
    }
  }

  Future<void> _reject(
    BuildContext context,
    WidgetRef ref,
    OrderApproverRole role,
  ) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => _RejectReasonDialog(
        orderNo: order.orderNo,
        roleLabel: role.label,
      ),
    );
    if (reason == null || !context.mounted) return;

    final name = ref.read(profileDisplayNameProvider);
    final result = await ref.read(ordersProvider.notifier).rejectOrderRole(
          orderId: order.id,
          role: role,
          rejectedByName: name,
          rejectionReason: reason,
        );
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    switch (result) {
      case OrderRejectResult.success:
        messenger.showAppSnackBar(
          SnackBar(
            content: Text(
              '${order.orderNo} reddedildi (${role.label}) → iptal',
            ),
            backgroundColor: AppColors.critical,
          ),
        );
      case OrderRejectResult.invalidInput:
        messenger.showAppSnackBar(
          const SnackBar(content: Text('Red için açıklama zorunludur')),
        );
      case OrderRejectResult.notAllowed:
        messenger.showAppSnackBar(
          const SnackBar(content: Text('Bu rol için red yetkiniz yok')),
        );
      case OrderRejectResult.notPending:
      case OrderRejectResult.notFound:
        messenger.showAppSnackBar(
          const SnackBar(content: Text('Red işlemi yapılamadı')),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approvals = order.approvals;
    final dateFormat = DateFormat('d MMM HH:mm');
    final permissions = ref.watch(userPermissionsProvider);

    if (order.status == OrderStatus.cancelled) {
      final cancellation = order.cancellation;
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.critical.withValues(alpha: 0.08),
          borderRadius: AppRadii.md,
          border: Border.all(
            color: AppColors.critical.withValues(alpha: 0.35),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sipariş reddedildi / iptal', style: AppTypography.titleMedium),
            if (cancellation != null) ...[
              const SizedBox(height: 8),
              if (cancellation.rejectedByRole != null)
                Text(
                  'Red: ${cancellation.rejectedByRole!.label}',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.critical,
                  ),
                ),
              Text(
                'Açıklama: ${cancellation.cancellationReason}',
                style: AppTypography.bodySmall,
              ),
              Text(
                '${cancellation.cancelledByName} · '
                '${dateFormat.format(cancellation.cancelledAt)}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
      );
    }

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
            'Satın Alma onayı zorunludur. Ek olarak Proje Müdürü veya İşveren '
            'onayından biri yeterlidir. Herhangi bir rolün Red işlemi siparişi '
            'iptal eder; red için açıklama zorunludur.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 12),
          _ApproverRow(
            role: OrderApproverRole.purchasing,
            approved: approvals.purchasing,
            approvedAt: approvals.purchasingAt,
            dateFormat: dateFormat,
            required: true,
            canAct: userCanApproveOrderRole(
              permissions,
              OrderApproverRole.purchasing,
            ),
            onApprove: () =>
                _approve(context, ref, OrderApproverRole.purchasing),
            onReject: () => _reject(context, ref, OrderApproverRole.purchasing),
          ),
          const SizedBox(height: 8),
          _ApproverRow(
            role: OrderApproverRole.projectManager,
            approved: approvals.projectManager,
            approvedAt: approvals.projectManagerAt,
            dateFormat: dateFormat,
            required: false,
            canAct: userCanApproveOrderRole(
              permissions,
              OrderApproverRole.projectManager,
            ),
            onApprove: () =>
                _approve(context, ref, OrderApproverRole.projectManager),
            onReject: () =>
                _reject(context, ref, OrderApproverRole.projectManager),
          ),
          const SizedBox(height: 8),
          _ApproverRow(
            role: OrderApproverRole.employer,
            approved: approvals.employer,
            approvedAt: approvals.employerAt,
            dateFormat: dateFormat,
            required: false,
            canAct: userCanApproveOrderRole(
              permissions,
              OrderApproverRole.employer,
            ),
            onApprove: () => _approve(context, ref, OrderApproverRole.employer),
            onReject: () => _reject(context, ref, OrderApproverRole.employer),
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
    required this.canAct,
    required this.onApprove,
    required this.onReject,
  });

  final OrderApproverRole role;
  final bool approved;
  final DateTime? approvedAt;
  final DateFormat dateFormat;
  final bool required;
  final bool canAct;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
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
                  Flexible(
                    child: Text(role.label, style: AppTypography.titleMedium),
                  ),
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
                )
              else if (!approved && !canAct)
                Text(
                  'Bu onay sizin rolünüze ait değil',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
        ),
        if (!approved && canAct)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton.tonal(
                onPressed: onApprove,
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text('Onay'),
              ),
              const SizedBox(width: 6),
              OutlinedButton(
                onPressed: onReject,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.critical,
                  side: const BorderSide(color: AppColors.critical),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text('Red'),
              ),
            ],
          )
        else if (approved)
          Text(
            'Onaylandı',
            style: AppTypography.labelMedium.copyWith(color: AppColors.success),
          ),
      ],
    );
  }
}

class _RejectReasonDialog extends StatefulWidget {
  const _RejectReasonDialog({
    required this.orderNo,
    required this.roleLabel,
  });

  final String orderNo;
  final String roleLabel;

  @override
  State<_RejectReasonDialog> createState() => _RejectReasonDialogState();
}

class _RejectReasonDialogState extends State<_RejectReasonDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, _controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceElevated,
      title: Text('Siparişi Reddet', style: AppTypography.titleLarge),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${widget.orderNo} — ${widget.roleLabel} olarak red. '
              'Sipariş iptal edilecek.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller,
              autofocus: true,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Açıklama (zorunlu)',
                hintText: 'Red sebebini yazın',
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Sebepsiz red kabul edilmez';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(backgroundColor: AppColors.critical),
          child: const Text('Reddet'),
        ),
      ],
    );
  }
}
