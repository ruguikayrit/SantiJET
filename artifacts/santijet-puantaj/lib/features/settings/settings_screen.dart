import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_info.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_mode_provider.dart';
import '../../data/providers/app_data_provider.dart';
import '../../data/providers/catalog_provider.dart';

/// Tema, personel/proje/katalog yönetimi ve uygulama bilgisi.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          Text('Görünüm', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('Sistem'),
                icon: Icon(Icons.brightness_auto),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('Açık'),
                icon: Icon(Icons.light_mode),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Koyu'),
                icon: Icon(Icons.dark_mode),
              ),
            ],
            selected: {themeMode},
            onSelectionChanged: (s) {
              ref.read(themeModeProvider.notifier).set(s.first);
            },
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
