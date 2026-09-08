import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/sj_empty_state.dart';
import '../../core/design_system/sj_search_bar.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/santijet_header.dart';
import '../../data/filters_provider.dart';
import '../../data/hareketler_store.dart';
import '../../data/settings_store.dart';
import '../../domain/kasa_lookups.dart';
import 'hareket_tile.dart';

/// Hareket listesi — filtre chip’leri + arama.
class HareketlerScreen extends ConsumerWidget {
  const HareketlerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(hareketFiltersProvider);
    final filtered = ref.watch(filteredHareketlerProvider);
    final all = ref.watch(hareketlerProvider);
    final santiyeler = ref.watch(santiyelerProvider);
    final tedarikciler = all
        .map((h) => h.tedarikci.trim())
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.hareketForm),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SantijetHeader(subtitle: 'Hareketler'),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                0,
              ),
              child: SJSearchBar(
                hint: 'Tedarikçi, açıklama…',
                onChanged: (q) =>
                    ref.read(hareketFiltersProvider.notifier).setQuery(q),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                children: [
                  _Chip(
                    label: 'Gelir',
                    selected: filters.onlyGelir,
                    onTap: () => ref
                        .read(hareketFiltersProvider.notifier)
                        .setOnlyGelir(!filters.onlyGelir),
                  ),
                  _Chip(
                    label: 'Gider',
                    selected: filters.onlyGider,
                    onTap: () => ref
                        .read(hareketFiltersProvider.notifier)
                        .setOnlyGider(!filters.onlyGider),
                  ),
                  _MenuChip(
                    label: filters.santiye ?? 'Şantiye',
                    selected: filters.santiye != null,
                    items: santiyeler,
                    onSelected: (v) => ref
                        .read(hareketFiltersProvider.notifier)
                        .setSantiye(v),
                    onClear: () => ref
                        .read(hareketFiltersProvider.notifier)
                        .setSantiye(null),
                  ),
                  _MenuChip(
                    label: filters.odemeSekli ?? 'Ödeme',
                    selected: filters.odemeSekli != null,
                    items: OdemeSekli.all,
                    onSelected: (v) => ref
                        .read(hareketFiltersProvider.notifier)
                        .setOdemeSekli(v),
                    onClear: () => ref
                        .read(hareketFiltersProvider.notifier)
                        .setOdemeSekli(null),
                  ),
                  _MenuChip(
                    label: filters.belgeTuru ?? 'Belge',
                    selected: filters.belgeTuru != null,
                    items: BelgeTuru.all,
                    onSelected: (v) => ref
                        .read(hareketFiltersProvider.notifier)
                        .setBelgeTuru(v),
                    onClear: () => ref
                        .read(hareketFiltersProvider.notifier)
                        .setBelgeTuru(null),
                  ),
                  if (tedarikciler.isNotEmpty)
                    _MenuChip(
                      label: filters.tedarikci ?? 'Tedarikçi',
                      selected: filters.tedarikci != null,
                      items: tedarikciler,
                      onSelected: (v) => ref
                          .read(hareketFiltersProvider.notifier)
                          .setTedarikci(v),
                      onClear: () => ref
                          .read(hareketFiltersProvider.notifier)
                          .setTedarikci(null),
                    ),
                  _Chip(
                    label: 'Tarih',
                    selected: filters.from != null || filters.to != null,
                    onTap: () async {
                      final range = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                        initialDateRange: filters.from != null
                            ? DateTimeRange(
                                start: filters.from!,
                                end: filters.to ?? filters.from!,
                              )
                            : null,
                      );
                      if (range != null) {
                        ref.read(hareketFiltersProvider.notifier).setDateRange(
                              from: range.start,
                              to: range.end,
                            );
                      }
                    },
                  ),
                  if (!filters.isEmpty)
                    _Chip(
                      label: 'Temizle',
                      selected: false,
                      onTap: () =>
                          ref.read(hareketFiltersProvider.notifier).clear(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: filtered.isEmpty
                  ? const SJEmptyState(
                      icon: Icons.filter_alt_off_outlined,
                      title: 'Sonuç yok',
                      message: 'Filtreleri gevşetin veya hareket ekleyin.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        0,
                        AppSpacing.md,
                        100,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final h = filtered[index];
                        return Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: HareketTile(
                            hareket: h,
                            onTap: () => context.push(
                              '${AppRoutes.hareketForm}?id=${h.id}',
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.electricBlue.withValues(alpha: 0.2),
        checkmarkColor: AppColors.electricBlue,
        labelStyle: AppTypography.labelMedium.copyWith(
          color: selected ? AppColors.electricBlue : AppColors.textSecondary,
        ),
        side: BorderSide(
          color: selected ? AppColors.electricBlue : AppColors.border,
        ),
        backgroundColor: AppColors.surface,
      ),
    );
  }
}

class _MenuChip extends StatelessWidget {
  const _MenuChip({
    required this.label,
    required this.selected,
    required this.items,
    required this.onSelected,
    required this.onClear,
  });

  final String label;
  final bool selected;
  final List<String> items;
  final ValueChanged<String> onSelected;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<String>(
        onSelected: (v) {
          if (v == '__clear__') {
            onClear();
          } else {
            onSelected(v);
          }
        },
        itemBuilder: (context) => [
          if (selected)
            const PopupMenuItem(value: '__clear__', child: Text('Temizle')),
          ...items.map((e) => PopupMenuItem(value: e, child: Text(e))),
        ],
        child: FilterChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) {},
          selectedColor: AppColors.electricBlue.withValues(alpha: 0.2),
          checkmarkColor: AppColors.electricBlue,
          labelStyle: AppTypography.labelMedium.copyWith(
            color: selected ? AppColors.electricBlue : AppColors.textSecondary,
          ),
          side: BorderSide(
            color: selected ? AppColors.electricBlue : AppColors.border,
          ),
          backgroundColor: AppColors.surface,
        ),
      ),
    );
  }
}
