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
import '../../data/kasa_import_template_service.dart';
import '../../data/kasa_ocr_service.dart';
import '../../data/settings_store.dart';
import '../../domain/hareket_filters.dart';
import '../../domain/kasa_hareket.dart';
import '../../domain/kasa_import_format.dart';
import '../../domain/kasa_rules.dart';
import '../../domain/kasa_transfer_format.dart';
import '../../domain/money_format.dart';
import 'import_preview_screen.dart';

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
    String? rawHint,
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
    // OCR/Excel şantiye sütunu aktif seçimden farklı olabilir — önizlemede de
    // kaydedilecek hâli görünsün diye aktif şantiyeyi baştan yaz.
    final active = ref.read(activeSantiyeProvider).trim();
    final stamped = rows.map((h) => h.copyWith(santiye: active)).toList();

    final chosen = await Navigator.of(context).push<List<KasaHareket>>(
      MaterialPageRoute(
        builder: (_) => ImportPreviewScreen(
          title: title,
          hareketler: stamped,
          skipped: skipped,
          existing: ref.read(santiyeScopedHareketlerProvider),
          rawHint: rawHint,
        ),
      ),
    );
    if (chosen == null || chosen.isEmpty) return;
    await ref.read(hareketlerProvider.notifier).appendImported(chosen);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${chosen.length} satır $active şantiyesine eklendi.',
        ),
      ),
    );
  }

  Future<void> _showImportTemplateSheet() async {
    if (_busy) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: Text(
                'Örnek format indir',
                style: AppTypography.cardLabelMedium,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.table_chart_outlined),
              title: const Text('Excel şablonu (.xlsx)'),
              subtitle: const Text('Hatasız aktarım için önerilir'),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  await kasaImportTemplateService.shareExampleExcel();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Şablon indirilemedi: $e')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('Örnek tablo görseli (.jpg)'),
              subtitle: const Text('JPG/PDF OCR için referans tablo'),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  await kasaImportTemplateService.shareExampleJpg();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Görsel indirilemedi: $e')),
                  );
                }
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
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
      final santiye = ref.read(activeSantiyeProvider);

      if (format == KasaTransferFormat.excel) {
        final result = kasaImportService.parseExcelBytes(
          bytes,
          defaultSantiye: santiye,
        );
        await _confirmAndMerge(
          rows: result.hareketler,
          skipped: result.skipped,
          title: 'Excel içe aktar',
          rawHint: 'Mevcut hareketler silinmez; seçilenler üste eklenir.',
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
        setState(() => _status = 'JPG OCR (ön işleme)…');
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
                'OCR satır bulamadı — formu elle tamamlayın. '
                'Yoğun tablolar için Excel dosyası önerilir.',
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
          rawHint: ocr.usedOverlay
              ? 'Tablo hizalama kullanıldı. Satırları kontrol edin; hatalıları kaldırın.'
              : 'Metin satır parse kullanıldı. Tercihen Excel dosyası daha güvenilir.',
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
            content: Text(
              'OCR satır bulamadı — formu elle tamamlayın. '
              'Yoğun tablolar için Excel dosyası önerilir.',
            ),
          ),
        );
        context.push(AppRoutes.hareketForm);
        return;
      }
      await _confirmAndMerge(
        rows: ocr.hareketler,
        skipped: ocr.skipped,
        title: 'PDF OCR içe aktar',
        rawHint: ocr.usedOverlay
            ? 'Tablo hizalama kullanıldı. Satırları kontrol edin; hatalıları kaldırın.'
            : 'Metin satır parse kullanıldı. Tercihen Excel dosyası daha güvenilir.',
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
    final base = ref.watch(santiyeScopedHareketlerProvider);
    final scoped = filterHareketler(
      base,
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
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : _showImportTemplateSheet,
                      icon: const Icon(Icons.download_outlined, size: 20),
                      label: const Text('Örnek format indir'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    KasaImportFormat.userHint,
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
