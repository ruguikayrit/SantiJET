import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/sj_card.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/kasa_transfer_format_row.dart';
import '../../core/widgets/santijet_header.dart';
import '../../data/hareketler_store.dart';
import '../../data/import_draft_provider.dart';
import '../../data/kasa_export_service.dart';
import '../../data/kasa_import_service.dart';
import '../../data/kasa_ocr_service.dart';
import '../../data/settings_store.dart';
import '../../domain/hareket_filters.dart';
import '../../domain/kasa_hareket.dart';
import '../../domain/kasa_rules.dart';
import '../../domain/kasa_transfer_format.dart';
import '../../domain/money_format.dart';

/// Rapor — kırılım üstte; JPG/PDF/Excel içe·dışa aktar en altta.
class RaporScreen extends ConsumerStatefulWidget {
  const RaporScreen({super.key});

  @override
  ConsumerState<RaporScreen> createState() => _RaporScreenState();
}

class _RaporScreenState extends ConsumerState<RaporScreen> {
  DateTime? _from;
  DateTime? _to;
  bool _busy = false;
  String? _status;

  Future<void> _export(
    KasaTransferFormat format,
    List<KasaHareket> scoped,
  ) async {
    if (scoped.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      await kasaExportService.export(
        format,
        hareketler: scoped,
        from: _from,
        to: _to,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(format.successExport)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dışa aktarım başarısız: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmAndMerge({
    required List<KasaHareket> rows,
    required int skipped,
    required String title,
  }) async {
    if (rows.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            skipped > 0
                ? 'Geçerli satır yok ($skipped atlandı).'
                : 'Aktarılacak satır bulunamadı.',
          ),
        ),
      );
      return;
    }
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: Text(title, style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          '${rows.length} satır eklenecek'
          '${skipped > 0 ? ' ($skipped atlandı)' : ''}. '
          'Mevcut hareketler silinmez; üzerine eklenir.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final current = ref.read(hareketlerProvider);
      await ref
          .read(hareketlerProvider.notifier)
          .replaceAll([...rows, ...current]);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${rows.length} satır içe aktarıldı.')),
      );
    }
  }

  Future<void> _import(KasaTransferFormat format) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = format == KasaTransferFormat.excel
          ? 'Excel okunuyor…'
          : 'OCR ile okunuyor…';
    });
    try {
      final picked = await kasaImportService.pick(format);
      if (picked == null || picked.files.isEmpty) return;
      final file = picked.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        throw StateError('Dosya okunamadı.');
      }
      final santiye = ref.read(defaultSantiyeProvider);

      if (format == KasaTransferFormat.excel) {
        final result = kasaImportService.parseExcelBytes(
          bytes,
          defaultSantiye: santiye,
        );
        await _confirmAndMerge(
          rows: result.hareketler,
          skipped: result.skipped,
          title: 'Excel içe aktar',
        );
        return;
      }

      if (format == KasaTransferFormat.jpg) {
        final lower = file.name.toLowerCase();
        final mime = lower.endsWith('.png')
            ? 'image/png'
            : lower.endsWith('.webp')
                ? 'image/webp'
                : 'image/jpeg';
        setState(() => _status = 'JPG OCR…');
        final ocr = await KasaOcrService.importFromImage(
          bytes,
          mime: mime,
          defaultSantiye: santiye,
        );
        if (ocr.hareketler.isEmpty) {
          // Fallback: form taslağı
          final draft = kasaImportService.draftFromBelge(
            format: format,
            fileName: file.name,
          );
          ref.read(belgeImportDraftProvider.notifier).setDraft(draft);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'OCR satır bulamadı — formu elle tamamlayın.',
              ),
            ),
          );
          context.push(AppRoutes.hareketForm);
          return;
        }
        await _confirmAndMerge(
          rows: ocr.hareketler,
          skipped: ocr.skipped,
          title: 'JPG OCR içe aktar',
        );
        return;
      }

      // PDF
      setState(() => _status = 'PDF OCR…');
      final ocr = await KasaOcrService.importFromPdf(
        bytes,
        defaultSantiye: santiye,
      );
      if (ocr.hareketler.isEmpty) {
        final draft = kasaImportService.draftFromBelge(
          format: format,
          fileName: file.name,
        );
        ref.read(belgeImportDraftProvider.notifier).setDraft(draft);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OCR satır bulamadı — formu elle tamamlayın.'),
          ),
        );
        context.push(AppRoutes.hareketForm);
        return;
      }
      await _confirmAndMerge(
        rows: ocr.hareketler,
        skipped: ocr.skipped,
        title: 'PDF OCR içe aktar',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İçe aktarım başarısız: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _status = null;
        });
      }
    }
  }

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
                  const SizedBox(height: AppSpacing.xl),
                  KasaTransferFormatRow(
                    title: 'DIŞA AKTAR',
                    busy: _busy,
                    enabled: scoped.isNotEmpty,
                    onSelected: (f) => _export(f, scoped),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  KasaTransferFormatRow(
                    title: 'İÇERİ AKTAR',
                    busy: _busy,
                    onSelected: _import,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Excel: tablo satırları. JPG/PDF: OCR ile satır satır okunur '
                    've kasaya eklenir.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  if (_status != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _status!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.electricBlue,
                      ),
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
