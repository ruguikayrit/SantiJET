import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_info.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../core/design_system/sj_list_item.dart';
import '../../core/design_system/sj_modal.dart';
import '../../core/design_system/sj_status_badge.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_date.dart';
import '../../core/widgets/santijet_header.dart';
import '../../data/providers/app_data_provider.dart';
import '../../domain/entities/concrete_order.dart';

/// Sipariş / irsaliye listesi.
class SiparisScreen extends ConsumerWidget {
  const SiparisScreen({super.key});

  static String _m3(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  Color _statusColor(OrderStatus s) => switch (s) {
        OrderStatus.open => AppColors.warning,
        OrderStatus.partial => AppColors.info,
        OrderStatus.delivered => AppColors.success,
        OrderStatus.cancelled => AppColors.textMuted,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(activeProjectProvider);
    final orders = ref.watch(activeOrdersProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SantijetHeader(
              subtitle: 'Sipariş / İrsaliye',
              avatarInitial: 'SJ',
            ),
            Expanded(
              child: project == null
                  ? const SJEmptyState(
                      title: 'Proje seçin',
                      message: 'Sipariş için aktif bir proje gerekir.',
                      icon: Icons.apartment_outlined,
                    )
                  : orders.isEmpty
                      ? SJEmptyState(
                          title: 'Sipariş yok',
                          message: 'Beton siparişi ve irsaliye kaydı ekleyin.',
                          icon: Icons.receipt_long_outlined,
                          actionLabel: 'Sipariş Ekle',
                          onAction: () => _openEditor(context, ref),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.sm,
                            AppSpacing.md,
                            88,
                          ),
                          itemCount: orders.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            final o = orders[index];
                            final waybill = o.waybillNo.isEmpty
                                ? 'İrsaliye yok'
                                : 'İrs: ${o.waybillNo}';
                            return SJListItem(
                              title: o.supplier.isEmpty
                                  ? 'Tedarikçi yok'
                                  : o.supplier,
                              subtitle:
                                  '${o.orderDate} · ${o.concreteClass} · $waybill\n'
                                  'Sipariş ${_m3(o.orderedM3)} · '
                                  'Teslim ${_m3(o.deliveredM3)} m³',
                              leadingIcon: Icons.receipt_long_outlined,
                              accentColor: _statusColor(o.status),
                              trailing: SJStatusBadge(
                                label: o.status.label,
                                color: _statusColor(o.status),
                              ),
                              onTap: () =>
                                  _openEditor(context, ref, existing: o),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: project == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openEditor(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Sipariş Ekle'),
            ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    ConcreteOrder? existing,
  }) async {
    final project = ref.read(activeProjectProvider);
    if (project == null) return;

    final dateCtrl = TextEditingController(
      text: existing?.orderDate ?? AppDate.format(AppDate.today()),
    );
    final supplierCtrl =
        TextEditingController(text: existing?.supplier ?? '');
    final orderedCtrl = TextEditingController(
      text: existing == null ? '' : _m3(existing.orderedM3),
    );
    final deliveredCtrl = TextEditingController(
      text: existing == null ? '0' : _m3(existing.deliveredM3),
    );
    final waybillCtrl =
        TextEditingController(text: existing?.waybillNo ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    var concreteClass = existing?.concreteClass ?? 'C30/37';
    var status = existing?.status ?? OrderStatus.open;

    final saved = await SJModal.showSheet<bool>(
      context: context,
      title: existing == null ? 'Yeni sipariş' : 'Siparişi düzenle',
      child: StatefulBuilder(
        builder: (ctx, setLocal) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: dateCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Sipariş tarihi (gg.aa.yyyy)',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: supplierCtrl,
                  decoration: const InputDecoration(labelText: 'Tedarikçi'),
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  value: concreteClass,
                  decoration: const InputDecoration(labelText: 'Beton sınıfı'),
                  items: [
                    for (final c in AppInfo.concreteClasses)
                      DropdownMenuItem(value: c, child: Text(c)),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setLocal(() => concreteClass = v);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: orderedCtrl,
                  decoration: const InputDecoration(labelText: 'Sipariş m³'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: deliveredCtrl,
                  decoration: const InputDecoration(labelText: 'Teslim m³'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: waybillCtrl,
                  decoration: const InputDecoration(labelText: 'İrsaliye no'),
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<OrderStatus>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Durum'),
                  items: [
                    for (final s in OrderStatus.values)
                      DropdownMenuItem(value: s, child: Text(s.label)),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setLocal(() => status = v);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(labelText: 'Not'),
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: () {
                    final ordered = double.tryParse(
                      orderedCtrl.text.trim().replaceAll(',', '.'),
                    );
                    if (ordered == null || ordered <= 0) return;
                    Navigator.pop(ctx, true);
                  },
                  child: const Text('Kaydet'),
                ),
                if (existing != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: () async {
                      final ok = await SJModal.confirm(
                        context: ctx,
                        title: 'Siparişi sil',
                        message: 'Bu sipariş kaydı silinsin mi?',
                        confirmLabel: 'Sil',
                        destructive: true,
                      );
                      if (!ok || !ctx.mounted) return;
                      ref.read(ordersProvider.notifier).delete(existing.id);
                      Navigator.pop(ctx, false);
                    },
                    child: Text(
                      'Sil',
                      style: TextStyle(color: AppColors.critical),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );

    if (saved != true) return;
    final ordered =
        double.tryParse(orderedCtrl.text.trim().replaceAll(',', '.')) ?? 0;
    final delivered =
        double.tryParse(deliveredCtrl.text.trim().replaceAll(',', '.')) ?? 0;
    final draft = ConcreteOrder(
      id: existing?.id ?? '',
      projectId: project.id,
      orderDate: dateCtrl.text.trim(),
      supplier: supplierCtrl.text.trim(),
      orderedM3: ordered,
      deliveredM3: delivered,
      waybillNo: waybillCtrl.text.trim(),
      concreteClass: concreteClass,
      status: status,
      notes: notesCtrl.text.trim(),
    );
    if (existing == null) {
      ref.read(ordersProvider.notifier).add(draft);
    } else {
      ref.read(ordersProvider.notifier).update(draft);
    }
  }
}
