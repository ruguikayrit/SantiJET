import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_info.dart';
import '../../core/design_system/sj_card.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../core/design_system/sj_stat_card.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/puantaj_date.dart';
import '../../data/providers/app_data_provider.dart';
import '../../domain/enums/attendance_status.dart';

/// Ana sayfa — bugünkü özet KPI + hızlı aksiyonlar.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final project = ref.watch(activeProjectProvider);
    final people = ref.watch(activePersonnelProvider);
    final attendance = ref.watch(attendanceProvider);
    final today = PuantajDate.today();

    if (project == null) {
      return Scaffold(
        body: SafeArea(
          child: SJEmptyState(
            title: 'Önce proje ekleyin',
            message: 'Puantaj tutmak için en az bir projeniz olmalı.',
            icon: Icons.apartment_outlined,
            actionLabel: 'Projelere Git',
            onAction: () => context.go(AppRoutes.projeler),
          ),
        ),
      );
    }

    final todayRecords = attendance
        .where((a) => a.projectId == project.id && a.date == today)
        .toList();
    final enteredIds = todayRecords.map((a) => a.personId).toSet();
    final missing = people.where((p) => !enteredIds.contains(p.id)).length;
    final present = todayRecords
        .where((a) =>
            a.status == AttendanceStatus.present ||
            a.status == AttendanceStatus.half)
        .length;
    final absent = todayRecords
        .where((a) => a.status == AttendanceStatus.absent)
        .length;
    final totalHours = todayRecords.fold<double>(
      0,
      (sum, a) => sum + a.hours + a.overtimeHours,
    );

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/s_logo.png',
                      width: 36,
                      height: 36,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.apartment,
                        color: AppColors.electricBlue,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppInfo.displayName,
                            style: theme.textTheme.headlineMedium,
                          ),
                          Text(
                            AppInfo.tagline,
                            style: theme.textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              sliver: SliverGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                childAspectRatio: 1.45,
                children: [
                  SJStatCard(
                    label: 'Mevcut / Yarım',
                    value: '$present',
                    accentColor: AttendanceStatus.present.color,
                  ),
                  SJStatCard(
                    label: 'Yok',
                    value: '$absent',
                    accentColor: AttendanceStatus.absent.color,
                  ),
                  SJStatCard(
                    label: 'Girilmedi',
                    value: '$missing',
                    accentColor: AppColors.warning,
                  ),
                  SJStatCard(
                    label: 'Toplam Saat',
                    value: totalHours == totalHours.roundToDouble()
                        ? totalHours.toStringAsFixed(0)
                        : totalHours.toStringAsFixed(1),
                    unit: 'sa',
                    accentColor: AppColors.electricBlue,
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Hızlı işlemler', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    SJCard(
                      onTap: () => context.go(AppRoutes.puantaj),
                      child: Row(
                        children: [
                          Icon(Icons.fact_check,
                              color: theme.colorScheme.primary),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Bugünkü puantaj',
                                    style: theme.textTheme.titleMedium),
                                Text(
                                  people.isEmpty
                                      ? 'Önce personel ekleyin'
                                      : missing > 0
                                          ? '$missing personelin kaydı eksik'
                                          : 'Tüm kayıtlar tamam',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SJCard(
                      onTap: () => context.go(AppRoutes.imalat),
                      child: Row(
                        children: [
                          Icon(Icons.precision_manufacturing,
                              color: theme.colorScheme.primary),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'İmalat girişi',
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SJCard(
                      onTap: () => context.go(AppRoutes.verim),
                      child: Row(
                        children: [
                          Icon(Icons.speed, color: theme.colorScheme.primary),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Verim',
                                    style: theme.textTheme.titleMedium),
                                Text(
                                  'İş Programı bulut verisi gerekir',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
