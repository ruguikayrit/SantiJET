import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/design_system.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_format.dart';
import '../../core/widgets/analiz_list_item.dart';
import '../../data/providers/catalog_provider.dart';
import '../../domain/calc/analiz_compare.dart';
import '../../domain/entities/poz_analiz.dart';
import '../../domain/enums/app_enums.dart';

/// Analiz karşılaştırma
class KarsilastirScreen extends ConsumerStatefulWidget {
  const KarsilastirScreen({this.initialIds = const [], super.key});

  final List<String> initialIds;

  @override
  ConsumerState<KarsilastirScreen> createState() => _KarsilastirScreenState();
}

class _KarsilastirScreenState extends ConsumerState<KarsilastirScreen> {
  final _searchController = TextEditingController();
  final _selectedIds = <String>[];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selectedIds.addAll(widget.initialIds);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggle(PozAnaliz analiz) {
    setState(() {
      if (_selectedIds.contains(analiz.id)) {
        _selectedIds.remove(analiz.id);
      } else {
        _selectedIds.add(analiz.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(catalogProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Karşılaştırma'),
        actions: [
          if (_selectedIds.length >= 2)
            TextButton(
              onPressed: () => setState(_selectedIds.clear),
              child: const Text('Temizle'),
            ),
        ],
      ),
      body: catalogAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => SJEmptyState(
          title: 'Katalog yüklenemedi',
          message: '$e',
          icon: Icons.error_outline,
        ),
        data: (catalog) {
          final selected = _selectedIds
              .map(catalog.byIdOrNull)
              .whereType<PozAnaliz>()
              .toList();
          final compare =
              selected.length >= 2 ? buildAnalizCompare(selected) : null;
          final results = _query.trim().isEmpty
              ? const <PozAnaliz>[]
              : catalog.search(_query, limit: 40);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  hint: 'Karşılaştırmaya analiz ekle...',
                  onChanged: (v) => setState(() => _query = v),
                  onClear: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                ),
              ),
              if (_selectedIds.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final a in selected)
                        InputChip(
                          label: Text(a.pozNo),
                          onDeleted: () => _toggle(a),
                        ),
                    ],
                  ),
                ),
              if (_query.trim().isNotEmpty)
                Expanded(
                  flex: 2,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: results.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.xs),
                    itemBuilder: (context, i) {
                      final analiz = results[i];
                      final selectedNow = _selectedIds.contains(analiz.id);
                      return Stack(
                        children: [
                          AnalizListItem(
                            analiz: analiz,
                            onTap: () => _toggle(analiz),
                          ),
                          if (selectedNow)
                            const Positioned(
                              right: 8,
                              top: 8,
                              child: Icon(
                                Icons.check_circle,
                                color: AppColors.electricBlue,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                )
              else if (compare == null)
                Expanded(
                  child: SJEmptyState(
                    title: 'Analiz seçin',
                    message:
                        'Karşılaştırma için en az 2 analiz seçin. Arama kutusundan poz ekleyin.',
                    icon: Icons.compare_arrows,
                  ),
                ),
              if (compare != null)
                Expanded(
                  flex: 5,
                  child: _CompareBody(compare: compare),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CompareBody extends StatelessWidget {
  const _CompareBody({required this.compare});

  final AnalizCompareResult compare;

  static const _colMin = 140.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SJCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Birim Fiyat Özeti',
                      style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
                  _summaryHeader(theme),
                  _summaryRow(
                    theme,
                    'Malzeme + İşçilik',
                    (a) => a.malzemeIscilikToplami,
                  ),
                  _summaryRow(
                    theme,
                    'Yüklenici Karı',
                    (a) => a.yukleniciKarTutari,
                  ),
                  _summaryRow(
                    theme,
                    '1 Birim Fiyatı',
                    (a) => a.birimFiyati,
                    highlight: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SJCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kalem Karşılaştırması',
                      style: theme.textTheme.titleLarge),
                  Text(
                    'Yeşil: en düşük tutar · Kırmızı: en yüksek tutar',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _kalemHeader(theme),
                  for (final row in compare.kalemRows) _kalemRow(theme, row),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryHeader(ThemeData theme) {
    return Row(
      children: [
        SizedBox(
          width: 180,
          child: Text('Analiz', style: theme.textTheme.labelMedium),
        ),
        for (final a in compare.analizler)
          SizedBox(
            width: _colMin,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.pozNo,
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: AppColors.electricBlue)),
                Text(a.analizAdi,
                    style: theme.textTheme.bodySmall, maxLines: 2),
              ],
            ),
          ),
      ],
    );
  }

  Widget _summaryRow(
    ThemeData theme,
    String label,
    double Function(AnalizCompareSummary) pick, {
    bool highlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 180,
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          for (final a in compare.analizler)
            Builder(
              builder: (context) {
                final val = pick(a);
                final isMin = highlight &&
                    val == compare.minBirimFiyati &&
                    compare.analizler.length > 1;
                final isMax = highlight &&
                    val == compare.maxBirimFiyati &&
                    compare.analizler.length > 1;
                final bg = isMin
                    ? const Color(0x18059669)
                    : isMax
                        ? const Color(0x18DC2626)
                        : Colors.transparent;
                return Container(
                  width: _colMin,
                  padding: const EdgeInsets.all(6),
                  color: bg,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${AppFormat.decimal(val)} TL',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: highlight ? AppColors.electricBlue : null,
                        ),
                      ),
                      if (highlight)
                        Text('/ ${a.olcuBirimi}',
                            style: theme.textTheme.labelSmall),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _kalemHeader(ThemeData theme) {
    return Row(
      children: [
        SizedBox(width: 72, child: Text('Tip', style: theme.textTheme.labelMedium)),
        SizedBox(width: 88, child: Text('Poz', style: theme.textTheme.labelMedium)),
        SizedBox(width: 160, child: Text('Tanım', style: theme.textTheme.labelMedium)),
        for (final a in compare.analizler)
          SizedBox(
            width: _colMin,
            child: Text(
              a.pozNo,
              style: theme.textTheme.labelMedium,
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _kalemRow(ThemeData theme, CompareKalemRow row) {
    final amounts = compare.analizler
        .map((a) => row.values[a.id]?.tutar)
        .whereType<double>()
        .toList();
    final min = amounts.isEmpty ? null : amounts.reduce((a, b) => a < b ? a : b);
    final max = amounts.isEmpty ? null : amounts.reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(_tipLabel(row.tip), style: theme.textTheme.bodySmall),
          ),
          SizedBox(
            width: 88,
            child: Text(row.pozNo, style: theme.textTheme.bodySmall),
          ),
          SizedBox(
            width: 160,
            child: Text(row.tanim, style: theme.textTheme.bodySmall, maxLines: 2),
          ),
          for (final a in compare.analizler)
            Builder(
              builder: (context) {
                final val = row.values[a.id];
                final tutar = val?.tutar;
                final bg = tutar != null && min != null && max != null
                    ? tutar == min
                        ? const Color(0x18059669)
                        : tutar == max
                            ? const Color(0x18DC2626)
                            : Colors.transparent
                    : Colors.transparent;
                return Container(
                  width: _colMin,
                  padding: const EdgeInsets.all(4),
                  color: bg,
                  child: val == null
                      ? Text('—', style: theme.textTheme.bodySmall)
                      : Column(
                          children: [
                            Text(
                              AppFormat.decimal(val.tutar),
                              style: theme.textTheme.bodySmall,
                            ),
                            Text(
                              '${AppFormat.decimal(val.miktar)} ${row.olcuBirimi}',
                              style: theme.textTheme.labelSmall,
                            ),
                          ],
                        ),
                );
              },
            ),
        ],
      ),
    );
  }

  String _tipLabel(AnalizKalemTip tip) => switch (tip) {
        AnalizKalemTip.malzeme => 'Malzeme',
        AnalizKalemTip.iscilik => 'İşçilik',
        AnalizKalemTip.ekipman => 'Ekipman',
      };
}
