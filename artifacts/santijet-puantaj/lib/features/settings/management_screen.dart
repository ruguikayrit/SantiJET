import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/sj_card.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/providers/active_operator_provider.dart';
import '../../data/providers/app_data_provider.dart';
import '../../data/providers/catalog_provider.dart';
import '../../data/providers/company_provider.dart';
import '../../domain/permissions/role_degree.dart';

/// Firma / Personel / Meslekler / Ekipler yönetimi — Ayarlar alt sayfası.
class ManagementScreen extends ConsumerWidget {
  const ManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeProjectProvider);
    final company = ref.watch(companyInfoProvider);
    final peopleCount = ref.watch(projectPersonnelProvider).length;
    final professionCount = ref.watch(professionsProvider).length;
    final teamCount = ref.watch(teamsProvider).length;
    final categoryCount = ref.watch(taskCategoriesProvider).length;
    final operator = ref.watch(activeOperatorProvider);

    String aktifSubtitle() {
      if (active == null) return 'Önce proje seçin';
      if (operator == null) return 'Bu cihazda kim çalışıyor?';
      final degree = RoleDegree.isFirstDegree(operator)
          ? '1. derece'
          : 'saha';
      return '${operator.name}'
          '${operator.profession.isNotEmpty ? ' · ${operator.profession}' : ''}'
          ' · $degree';
    }

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
            icon: Icons.badge_outlined,
            title: 'Aktif kullanıcı',
            subtitle: aktifSubtitle(),
            onTap: () => context.push(AppRoutes.aktifKullanici),
          ),
          _SettingsTile(
            icon: Icons.business_outlined,
            title: 'Firma Bilgileri',
            subtitle: company.name.trim().isEmpty
                ? 'Firma adı, vergi no, iletişim'
                : company.name.trim(),
            onTap: () => context.push(AppRoutes.firma),
          ),
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
          _SettingsTile(
            icon: Icons.category_outlined,
            title: 'Görev kategorileri',
            subtitle: '$categoryCount kategori · Satın Alma, Saha, Ofis…',
            onTap: () => context.push(AppRoutes.gorevKategorileri),
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
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
