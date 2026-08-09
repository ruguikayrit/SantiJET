import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/sj_card.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_date.dart';
import '../../core/widgets/santijet_header.dart';
import '../../data/providers/app_data_provider.dart';
import '../../domain/entities/entities.dart';
import '../projects/widgets/project_switcher.dart';

/// Teslim alma — irsaliye kayıtları + talep karşılama progress.
class TeslimScreen extends ConsumerWidget {
  const TeslimScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(activeProjectProvider);
    final deliveries = ref.watch(activeDeliveriesProvider);
    final requests = ref.watch(activeRequestsProvider);

    if (project == null) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const SantijetHeader(subtitle: 'Teslim'),
              Expanded(
                child: SJEmptyState(
                  title: 'Proje yok',
                  message: 'Teslim kaydı için proje seçin.',
                  icon: Icons.local_shipping_outlined,
                  actionLabel: 'Projeler',
                  onAction: () => context.go(AppRoutes.projeler),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final fulfillment = _fulfillmentRows(requests, deliveries);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: SantijetHeader(subtitle: 'Teslim'),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: ProjectSwitcher(),
              ),
            ),
            if (fulfillment.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text(
                      'Karşılama',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    for (final row in fulfillment)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: SJCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                row.label,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                '${_fmt(row.delivered)} / ${_fmt(row.requested)} ${row.birim}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              ClipRRect(
                                borderRadius: AppRadii.sm,
                                child: LinearProgressIndicator(
                                  value: row.progress,
                                  minHeight: 6,
                                  backgroundColor: AppColors.border,
                                  color: row.progress >= 1
                                      ? AppColors.success
                                      : AppColors.electricBlueLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ]),
                ),
              ),
            if (deliveries.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: SJEmptyState(
                  title: 'Teslim kaydı yok',
                  message:
                      'İrsaliye ile teslim alma; satırları talep veya keşif pozuna bağlayın.',
                  icon: Icons.inventory_2_outlined,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.xxl,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final d = deliveries[index];
                      return Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: SJCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                d.irsaliyeNo.isEmpty
                                    ? 'Teslim'
                                    : 'İrsaliye ${d.irsaliyeNo}',
                                style: AppTypography.titleMedium.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${AppDate.format(d.date)}'
                                '${d.supplierName.isEmpty ? '' : ' · ${d.supplierName}'}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              for (final line in d.lines)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.xs,
                                  ),
                                  child: Text(
                                    '${line.pozNo.isEmpty ? '' : '${line.pozNo} · '}'
                                    '${line.materialName}: '
                                    '${_fmt(line.quantity)} ${line.birim}',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: deliveries.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static List<_FulfillmentRow> _fulfillmentRows(
    List<MaterialRequest> requests,
    List<Delivery> deliveries,
  ) {
    final deliveredByLine = <String, double>{};
    for (final d in deliveries) {
      for (final line in d.lines) {
        final key = line.requestLineId ?? line.pozNo;
        if (key.isEmpty) continue;
        deliveredByLine[key] = (deliveredByLine[key] ?? 0) + line.quantity;
      }
    }

    final rows = <_FulfillmentRow>[];
    for (final req in requests) {
      for (final line in req.lines) {
        final delivered = deliveredByLine[line.id] ??
            deliveredByLine[line.pozNo] ??
            0;
        rows.add(
          _FulfillmentRow(
            label: line.materialName,
            birim: line.birim,
            requested: line.miktar,
            delivered: delivered,
          ),
        );
      }
    }
    return rows.take(8).toList();
  }

  static String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }
}

class _FulfillmentRow {
  const _FulfillmentRow({
    required this.label,
    required this.birim,
    required this.requested,
    required this.delivered,
  });

  final String label;
  final String birim;
  final double requested;
  final double delivered;

  double get progress {
    if (requested <= 0) return 0;
    return (delivered / requested).clamp(0.0, 1.0);
  }
}
