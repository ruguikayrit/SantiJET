import 'package:flutter/material.dart';
import 'package:santijet_demir/core/widgets/app_toast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:santijet_demir/core/format/app_format.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/domain/entities/order.dart';
import 'package:santijet_demir/domain/enums/app_enums.dart';
import 'package:santijet_demir/features/orders/order_diameter_amounts.dart';
import 'package:santijet_demir/features/orders/providers/orders_provider.dart';
import 'package:santijet_demir/features/orders/widgets/order_cancel_dialog.dart';
import 'package:santijet_demir/features/survey/providers/survey_provider.dart';

class _DiameterAmountDialog extends StatefulWidget {
  const _DiameterAmountDialog({
    required this.diameter,
    required this.initial,
  });

  final int diameter;
  final String initial;

  @override
  State<_DiameterAmountDialog> createState() => _DiameterAmountDialogState();
}

class _DiameterAmountDialogState extends State<_DiameterAmountDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double? _parsed() {
    final parsed = double.tryParse(_controller.text.trim().replaceAll(',', '.'));
    if (parsed == null || parsed < 0) return null;
    return parsed;
  }

  void _save() {
    final parsed = _parsed();
    if (parsed == null) return;
    Navigator.pop(context, parsed);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceElevated,
      title: Text('Ø${widget.diameter}', style: AppTypography.titleLarge),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Sipariş',
        ),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}

class OrderCard extends ConsumerWidget {
  const OrderCard({super.key, required this.order});

  final OrderItem order;

  void _deliver(BuildContext context) {
    context.push(AppRoutes.newDeliveryForOrder(order.id));
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
        'Tamamlanan sipariş iptal edilemez',
      OrderCancelResult.invalidInput => 'Ad soyad ve iptal nedeni zorunludur',
      OrderCancelResult.notFound => 'Sipariş bulunamadı',
    };

    ScaffoldMessenger.of(context).showAppSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: result == OrderCancelResult.success
            ? AppColors.warning
            : AppColors.critical,
      ),
    );
  }

  Future<void> _reviseDiameter(
    BuildContext context,
    WidgetRef ref,
    Map<int, double> amounts,
    int diameter,
  ) async {
    if (order.status == OrderStatus.cancelled) return;
    final current = amounts[diameter] ?? 0;
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => _DiameterAmountDialog(
        diameter: diameter,
        initial: current == 0 ? '' : current.toStringAsFixed(2),
      ),
    );
    if (result == null || !context.mounted) return;

    await ref.read(ordersProvider.notifier).updateDiameterAmount(
          orderId: order.id,
          diameter: diameter,
          amount: result,
          baseAmounts: amounts,
        );
  }

  Future<void> _openDiameters(
    BuildContext context,
    WidgetRef ref,
    Map<int, double> amounts,
  ) async {
    if (amounts.isEmpty) {
      ScaffoldMessenger.of(context).showAppSnackBar(
        const SnackBar(content: Text('Bu siparişte çap verisi yok')),
      );
      return;
    }

    final diameters = amounts.keys.toList()..sort();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Text(
                    '${order.orderNo} · Çaplar',
                    style: AppTypography.titleLarge,
                  ),
                ),
                for (final diameter in diameters)
                  ListTile(
                    leading: Icon(
                      Icons.circle,
                      size: 12,
                      color: AppColors.diameterColor(diameter),
                    ),
                    title: Text('Ø$diameter'),
                    trailing: Text(
                      '${AppFormat.tonnage(amounts[diameter] ?? 0)}t',
                      style: AppTypography.titleMedium,
                    ),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      await _reviseDiameter(context, ref, amounts, diameter);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateStr = DateFormat('dd.MM.yyyy').format(order.date);
    final showDeliver = order.status.canDeliver;
    final showCancel = order.status.canCancel;
    final cancellation = order.cancellation;
    final imalat = order.imalatTypes.join(' · ');
    final survey = ref.watch(surveyProjectProvider);
    final amounts = resolvedOrderDiameterAmounts(order, survey.imalats);
    final diameters = amounts.keys.toList()..sort();
    final shownTonnage = amounts.isEmpty
        ? order.tonnage
        : amounts.values.fold(0.0, (sum, value) => sum + value);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppColors.cardElevation,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () => _openDiameters(context, ref, amounts),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          order.orderNo,
                          style: AppTypography.titleLarge.copyWith(
                            color: AppColors.cardTextPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dateStr,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.cardTextMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (imalat.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      imalat,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.cardTextMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Toplam',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.cardTextMuted,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        AppFormat.tonnage(shownTonnage),
                        style: AppTypography.titleLarge.copyWith(
                          color: AppColors.cardTextPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (diameters.isNotEmpty) ...[
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  const gap = 8.0;
                  final columns = constraints.maxWidth >= 340 ? 3 : 2;
                  final width =
                      (constraints.maxWidth - gap * (columns - 1)) / columns;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final diameter in diameters)
                        SizedBox(
                          width: width,
                          child: Material(
                            color: AppColors.cardTextPrimary.withValues(
                              alpha: 0.04,
                            ),
                            borderRadius: AppRadii.sm,
                            child: InkWell(
                              borderRadius: AppRadii.sm,
                              onTap: () => _reviseDiameter(
                                context,
                                ref,
                                amounts,
                                diameter,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: AppRadii.sm,
                                  border: Border.all(
                                    color: AppColors.cardBorder,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      'Ø$diameter',
                                      style: AppTypography.labelMedium.copyWith(
                                        color: AppColors.diameterColor(
                                          diameter,
                                        ),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${AppFormat.tonnage(amounts[diameter] ?? 0)} t',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.cardTextPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
            if (cancellation != null) ...[
              const SizedBox(height: 8),
              Text(
                'İptal: ${cancellation.cancellationReason}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.critical,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (showDeliver || showCancel)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (showDeliver)
                    TextButton(
                      onPressed: () => _deliver(context),
                      child: const Text('Teslim'),
                    ),
                  if (showCancel)
                    TextButton(
                      onPressed: () => _cancelOrder(context, ref),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.critical,
                      ),
                      child: const Text('İptal'),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
