import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/design_system.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_format.dart';
import '../../data/providers/catalog_provider.dart';
import '../../domain/enums/app_enums.dart';

/// Disipline göre kategori indeksi — RN `analiz-katalogu` karşılığı.
class AnalizKatalogScreen extends ConsumerStatefulWidget {
  const AnalizKatalogScreen({super.key});

  @override
  ConsumerState<AnalizKatalogScreen> createState() =>
      _AnalizKatalogScreenState();
}

class _AnalizKatalogScreenState extends ConsumerState<AnalizKatalogScreen> {
  AnalizDiscipline _discipline = AnalizDiscipline.insaat;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(catalogProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Analiz Kataloğu')),
      body: SafeArea(
        top: false,
        child: catalogAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => SJEmptyState(
            title: 'Katalog yüklenemedi',
            message: '$e',
            icon: Icons.error_outline,
          ),
          data: (catalog) {
            final categories = catalog.categoriesForDiscipline(_discipline);
            final filtered = _query.trim().isEmpty
                ? categories
                : categories
                    .where((c) => c.toLowerCase().contains(_query.toLowerCase()))
                    .toList();

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
                    hint: 'Kategori ara...',
                    onChanged: (v) => setState(() => _query = v),
                    onClear: () => setState(() => _query = ''),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: SJFilterChips(
                    labels: const ['İnşaat', 'Mekanik', 'Elektrik'],
                    selectedIndex: _discipline.index,
                    onSelected: (i) => setState(
                      () => _discipline = AnalizDiscipline.values[i],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${AppFormat.integer(filtered.length)} kategori',
                      style: theme.textTheme.labelMedium,
                    ),
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? const SJEmptyState(
                          title: 'Kategori bulunamadı',
                          message: 'Farklı bir arama deneyin.',
                          icon: Icons.search_off,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.xs),
                          itemBuilder: (context, i) {
                            final cat = filtered[i];
                            final count = catalog
                                .forDiscipline(_discipline)
                                .where((a) => a.kategori.trim() == cat)
                                .length;
                            return SJListItem(
                              title: cat,
                              subtitle: '$count analiz',
                              leadingIcon: Icons.folder_outlined,
                              trailingText: AppFormat.integer(count),
                              onTap: () => context.push(
                                '${AppRoutes.pozlar}?modul=${_discipline.jsonValue}&cat=${Uri.encodeComponent(cat)}',
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
