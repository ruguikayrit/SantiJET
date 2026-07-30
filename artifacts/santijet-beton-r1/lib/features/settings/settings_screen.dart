import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_info.dart';
import '../../core/design_system/sj_card.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_mode_provider.dart';
import '../../data/providers/app_data_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final project = ref.watch(activeProjectProvider);
    final pending = ref.watch(dashboardSummaryProvider).pendingSamples;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _Tile(icon: Icons.folder_copy, title: 'Projelerim', subtitle: project?.name ?? 'Proje seç veya oluştur', onTap: () => context.push(AppRoutes.projeler)),
          _Tile(icon: Icons.science_outlined, title: 'Kalite / Numune', subtitle: pending == 0 ? 'Basınç dayanımı ve cüruf' : '$pending bekleyen numune', onTap: () => context.push(AppRoutes.kalite)),
          _Tile(
            icon: Icons.dark_mode,
            title: 'Tema',
            subtitle: themeLabel(themeMode),
            onTap: () => showModalBottomSheet<void>(
              context: context,
              backgroundColor: AppColors.surfaceElevated,
              builder: (ctx) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final mode in ['light', 'dark', 'santijet', 'system'])
                    ListTile(
                      title: Text(themeLabel(mode)),
                      onTap: () {
                        ref.read(themeModeProvider.notifier).setThemeMode(mode);
                        Navigator.pop(ctx);
                      },
                    ),
                ],
              ),
            ),
          ),
          _Tile(icon: Icons.info_outline, title: 'Hakkında', subtitle: '${AppInfo.displayName} v${AppInfo.version}', onTap: () => context.push(AppRoutes.hakkinda)),
          const SizedBox(height: 8),
          _Tile(
            icon: Icons.delete_forever,
            title: 'Tüm Verileri Sil',
            subtitle: 'BETON R1 yerel kayıtları silinir',
            destructive: true,
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Tüm Verileri Sil'),
                  content: const Text('Tüm BETON R1 verileri silinir. Geri alınamaz.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
                    FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.critical), onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil')),
                  ],
                ),
              );
              if (ok != true) return;
              ref.read(projectsProvider.notifier).replaceAll([]);
              ref.read(pourPlansProvider.notifier).replaceAll([]);
              ref.read(pourRecordsProvider.notifier).replaceAll([]);
              ref.read(ordersProvider.notifier).replaceAll([]);
              ref.read(qualityProvider.notifier).replaceAll([]);
              ref.read(activeProjectIdProvider.notifier).set(null);
            },
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.title, required this.subtitle, required this.onTap, this.destructive = false});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SJCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: destructive ? AppColors.critical : Theme.of(context).colorScheme.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: destructive ? AppColors.critical : null, fontWeight: FontWeight.w600)),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Hakkında')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Image.asset('assets/images/splash_bolt.png', width: 120, height: 120, fit: BoxFit.contain),
            Text(AppInfo.displayName, style: AppTypography.headlineLarge),
            const SizedBox(height: 8),
            Text('Versiyon ${AppInfo.version}', style: AppTypography.bodyMedium),
            const SizedBox(height: 24),
            Text(AppInfo.tagline, style: AppTypography.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Text(AppInfo.localDataNote, style: AppTypography.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Text('Mevcut BETON uygulaması (/beton/) ile ayrıdır.', style: AppTypography.labelMedium, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
