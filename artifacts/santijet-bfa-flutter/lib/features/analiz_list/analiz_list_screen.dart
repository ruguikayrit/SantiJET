import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/design_system.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../core/design_system/sj_filter_chips.dart';
import '../../core/design_system/sj_search_bar.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_format.dart';
import '../../core/widgets/analiz_list_item.dart';
import '../../data/providers/catalog_provider.dart';
import '../../data/providers/favorites_provider.dart';
import '../../data/providers/recent_views_provider.dart';
import '../../data/services/bulk_export_service.dart';
import '../../domain/entities/poz_analiz.dart';
import '../../domain/enums/app_enums.dart';
import '../export/export_format_sheet.dart';

/// Analiz listesi — modül/disiplin, favoriler veya tüm katalog için arama,
/// kategori filtresi ve favori yönetimiyle listeleme.
///
/// [modul]: insaat | mekanik | elektrik | favoriler | null (tüm katalog).
class AnalizListScreen extends ConsumerStatefulWidget {
  const AnalizListScreen({this.modul, this.query, this.cat, super.key});

  final String? modul;
  final String? query;
  final String? cat;

  @override
  ConsumerState<AnalizListScreen> createState() => _AnalizListScreenState();
}

class _AnalizListScreenState extends ConsumerState<AnalizListScreen> {
  late final TextEditingController _searchController;
  late String _query;
  String? _selectedCategory;
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _query = widget.query ?? '';
    _searchController = TextEditingController(text: _query);
    _selectedCategory = widget.cat;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _title {
    return switch (widget.modul) {
      'insaat' => 'İnşaat B.F.A.',
      'mekanik' => 'Mekanik Tesisat B.F.A.',
      'elektrik' => 'Elektrik Tesisat B.F.A.',
      'favoriler' => 'Favoriler',
      _ => 'Katalog',
    };
  }

  List<PozAnaliz> _baseList(CatalogData catalog, Set<String> favorites) {
    return switch (widget.modul) {
      'insaat' => catalog.forDiscipline(AnalizDiscipline.insaat),
      'mekanik' => catalog.forDiscipline(AnalizDiscipline.mekanik),
      'elektrik' => catalog.forDiscipline(AnalizDiscipline.elektrik),
      'favoriler' =>
        favorites.map(catalog.byIdOrNull).whereType<PozAnaliz>().toList(),
      _ => catalog.all,
    };
  }

  void _openAnaliz(String id) {
    ref.read(recentViewsProvider.notifier).record(id);
    context.push(AppRoutes.pozDetay(id));
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
      if (_selectedIds.isEmpty) _selectionMode = false;
    });
  }

  Future<void> _bulkExport(List<PozAnaliz> selected) async {
    final format = await ExportFormatSheet.pick(context, title: 'Toplu Dışa Aktar');
    if (format == null || !mounted) return;
    try {
      await bulkExportService.shareZip(
        analizler: selected,
        asPdf: format == ExportFormat.pdf,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dışa aktarma başarısız: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catalogAsync = ref.watch(catalogProvider);
    final favorites = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectionMode ? '${_selectedIds.length} seçili' : _title),
        actions: [
          if (widget.modul != 'favoriler')
            IconButton(
              tooltip: _selectionMode ? 'Seçimi kapat' : 'Çoklu seçim',
              icon: Icon(_selectionMode ? Icons.close : Icons.checklist),
              onPressed: () => setState(() {
                _selectionMode = !_selectionMode;
                if (!_selectionMode) _selectedIds.clear();
              }),
            ),
          if (_selectionMode && _selectedIds.length >= 2)
            IconButton(
              tooltip: 'Karşılaştır',
              icon: const Icon(Icons.compare_arrows),
              onPressed: () => context.push(
                '${AppRoutes.karsilastir}?ids=${_selectedIds.join(',')}',
              ),
            ),
          if (_selectionMode && _selectedIds.isNotEmpty)
            IconButton(
              tooltip: 'Toplu dışa aktar',
              icon: const Icon(Icons.archive_outlined),
              onPressed: () {
                final catalog = catalogAsync.asData?.value;
                if (catalog == null) return;
                final selected = _selectedIds
                    .map(catalog.byIdOrNull)
                    .whereType<PozAnaliz>()
                    .toList();
                _bulkExport(selected);
              },
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: catalogAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => SJEmptyState(
            title: 'Katalog yüklenemedi',
            message: '$e',
            icon: Icons.error_outline,
          ),
          data: (catalog) => _body(theme, catalog, favorites),
        ),
      ),
    );
  }

  Widget _body(ThemeData theme, CatalogData catalog, Set<String> favorites) {
    final base = _baseList(catalog, favorites);
    final categories = switch (widget.modul) {
      'insaat' => catalog.categoriesForDiscipline(AnalizDiscipline.insaat),
      'mekanik' => catalog.categoriesForDiscipline(AnalizDiscipline.mekanik),
      'elektrik' => catalog.categoriesForDiscipline(AnalizDiscipline.elektrik),
      _ => CatalogData.kategoriler(base),
    };

    // Kategori filtresi
    var filtered = _selectedCategory == null
        ? base
        : base.where((a) => a.kategori.trim() == _selectedCategory).toList();

    // Arama filtresi
    final q = _query.trim();
    if (q.isNotEmpty) {
      filtered = catalog.searchIn(filtered, q);
    }

    final chipLabels = ['Tümü', ...categories];
    final selectedIndex = _selectedCategory == null
        ? 0
        : categories.indexOf(_selectedCategory!) + 1;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.xs,
          ),
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
        if (categories.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: SJFilterChips(
              labels: chipLabels,
              selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
              onSelected: (i) => setState(
                () => _selectedCategory = i == 0 ? null : categories[i - 1],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xxs,
          ),
          child: Row(
            children: [
              Text(
                '${AppFormat.integer(filtered.length)} analiz',
                style: theme.textTheme.labelMedium,
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? _emptyState()
              : ListView.separated(
                  // Flutter 3.44'te yeni scrollCacheExtent tipi henüz public
                  // export edilmediği için uyumluluk amacıyla eski alanı
                  // kullanıyoruz.
                  // ignore: deprecated_member_use
                  cacheExtent: 900,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.xs,
                    AppSpacing.md,
                    AppSpacing.xl,
                  ),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.xs),
                  itemBuilder: (context, i) {
                    final a = filtered[i];
                    final selected = _selectedIds.contains(a.id);
                    return GestureDetector(
                      onLongPress: () {
                        setState(() {
                          _selectionMode = true;
                          _selectedIds.add(a.id);
                        });
                      },
                      child: Stack(
                        children: [
                          AnalizListItem(
                            analiz: a,
                            isFavorite: favorites.contains(a.id),
                            onTap: () {
                              if (_selectionMode) {
                                _toggleSelect(a.id);
                              } else {
                                _openAnaliz(a.id);
                              }
                            },
                            onToggleFavorite: _selectionMode
                                ? null
                                : () => ref
                                    .read(favoritesProvider.notifier)
                                    .toggle(a.id),
                          ),
                          if (_selectionMode)
                            Positioned(
                              left: 8,
                              top: 8,
                              child: Icon(
                                selected
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: selected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _emptyState() {
    if (widget.modul == 'favoriler' && _query.trim().isEmpty) {
      return const SJEmptyState(
        title: 'Henüz favori yok',
        message:
            'Analiz detayından yıldıza dokunarak favorilerinize ekleyebilirsiniz.',
        icon: Icons.star_border,
      );
    }
    return const SJEmptyState(
      title: 'Sonuç bulunamadı',
      message: 'Farklı bir poz no, kategori veya anahtar kelime deneyin.',
      icon: Icons.search_off,
    );
  }
}
