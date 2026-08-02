import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/sj_card.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/santijet_header.dart';
import '../../data/providers/app_data_provider.dart';
import '../../domain/beton_progress.dart';
import '../../domain/entities/concrete_order.dart';
import '../../domain/entities/concrete_pour.dart';
import '../../domain/structural_element_kind.dart';
import 'dokum_editor.dart';

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
                  : () => _open(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Yeni Döküm'),
            ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SantijetHeader(
              subtitle: 'Döküm',
              avatarInitial: 'SJ',
            ),
            Expanded(
              child: project == null
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
                          onAction:
                              orders.isEmpty ? null : () => _open(context, ref),
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
                              plannedM3: _plannedForPour(p, orders),
                              onTap: () => _open(context, ref, existing: p),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bağlı siparişin plan metrajı (yoksa null).
  static double? _plannedForPour(
    ConcretePour pour,
    List<ConcreteOrder> orders,
  ) {
    if (pour.orderId != null && pour.orderId!.isNotEmpty) {
      for (final o in orders) {
        if (o.id == pour.orderId) return o.plannedM3;
      }
    }
    // Eski kayıtlar: tarih + yapısal eleman
    for (final o in orders) {
      if (o.plannedDate != pour.date) continue;
      if (o.elementName.trim().isEmpty) return o.plannedM3;
      if (o.elementName.trim() == pour.elementName.trim()) {
        return o.plannedM3;
      }
    }
    return null;
  }

  Future<void> _open(
    BuildContext context,
    WidgetRef ref, {
    ConcretePour? existing,
  }) async {
    final project = ref.read(activeProjectProvider);
    if (project == null) return;

    final orders = ref.read(activeOrdersProvider);
    if (orders.isEmpty && existing == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aktif sipariş yok — Program’dan sipariş ekleyin'),
        ),
      );
      return;
    }

    final saved = await openDokumEditor(context, ref, existing: existing);
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Döküm kaydedildi')),
      );
    }
  }
}

class _PourCard extends StatelessWidget {
  const _PourCard({
    required this.pour,
    required this.plannedM3,
    required this.onTap,
  });

  final ConcretePour pour;
  final double? plannedM3;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final kind = StructuralElementKind.fromElementName(pour.elementName);
    final accent = pour.isExtraPour ? AppColors.warning : kind.accentColor;
    final poured = pour.volumeM3;
    final plan = plannedM3;
    final gap = plan == null ? null : poured - plan;
    final gapColor = gap == null
        ? AppColors.cardTextMuted
        : gap.abs() < 0.01
            ? AppColors.success
            : gap > 0
                ? AppColors.warning
                : AppColors.critical;

    return SJCard(
      onTap: onTap,
      accentColor: accent,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final mixerCount = pour.mixers.isNotEmpty
              ? pour.mixers.length
              : pour.mixerCount;
          final mixerBits = <String>[
            if (mixerCount != null) '$mixerCount mikser',
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
              if (pour.sampleType != null ||
                  pour.sampleCount != null ||
                  pour.sampleTakenHour.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    [
                      if (pour.sampleType != null)
                        'Numune ${pour.sampleType!.label}',
                      if (pour.sampleCount != null) '${pour.sampleCount} adet',
                      if (pour.sampleTakenHour.isNotEmpty)
                        pour.sampleTakenHour,
                    ].join(' · '),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.cardTextMuted,
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      label: 'Plan',
                      value: plan == null
                          ? '—'
                          : BetonProgress.fmtM3(plan),
                      color: AppColors.info,
                      showUnit: plan != null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _MiniStat(
                      label: 'Dökülen',
                      value: BetonProgress.fmtM3(poured),
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _MiniStat(
                      label: 'Fark',
                      value: gap == null
                          ? '—'
                          : '${gap >= 0 ? '+' : ''}${BetonProgress.fmtM3(gap)}',
                      color: gapColor,
                      showUnit: gap != null,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
    this.showUnit = true,
  });

  final String label;
  final String value;
  final Color color;
  final bool showUnit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadii.sm,
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.cardTextMuted,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (showUnit) ...[
                const SizedBox(width: 2),
                Padding(
                  padding: const EdgeInsets.only(bottom: 1),
                  child: Text(
                    'm³',
                    style: theme.textTheme.labelSmall?.copyWith(color: color),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
