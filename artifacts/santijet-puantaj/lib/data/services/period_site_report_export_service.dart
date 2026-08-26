import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/constants/app_info.dart';
import 'period_site_report_builder.dart';
import 'report_file_access_stub.dart'
    if (dart.library.html) 'report_file_access_web.dart'
    if (dart.library.io) 'report_file_access_io.dart' as file_access;

/// Haftalık / aylık birleşik saha raporu — puantaj + imalat + verim.
class PeriodSiteReportExportService {
  pw.Font? _regularFont;
  pw.Font? _boldFont;

  static const _ink = PdfColor.fromInt(0xFF111827);
  static const _inkMuted = PdfColor.fromInt(0xFF6B7280);
  static const _headerBg = PdfColor.fromInt(0xFFE8F0FF);
  static const _border = PdfColor.fromInt(0xFFE5E7EB);

  Future<pw.ThemeData> _pdfTheme() async {
    _regularFont ??= await PdfGoogleFonts.notoSansRegular();
    _boldFont ??= await PdfGoogleFonts.notoSansBold();
    return pw.ThemeData.withFont(
      base: _regularFont!,
      bold: _boldFont!,
    );
  }

  Future<void> exportPdf(
    PeriodSiteReportData report, {
    required String projectName,
    String companyName = '',
  }) async {
    final bytes = await _buildPdfBytes(
      report,
      projectName: projectName,
      companyName: companyName,
    );
    await file_access.downloadBytesFile(
      fileName: 'santijet-${report.fileStem}.pdf',
      bytes: bytes,
      mimeType: 'application/pdf',
      shareText: '${report.periodLabel} saha raporu',
    );
  }

  Future<void> exportExcel(
    PeriodSiteReportData report, {
    required String projectName,
  }) async {
    final bytes = _buildExcelBytes(report, projectName: projectName);
    await file_access.downloadBytesFile(
      fileName: 'santijet-${report.fileStem}.xlsx',
      bytes: bytes,
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      shareText: '${report.periodLabel} saha raporu',
    );
  }

  Future<Uint8List> _buildPdfBytes(
    PeriodSiteReportData report, {
    required String projectName,
    required String companyName,
  }) async {
    final theme = await _pdfTheme();
    final doc = pw.Document(theme: theme);
    final now = DateTime.now();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(18),
        build: (context) => [
          pw.Text(
            '${report.periodLabel} Saha Raporu',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '$projectName · ${report.rangeLabel}',
            style: const pw.TextStyle(fontSize: 10, color: _inkMuted),
          ),
          if (companyName.isNotEmpty)
            pw.Text(
              companyName,
              style: const pw.TextStyle(fontSize: 9, color: _inkMuted),
            ),
          pw.Text(
            '${AppInfo.displayName} · ${now.day.toString().padLeft(2, '0')}.'
            '${now.month.toString().padLeft(2, '0')}.${now.year}',
            style: const pw.TextStyle(fontSize: 8, color: _inkMuted),
          ),
          pw.SizedBox(height: 12),
          _pdfSectionTitle('Personel puantajı'),
          pw.SizedBox(height: 6),
          _pdfTable(
            PeriodPersonelSummary.headers,
            report.personelSummary.exportRows,
          ),
          if (report.personelSummary.summaryLines.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            for (final line in report.personelSummary.summaryLines)
              pw.Text(
                line,
                style: const pw.TextStyle(fontSize: 8, color: _inkMuted),
              ),
          ],
          pw.SizedBox(height: 12),
          _pdfSectionTitle('Ekip puantajı'),
          pw.SizedBox(height: 6),
          _pdfTable(report.ekipPuantaj.headers, report.ekipPuantaj.rows),
          if (report.ekipPuantaj.summaryLines.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            for (final line in report.ekipPuantaj.summaryLines)
              pw.Text(
                line,
                style: const pw.TextStyle(fontSize: 8, color: _inkMuted),
              ),
          ],
          pw.SizedBox(height: 12),
          _pdfSectionTitle('Yapılan işler (İmalat)'),
          pw.SizedBox(height: 6),
          _pdfTable(
            const [
              'İmalat',
              'Konum',
              'Ekip',
              'Dönem',
              'Birim',
              'Adam-gün',
              'Kümülatif',
              'Plan',
              '%',
            ],
            [
              for (final r in report.imalatRows)
                [
                  r.name,
                  r.location,
                  r.teamName,
                  _fmt(r.periodQty),
                  r.unit,
                  _fmt(r.periodLaborDays),
                  _fmt(r.totalQty),
                  _fmt(r.plannedQty),
                  '${r.progressPct.toStringAsFixed(0)}%',
                ],
            ],
          ),
          pw.SizedBox(height: 12),
          _pdfSectionTitle('Verim'),
          pw.SizedBox(height: 6),
          _pdfTable(
            const [
              'İmalat',
              'Plan AG',
              'Dönem AG',
              'Plan metraj',
              'Dönem metraj',
              'Verim',
            ],
            [
              for (final r in report.verimRows)
                [
                  r.imalatName,
                  _fmt(r.plannedWorkerDays),
                  _fmt(r.periodActualWorkerDays),
                  r.plannedQty != null ? _fmt(r.plannedQty!) : '—',
                  _fmt(r.periodActualQty),
                  r.unitEfficiency != null
                      ? '%${(r.unitEfficiency! * 100).toStringAsFixed(0)}'
                      : '—',
                ],
            ],
          ),
        ],
      ),
    );

    return Uint8List.fromList(await doc.save());
  }

  pw.Widget _pdfSectionTitle(String text) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 11,
        fontWeight: pw.FontWeight.bold,
        color: _ink,
      ),
    );
  }

  pw.Widget _pdfTable(List<String> headers, List<List<String>> rows) {
    if (rows.isEmpty) {
      return pw.Text(
        'Kayıt yok',
        style: const pw.TextStyle(fontSize: 9, color: _inkMuted),
      );
    }
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 8,
        color: _ink,
      ),
      cellStyle: const pw.TextStyle(fontSize: 7, color: _ink),
      headerDecoration: const pw.BoxDecoration(color: _headerBg),
      border: pw.TableBorder.all(color: _border, width: 0.4),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.centerLeft,
    );
  }

  List<int> _buildExcelBytes(
    PeriodSiteReportData report, {
    required String projectName,
  }) {
    final excel = Excel.createExcel();
    excel.delete('Sheet1');

    _writeSheet(
      excel,
      'Özet',
      ['Alan', 'Değer'],
      [
        ['Proje', projectName],
        ['Dönem', report.periodLabel],
        ['Aralık', report.rangeLabel],
        ['İmalat kalemi', '${report.imalatRows.length}'],
        ['Verim satırı', '${report.verimRows.length}'],
        for (final line in report.personelSummary.summaryLines)
          ['Personel puantaj', line],
        for (final line in report.ekipPuantaj.summaryLines)
          ['Ekip puantaj', line],
      ],
    );
    _writeSheet(
      excel,
      'Personel',
      PeriodPersonelSummary.headers,
      report.personelSummary.exportRows,
    );
    _writeSheet(
      excel,
      'Ekip',
      report.ekipPuantaj.headers,
      report.ekipPuantaj.rows,
    );
    _writeSheet(
      excel,
      'İmalat',
      const [
        'İmalat',
        'Konum',
        'Ekip',
        'Dönem',
        'Birim',
        'Adam-gün',
        'Kümülatif',
        'Plan',
        '%',
      ],
      [
        for (final r in report.imalatRows)
          [
            r.name,
            r.location,
            r.teamName,
            _fmt(r.periodQty),
            r.unit,
            _fmt(r.periodLaborDays),
            _fmt(r.totalQty),
            _fmt(r.plannedQty),
            '${r.progressPct.toStringAsFixed(0)}%',
          ],
      ],
    );
    _writeSheet(
      excel,
      'Verim',
      const [
        'İmalat',
        'Plan AG',
        'Dönem AG',
        'Plan metraj',
        'Dönem metraj',
        'Verim',
      ],
      [
        for (final r in report.verimRows)
          [
            r.imalatName,
            _fmt(r.plannedWorkerDays),
            _fmt(r.periodActualWorkerDays),
            r.plannedQty != null ? _fmt(r.plannedQty!) : '—',
            _fmt(r.periodActualQty),
            r.unitEfficiency != null
                ? '%${(r.unitEfficiency! * 100).toStringAsFixed(0)}'
                : '—',
          ],
      ],
    );

    return excel.encode()!;
  }

  void _writeSheet(
    Excel excel,
    String name,
    List<String> headers,
    List<List<String>> rows,
  ) {
    final sheet = excel[name];
    for (var c = 0; c < headers.length; c++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0))
          .value = TextCellValue(headers[c]);
    }
    for (var r = 0; r < rows.length; r++) {
      for (var c = 0; c < rows[r].length; c++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1))
            .value = TextCellValue(rows[r][c]);
      }
    }
  }

  static String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }
}

final periodSiteReportExportService = PeriodSiteReportExportService();
