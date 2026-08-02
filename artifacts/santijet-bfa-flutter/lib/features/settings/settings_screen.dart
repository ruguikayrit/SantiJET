import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_info.dart';
import '../../core/design_system/design_system.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_mode_provider.dart';
import '../../data/providers/favorites_provider.dart';
import '../../data/providers/kesif_provider.dart';
import '../../data/providers/recent_views_provider.dart';
import '../../data/providers/user_analiz_provider.dart';
import '../../data/services/backup_service.dart';

/// Ayarlar — Faz 12'de uygulanacaktır
/// (tema seçimi, JSON yedek dışa/içe aktarma, hukuki linkler, sürüm bilgisi).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mode = ref.watch(themeModeProvider);
    final userAnalizleri = ref.watch(userAnalizProvider);
    final favoriteIds = ref.watch(favoritesProvider);
    final recentIds = ref.watch(recentViewsProvider);
    final kesifProjects = ref.watch(kesifProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text('Görünüm', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            _ThemeTile(
              title: 'Açık',
              subtitle: 'Açık zemin · açık kartlar',
              selected: mode == 'light',
              onTap: () =>
                  ref.read(themeModeProvider.notifier).setThemeMode('light'),
            ),
            const SizedBox(height: AppSpacing.xs),
            _ThemeTile(
              title: 'Koyu',
              subtitle: 'Koyu zemin · koyu kartlar',
              selected: mode == 'dark',
              onTap: () =>
                  ref.read(themeModeProvider.notifier).setThemeMode('dark'),
            ),
            const SizedBox(height: AppSpacing.xs),
            _ThemeTile(
              title: 'ŞantiJET',
              subtitle: 'Açık zemin · koyu özet kartları',
              selected: mode == 'santijet',
              onTap: () =>
                  ref.read(themeModeProvider.notifier).setThemeMode('santijet'),
            ),
            const SizedBox(height: AppSpacing.xs),
            _ThemeTile(
              title: 'ŞantiJET Pro',
              subtitle: 'Koyu zemin · açık özet kartları',
              selected: mode == 'santijet_pro',
              onTap: () => ref
                  .read(themeModeProvider.notifier)
                  .setThemeMode('santijet_pro'),
            ),
            const SizedBox(height: AppSpacing.xs),
            _ThemeTile(
              title: 'Sistem',
              subtitle: 'Cihaz tema ayarını kullan',
              selected: mode == 'system',
              onTap: () =>
                  ref.read(themeModeProvider.notifier).setThemeMode('system'),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Veri', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            SJCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Yerel veriler', style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${userAnalizleri.length} özel analiz · '
                    '${favoriteIds.length} favori · '
                    '${recentIds.length} son görüntülenen · '
                    '${kesifProjects.length} keşif',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: SJButton(
                          label: 'Dışa Aktar',
                          icon: Icons.upload_file,
                          onPressed: () => _exportBackup(context, ref),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: SJButton(
                          label: 'İçe Aktar',
                          icon: Icons.download,
                          variant: SJButtonVariant.secondary,
                          onPressed: () => _importBackup(context, ref),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Hakkında', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            SJListItem(
              title: AppInfo.displayName,
              subtitle:
                  '${AppInfo.dataSourceLabel} · ${AppInfo.dataUpdateLabel}',
              leadingIcon: Icons.info_outline,
              accentColor: AppColors.electricBlueLight,
              trailingText: AppInfo.version,
            ),
            const SizedBox(height: AppSpacing.xs),
            SJListItem(
              title: 'Gizlilik Politikası',
              subtitle: 'Yerel veri ve gizlilik ilkeleri',
              leadingIcon: Icons.privacy_tip_outlined,
              accentColor: AppColors.info,
              onTap: () => context.push(AppRoutes.legalDocument('privacy')),
            ),
            const SizedBox(height: AppSpacing.xs),
            SJListItem(
              title: 'Kullanım Koşulları',
              subtitle: 'Kullanım kapsamı ve sorumluluk reddi',
              leadingIcon: Icons.gavel_outlined,
              accentColor: AppColors.warning,
              onTap: () => context.push(AppRoutes.legalDocument('terms')),
            ),
            const SizedBox(height: AppSpacing.xs),
            SJListItem(
              title: 'Kaynaklar',
              subtitle: 'ÇŞİDB YFK 2026 Yayınları',
              leadingIcon: Icons.open_in_browser,
              accentColor: AppColors.electricBlueLight,
              onTap: () => context.push(AppRoutes.sources),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    final mode = ref.read(themeModeProvider);
    final backup = BfaBackup(
      exportedAt: DateTime.now().toIso8601String(),
      userAnalizleri: ref.read(userAnalizProvider),
      favoriteIds: ref.read(favoritesProvider).toList(),
      recentIds: ref.read(recentViewsProvider),
      kesifProjects: ref.read(kesifProvider),
      themeMode: mode,
    );
    await backupService.share(backup);
  }

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    try {
      final backup = await backupService.pickAndParse();
      if (backup == null || !context.mounted) return;

      final replace = await SJModal.confirm(
        context: context,
        title: 'Yedek İçe Aktar',
        message:
            'Yedek dosyası mevcut verilerle birleştirilsin mi? Değiştir seçeneği mevcut yerel verileri siler.',
        confirmLabel: 'Birleştir',
        cancelLabel: 'Değiştir',
      );

      if (replace) {
        ref.read(userAnalizProvider.notifier).merge(backup.userAnalizleri);
        ref.read(favoritesProvider.notifier).merge(backup.favoriteIds);
        ref.read(recentViewsProvider.notifier).merge(backup.recentIds);
        ref.read(kesifProvider.notifier).merge(backup.kesifProjects);
      } else {
        ref.read(userAnalizProvider.notifier).replaceAll(backup.userAnalizleri);
        ref.read(favoritesProvider.notifier).replaceAll(backup.favoriteIds);
        ref.read(recentViewsProvider.notifier).replaceAll(backup.recentIds);
        ref.read(kesifProvider.notifier).replaceAll(backup.kesifProjects);
      }

      final restored = backup.themeMode == 'gecejet'
          ? 'santijet_pro'
          : backup.themeMode;
      await ref.read(themeModeProvider.notifier).setThemeMode(
            switch (restored) {
              'light' || 'dark' || 'santijet' || 'santijet_pro' || 'system' =>
                restored,
              _ => 'santijet_pro',
            },
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yedek içe aktarıldı.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yedek okunamadı: $e')),
        );
      }
    }
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SJCard(
      selected: selected,
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
