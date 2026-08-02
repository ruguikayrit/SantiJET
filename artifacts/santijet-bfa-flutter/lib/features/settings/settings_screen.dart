import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_info.dart';
import '../../core/design_system/sj_card.dart';
import '../../core/design_system/sj_modal.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_mode_provider.dart';
import '../../data/providers/favorites_provider.dart';
import '../../data/providers/kesif_provider.dart';
import '../../data/providers/recent_views_provider.dart';
import '../../data/providers/user_analiz_provider.dart';
import '../../data/services/backup_service.dart';

/// Ayarlar — Puantaj/Beton ile aynı kart/tile + tema sheet düzeni.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _busy = false;

  void _showThemePicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      builder: (ctx) => SafeArea(
        child: Column(
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
                ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode('santijet_pro');
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
      ),
    );
  }

  void _showBackupDialog(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Yedekleme & Geri Yükleme',
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Özel analizler, favoriler, son görüntülenenler ve keşif '
                'projelerini JSON dosyası olarak dışa / içe aktarın.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _busy
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        await _exportBackup();
                      },
                icon: const Icon(Icons.upload),
                label: const Text('Verileri Dışa Aktar'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        await _importBackup();
                      },
                icon: const Icon(Icons.download),
                label: const Text('Verileri İçe Aktar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportBackup() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yedek dışa aktarıldı')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dışa aktarma hatası: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importBackup() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final backup = await backupService.pickAndParse();
      if (backup == null || !mounted) return;

      final merge = await SJModal.confirm(
        context: context,
        title: 'Yedek İçe Aktar',
        message:
            'Yedek dosyası mevcut verilerle birleştirilsin mi? Değiştir seçeneği mevcut yerel verileri siler.',
        confirmLabel: 'Birleştir',
        cancelLabel: 'Değiştir',
      );

      if (merge) {
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yedek içe aktarıldı')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Yedek okunamadı: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final userAnalizleri = ref.watch(userAnalizProvider);
    final favoriteIds = ref.watch(favoritesProvider);
    final recentIds = ref.watch(recentViewsProvider);
    final kesifProjects = ref.watch(kesifProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _SettingsTile(
            icon: Icons.dark_mode,
            title: 'Tema',
            subtitle: themeLabel(themeMode),
            onTap: () => _showThemePicker(context),
          ),
          _SettingsTile(
            icon: Icons.backup,
            title: 'Yedekleme & Geri Yükleme',
            subtitle: _busy
                ? 'İşleniyor…'
                : '${userAnalizleri.length} özel analiz · '
                    '${favoriteIds.length} favori · '
                    '${recentIds.length} son · '
                    '${kesifProjects.length} keşif',
            onTap: () {
              if (!_busy) _showBackupDialog(context);
            },
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Gizlilik Politikası',
            subtitle: 'Yerel veri ve gizlilik ilkeleri',
            onTap: () => context.push(AppRoutes.legalDocument('privacy')),
          ),
          _SettingsTile(
            icon: Icons.gavel_outlined,
            title: 'Kullanım Koşulları',
            subtitle: 'Kullanım kapsamı ve sorumluluk reddi',
            onTap: () => context.push(AppRoutes.legalDocument('terms')),
          ),
          _SettingsTile(
            icon: Icons.open_in_browser,
            title: 'Kaynaklar',
            subtitle: 'ÇŞİDB YFK 2026 Yayınları',
            onTap: () => context.push(AppRoutes.sources),
          ),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'Hakkında',
            subtitle: '${AppInfo.displayName} v${AppInfo.version}',
            onTap: () => _showAbout(context),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/splash_bolt.png',
                width: 96,
                height: 96,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
              const SizedBox(height: 8),
              Text(
                AppInfo.displayName,
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Versiyon ${AppInfo.version}',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppInfo.tagline,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '${AppInfo.dataSourceLabel} · ${AppInfo.dataUpdateLabel}',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Destek: ${AppInfo.supportEmail}',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ana sayfa özet kartlarıyla aynı yüzey (ŞantiJET’te koyu dolgu).
class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

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
            return Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.cardTextPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.cardTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.cardTextMuted,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
