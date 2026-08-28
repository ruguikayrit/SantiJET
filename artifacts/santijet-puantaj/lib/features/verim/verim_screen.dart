import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/sj_card.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/santijet_header.dart';
import '../../data/providers/app_data_provider.dart';
import '../../data/providers/verim_provider.dart';

/// Verim — plan + gerçekleşen tamamen İmalat sekmesinden.
class VerimScreen extends ConsumerWidget {
  const VerimScreen({super.key, this.embedded = false});

  /// Hub içindeyken üst chrome (header) gösterilmez.
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final project = ref.watch(activeProjectProvider);
    final rows = ref.watch(verimRowsProvider);

    if (project == null) {
      final empty = SJEmptyState(
        title: 'Önce proje ekleyin',
        message: 'Verim hesabı aktif projeye bağlıdır.',
        icon: Icons.apartment_outlined,
        actionLabel: 'Projelere Git',
        onAction: () => context.go(AppRoutes.projeler),
      );
      if (embedded) return empty;
      return Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SantijetHeader(subtitle: 'Verim'),
              Expanded(child: empty),
            ],
          ),
        ),
      );
    }

    final body = rows.isEmpty
        ? SJEmptyState(
            title: 'Henüz imalat yok',
            message:
                'Verim, İmalat sekmesindeki planlanan ve gerçekleşen '
                'değerlerden hesaplanır. Önce imalat tanımlayın.',
            icon: Icons.speed_outlined,
            actionLabel: 'İmalat',
            onAction: () => context.go(AppRoutes.imalat),
          )
        : ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xxl,
            ),
            children: [
              Text(
                'İmalat bazlı verim',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Plan ← İmalat (miktar · gün · iş gücü)\n'
                'Gerçek ← günlük imalat kayıtları\n'
                'Birim verim = (gerçek metraj / gerçek AG) ÷ (plan metraj / plan AG)',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              for (final row in rows) ...[
                _VerimRowCard(row: row),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          );

    if (embedded) return body;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SantijetHeader(subtitle: 'Verim'),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class _VerimRowCard extends StatelessWidget {
  const _VerimRowCard({required this.row});

  final VerimRow row;

  @override
  Widget build(BuildContext context) {
    final primary = row.unitEfficiency;
    final color = _pctColor(primary);
    final plannedQty = row.plannedQty;

    return SJCard(
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      row.imalatName,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  if (primary != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: AppRadii.full,
                        border: Border.all(color: color.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        '%${(primary * 100).toStringAsFixed(0)}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              if (row.locationLabel.isNotEmpty ||
                  row.teamName != 'Diğer') ...[
                const SizedBox(height: 4),
                Text(
                  [
                    if (row.teamName != 'Diğer') row.teamName,
                    if (row.locationLabel.isNotEmpty) row.locationLabel,
                  ].join(' · '),
                  style: theme.textTheme.labelSmall,
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              _metric(
                theme,
                label: 'İş gücü',
                planned: _fmt(row.plannedWorkerDays),
                actual: _fmt(row.actualWorkerDays),
                unit: 'adam-gün',
              ),
              if (plannedQty != null) ...[
                const SizedBox(height: AppSpacing.xs),
                _metric(
                  theme,
                  label: 'Miktar',
                  planned: _fmt(plannedQty),
                  actual: _fmt(row.actualQty),
                  unit: row.unit,
                ),
              ] else ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Plan metraj girilmemiş',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.warning,
                  ),
                ),
              ],
              if (primary != null) ...[
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: primary.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: color.withValues(alpha: 0.15),
                    color: color,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _metric(
    ThemeData theme, {
    required String label,
    required String planned,
    required String actual,
    required String unit,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(label, style: theme.textTheme.labelMedium),
        ),
        Expanded(
          child: Text(
            'Plan $planned  ·  Gerçek $actual ${unit.trim()}',
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  static String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  Color _pctColor(double? ratio) {
    if (ratio == null) return AppColors.cardTextMuted;
    if (ratio >= 0.8) return AppColors.success;
    if (ratio >= 0.5) return AppColors.warning;
    return AppColors.critical;
  }
}
