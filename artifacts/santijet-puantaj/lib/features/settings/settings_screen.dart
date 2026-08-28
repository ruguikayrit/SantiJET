import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_info.dart';
import '../../core/design_system/sj_card.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_mode_provider.dart';
import '../../data/providers/app_data_provider.dart';
import '../../data/providers/backup_provider.dart';
import '../../data/providers/catalog_provider.dart';
import '../../data/providers/company_provider.dart';
import '../../data/providers/demo_intro_provider.dart';
import '../../data/providers/demo_seed_provider.dart';
import '../../data/providers/daily_report_provider.dart';
import '../../data/providers/production_provider.dart';
import '../../data/providers/tasks_provider.dart';
import '../../data/providers/uninsured_teams_provider.dart';
import '../../data/providers/plan_cloud_sync_provider.dart';
import '../../data/providers/yevmiyeli_is_provider.dart';
import '../../data/services/puantaj_backup_service.dart';
import '../../domain/catalogs/professions.dart';
import '../../domain/catalogs/task_categories.dart';
import '../../core/design_system/sj_modal.dart';

/// Ayarlar — Demir ile aynı kart/tile düzeni; Puantaj kapsamına indirgenmiş.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _busy = false;

  void _showThemePicker(BuildContext context) {
    final sheetTheme = SJModal.sheetThemeOf(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: SJModal.sheetSurface,
      builder: (ctx) => Theme(
        data: sheetTheme,
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
      ),
    );
  }

  void _showBackupDialog(BuildContext context) {
    final sheetTheme = SJModal.sheetThemeOf(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: SJModal.sheetSurface,
      builder: (ctx) => Theme(
        data: sheetTheme,
        child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Yedekleme & Geri Yükleme',
                style: sheetTheme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Tüm uygulama verisi tek JSON dosyasında yedeklenir: proje, '
                'personel, puantaj, sigortasız ekip, imalat, verim, görev, '
                'günlük rapor, yevmiyeli iş, kataloglar ve firma bilgisi.',
                style: sheetTheme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _busy
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        await _export();
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
                        await _import();
                      },
                icon: const Icon(Icons.download),
                label: const Text('Verileri İçe Aktar'),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

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
    final dialogTheme = SJModal.sheetThemeOf(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Theme(
        data: dialogTheme,
        child: AlertDialog(
        backgroundColor: SJModal.sheetSurface,
        title: const Text('Verileri İçe Aktar'),
        content: const Text(
          'Seçilen yedek dosyası mevcut tüm uygulama verisinin üzerine '
          'yazılacak. Devam edilsin mi?',
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
            '${payload.personnel.length} personel · '
            '${payload.tasks.length} görev · '
            '${payload.dailyReports.length} rapor',
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

  Future<void> _confirmDeleteAllData(BuildContext context) async {
    final dialogTheme = SJModal.sheetThemeOf(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Theme(
        data: dialogTheme,
        child: AlertDialog(
        backgroundColor: SJModal.sheetSurface,
        title: const Text('Tüm Verileri Sil'),
        content: const Text(
          'Projeler, personel, puantaj, imalat, görev, rapor, yevmiyeli '
          'iş ve kataloglar silinir. Bu işlem geri alınamaz. Devam edilsin mi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.critical,
              foregroundColor: AppColors.readableOn(AppColors.critical),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
        ),
      ),
    );
    if (ok != true || !mounted) return;

    ref.read(projectsProvider.notifier).replaceAll([]);
    ref.read(personnelProvider.notifier).replaceAll([]);
    ref.read(attendanceProvider.notifier).replaceAll([]);
    ref.read(productionProvider.notifier).replaceAll([]);
    ref.read(productionProvider.notifier).clearAllYearlyChartDemoFlags();
    ref.read(tasksProvider.notifier).replaceAll([]);
    ref.read(dailyReportsProvider.notifier).replaceAll([]);
    ref.read(yevmiyeliIsProvider.notifier).replaceAll([]);
    ref.read(uninsuredTeamsProvider.notifier).replaceAll([]);
    ref
        .read(professionsProvider.notifier)
        .resetToDefaults(ProfessionCatalog.defaultProfessions);
    ref
        .read(teamsProvider.notifier)
        .resetToDefaults(ProfessionCatalog.defaultTradeGroups);
    ref
        .read(taskCategoriesProvider.notifier)
        .resetToDefaults(TaskCategoryCatalog.defaults);
    ref.read(activeProjectIdProvider.notifier).set(null);
    ref.read(planCloudSyncControllerProvider).clearAllCaches();
    ref.read(demoIntroProvider.notifier).resetIntroForReplay();
    ref.read(companyInfoProvider.notifier).clear();

    if (!mounted) return;
    ScaffoldMessenger.of(this.context).showSnackBar(
      const SnackBar(content: Text('Tüm veriler silindi')),
    );
  }

  Future<void> _confirmLoadDemo(BuildContext context) async {
    final ok = await SJModal.confirm(
      context: context,
      title: 'Demo veriyi yükle',
      message:
          'Demo Şantiye sıfırlanır ve yeniden kurulur: personel, puantaj, '
          'sigortasız ekip, imalat (plan bulutu İmalat formunda), görevler '
          '(Satın Alma / Saha / Ofis / Görüşme), günlük raporlar ve yevmiyeli işler.',
      confirmLabel: 'Yükle',
    );
    if (!ok || !mounted) return;

    setState(() => _busy = true);
    try {
      final project =
          await ref.read(demoSeedControllerProvider).loadAll();
      ref.read(demoIntroProvider.notifier).completeIntro(showGuide: true);
      if (!mounted) return;
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(
          content: Text(
            'Demo yüklendi: ${project.name}. Ana sayfadaki rehberden '
            'modülleri gezebilirsiniz.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(content: Text('Demo yüklenemedi: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final project = ref.watch(activeProjectProvider);
    final peopleCount = ref.watch(projectPersonnelProvider).length;
    final professionCount = ref.watch(professionsProvider).length;
    final teamCount = ref.watch(teamsProvider).length;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Ayarlar'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _SettingsTile(
            icon: Icons.account_circle_outlined,
            title: 'Hesap',
            subtitle: 'Bulut girişi — ekip paylaşımı için',
            onTap: () => context.push(AppRoutes.auth),
          ),
          _SettingsTile(
            icon: Icons.group_add_outlined,
            title: 'İş koduna katıl',
            subtitle: 'Paylaşılan kod ile aynı şantiye verilerine eriş',
            onTap: () => context.push(AppRoutes.projeKatil),
          ),
          _SettingsTile(
            icon: Icons.folder_copy,
            title: 'Projelerim',
            subtitle: project?.name ?? 'Proje seç veya oluştur',
            onTap: () => context.push(AppRoutes.projeler),
          ),
          _SettingsTile(
            icon: Icons.manage_accounts_outlined,
            title: 'Yönetim',
            subtitle: project == null
                ? 'Personel, meslekler, ekipler'
                : '$peopleCount personel · $professionCount meslek · '
                    '$teamCount ekip',
            onTap: () => context.push(AppRoutes.yonetim),
          ),
          _SettingsTile(
            icon: Icons.dark_mode,
            title: 'Tema',
            subtitle: themeLabel(themeMode),
            onTap: () => _showThemePicker(context),
          ),
          _SettingsTile(
            icon: Icons.backup,
            title: 'Yedekleme & Geri Yükleme',
            subtitle: 'Verileri JSON olarak dışa/içe aktar',
            onTap: () => _showBackupDialog(context),
          ),
          _SettingsTile(
            icon: Icons.play_circle_outline,
            title: 'Uygulama tanıtımı',
            subtitle: 'Modülleri anlatan kısa tur · demo yükleme',
            onTap: () => context.push(AppRoutes.demoIntro),
          ),
          _SettingsTile(
            icon: Icons.science_outlined,
            title: 'Demo veriyi yükle',
            subtitle: _busy
                ? 'Yükleniyor…'
                : 'Tüm modülleri kapsayan Demo Şantiye örneği',
            onTap: () {
              if (!_busy) _confirmLoadDemo(context);
            },
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
            subtitle: 'Projeler, personel, puantaj ve imalat silinir',
            onTap: () => _confirmDeleteAllData(context),
            destructive: true,
          ),
        ],
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
              color: destructive ? AppColors.critical : null,
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

/// Hakkında — Demir AboutScreen düzeni, Puantaj metni.
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
            Text(
              AppInfo.displayName,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Versiyon ${AppInfo.version}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Text(
              'Saha operasyonu, günlük rapor, personel devam, yevmiye, '
              'imalat ve verim takibi. ${AppInfo.tagline}',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Destek: ${AppInfo.supportEmail}',
              style: Theme.of(context).textTheme.labelMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
