import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/sj_card.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_date.dart';
import '../../data/providers/app_data_provider.dart';
import '../../domain/beton_progress.dart';
import '../../domain/entities/concrete_order.dart';
import '../../domain/entities/concrete_pour.dart';

/// Gelen / dökülen beton kayıtları — sipariş seçimi + mikser / pompa.
class DokumScreen extends ConsumerWidget {
  const DokumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(activeProjectProvider);
    final pours = ref.watch(activePoursProvider);
    final orders = ref.watch(activeOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Döküm Kayıtları')),
      floatingActionButton: project == null
          ? null
          : FloatingActionButton.extended(
              onPressed: orders.isEmpty
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Önce Program sekmesinden sipariş ekleyin',
                          ),
                        ),
                      );
                    }
                  : () => _openEditor(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Yeni Döküm'),
            ),
      body: project == null
          ? const SJEmptyState(
              title: 'Proje seçin',
              message: 'Döküm kaydı için aktif bir proje gerekli.',
              icon: Icons.apartment_outlined,
            )
          : pours.isEmpty
              ? SJEmptyState(
                  title: 'Henüz döküm yok',
                  message: orders.isEmpty
                      ? 'Önce Program’dan aktif sipariş oluşturun, '
                          'sonra mikser ve pompa verilerini girin.'
                      : 'Aktif sipariş seçip mikser / pompa verilerini girin.',
                  icon: Icons.local_shipping_outlined,
                  actionLabel: orders.isEmpty ? null : 'Döküm Ekle',
                  onAction: orders.isEmpty
                      ? null
                      : () => _openEditor(context, ref),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    88,
                  ),
                  itemCount: pours.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final p = pours[index];
                    return _PourCard(
                      pour: p,
                      onTap: () => _openEditor(context, ref, existing: p),
                    );
                  },
                ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    ConcretePour? existing,
  }) async {
    final project = ref.read(activeProjectProvider);
    if (project == null) return;

    final orders = List<ConcreteOrder>.from(ref.read(activeOrdersProvider))
      ..sort((a, b) {
        final today = AppDate.format(AppDate.today());
        final aToday = a.plannedDate == today ? 0 : 1;
        final bToday = b.plannedDate == today ? 0 : 1;
        if (aToday != bToday) return aToday.compareTo(bToday);
        return a.plannedDate.compareTo(b.plannedDate);
      });

    if (orders.isEmpty && existing == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aktif sipariş yok — Program’dan sipariş ekleyin'),
        ),
      );
      return;
    }

    ConcreteOrder? selectedOrder;
    if (existing?.orderId != null) {
      for (final o in orders) {
        if (o.id == existing!.orderId) {
          selectedOrder = o;
          break;
        }
      }
    }
    selectedOrder ??= orders.isNotEmpty ? orders.first : null;

    // Düzenlemede sipariş listede yoksa özet için sentetik sipariş
    if (selectedOrder == null && existing != null) {
      selectedOrder = ConcreteOrder(
        id: existing.orderId ?? existing.id,
        projectId: project.id,
        plannedDate: existing.date,
        plannedM3: existing.volumeM3,
        elementName: existing.elementName,
        block: existing.block,
        floor: existing.floor,
        concreteClass: existing.concreteClass,
        supplier: existing.supplier,
      );
    }

    // Dropdown değeri her zaman listedeki bir siparişe bağlansın
    if (orders.isNotEmpty &&
        (selectedOrder == null ||
            !orders.any((o) => o.id == selectedOrder!.id))) {
      selectedOrder = orders.first;
    }

    final volumeCtrl = TextEditingController(
      text: existing == null ? '' : BetonProgress.fmtM3(existing.volumeM3),
    );
    final mixerCountCtrl = TextEditingController(
      text: existing?.mixerCount?.toString() ?? '',
    );
    final mixerPlateCtrl =
        TextEditingController(text: existing?.mixerPlate ?? '');
    final ticketCtrl = TextEditingController(text: existing?.ticketNo ?? '');
    final slumpCtrl = TextEditingController(
      text: existing?.slumpCm == null
          ? ''
          : BetonProgress.fmtM3(existing!.slumpCm!),
    );
    final mixerNoteCtrl =
        TextEditingController(text: existing?.mixerNote ?? '');
    final pumpCountCtrl = TextEditingController(
      text: existing?.pumpCount?.toString() ?? '',
    );
    final pumpTypeCtrl =
        TextEditingController(text: existing?.pumpType ?? '');
    final pumpNoteCtrl = TextEditingController(text: existing?.pumpNote ?? '');

    // Ek döküm hedefi (sipariş dışı)
    final extraElementCtrl =
        TextEditingController(text: existing?.isExtraPour == true
            ? existing!.elementName
            : '');
    final extraBlockCtrl = TextEditingController(
      text: existing?.isExtraPour == true ? existing!.block : '',
    );
    final extraFloorCtrl = TextEditingController(
      text: existing?.isExtraPour == true ? existing!.floor : '',
    );

    var isExtra = existing?.isExtraPour ?? false;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceElevated,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.md,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + AppSpacing.md,
          ),
          child: StatefulBuilder(
            builder: (context, setSheet) {
              final order = selectedOrder;
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      existing == null
                          ? (isExtra ? 'Ek Döküm' : 'Yeni Döküm')
                          : (isExtra
                              ? 'Ek Dökümü Düzenle'
                              : 'Dökümü Düzenle'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (orders.isNotEmpty) ...[
                      DropdownButtonFormField<String>(
                        value: order!.id,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Aktif sipariş',
                        ),
                        items: [
                          for (final o in orders)
                            DropdownMenuItem(
                              value: o.id,
                              child: Text(
                                _orderLabel(o),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (id) {
                          if (id == null) return;
                          setSheet(() {
                            selectedOrder =
                                orders.firstWhere((o) => o.id == id);
                          });
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _OrderSummaryBox(order: order),
                    ] else if (order != null) ...[
                      _OrderSummaryBox(order: order),
                    ] else
                      Text(
                        'Sipariş bulunamadı',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.critical,
                            ),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Ek döküm'),
                      subtitle: const Text(
                        'Beton sipariş dışı bir yere döküldüyse açın',
                      ),
                      value: isExtra,
                      onChanged: (v) => setSheet(() => isExtra = v),
                    ),
                    if (isExtra) ...[
                      TextField(
                        controller: extraElementCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Dökülen yapısal eleman',
                        ),
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      TextField(
                        controller: extraBlockCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Blok',
                          hintText: 'örn. A Blok',
                        ),
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      TextField(
                        controller: extraFloorCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Kat',
                          hintText: 'örn. Bodrum Kat',
                        ),
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Mikser verileri',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: volumeCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Gelen hacim (m³)',
                      ),
                    ),
                    TextField(
                      controller: mixerCountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Mikser adedi',
                      ),
                    ),
                    TextField(
                      controller: mixerPlateCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Plaka',
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                    TextField(
                      controller: ticketCtrl,
                      decoration: const InputDecoration(
                        labelText: 'İrsaliye no',
                      ),
                    ),
                    TextField(
                      controller: slumpCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Çökme (cm)',
                      ),
                    ),
                    TextField(
                      controller: mixerNoteCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Mikser notu',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Pompa verileri',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: pumpCountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Pompa adedi',
                      ),
                    ),
                    TextField(
                      controller: pumpTypeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Pompa tipi',
                        hintText: 'örn. Sabit / Mobil',
                      ),
                    ),
                    TextField(
                      controller: pumpNoteCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Pompa notu',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(
                      onPressed: () {
                        final orderSel = selectedOrder;
                        if (orderSel == null) return;
                        final vol = double.tryParse(
                              volumeCtrl.text.replaceAll(',', '.'),
                            ) ??
                            0;
                        if (vol <= 0) return;

                        final element = isExtra
                            ? extraElementCtrl.text.trim()
                            : orderSel.elementName;
                        final block = isExtra
                            ? extraBlockCtrl.text.trim()
                            : orderSel.block;
                        final floor = isExtra
                            ? extraFloorCtrl.text.trim()
                            : orderSel.floor;

                        if (isExtra && element.isEmpty) return;

                        final draft = ConcretePour(
                          id: existing?.id ?? '',
                          projectId: project.id,
                          date: orderSel.plannedDate,
                          volumeM3: vol,
                          elementName: element,
                          block: block,
                          floor: floor,
                          concreteClass: orderSel.concreteClass,
                          supplier: orderSel.supplier,
                          ticketNo: ticketCtrl.text.trim(),
                          mixerCount: int.tryParse(mixerCountCtrl.text.trim()),
                          mixerPlate: mixerPlateCtrl.text.trim(),
                          mixerNote: mixerNoteCtrl.text.trim(),
                          pumpCount: int.tryParse(pumpCountCtrl.text.trim()),
                          pumpType: pumpTypeCtrl.text.trim(),
                          pumpNote: pumpNoteCtrl.text.trim(),
                          slumpCm: double.tryParse(
                            slumpCtrl.text.trim().replaceAll(',', '.'),
                          ),
                          pourStart: existing?.pourStart ?? DateTime.now(),
                          orderId: orderSel.id,
                          isExtraPour: isExtra,
                        );
                        if (existing == null) {
                          ref.read(poursProvider.notifier).add(draft);
                        } else {
                          ref.read(poursProvider.notifier).update(draft);
                        }
                        Navigator.pop(ctx, true);
                      },
                      child: const Text('Kaydet'),
                    ),
                    if (existing != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      TextButton(
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: ctx,
                            builder: (dCtx) => AlertDialog(
                              title: const Text('Dökümü sil'),
                              content: const Text(
                                'Bu döküm kaydı silinsin mi?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dCtx, false),
                                  child: const Text('Vazgeç'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(dCtx, true),
                                  child: Text(
                                    'Sil',
                                    style: TextStyle(color: AppColors.critical),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (ok != true || !ctx.mounted) return;
                          ref.read(poursProvider.notifier).delete(existing.id);
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
      },
    );

    volumeCtrl.dispose();
    mixerCountCtrl.dispose();
    mixerPlateCtrl.dispose();
    ticketCtrl.dispose();
    slumpCtrl.dispose();
    mixerNoteCtrl.dispose();
    pumpCountCtrl.dispose();
    pumpTypeCtrl.dispose();
    pumpNoteCtrl.dispose();
    extraElementCtrl.dispose();
    extraBlockCtrl.dispose();
    extraFloorCtrl.dispose();

    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isExtra ? 'Ek döküm kaydedildi' : 'Döküm kaydedildi'),
        ),
      );
    }
  }

  static String _orderLabel(ConcreteOrder o) {
    final name = o.elementName.isEmpty ? 'Sipariş' : o.elementName;
    final loc = o.locationSummary;
    final parts = <String>[
      o.plannedDate,
      name,
      if (loc.isNotEmpty) loc,
      '${BetonProgress.fmtM3(o.plannedM3)} m³',
    ];
    return parts.join(' · ');
  }
}

class _OrderSummaryBox extends StatelessWidget {
  const _OrderSummaryBox({required this.order});

  final ConcreteOrder order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = <String>[
      if (order.elementName.isNotEmpty)
        'Yapısal eleman: ${order.elementName}',
      if (order.block.isNotEmpty) 'Blok: ${order.block}',
      if (order.floor.isNotEmpty) 'Kat: ${order.floor}',
      'Sınıf: ${order.concreteClass}',
      if (order.supplier.isNotEmpty) 'Firma: ${order.supplier}',
      'Plan: ${BetonProgress.fmtM3(order.plannedM3)} m³',
      if (order.plannedStartHour.isNotEmpty) 'Saat: ${order.plannedStartHour}',
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sipariş özeti (otomatik)',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.cardTextSecondary,
            ),
          ),
          const SizedBox(height: 4),
          for (final line in rows)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                line,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.cardTextPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PourCard extends StatelessWidget {
  const _PourCard({required this.pour, required this.onTap});

  final ConcretePour pour;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SJCard(
      onTap: onTap,
      accentColor: pour.isExtraPour ? AppColors.warning : AppColors.success,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final mixerBits = <String>[
            if (pour.mixerCount != null) '${pour.mixerCount} mikser',
            if (pour.mixerPlate.isNotEmpty) pour.mixerPlate,
            if (pour.ticketNo.isNotEmpty) 'İrsaliye ${pour.ticketNo}',
          ];
          final pumpBits = <String>[
            if (pour.pumpCount != null) '${pour.pumpCount} pompa',
            if (pour.pumpType.isNotEmpty) pour.pumpType,
            if (pour.pumpNote.isNotEmpty) pour.pumpNote,
          ];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      pour.elementName.isEmpty
                          ? 'Yapısal eleman belirtilmedi'
                          : pour.elementName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.cardTextPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (pour.isExtraPour)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.18),
                        borderRadius: AppRadii.sm,
                      ),
                      child: Text(
                        'Ek döküm',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.18),
                      borderRadius: AppRadii.sm,
                    ),
                    child: Text(
                      '${BetonProgress.fmtM3(pour.volumeM3)} m³',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                [
                  pour.date,
                  pour.concreteClass,
                  if (pour.supplier.isNotEmpty) pour.supplier,
                ].join(' · '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.cardTextSecondary,
                ),
              ),
              if (pour.locationSummary.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    pour.locationSummary,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.cardTextMuted,
                    ),
                  ),
                ),
              if (mixerBits.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Mikser: ${mixerBits.join(' · ')}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.cardTextMuted,
                    ),
                  ),
                ),
              if (pumpBits.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Pompa: ${pumpBits.join(' · ')}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.cardTextMuted,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
