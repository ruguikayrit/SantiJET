import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/sj_card.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/analiz_list_item.dart';
import '../../core/widgets/santijet_header.dart';
import '../../data/providers/catalog_provider.dart';
import '../../data/providers/favorites_provider.dart';
import '../../data/providers/recent_views_provider.dart';
import '../../domain/entities/poz_analiz.dart';
import '../../domain/enums/app_enums.dart';
import '../ozel_analiz/new_analiz_module_sheet.dart';

/// Analiz yüzeyi — özel analiz, karşılaştırma ve katalog girişleri.
class AnalizHubScreen extends ConsumerWidget {
  const AnalizHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(catalogProvider);
    final favorites = ref.watch(favoritesProvider);
    final recentIds = ref.watch(recentViewsProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: FloatingActionButton.extended(
          onPressed: () async {
            final discipline = await NewAnalizModuleSheet.show(context);
            if (discipline == null || !context.mounted) return;
            context.push(
              '${AppRoutes.analizYeni}?modul=${discipline.jsonValue}',
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Yeni Analiz'),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: catalogAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (catalog) {
            final recent = recentIds
                .map(catalog.byIdOrNull)
                .whereType<PozAnaliz>()
                .take(8)
                .toList();
            final ozel = catalog.all
                .where((a) => a.kaynakTip != KaynakTip.sistem)
                .take(8)
                .toList();

            return CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(
                  child: SantijetHeader(subtitle: 'Analiz'),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.xs,
                    AppSpacing.md,
                    0,
                  ),
                  sliver: SliverList.list(
                    children: [
                      _HubTile(
                        icon: Icons.folder_open_outlined,
                        color: AppColors.moduleInsaat,
                        title: 'Analiz Kataloğu',
                        subtitle: 'Kategori ve disiplin indexi',
                        onTap: () => context.push(AppRoutes.analizKatalogu),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _HubTile(
                        icon: Icons.layers_outlined,
                        color: AppColors.moduleInsaat,
                        title: 'İnşaat Analizleri',
                        subtitle: 'Disiplin listesi',
                        onTap: () =>
                            context.push('${AppRoutes.pozlar}?modul=insaat'),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _HubTile(
                        icon: Icons.plumbing_outlined,
                        color: AppColors.moduleMekanik,
                        title: 'Mekanik Tesisat Analizleri',
                        onTap: () =>
                            context.push('${AppRoutes.pozlar}?modul=mekanik'),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _HubTile(
                        icon: Icons.bolt_outlined,
                        color: AppColors.moduleElektrik,
                        title: 'Elektrik Analizleri',
                        onTap: () =>
                            context.push('${AppRoutes.pozlar}?modul=elektrik'),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _HubTile(
                        icon: Icons.compare_arrows,
                        color: AppColors.moduleMekanik,
                        title: 'Analiz Karşılaştır',
                        subtitle: 'Birden fazla analizi yan yana',
                        onTap: () => context.push(AppRoutes.karsilastir),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _HubTile(
                        icon: Icons.star_outline,
                        color: AppColors.moduleFavori,
                        title: 'Favori Analizler',
                        subtitle: '${favorites.length} kayıt',
                        onTap: () =>
                            context.push('${AppRoutes.pozlar}?modul=favoriler'),
                      ),
                    ],
                  ),
                ),
                if (ozel.isNotEmpty) ...[
                  _section('Özel Analizlerim'),
                  _list(ozel, favorites, ref, context),
                ],
                if (recent.isNotEmpty) ...[
                  _section('Son Görüntülenenler'),
                  _list(recent, favorites, ref, context),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 88)),
              ],
            );
          },
        ),
      ),
    );
  }

  static Widget _section(String title) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      sliver: Builder(
        builder: (context) => SliverToBoxAdapter(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                ),
          ),
        ),
      ),
    );
  }

  static Widget _list(
    List<PozAnaliz> items,
    Set<String> favorites,
    WidgetRef ref,
    BuildContext context,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      sliver: SliverList.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
        itemBuilder: (context, i) {
          final a = items[i];
          return AnalizListItem(
            analiz: a,
            isFavorite: favorites.contains(a.id),
            onTap: () {
              ref.read(recentViewsProvider.notifier).record(a.id);
              context.push(AppRoutes.pozDetay(a.id));
            },
            onToggleFavorite: () =>
                ref.read(favoritesProvider.notifier).toggle(a.id),
          );
        },
      ),
    );
  }
}

class _HubTile extends StatelessWidget {
  const _HubTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SJCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.cardTextPrimary,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.cardTextMuted,
                    ),
                  ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.cardTextMuted),
        ],
      ),
    );
  }
}
