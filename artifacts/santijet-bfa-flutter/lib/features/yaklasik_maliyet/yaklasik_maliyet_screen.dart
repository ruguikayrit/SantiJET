import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/design_system.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_format.dart';
import '../../core/widgets/santijet_header.dart';
import '../../data/providers/kesif_provider.dart';
import '../../data/services/kesif_export_service.dart';
import '../../domain/entities/kesif.dart';
import '../../domain/enums/app_enums.dart';
import '../export/export_format_sheet.dart';
import '../kesif/widgets/discipline_section_header.dart';

/// Yaklaşık Maliyet — birim fiyatlar + tutar özeti (3 ana başlık).
class YaklasikMaliyetScreen extends ConsumerStatefulWidget {
  const YaklasikMaliyetScreen({super.key});

  @override
  ConsumerState<YaklasikMaliyetScreen> createState() =>
      _YaklasikMaliyetScreenState();
}

class _YaklasikMaliyetScreenState extends ConsumerState<YaklasikMaliyetScreen> {
  final Set<AnalizDiscipline> _collapsed = {};

  Future<void> _export(KesifProject kesif) async {
    final format = await ExportFormatSheet.pick(context);
    if (format == null || !mounted) return;
    if (format == ExportFormat.pdf) {
      await kesifExportService.sharePdf(
        kesif,
        title: KesifExportService.yaklasikMaliyetPdfTitle,
        filenamePrefix: 'yaklasik_maliyet',
        includeFiyat: true,
      );
    } else {
      await kesifExportService.shareExcel(kesif);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kesif = ref.watch(activeKesifProvider);
    final theme = Theme.of(context);

    if (kesif == null) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SantijetHeader(subtitle: 'Yaklaşık Maliyet'),
              Expanded(
                child: SJEmptyState(
                  title: 'Aktif proje yok',
                  message:
                      'Yaklaşık maliyet için Projelerim’den bir proje seçin.',
                  icon: Icons.account_balance_wallet_outlined,
                  actionLabel: 'Projelerim',
                  onAction: () => context.push(AppRoutes.projeler),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final byDisc = kesif.satirlarByDiscipline;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SantijetHeader(
                subtitle: 'Yaklaşık Maliyet',
                actions: [
                  IconButton(
                    tooltip: 'Dışa Aktar',
                    onPressed: () => _export(kesif),
                    icon: const Icon(Icons.download_outlined),
                  ),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.md),
              sliver: SliverList.list(
                children: [
                  Text(
                    kesif.ad,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SJStatCard(
                    label: 'Genel Toplam',
                    value: AppFormat.currency(kesif.toplam),
                    unit: '',
                    accentColor: AppColors.moduleKesif,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Yaklaşık Maliyet Listesi',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (kesif.satirlar.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: SJCard(
                        child: Text(
                          'Keşif listesinde poz yok. Poz ekledikçe satırlar burada listelenir.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.cardTextMuted,
                          ),
                        ),
                      ),
                    )
                  else
                    for (final d in AnalizDiscipline.kesifSirasi) ...[
                      if ((byDisc[d] ?? const []).isNotEmpty) ...[
                        DisciplineSectionHeader(
                          discipline: d,
                          count: byDisc[d]!.length,
                          expanded: !_collapsed.contains(d),
                          onToggle: () {
                            setState(() {
                              if (_collapsed.contains(d)) {
                                _collapsed.remove(d);
                              } else {
                                _collapsed.add(d);
                              }
                            });
                          },
                          trailing: Text(
                            AppFormat.currency(
                              byDisc[d]!
                                  .fold<double>(0, (s, r) => s + r.tutar),
                            ),
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: AppColors.moduleKesif,
                            ),
                          ),
                        ),
                        if (!_collapsed.contains(d))
                          for (final satir in byDisc[d]!) ...[
                            _FiyatSatirCard(
                              projectId: kesif.id,
                              satir: satir,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                          ],
                      ],
                    ],
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FiyatSatirCard extends ConsumerStatefulWidget {
  const _FiyatSatirCard({required this.projectId, required this.satir});

  final String projectId;
  final KesifSatiri satir;

  @override
  ConsumerState<_FiyatSatirCard> createState() => _FiyatSatirCardState();
}

class _FiyatSatirCardState extends ConsumerState<_FiyatSatirCard> {
  /// ~8 basamak + TR binlik/ondalık (ör. 12.345.678,90).
  static const _bfFieldWidth = 118.0;

  late final TextEditingController _bfController;

  @override
  void initState() {
    super.initState();
    _bfController = TextEditingController(
      text: AppFormat.decimal(widget.satir.birimFiyati, fractionDigits: 2),
    );
  }

  @override
  void didUpdateWidget(covariant _FiyatSatirCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.satir.birimFiyati != widget.satir.birimFiyati) {
      final next =
          AppFormat.decimal(widget.satir.birimFiyati, fractionDigits: 2);
      if (_bfController.text != next) {
        _bfController.text = next;
      }
    }
  }

  @override
  void dispose() {
    _bfController.dispose();
    super.dispose();
  }

  void _commitBirimFiyat() {
    final raw = _bfController.text
        .replaceAll('₺', '')
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    final value = double.tryParse(raw) ?? 0;
    ref.read(kesifProvider.notifier).updateBirimFiyat(
          widget.projectId,
          widget.satir.id,
          value,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final satir = widget.satir;
    final metraj = satir.hesaplananMetraj;
    final birim =
        satir.olcuBirimi.trim().isEmpty ? 'ad' : satir.olcuBirimi.trim();

    return SJCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            satir.pozNo,
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.moduleKesif,
            ),
          ),
          Text(
            satir.analizAdi,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.cardTextPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              SizedBox(
                width: _bfFieldWidth,
                child: TextField(
                  controller: _bfController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.right,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.cardTextPrimary,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'B.F.',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                  ),
                  onEditingComplete: _commitBirimFiyat,
                  onSubmitted: (_) => _commitBirimFiyat(),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '₺/$birim',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.cardTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _MetricLine(
            label: 'Metraj',
            value: '${AppFormat.decimal(metraj)} $birim',
          ),
          const SizedBox(height: 4),
          _MetricLine(
            label: 'Tutar',
            value: AppFormat.currency(satir.tutar),
            emphasize: true,
          ),
          const SizedBox(height: 4),
          Text(
            satir.fiyatKaynagi.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.cardTextMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricLine extends StatelessWidget {
  const _MetricLine({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppColors.cardTextMuted,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            value,
            style: emphasize
                ? theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.cardTextPrimary,
                    fontWeight: FontWeight.w700,
                  )
                : theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.cardTextSecondary,
                  ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
