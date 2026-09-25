import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/design_system/sj_button.dart';
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
import '../../domain/hareket_filters.dart';
import 'hareket_tile.dart';

enum _TransferMode { move, copy }

/// Hareket listesi — filtre / sıra + basılı tut seç → taşı/kopyala.
class HareketlerScreen extends ConsumerStatefulWidget {
  const HareketlerScreen({super.key});

  @override
  ConsumerState<HareketlerScreen> createState() => _HareketlerScreenState();
}

class _HareketlerScreenState extends ConsumerState<HareketlerScreen> {
  final Set<String> _selected = {};
  bool get _selecting => _selected.isNotEmpty;

  void _exitSelection() => setState(() => _selected.clear());

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  void _selectAll(List<String> ids) {
    setState(() {
      if (_selected.length == ids.length) {
        _selected.clear();
      } else {
        _selected
          ..clear()
          ..addAll(ids);
      }
    });
  }

  Future<void> _transfer(_TransferMode mode) async {
    if (_selected.isEmpty) return;
    final active = ref.read(activeSantiyeProvider).trim();
    final targets = ref
        .read(santiyelerProvider)
        .where((s) => s.trim().isNotEmpty && s.trim() != active)
        .toList();
    if (targets.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Başka şantiye yok. Ayarlar’dan şantiye ekleyin.',
          ),
        ),
      );
      return;
    }

    final target = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                mode == _TransferMode.move
                    ? 'Taşı — hedef şantiye'
                    : 'Kopyala — hedef şantiye',
                style: AppTypography.cardLabelMedium,
              ),
            ),
            ...targets.map(
              (s) => ListTile(
                leading: const Icon(Icons.apartment_outlined),
                title: Text(s),
                onTap: () => Navigator.pop(ctx, s),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (target == null || !mounted) return;

    final count = _selected.length;
    final verb = mode == _TransferMode.move ? 'taşımak' : 'kopyalamak';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: Text(
          mode == _TransferMode.move ? 'Taşı' : 'Kopyala',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          '$count hareketi «$target» şantiyesine $verb istiyor musunuz?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(mode == _TransferMode.move ? 'Taşı' : 'Kopyala'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final notifier = ref.read(hareketlerProvider.notifier);
    final done = mode == _TransferMode.move
        ? await notifier.moveToSantiye(
            ids: Set<String>.from(_selected),
            targetSantiye: target,
          )
        : await notifier.copyToSantiye(
            ids: Set<String>.from(_selected),
            targetSantiye: target,
            newId: const Uuid().v4,
          );

    if (!mounted) return;
    _exitSelection();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mode == _TransferMode.move
              ? '$done hareket «$target» şantiyesine taşındı.'
              : '$done hareket «$target» şantiyesine kopyalandı.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(hareketFiltersProvider);
    final filtered = ref.watch(filteredHareketlerProvider);
    final ids = filtered.map((h) => h.id).toList();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      floatingActionButton: _selecting
          ? null
          : FloatingActionButton(
              onPressed: () => context.push(AppRoutes.hareketForm),
              child: const Icon(Icons.add),
            ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SantijetHeader(
              subtitle: _selecting
                  ? '${_selected.length} seçili'
                  : 'Hareketler',
            ),
            if (!_selecting) ...[
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  children: [
                    _MenuChip(
                      label: 'Sıra',
                      selected: filters.hasCustomSort,
                      items: HareketSort.values.map((s) => s.label).toList(),
                      onSelected: (v) {
                        final match = HareketSort.values.firstWhere(
                          (s) => s.label == v,
                          orElse: () => HareketSort.tarihYeni,
                        );
                        ref
                            .read(hareketFiltersProvider.notifier)
                            .setSort(match);
                      },
                      onClear: () => ref
                          .read(hareketFiltersProvider.notifier)
                          .setSort(HareketSort.tarihYeni),
                    ),
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
                          ref
                              .read(hareketFiltersProvider.notifier)
                              .setDateRange(
                                from: range.start,
                                to: range.end,
                              );
                        }
                      },
                    ),
                    _Chip(
                      label: 'Temizle',
                      selected: false,
                      enabled:
                          !filters.isEmpty || filters.hasCustomSort,
                      onTap: () =>
                          ref.read(hareketFiltersProvider.notifier).clear(),
                    ),
                  ],
                ),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () => _selectAll(ids),
                      child: Text(
                        _selected.length == ids.length && ids.isNotEmpty
                            ? 'Hiçbiri'
                            : 'Tümü',
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _exitSelection,
                      child: const Text('İptal'),
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
                        120,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final h = filtered[index];
                        final isSelected = _selected.contains(h.id);
                        return Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: HareketTile(
                            hareket: h,
                            selected: isSelected,
                            onLongPress: () {
                              if (!_selecting) {
                                setState(() => _selected.add(h.id));
                              } else {
                                _toggle(h.id);
                              }
                            },
                            onTap: () {
                              if (_selecting) {
                                _toggle(h.id);
                              } else {
                                context.push(
                                  '${AppRoutes.hareketForm}?id=${h.id}',
                                );
                              }
                            },
                          ),
                        );
                      },
                    ),
            ),
            if (_selecting)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: SJButton(
                            label: 'Taşı',
                            variant: SJButtonVariant.secondary,
                            expanded: true,
                            icon: Icons.drive_file_move_outline,
                            onPressed: () => _transfer(_TransferMode.move),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: SJButton(
                            label: 'Kopyala',
                            expanded: true,
                            icon: Icons.copy_outlined,
                            onPressed: () => _transfer(_TransferMode.copy),
                          ),
                        ),
                      ],
                    ),
                  ),
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
    this.enabled = true,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        onSelected: enabled ? (_) => onTap() : null,
        selectedColor: AppColors.electricBlue.withValues(alpha: 0.2),
        labelStyle: AppTypography.labelMedium.copyWith(
          color: !enabled
              ? AppColors.textMuted
              : selected
                  ? AppColors.electricBlue
                  : AppColors.textSecondary,
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
        tooltip: label,
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
        child: AbsorbPointer(
          child: FilterChip(
            label: Text(
              label,
              overflow: TextOverflow.ellipsis,
            ),
            selected: selected,
            showCheckmark: false,
            onSelected: (_) {},
            selectedColor: AppColors.electricBlue.withValues(alpha: 0.2),
            labelStyle: AppTypography.labelMedium.copyWith(
              color:
                  selected ? AppColors.electricBlue : AppColors.textSecondary,
            ),
            side: BorderSide(
              color: selected ? AppColors.electricBlue : AppColors.border,
            ),
            backgroundColor: AppColors.surface,
          ),
        ),
      ),
    );
  }
}
