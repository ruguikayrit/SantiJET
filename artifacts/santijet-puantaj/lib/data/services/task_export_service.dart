import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'report_file_access_stub.dart'
    if (dart.library.html) 'report_file_access_web.dart'
    if (dart.library.io) 'report_file_access_io.dart' as file_access;
import 'task_report_builder.dart';

/// Saha görevlerini PDF / Excel olarak üretir ve paylaşır.
class TaskExportService {
  pw.Font? _regularFont;
  pw.Font? _boldFont;

  static const _ink = PdfColor.fromInt(0xFF111827);
  static const _inkMuted = PdfColor.fromInt(0xFF6B7280);
  static const _headerBg = PdfColor.fromInt(0xFFE8F0FF);
  static const _border = PdfColor.fromInt(0xFFE5E7EB);
  static const _blue = PdfColor.fromInt(0xFF0055FF);

  Future<pw.ThemeData> _pdfTheme() async {
    _regularFont ??= await PdfGoogleFonts.notoSansRegular();
    _boldFont ??= await PdfGoogleFonts.notoSansBold();
    return pw.ThemeData.withFont(
      base: _regularFont!,
      bold: _boldFont!,
    );
  }

  Future<void> exportPdf(TaskReportData report) async {
    final bytes = await _buildPdfBytes(report);
    await file_access.downloadBytesFile(
      fileName: 'santijet-${report.fileStem}.pdf',
      bytes: bytes,
      mimeType: 'application/pdf',
      shareText: report.title,
    );
  }

  Future<void> exportExcel(TaskReportData report) async {
    final bytes = _buildExcelBytes(report);
    await file_access.downloadBytesFile(
      fileName: 'santijet-${report.fileStem}.xlsx',
      bytes: bytes,
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      shareText: report.title,
    );
  }

  Future<Uint8List> _buildPdfBytes(TaskReportData report) async {
    final theme = await _pdfTheme();
    final doc = pw.Document(theme: theme);
    final now = DateTime.now();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(18),
        build: (context) => [
          pw.Text(
            report.title,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            report.subtitle,
            style: const pw.TextStyle(fontSize: 10, color: _inkMuted),
          ),
          pw.Text(
            'Oluşturulma: ${now.day.toString().padLeft(2, '0')}.'
            '${now.month.toString().padLeft(2, '0')}.${now.year} '
            '${now.hour.toString().padLeft(2, '0')}:'
            '${now.minute.toString().padLeft(2, '0')} · '
            '${report.taskCount} görev',
            style: const pw.TextStyle(fontSize: 8, color: _inkMuted),
          ),
          pw.SizedBox(height: 12),
          if (report.rows.isEmpty)
            pw.Text(
              'Seçilen filtrede görev yok.',
              style: const pw.TextStyle(fontSize: 11, color: _inkMuted),
            )
          else
            _table(report.headers, report.rows),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _table(List<String> headers, List<List<String>> rows) {
    final flatHeaders = [
      for (final h in headers) h.replaceAll('\n', ' '),
    ];
    return pw.TableHelper.fromTextArray(
      headers: flatHeaders,
      data: [
        for (final row in rows)
          [
            for (var i = 0; i < flatHeaders.length; i++)
              i < row.length ? row[i] : '',
          ],
      ],
      headerStyle: pw.TextStyle(
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
        color: _blue,
      ),
      headerDecoration: const pw.BoxDecoration(color: _headerBg),
      cellStyle: const pw.TextStyle(fontSize: 8, color: _ink),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.center,
      border: pw.TableBorder.all(color: _border, width: 0.5),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      columnWidths: {
        0: const pw.FixedColumnWidth(22),
        1: const pw.FlexColumnWidth(2.4),
        2: const pw.FixedColumnWidth(52),
        3: const pw.FlexColumnWidth(1.2),
        4: const pw.FlexColumnWidth(1.4),
        5: const pw.FixedColumnWidth(58),
        6: const pw.FixedColumnWidth(58),
        7: const pw.FixedColumnWidth(62),
        8: const pw.FlexColumnWidth(2),
      },
    );
  }

  List<int> _buildExcelBytes(TaskReportData report) {
    final excel = Excel.createExcel();
    excel.delete('Sheet1');
    final sheet = excel['Görevler'];
    for (var c = 0; c < report.headers.length; c++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0))
          .value = TextCellValue(report.headers[c].replaceAll('\n', ' '));
    }
    for (var r = 0; r < report.rows.length; r++) {
      final row = report.rows[r];
      for (var c = 0; c < report.headers.length; c++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1))
            .value = TextCellValue(c < row.length ? row[c] : '');
      }
    }
    sheet
        .cell(
          CellIndex.indexByColumnRow(
            columnIndex: 0,
            rowIndex: report.rows.length + 2,
          ),
        )
        .value = TextCellValue(
      '${report.title} · ${report.subtitle} · ${report.taskCount} görev',
    );
    return excel.encode()!;
  }
}

final taskExportService = TaskExportService();
