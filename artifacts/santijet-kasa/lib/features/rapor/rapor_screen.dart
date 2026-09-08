import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/sj_card.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/santijet_header.dart';
import '../../data/hareketler_store.dart';
import '../../domain/csv_export.dart';
import '../../domain/hareket_filters.dart';
import '../../domain/kasa_rules.dart';
import '../../domain/money_format.dart';

/// Rapor — kırılım + CSV dışa aktar.
class RaporScreen extends ConsumerStatefulWidget {
  const RaporScreen({super.key});

  @override
  ConsumerState<RaporScreen> createState() => _RaporScreenState();
}

class _RaporScreenState extends ConsumerState<RaporScreen> {
  DateTime? _from;
  DateTime? _to;

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(hareketlerProvider);
    final scoped = filterHareketler(
      all,
      HareketFilters(from: _from, to: _to),
    );
    final ozet = hesaplaOzet(scoped);

    final giderSantiye = breakdownBy(scoped, (h) => h.santiye, gider: true);
    final giderOdeme = breakdownBy(scoped, (h) => h.odemeSekli, gider: true);
    final giderBelge = breakdownBy(scoped, (h) => h.belgeTuru, gider: true);
    final gelirSantiye = breakdownBy(scoped, (h) => h.santiye, gider: false);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SantijetHeader(subtitle: 'Rapor'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  40,
                ),
                children: [
                  SJCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tarih aralığı',
                          style: AppTypography.cardLabelMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  final range = await showDateRangePicker(
                                    context: context,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2035),
                                    initialDateRange: _from != null
                                        ? DateTimeRange(
                                            start: _from!,
                                            end: _to ?? _from!,
                                          )
                                        : null,
                                  );
                                  if (range != null) {
                                    setState(() {
                                      _from = range.start;
                                      _to = range.end;
                                    });
                                  }
                                },
                                child: Text(
                                  _from == null
                                      ? 'Tüm zamanlar'
                                      : '${_from!.day}.${_from!.month}.${_from!.year} – ${_to!.day}.${_to!.month}.${_to!.year}',
                                ),
                              ),
                            ),
                            if (_from != null) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () => setState(() {
                                  _from = null;
                                  _to = null;
                                }),
                                icon: const Icon(Icons.clear),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _MiniOzet(
                          gelir: ozet.toplamGelir,
                          gider: ozet.toplamGider,
                          kasa: ozet.guncelKasa,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton.icon(
                    onPressed: scoped.isEmpty
                        ? null
                        : () async {
                            final csv = CsvExport.hareketlerToCsv(scoped);
                            await Clipboard.setData(ClipboardData(text: csv));
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'CSV panoya kopyalandı (Excel’e yapıştırın).',
                                ),
                              ),
                            );
                          },
                    icon: const Icon(Icons.file_download_outlined),
                    label: const Text('CSV dışa aktar'),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (scoped.isEmpty)
                    const SJEmptyState(
                      icon: Icons.insights_outlined,
                      title: 'Raporlanacak hareket yok',
                      message:
                          'Tarih aralığını değiştirin veya hareket ekleyin.',
                    )
                  else ...[
                    _Section(
                      title: 'Gider · Şantiye',
                      rows: giderSantiye,
                    ),
                    _Section(
                      title: 'Gider · Ödeme şekli',
                      rows: giderOdeme,
                    ),
                    _Section(
                      title: 'Gider · Belge türü',
                      rows: giderBelge,
                    ),
                    _Section(
                      title: 'Gelir · Şantiye',
                      rows: gelirSantiye,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniOzet extends StatelessWidget {
  const _MiniOzet({
    required this.gelir,
    required this.gider,
    required this.kasa,
  });

  final double gelir;
  final double gider;
  final double kasa;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _row('Gelir', MoneyFormat.format(gelir), AppColors.electricBlue),
        _row('Gider', MoneyFormat.format(gider), AppColors.critical),
        _row(
          'Güncel kasa',
          MoneyFormat.formatSigned(kasa),
          kasa < 0 ? AppColors.critical : AppColors.success,
        ),
      ],
    );
  }

  Widget _row(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(label, style: AppTypography.cardBodyMedium),
          const Spacer(),
          Text(
            value,
            style: AppTypography.cardTitleMedium.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows});

  final String title;
  final List<BreakdownRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: SJCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.cardLabelMedium),
            const SizedBox(height: AppSpacing.sm),
            ...rows.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(r.label, style: AppTypography.cardBodyMedium),
                    ),
                    Text(
                      MoneyFormat.format(r.amount),
                      style: AppTypography.cardTitleMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
