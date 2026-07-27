import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/providers/app_data_provider.dart';
import '../../data/providers/catalog_provider.dart';

/// Personel / Meslekler / Ekipler yönetimi — Ayarlar alt sayfası.
class ManagementScreen extends ConsumerWidget {
  const ManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeProjectProvider);
    final peopleCount = ref.watch(projectPersonnelProvider).length;
    final professionCount = ref.watch(professionsProvider).length;
    final teamCount = ref.watch(teamsProvider).length;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Yönetim'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.ayarlar),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _SettingsTile(
            icon: Icons.groups_outlined,
            title: 'Personel',
            subtitle: active == null
                ? 'Önce proje seçin'
                : '${active.name}: $peopleCount kayıt',
            onTap: () => context.push(AppRoutes.personel),
          ),
          _SettingsTile(
            icon: Icons.work_outline,
            title: 'Meslekler',
            subtitle: '$professionCount meslek · manuel eklenebilir',
            onTap: () => context.push(AppRoutes.meslekler),
          ),
          _SettingsTile(
            icon: Icons.diversity_3_outlined,
            title: 'Ekipler',
            subtitle: '$teamCount ekip · manuel eklenebilir',
            onTap: () => context.push(AppRoutes.ekipler),
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
  });

  final IconData icon;
  final String title;
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
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: AppRadii.md,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.electricBlueLight, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.titleMedium),
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
