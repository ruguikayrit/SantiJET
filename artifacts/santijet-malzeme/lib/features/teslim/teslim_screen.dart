import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/sj_empty_state.dart';
import '../../core/design_system/sj_fab.dart';
import '../../core/design_system/sj_search_bar.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_date.dart';
import '../../core/utils/id_gen.dart';
import '../../core/widgets/santijet_header.dart';
import '../../data/providers/app_data_provider.dart';
import '../../domain/entities/entities.dart';

/// Teslim / Gelen — ŞantiJET Pro RN `malzeme` → Tab Gelen kurgusu.
class TeslimScreen extends ConsumerStatefulWidget {
  const TeslimScreen({super.key});

  @override
  ConsumerState<TeslimScreen> createState() => _TeslimScreenState();
}

class _TeslimScreenState extends ConsumerState<TeslimScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(activeProjectProvider);
    final hasActiveProject = project != null;
    final deliveries = ref.watch(activeDeliveriesProvider);
    final requests = ref.watch(activeRequestsProvider);
    final projects = ref.watch(projectsProvider);

    String projectName(String id) {
      for (final p in projects) {
        if (p.id == id) return p.name;
      }
      return 'Proje';
    }

    MaterialRequest? linkedReq(Delivery d) {
      if (d.materialRequestId == null) return null;
      for (final r in requests) {
        if (r.id == d.materialRequestId) return r;
      }
      return null;
    }

    final q = _searchQuery.trim().toLowerCase();
    final filtered = q.isEmpty
        ? deliveries
        : deliveries
            .where(
              (d) =>
                  d.name.toLowerCase().contains(q) ||
                  d.supplier.toLowerCase().contains(q) ||
                  d.waybillNo.toLowerCase().contains(q) ||
                  d.pozCode.toLowerCase().contains(q),
            )
            .toList();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SantijetHeader(subtitle: 'Teslim'),
          if (hasActiveProject) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: SJSearchBar(
                hint: 'Malzeme, irsaliye, tedarikçi ara...',
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Expanded(
            child: !hasActiveProject
                ? SJEmptyState(
                    title: 'Önce proje ekleyin',
                    message: 'Teslim / gelen malzeme için proje seçin.',
                    icon: Icons.apartment_outlined,
                    actionLabel: 'Projelere Git',
                    onAction: () => context.go(AppRoutes.projeler),
                  )
                : filtered.isEmpty
                    ? SJEmptyState(
                        title: 'Gelen malzeme yok',
                        message:
                            'Şantiyeye teslim alınan malzemeleri buraya ekleyin. '
                            'Talep 3 onay alınca otomatik oluşur.',
                        icon: Icons.download_outlined,
                        actionLabel: 'Taleplere Git',
                        onAction: () => context.go(AppRoutes.talep),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          SJFab.scrollClearanceOf(context),
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final d = filtered[index];
                          return _GelenCard(
                            delivery: d,
                            projectName: projectName(d.projectId),
                            linkedRequest: linkedReq(d),
                            onToggleKantar: () {
                              ref.read(deliveriesProvider.notifier).upsert(
                                    d.copyWith(
                                      kantarEnabled: !d.kantarEnabled,
                                    ),
                                  );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: hasActiveProject
          ? SJFab(
              label: 'Gelen Ekle',
              onPressed: () => _openAddGelen(context),
            )
          : null,
    );
  }

  Future<void> _openAddGelen(BuildContext context) async {
    final project = ref.read(activeProjectProvider);
    if (project == null) return;
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final unitCtrl = TextEditingController(text: 'AD');
    final supplierCtrl = TextEditingController();
    final irsCtrl = TextEditingController();

    final ok = await showModalBottomSheet<bool>(
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Gelen Malzeme Ekle',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Malzeme'),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: qtyCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(labelText: 'Miktar'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: unitCtrl,
                        decoration: const InputDecoration(labelText: 'Birim'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: supplierCtrl,
                  decoration: const InputDecoration(labelText: 'Tedarikçi'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: irsCtrl,
                  decoration: const InputDecoration(labelText: 'İrsaliye No'),
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    Navigator.pop(ctx, true);
                  },
                  child: const Text('Kaydet'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (ok != true) return;
    final qty = double.tryParse(qtyCtrl.text.replaceAll(',', '.')) ?? 0;
    ref.read(deliveriesProvider.notifier).upsert(
          Delivery(
            id: IdGen.make('dlv'),
            projectId: project.id,
            name: nameCtrl.text.trim(),
            unit: unitCtrl.text.trim(),
            quantity: qty,
            irsaliyeQty: qty,
            date: DateTime.now(),
            supplier: supplierCtrl.text.trim(),
            waybillNo: irsCtrl.text.trim(),
          ),
        );
  }
}

class _GelenCard extends StatelessWidget {
  const _GelenCard({
    required this.delivery,
    required this.projectName,
    required this.linkedRequest,
    required this.onToggleKantar,
  });

  final Delivery delivery;
  final String projectName;
  final MaterialRequest? linkedRequest;
  final VoidCallback onToggleKantar;

  @override
  Widget build(BuildContext context) {
    final meta = <String>[
      AppDate.format(delivery.date),
      if (delivery.supplier.isNotEmpty) delivery.supplier,
      if (delivery.pozCode.isNotEmpty) 'Poz: ${delivery.pozCode}',
      if (delivery.waybillNo.isNotEmpty) 'İrs: ${delivery.waybillNo}',
      if (delivery.invoiceNo.isNotEmpty) 'Fat: ${delivery.invoiceNo}',
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppColors.cardElevation,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  projectName,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.electricBlueLight,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        delivery.name,
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.cardTextPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (delivery.fromRequest)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.electricBlue,
                          borderRadius: AppRadii.full,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.assignment_outlined,
                              size: 10,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Talepten Gelen',
                              style: AppTypography.labelSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (delivery.category.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    delivery.category,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.cardTextMuted,
                    ),
                  ),
                ],
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    meta.join(' · '),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.cardTextMuted,
                    ),
                    maxLines: 2,
                  ),
                ],
                const SizedBox(height: 8),
                _ApprChip(
                  label: 'Kantar İzni',
                  checked: delivery.kantarEnabled,
                  color: const Color(0xFFF59E0B),
                  onTap: onToggleKantar,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (linkedRequest != null || delivery.irsaliyeQty != null) ...[
                if (linkedRequest != null)
                  _QtyLine(
                    label: 'Talep edilen',
                    value:
                        '${_fmt(linkedRequest!.quantity)} ${linkedRequest!.unit}',
                  ),
                if (delivery.irsaliyeQty != null)
                  _QtyLine(
                    label: 'İrsaliye',
                    value: '${_fmt(delivery.irsaliyeQty!)} ${delivery.unit}',
                    color: const Color(0xFF0EA5E9),
                  ),
              ] else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardInsetSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _fmt(delivery.quantity),
                        style: AppTypography.cardTitleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        delivery.unit,
                        style: AppTypography.cardLabelSmall,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }
}

class _QtyLine extends StatelessWidget {
  const _QtyLine({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.cardTextMuted,
            ),
          ),
          Text(
            value,
            style: AppTypography.labelLarge.copyWith(
              color: color ?? AppColors.cardTextPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ApprChip extends StatelessWidget {
  const _ApprChip({
    required this.label,
    required this.checked,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool checked;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: checked ? color : AppColors.cardBorder,
          ),
          color: checked ? color.withValues(alpha: 0.1) : Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: checked ? color : AppColors.cardTextMuted,
                  width: 1.5,
                ),
                color: checked ? color : Colors.transparent,
              ),
              child: checked
                  ? const Icon(Icons.check, size: 10, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: checked ? color : AppColors.cardTextMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
