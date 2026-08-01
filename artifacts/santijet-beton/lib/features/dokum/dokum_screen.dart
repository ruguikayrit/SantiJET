import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/sj_card.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/providers/app_data_provider.dart';
import '../../domain/beton_progress.dart';
import '../../domain/entities/concrete_pour.dart';
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
                  : () => _open(context, ref),
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
                      onTap: () => _open(context, ref, existing: p),
                    );
                  },
                ),
    );
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
