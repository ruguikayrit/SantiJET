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
    this.cutCards = const [],
    this.stockLengthM = 12,
  });

  final String title;
  final String? subtitle;
  final List<String> headers;
  final List<List<String>> rows;
  final List<(String, String)> keyValues;
  /// Uygulamadaki kesim özet kartlarıyla aynı içerik (görsel bar + formül).
  final List<PdfCutCardData> cutCards;
  final double stockLengthM;
}

/// PDF’te çizilecek tek kesim özet kartı.
class PdfCutCardData {
  const PdfCutCardData({
    required this.title,
    required this.formula,
    required this.remainder,
    required this.segments,
  });

  final String title;
  final String formula;
  final String remainder;
  final List<PdfCutSegmentData> segments;
}

class PdfCutSegmentData {
  const PdfCutSegmentData({
    required this.lengthM,
    required this.label,
    this.subtitle = '',
    this.isWaste = false,
  });

  final double lengthM;
  final String label;
  final String subtitle;
  final bool isWaste;
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

    widgets.add(pw.SizedBox(height: 8));

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
      if (section.cutCards.isNotEmpty ||
          (section.headers.isNotEmpty && section.rows.isNotEmpty)) {
        widgets.add(pw.SizedBox(height: 10));
      }
    }

    if (section.cutCards.isNotEmpty) {
      for (var i = 0; i < section.cutCards.length; i++) {
        if (i > 0) widgets.add(pw.SizedBox(height: 8));
        widgets.add(
          _buildCutCardWidget(
            section.cutCards[i],
            stockLengthM: section.stockLengthM,
          ),
        );
      }
    } else if (section.headers.isNotEmpty && section.rows.isNotEmpty) {
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

    widgets.add(pw.SizedBox(height: 20));
    return widgets;
  }

  pw.Widget _buildCutCardWidget(
    PdfCutCardData card, {
    required double stockLengthM,
  }) {
    final total = stockLengthM <= 0 ? 1.0 : stockLengthM;
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.8),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            card.title,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.orange800,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.SizedBox(
            height: 28,
            child: pw.Row(
              children: [
                for (final segment in card.segments)
                  pw.Expanded(
                    flex: ((segment.lengthM / total) * 1000).round().clamp(1, 100000),
                    child: pw.Container(
                      margin: const pw.EdgeInsets.only(right: 1),
                      alignment: pw.Alignment.center,
                      decoration: pw.BoxDecoration(
                        color: segment.isWaste
                            ? PdfColors.grey300
                            : PdfColors.indigo100,
                        border: pw.Border.all(
                          color: segment.isWaste
                              ? PdfColors.grey500
                              : PdfColors.indigo400,
                          width: 0.6,
                        ),
                      ),
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 2),
                        child: segment.isWaste
                            ? pw.Text(
                                'F',
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.grey700,
                                ),
                              )
                            : pw.Column(
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                children: [
                                  if (segment.label.isNotEmpty)
                                    pw.Text(
                                      segment.label,
                                      maxLines: 1,
                                      style: pw.TextStyle(
                                        fontSize: 7,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                  if (segment.subtitle.isNotEmpty)
                                    pw.Text(
                                      '${segment.subtitle} m',
                                      maxLines: 1,
                                      style: const pw.TextStyle(fontSize: 6),
                                    ),
                                ],
                              ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            card.formula,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            card.remainder,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.orange800,
            ),
          ),
        ],
      ),
    );
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
