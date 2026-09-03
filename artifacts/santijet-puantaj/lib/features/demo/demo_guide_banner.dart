import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/sj_card.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/providers/app_data_provider.dart';
import '../../data/providers/demo_intro_provider.dart';
import '../../data/providers/demo_seed_provider.dart';

/// Demo yüklendikten sonra ana sayfada modül rehberi.
class DemoGuideBanner extends ConsumerWidget {
  const DemoGuideBanner({super.key});

  static const _steps = <({String title, String route, IconData icon})>[
    (
      title: 'Puantaj',
      route: AppRoutes.puantaj,
      icon: Icons.fact_check_outlined,
    ),
    (
      title: 'İmalat',
      route: AppRoutes.imalat,
      icon: Icons.construction_outlined,
    ),
    (
      title: 'Verim',
      route: '${AppRoutes.imalat}?tab=verim',
      icon: Icons.speed_outlined,
    ),
    (
      title: 'Görev',
      route: AppRoutes.gorevler,
      icon: Icons.task_alt_outlined,
    ),
    (
      title: 'Rapor',
      route: AppRoutes.gunlukRapor,
      icon: Icons.description_outlined,
    ),
    (
      title: 'Personel',
      route: AppRoutes.personel,
      icon: Icons.groups_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intro = ref.watch(demoIntroProvider);
    if (!intro.guideVisible) return const SizedBox.shrink();

    final project = ref.watch(activeProjectProvider);
    final isDemo = project?.name == DemoSeedController.demoProjectName;

    return SJCard.builder(
      builder: (context, theme) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.explore_outlined, color: AppColors.info, size: 22),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isDemo
                            ? 'Örnek proje yüklü — ekranlar'
                            : 'Modül kısayolları',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Aşağıdaki kısayoldan ilgili sekmeye gidin.',
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Rehberi kapat',
                  onPressed: () =>
                      ref.read(demoIntroProvider.notifier).dismissGuide(),
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final step in _steps)
                  ActionChip(
                    avatar: Icon(step.icon, size: 16),
                    label: Text(step.title),
                    onPressed: () => context.go(step.route),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Not: Görevde kategori ve etiket zorunlu. Atanan değişince '
              'atayana onay satırı düşer. Plan / keşif paketi için '
              'Ayarlar → Plan dosyası.',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.cardTextMuted,
              ),
            ),
          ],
        );
      },
    );
  }
}
