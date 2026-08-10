import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/sj_card.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../core/design_system/sj_search_bar.dart';
import '../../core/design_system/sj_stat_card.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_format.dart';
import '../../core/widgets/analiz_list_item.dart';
import '../../core/widgets/santijet_header.dart';
import '../../data/providers/catalog_provider.dart';
import '../../data/providers/favorites_provider.dart';
import '../../data/providers/kesif_provider.dart';
import '../../data/providers/recent_views_provider.dart';
import '../../domain/entities/poz_analiz.dart';

/// Ana sayfa — özet kartları + son analizler / açık keşifler (ŞantiJET Maliyet).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAnaliz(String id) {
    ref.read(recentViewsProvider.notifier).record(id);
    context.push(AppRoutes.pozDetay(id));
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(catalogProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: catalogAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => SJEmptyState(
            title: 'Katalog yüklenemedi',
            message: '$e',
            icon: Icons.error_outline,
          ),
          data: (catalog) => _content(catalog),
        ),
      ),
    );
  }

  Widget _content(CatalogData catalog) {
    final searching = _query.trim().isNotEmpty;
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: SantijetHeader(showWordmark: true),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Text(
              '${AppFormat.integer(catalog.all.length)} poz · analiz · keşif · YM',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.xs,
          ),
          sliver: SliverToBoxAdapter(
            child: SJSearchBar(
              controller: _searchController,
              hint: 'Poz no veya analiz ara...',
              onChanged: (v) => setState(() => _query = v),
              onClear: () {
                _searchController.clear();
                setState(() => _query = '');
              },
            ),
          ),
        ),
        if (searching)
          _searchResults(catalog)
        else
          ..._dashboard(catalog),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
      ],
    );
  }

  Widget _searchResults(CatalogData catalog) {
    final results = catalog.search(_query, limit: 40);
    if (results.isEmpty) {
      return const SliverToBoxAdapter(
        child: SizedBox(
          height: 320,
          child: SJEmptyState(
            title: 'Sonuç bulunamadı',
            message: 'Farklı bir poz no veya anahtar kelime deneyin.',
            icon: Icons.search_off,
          ),
        ),
      );
    }
    final favorites = ref.watch(favoritesProvider);
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      sliver: SliverList.separated(
        itemCount: results.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
        itemBuilder: (context, i) {
          final a = results[i];
          return AnalizListItem(
            analiz: a,
            isFavorite: favorites.contains(a.id),
            onTap: () => _openAnaliz(a.id),
            onToggleFavorite: () =>
                ref.read(favoritesProvider.notifier).toggle(a.id),
          );
        },
      ),
    );
  }

  List<Widget> _dashboard(CatalogData catalog) {
    final favorites = ref.watch(favoritesProvider);
    final recentIds = ref.watch(recentViewsProvider);
    final kesifler = ref.watch(kesifProvider);
    final recent = recentIds
        .map(catalog.byIdOrNull)
        .whereType<PozAnaliz>()
        .take(5)
        .toList();
    final ymToplam =
        kesifler.fold<double>(0, (sum, p) => sum + p.toplam);
    final acikKesif = kesifler.take(3).toList();

    return [
      _sectionTitle('Özet'),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        sliver: SliverToBoxAdapter(
          child: Row(
            children: [
              Expanded(
                child: SJStatCard(
                  label: 'Açık Keşif',
                  value: '${kesifler.length}',
                  unit: '',
                  accentColor: AppColors.moduleKesif,
                  onTap: () => context.go(AppRoutes.kesif),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: SJStatCard(
                  label: 'YM Toplamı',
                  value: AppFormat.currency(ymToplam),
                  unit: '',
                  accentColor: AppColors.electricBlue,
                  onTap: () => context.go(AppRoutes.yaklasikMaliyet),
                ),
              ),
            ],
          ),
        ),
      ),
      if (acikKesif.isNotEmpty) ...[
        _sectionTitle('Açık Projeler'),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          sliver: SliverList.list(
            children: [
              for (final k in acikKesif) ...[
                SJCard(
                  onTap: () {
                    ref.read(activeKesifIdProvider.notifier).set(k.id);
                    context.go(AppRoutes.kesif);
                  },
                  child: Row(
                    children: [
                      Icon(Icons.description, color: AppColors.moduleKesif),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              k.ad,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: AppColors.cardTextPrimary),
                            ),
                            Text(
                              '${k.satirlar.length} satır · ${AppFormat.currency(k.toplam)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.cardTextMuted),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: AppColors.cardTextMuted),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
            ],
          ),
        ),
      ],
      if (recent.isNotEmpty) ...[
        _sectionTitle('Son Analizler'),
        _analizSliverList(recent, favorites),
      ],
    ];
  }

  Widget _analizSliverList(List<PozAnaliz> list, Set<String> favorites) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      sliver: SliverList.separated(
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
        itemBuilder: (context, i) {
          final a = list[i];
          return AnalizListItem(
            analiz: a,
            isFavorite: favorites.contains(a.id),
            onTap: () => _openAnaliz(a.id),
            onToggleFavorite: () =>
                ref.read(favoritesProvider.notifier).toggle(a.id),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      sliver: SliverToBoxAdapter(
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
              ),
        ),
      ),
    );
  }
}
