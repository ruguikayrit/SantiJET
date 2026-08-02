import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/sj_card.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../core/design_system/sj_search_bar.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_format.dart';
import '../../core/widgets/analiz_list_item.dart';
import '../../core/widgets/module_tile.dart';
import '../../core/widgets/santijet_header.dart';
import '../../data/providers/catalog_provider.dart';
import '../../data/providers/favorites_provider.dart';
import '../../data/providers/recent_views_provider.dart';
import '../../domain/entities/poz_analiz.dart';
import '../../domain/enums/app_enums.dart';
import '../ozel_analiz/new_analiz_module_sheet.dart';

/// Ana sayfa — SantijetHeader + arama + modüller (Puantaj/Demir chrome deseni).
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
      // Shell alt nav üstünde kalsın; nested scaffold FAB alt çubuğu örtmesin.
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
          child: SantijetHeader(showWordmark: true, avatarInitial: 'BF'),
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
              '${AppFormat.integer(catalog.all.length)} birim fiyat analizi',
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
    final recent = recentIds
        .map(catalog.byIdOrNull)
        .whereType<PozAnaliz>()
        .take(5)
        .toList();
    final favList = favorites
        .map(catalog.byIdOrNull)
        .whereType<PozAnaliz>()
        .take(5)
        .toList();

    return [
      _sectionTitle('Modüller'),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        sliver: SliverList.list(children: [
          ModuleTile(
            title: 'İnşaat B.F.A.',
            subtitle: 'Birim Fiyat Analizleri',
            icon: Icons.layers,
            accentColor: AppColors.moduleInsaat,
            count: catalog.countFor(AnalizDiscipline.insaat),
            onTap: () => context.push('${AppRoutes.pozlar}?modul=insaat'),
          ),
          const SizedBox(height: AppSpacing.xs),
          ModuleTile(
            title: 'Mekanik Tesisat B.F.A.',
            subtitle: 'Birim Fiyat Analizleri',
            icon: Icons.plumbing,
            accentColor: AppColors.moduleMekanik,
            count: catalog.countFor(AnalizDiscipline.mekanik),
            onTap: () => context.push('${AppRoutes.pozlar}?modul=mekanik'),
          ),
          const SizedBox(height: AppSpacing.xs),
          ModuleTile(
            title: 'Elektrik Tesisat B.F.A.',
            subtitle: 'Birim Fiyat Analizleri',
            icon: Icons.bolt,
            accentColor: AppColors.moduleElektrik,
            count: catalog.countFor(AnalizDiscipline.elektrik),
            onTap: () => context.push('${AppRoutes.pozlar}?modul=elektrik'),
          ),
          const SizedBox(height: AppSpacing.xs),
          ModuleTile(
            title: 'Favoriler',
            subtitle: 'Kaydettiğiniz analizler',
            icon: Icons.star,
            accentColor: AppColors.moduleFavori,
            count: favorites.length,
            onTap: () => context.push('${AppRoutes.pozlar}?modul=favoriler'),
          ),
        ]),
      ),
      if (recent.isNotEmpty) ...[
        _sectionTitle('Son Görüntülenenler'),
        _analizSliverList(recent, favorites),
      ],
      if (favList.isNotEmpty) ...[
        _sectionTitle('Favoriler'),
        _analizSliverList(favList, favorites),
      ],
      _sectionTitle('Hızlı Erişim'),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        sliver: SliverList.list(children: [
          _quickAccessTile(
            icon: Icons.folder_open_outlined,
            color: AppColors.moduleInsaat,
            title: 'Analiz Kataloğu',
            onTap: () => context.push(AppRoutes.analizKatalogu),
          ),
          const SizedBox(height: AppSpacing.xs),
          _quickAccessTile(
            icon: Icons.compare_arrows,
            color: AppColors.moduleMekanik,
            title: 'Analiz Karşılaştır',
            onTap: () => context.push(AppRoutes.karsilastir),
          ),
        ]),
      ),
    ];
  }

  Widget _quickAccessTile({
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
  }) {
    return SJCard(
      onTap: onTap,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.cardTextPrimary,
                  ),
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
    );
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
