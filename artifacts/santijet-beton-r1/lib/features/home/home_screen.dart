import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/sj_empty_state.dart';
import '../../core/design_system/sj_list_item.dart';
import '../../core/design_system/sj_stat_card.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/santijet_header.dart';
import '../../data/providers/app_data_provider.dart';
import '../projects/widgets/project_switcher.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static String m3(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(activeProjectProvider);
    final summary = ref.watch(dashboardSummaryProvider);
    final plans = ref.watch(activePourPlansProvider);
    final pours = ref.watch(activePourRecordsProvider);

    if (project == null) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const SantijetHeader(showWordmark: true, avatarInitial: 'R1'),
              const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: ProjectSwitcher(),
              ),
              Expanded(
                child: SJEmptyState(
                  title: 'Önce proje ekleyin',
                  message: 'BETON R1 kayıtları proje kapsamında tutulur.',
                  icon: Icons.apartment_outlined,
                  actionLabel: 'Projelere Git',
                  onAction: () => context.go(AppRoutes.projeler),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          children: [
            const SantijetHeader(showWordmark: true, avatarInitial: 'R1'),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: ProjectSwitcher(),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bugün', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Row(children: [
                    Expanded(
                      child: SJStatCard(
                        label: 'Planlanan',
                        value: m3(summary.todayPlannedM3),
                        unit: 'm³',
                        accentColor: AppColors.info,
                        onTap: () => context.go(AppRoutes.plan),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: SJStatCard(
                        label: 'Dökülen',
                        value: m3(summary.todayPouredM3),
                        unit: 'm³',
                        onTap: () => context.go(AppRoutes.dokum),
                      ),
                    ),
                  ]),
                  const SizedBox(height: AppSpacing.sm),
                  Row(children: [
                    Expanded(
                      child: SJStatCard(
                        label: 'Açık sipariş',
                        value: '${summary.openOrders}',
                        accentColor: AppColors.warning,
                        onTap: () => context.go(AppRoutes.siparis),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: SJStatCard(
                        label: 'Bekleyen numune',
                        value: '${summary.pendingSamples}',
                        accentColor: AppColors.partial,
                        onTap: () => context.go(AppRoutes.kalite),
                      ),
                    ),
                  ]),
                  const SizedBox(height: AppSpacing.xl),
                  Text('Son planlar', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
                  if (plans.isEmpty)
                    Text('Henüz plan yok.', style: Theme.of(context).textTheme.bodyMedium)
                  else
                    ...plans.take(3).map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: SJListItem(
                            title: p.location.isEmpty ? 'Lokasyon yok' : p.location,
                            subtitle: '${p.date} · ${p.concreteClass} · ${p.status.label}',
                            leadingIcon: Icons.event_note_outlined,
                            trailingText: '${m3(p.plannedM3)} m³',
                            onTap: () => context.go(AppRoutes.plan),
                          ),
                        )),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Son dökümler', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
                  if (pours.isEmpty)
                    Text('Henüz döküm yok.', style: Theme.of(context).textTheme.bodyMedium)
                  else
                    ...pours.take(3).map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: SJListItem(
                            title: p.location.isEmpty ? 'Lokasyon yok' : p.location,
                            subtitle: '${p.date} · ${p.concreteClass}',
                            leadingIcon: Icons.water_drop_outlined,
                            trailingText: '${m3(p.actualM3)} m³',
                            onTap: () => context.go(AppRoutes.dokum),
                          ),
                        )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
