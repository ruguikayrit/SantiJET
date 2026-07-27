import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_info.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_mode_provider.dart';
import '../../data/providers/app_data_provider.dart';
import '../../data/providers/backup_provider.dart';
import '../../data/providers/catalog_provider.dart';
import '../../data/services/puantaj_backup_service.dart';

/// Tema, personel/proje/katalog yönetimi, yedekleme ve uygulama bilgisi.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _busy = false;

  Future<void> _export() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(puantajBackupControllerProvider).exportAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yedek dışa aktarıldı')),
      );
    } on PuantajBackupException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
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

  Future<void> _import() async {
    if (_busy) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('İçe aktar'),
        content: const Text(
          'Seçilen yedek dosyası mevcut proje, personel, puantaj ve '
          'imalat verilerinin üzerine yazılacak. Devam edilsin mi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('İçe aktar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final payload =
          await ref.read(puantajBackupControllerProvider).importAll();
      if (!mounted) return;
      if (payload == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İçe aktarma iptal edildi')),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Yedek yüklendi · ${payload.projects.length} proje · '
            '${payload.personnel.length} personel',
          ),
        ),
      );
    } on PuantajBackupException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İçe aktarma hatası: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showThemePicker(BuildContext context) {
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

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);
    final peopleCount = ref.watch(projectPersonnelProvider).length;
    final projectCount = ref.watch(projectsProvider).length;
    final active = ref.watch(activeProjectProvider);
    final professionCount = ref.watch(professionsProvider).length;
    final teamCount = ref.watch(teamsProvider).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text('Yönetim', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.groups_outlined),
            title: const Text('Personel'),
            subtitle: Text(
              active == null
                  ? 'Önce proje seçin'
                  : '${active.name}: $peopleCount kayıt',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoutes.personel),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.apartment_outlined),
            title: const Text('Projeler'),
            subtitle: Text(
              active == null
                  ? '$projectCount proje'
                  : 'Aktif: ${active.name}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoutes.projeler),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.work_outline),
            title: const Text('Meslekler'),
            subtitle: Text('$professionCount meslek · manuel eklenebilir'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoutes.meslekler),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.diversity_3_outlined),
            title: const Text('Ekipler'),
            subtitle: Text('$teamCount ekip · manuel eklenebilir'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoutes.ekipler),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Yedekleme', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Tüm projeler, personel, puantaj, imalat ve kataloglar '
            'JSON dosyası olarak dışa / içe aktarılır.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _busy ? null : _export,
                  icon: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_outlined),
                  label: const Text('Dışa aktar'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _import,
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('İçe aktar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.electricBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Görünüm', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          _ThemeSettingsTile(
            subtitle: themeLabel(themeMode),
            onTap: () => _showThemePicker(context),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Uygulama', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(AppInfo.displayName),
            subtitle: Text(AppInfo.tagline),
            trailing: Text(AppInfo.version),
          ),
          Text(
            AppInfo.localDataNote,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Destek: ${AppInfo.supportEmail}',
            style: theme.textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

class _ThemeSettingsTile extends StatelessWidget {
  const _ThemeSettingsTile({
    required this.subtitle,
    required this.onTap,
  });

  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.md,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: AppRadii.md,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.dark_mode,
                color: AppColors.electricBlueLight,
                size: 22,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tema', style: AppTypography.titleMedium),
                    Text(subtitle, style: AppTypography.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
