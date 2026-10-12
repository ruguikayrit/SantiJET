import 'package:flutter/material.dart';
import 'package:santijet_demir/core/widgets/app_toast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:santijet_demir/core/format/app_format.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/domain/entities/order.dart';
import 'package:santijet_demir/domain/enums/app_enums.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:santijet_demir/features/incoming_rebar/providers/incoming_rebar_provider.dart';
import 'package:santijet_demir/features/orders/order_diameter_amounts.dart';
import 'package:santijet_demir/features/orders/providers/orders_provider.dart';
import 'package:santijet_demir/features/orders/widgets/order_cancel_dialog.dart';
import 'package:santijet_demir/features/shell/widgets/home_dashboard.dart';
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
                      '${AppFormat.tonnage(amounts[diameter] ?? 0)}',
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
    final deliveries = ref.watch(deliveriesProvider).where((delivery) {
      return delivery.orderId == order.id ||
          (delivery.orderNo.isNotEmpty && delivery.orderNo == order.orderNo);
    }).toList();
    final delivered = order.status == OrderStatus.cancelled
        ? 0.0
        : deliveries.fold(0.0, (sum, delivery) => sum + delivery.tonnage);
    final remaining = order.status == OrderStatus.cancelled
        ? 0.0
        : (shownTonnage - delivered).clamp(0.0, double.infinity);
    final lastDelivery = deliveries.isEmpty
        ? null
        : deliveries.map((delivery) => delivery.date).reduce(
              (a, b) => a.isAfter(b) ? a : b,
            );
    final visual = orderVisual(order, delivered, shownTonnage);
    final subtitle = [
      if (imalat.isNotEmpty) imalat,
      if (order.supplier.trim().isNotEmpty) order.supplier.trim(),
    ].join(' · ');
    final footer = visual == OrderVisual.cancelled
        ? '${deliveries.length} sevkiyat · $dateStr tarihinde iptal edildi'
        : lastDelivery == null
            ? '${deliveries.length} sevkiyat'
            : '${deliveries.length} sevkiyat · Son teslim: ${DateFormat('dd.MM.yyyy').format(lastDelivery)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x120F2744), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ColoredBox(color: visual.color, child: const SizedBox(width: 4)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        order.orderNo,
                        softWrap: true,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF0F2744),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _StatusPill(visual: visual),
                          const SizedBox(width: 8),
                          Text(
                            dateStr,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF8B97A8),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          _OrderMenu(
                            showDeliver: showDeliver,
                            showCancel: showCancel,
                            onDeliver: () => _deliver(context),
                            onCancel: () => _cancelOrder(context, ref),
                            onDiameters: () => _openDiameters(context, ref, amounts),
                          ),
                        ],
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          softWrap: true,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF64748B),
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      _OrderKpiBand(
                        total: shownTonnage,
                        delivered: delivered,
                        remaining: remaining.toDouble(),
                      ),
                      if (diameters.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            for (final diameter in diameters)
                              OrderDiameterKpiChip(
                                diameter: diameter,
                                tons: amounts[diameter] ?? 0,
                                onTap: () => _reviseDiameter(context, ref, amounts, diameter),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.local_shipping_outlined, size: 16, color: Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              footer,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 12),
                            ),
                          ),
                          if (cancellation != null)
                            const SizedBox.shrink()
                          else
                            const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () => _openDiameters(context, ref, amounts),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF2563EB),
                              side: const BorderSide(color: Color(0xFFBFDBFE)),
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                              minimumSize: const Size(0, 32),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Detay'),
                                Icon(Icons.chevron_right_rounded, size: 18),
                              ],
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

enum OrderVisual {
  pending(Color(0xFFF59E0B), 'Bekleyen', Icons.schedule_rounded),
  partial(Color(0xFF3B82F6), 'Kısmi Teslimat', Icons.local_shipping_outlined),
  done(Color(0xFF16A34A), 'Tamamlandı', Icons.check_circle_outline),
  cancelled(Color(0xFFEF4444), 'İptal Edildi', Icons.cancel_outlined);

  const OrderVisual(this.color, this.label, this.icon);
  final Color color;
  final String label;
  final IconData icon;
}

OrderVisual orderVisual(OrderItem order, double delivered, double ordered) {
  if (order.status == OrderStatus.cancelled) return OrderVisual.cancelled;
  if (order.status == OrderStatus.completed ||
      (ordered > 0.05 && delivered >= ordered - 0.05)) {
    return OrderVisual.done;
  }
  if (delivered > 0.05) return OrderVisual.partial;
  return OrderVisual.pending;
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.visual});

  final OrderVisual visual;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: visual.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(visual.icon, size: 13, color: visual.color),
          const SizedBox(width: 4),
          Text(
            visual.label,
            style: GoogleFonts.inter(
              color: visual.color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderKpiBand extends StatelessWidget {
  const _OrderKpiBand({
    required this.total,
    required this.delivered,
    required this.remaining,
  });

  final double total;
  final double delivered;
  final double remaining;

  @override
  Widget build(BuildContext context) {
    final cells = [
      _KpiCell(
        label: 'Toplam',
        value: AppFormat.tonnage(total),
        valueColor: const Color(0xFF0F2744),
      ),
      _KpiCell(
        label: 'Teslim',
        value: AppFormat.tonnage(delivered),
        valueColor: const Color(0xFF16A34A),
      ),
      _KpiCell(
        label: 'Kalan',
        value: AppFormat.tonnage(remaining),
        valueColor: remaining > 0.05
            ? const Color(0xFFF59E0B)
            : const Color(0xFF8B97A8),
      ),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < cells.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(child: cells[i]),
        ],
      ],
    );
  }
}

class _KpiCell extends StatelessWidget {
  const _KpiCell({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8EDF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            softWrap: true,
            style: GoogleFonts.inter(
              color: const Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            softWrap: false,
            style: GoogleFonts.inter(
              color: valueColor,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sipariş kartı ve saha sayım KPI’larında ortak çap rozeti.
class OrderDiameterKpiChip extends StatelessWidget {
  const OrderDiameterKpiChip({
    super.key,
    required this.diameter,
    required this.tons,
    this.onTap,
  });

  final int diameter;
  final double tons;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = HomeDashboard.diameterDot(diameter);
    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            'Ø$diameter',
            style: GoogleFonts.inter(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            AppFormat.tonnage(tons),
            style: GoogleFonts.inter(
              color: const Color(0xFF0F2744),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(99),
      child: onTap == null
          ? child
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(99),
              child: child,
            ),
    );
  }
}

class _OrderMenu extends StatelessWidget {
  const _OrderMenu({
    required this.showDeliver,
    required this.showCancel,
    required this.onDeliver,
    required this.onCancel,
    required this.onDiameters,
  });

  final bool showDeliver;
  final bool showCancel;
  final VoidCallback onDeliver;
  final VoidCallback onCancel;
  final VoidCallback onDiameters;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 18, color: Color(0xFF94A3B8)),
      padding: EdgeInsets.zero,
      onSelected: (value) {
        switch (value) {
          case 'deliver':
            onDeliver();
          case 'cancel':
            onCancel();
          case 'diameters':
            onDiameters();
        }
      },
      itemBuilder: (context) => [
        if (showDeliver)
          const PopupMenuItem(value: 'deliver', child: Text('Teslim al')),
        const PopupMenuItem(value: 'diameters', child: Text('Çaplar')),
        if (showCancel)
          const PopupMenuItem(value: 'cancel', child: Text('İptal et')),
      ],
    );
  }
}
