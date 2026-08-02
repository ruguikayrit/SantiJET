import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/design_system.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/analiz_list_item.dart';
import '../../core/widgets/metraj_input.dart';
import '../../data/providers/catalog_provider.dart';
import '../../domain/entities/poz_analiz.dart';

/// Katalogdan poz seçip miktar girerek keşife ekleme.
abstract final class KesifPozPickerSheet {
  static Future<({PozAnaliz analiz, double miktar})?> show(
    BuildContext context,
  ) {
    final parentTheme = Theme.of(context);
    final bg = AppColors.isSantijet
        ? AppColors.lightSurface
        : (parentTheme.cardTheme.color ?? parentTheme.colorScheme.surface);

    return showModalBottomSheet<({PozAnaliz analiz, double miktar})>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: bg,
      builder: (context) {
        final theme = AppColors.isSantijet
            ? parentTheme.copyWith(
                brightness: Brightness.light,
                colorScheme: const ColorScheme.light(
                  primary: AppColors.electricBlue,
                  onPrimary: Colors.white,
                  surface: AppColors.lightSurface,
                  onSurface: AppColors.lightTextPrimary,
                  onSurfaceVariant: AppColors.lightTextSecondary,
                ),
                textTheme: parentTheme.textTheme.apply(
                  bodyColor: AppColors.lightTextPrimary,
                  displayColor: AppColors.lightTextPrimary,
                ),
              )
            : parentTheme;
        return Theme(
          data: theme,
          child: const _KesifPozPickerSheet(),
        );
      },
    );
  }
}

class _KesifPozPickerSheet extends ConsumerStatefulWidget {
  const _KesifPozPickerSheet();

  @override
  ConsumerState<_KesifPozPickerSheet> createState() =>
      _KesifPozPickerSheetState();
}

class _KesifPozPickerSheetState extends ConsumerState<_KesifPozPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';
  PozAnaliz? _selected;
  double _miktar = 1;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catalogAsync = ref.watch(catalogProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.sm,
        bottom: AppSpacing.md + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Text(
            _selected == null ? 'Poz Seç' : 'Miktar Gir',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_selected == null) ...[
            SJSearchBar(
              controller: _searchController,
              hint: 'Poz no veya analiz ara...',
              onChanged: (v) => setState(() => _query = v),
              onClear: () {
                _searchController.clear();
                setState(() => _query = '');
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.5,
              child: catalogAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => SJEmptyState(
                  title: 'Katalog yüklenemedi',
                  message: '$e',
                  icon: Icons.error_outline,
                ),
                data: (catalog) {
                  final results = catalog.search(_query, limit: 40);
                  if (results.isEmpty) {
                    return const SJEmptyState(
                      title: 'Sonuç yok',
                      message: 'Farklı bir poz no deneyin.',
                      icon: Icons.search_off,
                    );
                  }
                  return ListView.separated(
                    itemCount: results.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.xs),
                    itemBuilder: (context, i) {
                      final a = results[i];
                      return AnalizListItem(
                        analiz: a,
                        onTap: () => setState(() => _selected = a),
                      );
                    },
                  );
                },
              ),
            ),
          ] else ...[
            AnalizListItem(analiz: _selected!),
            const SizedBox(height: AppSpacing.sm),
            MetrajInput(
              birimFiyati: _selected!.birimFiyati,
              olcuBirimi: _selected!.olcuBirimi,
              initialMiktar: _miktar,
              onChanged: (v) => _miktar = v,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: SJButton(
                    label: 'Geri',
                    variant: SJButtonVariant.secondary,
                    onPressed: () => setState(() => _selected = null),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: SJButton(
                    label: 'Ekle',
                    onPressed: () => Navigator.of(context).pop(
                      (analiz: _selected!, miktar: _miktar),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
