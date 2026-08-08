import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/sj_empty_state.dart';
import '../../core/design_system/sj_search_bar.dart';
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

/// Birim Fiyat yüzeyi — poz arama, katalog fiyatı, keşife uygula.
class BirimFiyatScreen extends ConsumerStatefulWidget {
  const BirimFiyatScreen({super.key});

  @override
  ConsumerState<BirimFiyatScreen> createState() => _BirimFiyatScreenState();
}

class _BirimFiyatScreenState extends ConsumerState<BirimFiyatScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _open(String id) {
    ref.read(recentViewsProvider.notifier).record(id);
    context.push(AppRoutes.pozDetay(id));
  }

  Future<void> _applyToKesif(PozAnaliz analiz) async {
    final projects = ref.read(kesifProvider);
    if (projects.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce bir keşif projesi oluşturun.')),
      );
      context.go(AppRoutes.kesif);
      return;
    }

    final projectId = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'Keşife fiyatı uygula',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                    ),
              ),
            ),
            for (final p in projects)
              ListTile(
                title: Text(
                  p.ad,
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                subtitle: Text(
                  '${p.satirlar.length} satır · ${AppFormat.currency(p.toplam)}',
                  style: TextStyle(color: AppColors.textMuted),
                ),
                onTap: () => Navigator.pop(ctx, p.id),
              ),
          ],
        ),
      ),
    );
    if (projectId == null || !mounted) return;

    final qtyController = TextEditingController(text: '1');
    final miktar = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Miktar — ${analiz.pozNo}',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: qtyController,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Miktar (${analiz.olcuBirimi})',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              final raw = qtyController.text.replaceAll(',', '.');
              Navigator.pop(ctx, double.tryParse(raw) ?? 1);
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
    qtyController.dispose();
    if (miktar == null || !mounted) return;

    ref.read(kesifProvider.notifier).addSatir(projectId, analiz, miktar);
    final ad = projects.firstWhere((p) => p.id == projectId).ad;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${analiz.pozNo} → $ad eklendi')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(catalogProvider);
    final favorites = ref.watch(favoritesProvider);
    final theme = Theme.of(context);

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
          data: (catalog) {
            final results = _query.trim().isEmpty
                ? catalog.all.take(60).toList()
                : catalog.search(_query, limit: 80);

            return CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(
                  child: SantijetHeader(subtitle: 'Birim Fiyat'),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.xs,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${AppFormat.integer(catalog.all.length)} poz · katalog / analiz fiyatı',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        SJSearchBar(
                          controller: _searchController,
                          hint: 'Poz no veya tanım ara...',
                          onChanged: (v) => setState(() => _query = v),
                          onClear: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                if (results.isEmpty)
                  const SliverToBoxAdapter(
                    child: SizedBox(
                      height: 280,
                      child: SJEmptyState(
                        title: 'Sonuç yok',
                        message: 'Farklı bir poz no deneyin.',
                        icon: Icons.search_off,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    sliver: SliverList.separated(
                      itemCount: results.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.xs),
                      itemBuilder: (context, i) {
                        final a = results[i];
                        return AnalizListItem(
                          analiz: a,
                          isFavorite: favorites.contains(a.id),
                          onTap: () => _open(a.id),
                          onToggleFavorite: () =>
                              ref.read(favoritesProvider.notifier).toggle(a.id),
                          trailing: IconButton(
                            tooltip: 'Keşife uygula',
                            icon: Icon(
                              Icons.playlist_add,
                              color: AppColors.textMuted,
                            ),
                            onPressed: () => _applyToKesif(a),
                          ),
                        );
                      },
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
              ],
            );
          },
        ),
      ),
    );
  }
}
