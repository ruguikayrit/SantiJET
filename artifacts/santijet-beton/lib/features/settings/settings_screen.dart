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

/// Ayarlar — Demir/Puantaj tile düzeni; Beton kapsamı.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showThemePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Açık'),
            onTap: () {
              ref.read(themeModeProvider.notifier).setThemeMode('light');
              Navigator.pop(ctx);
            },
          ),
          ListTile(
            title: const Text('Koyu'),
            onTap: () {
              ref.read(themeModeProvider.notifier).setThemeMode('dark');
              Navigator.pop(ctx);
            },
          ),
          ListTile(
            title: const Text('ŞantiJET'),
            subtitle: const Text('Açık zemin · koyu özet kartları'),
            onTap: () {
              ref.read(themeModeProvider.notifier).setThemeMode('santijet');
              Navigator.pop(ctx);
            },
          ),
          ListTile(
            title: const Text('ŞantiJET Pro'),
            subtitle: const Text('Koyu zemin · açık özet kartları'),
            onTap: () {
              ref.read(themeModeProvider.notifier).setThemeMode('santijet_pro');
              Navigator.pop(ctx);
            },
          ),
          ListTile(
            title: const Text('Sistem'),
            onTap: () {
              ref.read(themeModeProvider.notifier).setThemeMode('system');
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAllData(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Tüm Verileri Sil'),
        content: const Text(
          'Projeler, keşif, döküm, sipariş, fark ve basınç dayanım '
          'kayıtları silinir. Bu işlem geri alınamaz. Devam edilsin mi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.critical),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    ref.read(projectsProvider.notifier).replaceAll([]);
    ref.read(discoveryProvider.notifier).replaceAll([]);
    ref.read(poursProvider.notifier).replaceAll([]);
    ref.read(ordersProvider.notifier).replaceAll([]);
    ref.read(varianceProvider.notifier).replaceAll([]);
    ref.read(qualityProvider.notifier).replaceAll([]);
    ref.read(activeProjectIdProvider.notifier).set(null);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tüm veriler silindi')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final project = ref.watch(activeProjectProvider);
    final discoveryCount = ref.watch(activeDiscoveryProvider).length;
    final pourCount = ref.watch(activePoursProvider).length;
    final orderCount = ref.watch(activeOrdersProvider).length;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _SettingsTile(
            icon: Icons.folder_copy,
            title: 'Projelerim',
            subtitle: project?.name ?? 'Proje seç veya oluştur',
            onTap: () => context.push(AppRoutes.projeler),
          ),
          _SettingsTile(
            icon: Icons.inventory_2_outlined,
            title: 'Aktif proje özeti',
            subtitle: project == null
                ? 'Keşif, döküm, sipariş'
                : '$discoveryCount keşif · $pourCount döküm · $orderCount sipariş',
            onTap: () => context.go(AppRoutes.home),
          ),
          _SettingsTile(
            icon: Icons.science_outlined,
            title: 'Basınç dayanım raporları',
            subtitle: 'Temel · Kolon & Perde · Döşeme laboratuvar kayıtları',
            onTap: () => context.push(AppRoutes.kalite),
          ),
          _SettingsTile(
            icon: Icons.dark_mode,
            title: 'Tema',
            subtitle: themeLabel(themeMode),
            onTap: () => _showThemePicker(context, ref),
          ),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'Hakkında',
            subtitle: '${AppInfo.displayName} v${AppInfo.version}',
            onTap: () => context.push(AppRoutes.hakkinda),
          ),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.delete_forever,
            title: 'Tüm Verileri Sil',
            subtitle: 'Projeler, keşif, döküm ve siparişler silinir',
            onTap: () => _confirmDeleteAllData(context, ref),
            destructive: true,
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

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
        child: Builder(
          builder: (context) {
            final theme = Theme.of(context);
            final titleStyle = theme.textTheme.titleMedium?.copyWith(
              color: destructive
                  ? AppColors.critical
                  : AppColors.cardTextPrimary,
              fontWeight: FontWeight.w600,
            );
            return Row(
              children: [
                Icon(
                  icon,
                  color: destructive
                      ? AppColors.critical
                      : theme.colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: titleStyle),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            );
          },
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
            Image.asset(
              'assets/images/splash_bolt.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
            const SizedBox(height: 4),
            Text(AppInfo.displayName, style: AppTypography.headlineLarge),
            const SizedBox(height: 8),
            Text(
              'Versiyon ${AppInfo.version}',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 24),
            Text(
              'Şantiyeye gelen betonların kaydı, keşfe göre ilerleme, '
              'plan–gerçekleşen farkları ve WhatsApp ile beton firması '
              'paylaşımı. ${AppInfo.tagline}',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              AppInfo.localDataNote,
              style: AppTypography.labelMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Destek: ${AppInfo.supportEmail}',
              style: AppTypography.labelMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
