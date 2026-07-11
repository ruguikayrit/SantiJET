import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

/// Çok bölümlü PDF raporu için tek bölüm tanımı.
class PdfReportSection {
  const PdfReportSection({
    required this.title,
    this.subtitle,
    this.headers = const [],
    this.rows = const [],
    this.keyValues = const [],
  });

  final String title;
  final String? subtitle;
  final List<String> headers;
  final List<List<String>> rows;
  final List<(String, String)> keyValues;
}

class ExportService {
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

  Future<void> sharePdf({
    required String title,
    required List<List<String>> rows,
    required List<String> headers,
  }) async {
    final bytes = await _buildPdfBytes(title: title, headers: headers, rows: rows);
    await _shareBytes(
      bytes: bytes,
      fileName: '${_safeFileName(title)}.pdf',
      mimeType: 'application/pdf',
    );
  }

  Future<void> shareExcel({
    required String title,
    required List<List<String>> rows,
    required List<String> headers,
  }) async {
    final bytes = _buildExcelBytes(title: title, headers: headers, rows: rows);
    await _shareBytes(
      bytes: bytes,
      fileName: '${_safeFileName(title)}.xlsx',
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }

  Future<void> previewPdf({
    required String title,
    required List<List<String>> rows,
    required List<String> headers,
  }) async {
    final bytes = await _buildPdfBytes(title: title, headers: headers, rows: rows);
    await previewPdfBytes(bytes);
  }

  Future<void> previewPdfBytes(List<int> bytes) async {
    await Printing.layoutPdf(
      onLayout: (_) async => Uint8List.fromList(bytes),
    );
  }

  Future<void> sharePdfBytes({
    required List<int> bytes,
    required String fileName,
  }) async {
    await _shareBytes(
      bytes: bytes,
      fileName: fileName,
      mimeType: 'application/pdf',
    );
  }

  Future<List<int>> buildMultiSectionPdfBytes({
    required String title,
    required List<PdfReportSection> sections,
    String? subtitle,
  }) async {
    final theme = await _pdfTheme();
    final doc = pw.Document(theme: theme);
    final now = DateTime.now();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          final widgets = <pw.Widget>[
            pw.Text(
              'ŞantiJET DEMİR',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              title,
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            if (subtitle != null && subtitle.isNotEmpty) ...[
              pw.SizedBox(height: 4),
              pw.Text(
                subtitle,
                style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
              ),
            ],
            pw.SizedBox(height: 4),
            pw.Text(
              'Oluşturulma: ${now.day}.${now.month}.${now.year} '
              '${now.hour}:${now.minute.toString().padLeft(2, '0')}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 24),
          ];

          for (final section in sections) {
            widgets.addAll(_buildSectionWidgets(section));
          }

          return widgets;
        },
      ),
    );

    return doc.save();
  }

  List<pw.Widget> _buildSectionWidgets(PdfReportSection section) {
    final widgets = <pw.Widget>[
      pw.Text(
        section.title,
        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
      ),
    ];

    if (section.subtitle != null && section.subtitle!.isNotEmpty) {
      widgets.addAll([
        pw.SizedBox(height: 4),
        pw.Text(
          section.subtitle!,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
      ]);
    }

    widgets.add(const pw.SizedBox(height: 8));

    if (section.keyValues.isNotEmpty) {
      widgets.add(
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: const {
            0: pw.FlexColumnWidth(2),
            1: pw.FlexColumnWidth(3),
          },
          children: section.keyValues
              .map(
                (entry) => pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      child: pw.Text(
                        entry.$1,
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      child: pw.Text(entry.$2, style: const pw.TextStyle(fontSize: 9)),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      );
    }

    if (section.headers.isNotEmpty && section.rows.isNotEmpty) {
      widgets.add(
        pw.TableHelper.fromTextArray(
          headers: section.headers,
          data: section.rows,
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
          cellStyle: const pw.TextStyle(fontSize: 8),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          cellAlignment: pw.Alignment.centerLeft,
          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        ),
      );
    } else if (section.headers.isNotEmpty && section.rows.isEmpty) {
      widgets.add(
        pw.Text(
          'Bu bölümde gösterilecek veri yok.',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
      );
    }

    widgets.add(const pw.SizedBox(height: 20));
    return widgets;
  }

  Future<List<int>> _buildPdfBytes({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
  }) async {
    final theme = await _pdfTheme();
    final doc = pw.Document(theme: theme);
    final now = DateTime.now();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Text(
            'ŞantiJET DEMİR',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Oluşturulma: ${now.day}.${now.month}.${now.year} '
            '${now.hour}:${now.minute.toString().padLeft(2, '0')}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: rows,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          ),
        ],
      ),
    );

    return doc.save();
  }

  List<int> _buildExcelBytes({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    final excel = Excel.createExcel();
    final sheet = excel['Rapor'];
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    sheet.appendRow([TextCellValue('ŞantiJET DEMİR — $title')]);
    sheet.appendRow([TextCellValue('')]);
    sheet.appendRow(headers.map(TextCellValue.new).toList());
    for (final row in rows) {
      sheet.appendRow(row.map(TextCellValue.new).toList());
    }

    return excel.encode()!;
  }

  Future<void> _shareBytes({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
  }) async {
    if (kIsWeb) {
      await Printing.sharePdf(bytes: Uint8List.fromList(bytes), filename: fileName);
      return;
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path, mimeType: mimeType)], text: fileName);
  }

  String _safeFileName(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}

final exportService = ExportService();
