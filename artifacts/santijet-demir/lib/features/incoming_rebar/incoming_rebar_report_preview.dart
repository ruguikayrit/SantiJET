import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/data/services/export_service.dart';
import 'package:santijet_demir/features/incoming_rebar/incoming_rebar_tracking_report.dart';

const _reportTitle = 'Gelen Demir Takip Tablosu';

Future<void> openTrackingPdfPreview(
  BuildContext context,
  IncomingTrackingReport report,
) {
  return Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => TrackingPdfPreviewScreen(report: report),
    ),
  );
}

Future<void> openTrackingExcelPreview(
  BuildContext context,
  IncomingTrackingReport report,
) {
  return Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => TrackingExcelPreviewScreen(report: report),
    ),
  );
}

class TrackingPdfPreviewScreen extends StatefulWidget {
  const TrackingPdfPreviewScreen({super.key, required this.report});

  final IncomingTrackingReport report;

  @override
  State<TrackingPdfPreviewScreen> createState() =>
      _TrackingPdfPreviewScreenState();
}

class _TrackingPdfPreviewScreenState extends State<TrackingPdfPreviewScreen> {
  bool _colored = true;
  bool _landscape = true;
  bool _downloading = false;
  late Set<int> _selected;

  @override
  void initState() {
    super.initState();
    _selected = _allIndexes(widget.report.sections.length);
  }

  PdfPageFormat get _format =>
      _landscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4;

  List<PdfReportSection> get _sections => _picked(widget.report.sections, _selected);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12161C),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PreviewBar(
              title: 'PDF Önizleme',
              onClose: () => Navigator.pop(context),
              downloading: _downloading,
              onDownload: _downloadPdf,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _Choice(
                      label: 'Renkli',
                      selected: _colored,
                      onTap: () => setState(() => _colored = true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Choice(
                      label: 'Renksiz',
                      selected: !_colored,
                      onTap: () => setState(() => _colored = false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Choice(
                      label: 'Yatay',
                      selected: _landscape,
                      onTap: () => setState(() => _landscape = true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Choice(
                      label: 'Dikey',
                      selected: !_landscape,
                      onTap: () => setState(() => _landscape = false),
                    ),
                  ),
                ],
              ),
            ),
            _TableSelector(
              labels: [
                for (final section in widget.report.sections)
                  _sectionLabel(section),
              ],
              selected: _selected,
              onChanged: (selected) => setState(() => _selected = selected),
            ),
            Expanded(
              child: _sections.isEmpty
                  ? const _EmptySelection()
                  : PdfPreview(
                key: ValueKey('${_colored}_$_landscape${_selected.join(',')}'),
                build: _buildPdf,
                initialPageFormat: _format,
                pageFormats: {'A4': _format},
                allowPrinting: false,
                allowSharing: false,
                canChangePageFormat: false,
                canChangeOrientation: false,
                canDebug: false,
                useActions: false,
                dynamicLayout: false,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                scrollViewDecoration: const BoxDecoration(
                  color: Color(0xFF12161C),
                ),
                loadingWidget: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadPdf() async {
    if (_downloading) return;
    if (_sections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Çıktıya en az bir tablo ekleyin')),
      );
      return;
    }
    setState(() => _downloading = true);
    final messenger = ScaffoldMessenger.of(context);
    final origin = _shareOrigin(context);
    try {
      final bytes = await _buildPdf(_format);
      await exportService.sharePdfBytes(
        bytes: bytes,
        fileName: 'gelen-demir-takip.pdf',
        sharePositionOrigin: origin,
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('PDF indirilemedi: $error')),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<Uint8List> _buildPdf(PdfPageFormat format) async {
    final bytes = await exportService.buildMultiSectionPdfBytes(
      title: _reportTitle,
      sections: _sections,
      pageFormat: _format,
      colored: _colored,
    );
    return Uint8List.fromList(bytes);
  }
}

class TrackingExcelPreviewScreen extends StatefulWidget {
  const TrackingExcelPreviewScreen({super.key, required this.report});

  final IncomingTrackingReport report;

  @override
  State<TrackingExcelPreviewScreen> createState() =>
      _TrackingExcelPreviewScreenState();
}

class _TrackingExcelPreviewScreenState extends State<TrackingExcelPreviewScreen> {
  bool _downloading = false;
  late Set<int> _selected;

  @override
  void initState() {
    super.initState();
    _selected = _allIndexes(widget.report.sheets.length);
  }

  List<ExcelReportSheet> get _sheets => _picked(widget.report.sheets, _selected);

  Future<void> _downloadExcel() async {
    if (_downloading) return;
    if (_sheets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Çıktıya en az bir tablo ekleyin')),
      );
      return;
    }
    setState(() => _downloading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await exportService.shareExcelSheets(
        title: _reportTitle,
        sheets: _sheets,
        sharePositionOrigin: _shareOrigin(context),
        stacked: true,
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Excel indirilemedi: $error')),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12161C),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PreviewBar(
              title: 'Excel Önizleme',
              onClose: () => Navigator.pop(context),
              downloading: _downloading,
              onDownload: _downloadExcel,
            ),
            _TableSelector(
              labels: [for (final sheet in widget.report.sheets) sheet.title],
              selected: _selected,
              onChanged: (selected) => setState(() => _selected = selected),
            ),
            Expanded(
              child: _sheets.isEmpty
                  ? const _EmptySelection()
                  : ListView(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                children: [
                  for (final sheet in _sheets) ...[
                    Text(
                      sheet.title,
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _ExcelTable(sheet: sheet),
                    const SizedBox(height: 20),
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

class _ExcelTable extends StatelessWidget {
  const _ExcelTable({required this.sheet});

  final ExcelReportSheet sheet;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF1F4E79)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          border: TableBorder.all(color: const Color(0xFFD0D7E2), width: 0.6),
          children: [
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFF1F4E79)),
              children: [
                for (final header in sheet.headers)
                  _Cell(header, header: true, background: const Color(0xFF1F4E79)),
              ],
            ),
            for (var index = 0; index < sheet.rows.length; index++)
              TableRow(
                children: [
                  for (var column = 0; column < sheet.rows[index].length; column++)
                    _Cell(
                      sheet.rows[index][column],
                      strong: _isTotalRow(sheet.rows[index]) ||
                          _isTotalColumn(sheet.headers, column),
                      background: _cellFill(
                        sheet: sheet,
                        row: sheet.rows[index],
                        column: column,
                        rowIndex: index,
                      ),
                      tone: sheet.cellTones != null &&
                              index < sheet.cellTones!.length &&
                              column < sheet.cellTones![index].length
                          ? sheet.cellTones![index][column]
                          : 0,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

bool _isTotalRow(List<String> row) => row.isNotEmpty && row.first == 'TOPLAM';

bool _isTotalColumn(List<String> headers, int column) =>
    column < headers.length && headers[column] == 'TOPLAM';

Color? _cellFill({
  required ExcelReportSheet sheet,
  required List<String> row,
  required int column,
  required int rowIndex,
}) {
  if (!sheet.emphasizeTotals) return null;
  final totalRow = _isTotalRow(row);
  final totalColumn = _isTotalColumn(sheet.headers, column);
  if (totalRow && totalColumn) return const Color(0xFF9FC2E0);
  if (totalRow || totalColumn) return const Color(0xFFD6E6F5);
  if (rowIndex.isOdd) return const Color(0xFFF4F8FC);
  return null;
}

class _Cell extends StatelessWidget {
  const _Cell(
    this.text, {
    this.header = false,
    this.strong = false,
    this.tone = 0,
    this.background,
  });

  final String text;
  final bool header;
  final bool strong;
  final int tone;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final color = header
        ? Colors.white
        : switch (tone) {
            > 0 => const Color(0xFF15803D),
            < 0 => const Color(0xFFDC2626),
            _ => Colors.black,
          };
    return Container(
      color: background,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: header ? 11 : 12,
          fontWeight: header || strong || tone != 0
              ? FontWeight.w700
              : FontWeight.w500,
        ),
      ),
    );
  }
}

class _PreviewBar extends StatelessWidget {
  const _PreviewBar({
    required this.title,
    required this.onClose,
    required this.onDownload,
    required this.downloading,
  });

  final String title;
  final VoidCallback onClose;
  final VoidCallback onDownload;
  final bool downloading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, color: Colors.white),
          ),
          Expanded(
            child: Text(
              title,
              style: AppTypography.titleLarge.copyWith(color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: downloading
                        ? const [Color(0xFF86EFAC), Color(0xFF4ADE80)]
                        : const [Color(0xFF4ADE80), Color(0xFF15803D)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: InkWell(
                  onTap: downloading ? null : onDownload,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        downloading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.download_outlined,
                                size: 20,
                                color: Colors.white,
                              ),
                        const SizedBox(width: 6),
                        const Text(
                          'İndir',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Rect _shareOrigin(BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize) {
    return const Rect.fromLTWH(8, 8, 48, 48);
  }
  return box.localToGlobal(Offset.zero) & box.size;
}

Set<int> _allIndexes(int length) => {for (var index = 0; index < length; index++) index};

List<T> _picked<T>(List<T> items, Set<int> selected) => [
      for (var index = 0; index < items.length; index++)
        if (selected.contains(index)) items[index],
    ];

String _sectionLabel(PdfReportSection section) {
  final subtitle = section.subtitle;
  if (subtitle == null || subtitle.isEmpty) return section.title;
  return '${section.title} · $subtitle';
}

class _EmptySelection extends StatelessWidget {
  const _EmptySelection();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Çıktıya en az bir tablo ekleyin',
        style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
      ),
    );
  }
}

class _TableSelector extends StatelessWidget {
  const _TableSelector({
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  final List<String> labels;
  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    final allSelected = labels.isNotEmpty && selected.length == labels.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: SizedBox(
        height: 44,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _Choice(
              label: 'Tümü',
              selected: allSelected,
              onTap: () => onChanged(allSelected ? {} : _allIndexes(labels.length)),
            ),
            for (var index = 0; index < labels.length; index++) ...[
              const SizedBox(width: 8),
              _Choice(
                label: labels[index],
                selected: selected.contains(index),
                onTap: () {
                  final next = {...selected};
                  if (!next.add(index)) next.remove(index);
                  onChanged(next);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Material(
      color: selected ? AppColors.electricBlueLight : const Color(0xFF1C2430),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTypography.labelMedium.copyWith(
                color: selected ? Colors.black : Colors.white,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}
