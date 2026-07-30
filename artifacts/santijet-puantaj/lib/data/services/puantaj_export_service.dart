import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'puantaj_report_builder.dart';
import 'report_file_access_stub.dart'
    if (dart.library.html) 'report_file_access_web.dart'
    if (dart.library.io) 'report_file_access_io.dart' as file_access;

/// Puantaj cetvelini PDF / Excel olarak üretir ve paylaşır.
class PuantajExportService {
  pw.Font? _regularFont;
  pw.Font? _boldFont;

  Future<pw.ThemeData> _pdfTheme() async {
    _regularFont ??= await PdfGoogleFonts.notoSansRegular();
    _boldFont ??= await PdfGoogleFonts.notoSansBold();
    return pw.ThemeData.withFont(
      base: _regularFont!,
      bold: _boldFont!,
    );
  }

  Future<void> exportPdf(PuantajReportData report) async {
    final bytes = await _buildPdfBytes(report);
    await file_access.downloadBytesFile(
      fileName: 'santijet-puantaj-${report.fileStem}.pdf',
      bytes: bytes,
      mimeType: 'application/pdf',
      shareText: report.title,
    );
  }

  Future<void> exportExcel(PuantajReportData report) async {
    final bytes = _buildExcelBytes(report);
    await file_access.downloadBytesFile(
      fileName: 'santijet-puantaj-${report.fileStem}.xlsx',
      bytes: bytes,
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      shareText: report.title,
    );
  }

  Future<Uint8List> _buildPdfBytes(PuantajReportData report) async {
    final theme = await _pdfTheme();
    final doc = pw.Document(theme: theme);
    final now = DateTime.now();
    final pageFormat =
        report.landscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4;
    final cellFont = report.landscape ? 7.0 : 9.0;
    final headerFont = report.landscape ? 8.0 : 10.0;

    doc.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Text(
            'ŞantiJET Puantaj',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            report.title,
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            report.subtitle,
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'Oluşturulma: ${now.day.toString().padLeft(2, '0')}.'
            '${now.month.toString().padLeft(2, '0')}.${now.year} '
            '${now.hour.toString().padLeft(2, '0')}:'
            '${now.minute.toString().padLeft(2, '0')}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: report.headers,
            data: report.rows,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: headerFont,
            ),
            cellStyle: pw.TextStyle(fontSize: cellFont),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 3,
              vertical: 3,
            ),
          ),
          pw.SizedBox(height: 16),
          for (final line in report.summaryLines) ...[
            pw.Text(
              line,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: line.startsWith('Özet')
                    ? pw.FontWeight.bold
                    : pw.FontWeight.normal,
              ),
            ),
            pw.SizedBox(height: 4),
          ],
        ],
      ),
    );

    return Uint8List.fromList(await doc.save());
  }

  List<int> _buildExcelBytes(PuantajReportData report) {
    final excel = Excel.createExcel();
    final sheet = excel['Puantaj'];
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    sheet.appendRow([TextCellValue('ŞantiJET Puantaj — ${report.title}')]);
    sheet.appendRow([TextCellValue(report.subtitle)]);
    sheet.appendRow([TextCellValue('')]);
    sheet.appendRow(report.headers.map(TextCellValue.new).toList());
    for (final row in report.rows) {
      sheet.appendRow(row.map(TextCellValue.new).toList());
    }
    sheet.appendRow([TextCellValue('')]);
    for (final line in report.summaryLines) {
      sheet.appendRow([TextCellValue(line)]);
    }

    return excel.encode()!;
  }
}

final puantajExportService = PuantajExportService();
